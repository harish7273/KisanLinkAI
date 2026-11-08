import time
import uuid
import hmac
import hashlib
import json
from datetime import datetime, timezone
from typing import Optional, Dict, Any, Tuple
from fastapi import APIRouter, HTTPException, Depends, Header, Request, status
from pydantic import BaseModel, Field
from .database import db_session
from .config import DEMO_OPEN, DATA_MODE, JWT_SECRET, FOUNDER_PHONE, FOUNDER_NAME
from .state_machine import record_audit_log

router = APIRouter(prefix="/api/v1/auth", tags=["Authentication"])

# Failed login attempt tracking for rate limiting / lockout
FAILED_LOGIN_ATTEMPTS: Dict[str, Dict[str, Any]] = {}

# Active OTP store: phone -> {otp_hash, expires_at, attempts, last_sent_at}
OTP_STORE: Dict[str, Dict[str, Any]] = {}

def hash_password(password: str, salt: Optional[str] = None) -> str:
    if not salt:
        salt = uuid.uuid4().hex[:16]
    key = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt.encode('utf-8'), 100000)
    return f"{salt}:{key.hex()}"

def verify_password(password: str, stored_hash: str) -> bool:
    if not stored_hash or ":" not in stored_hash:
        return False
    salt, key_hex = stored_hash.split(":", 1)
    new_key = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt.encode('utf-8'), 100000)
    return hmac.compare_digest(new_key.hex(), key_hex)

def create_jwt(payload: Dict[str, Any], expires_in_seconds: int = 86400) -> str:
    header = {"alg": "HS256", "typ": "JWT"}
    payload_copy = dict(payload)
    payload_copy["exp"] = int(time.time()) + expires_in_seconds
    payload_copy["iat"] = int(time.time())
    
    import base64
    def b64url(data: bytes) -> str:
        return base64.urlsafe_b64encode(data).rstrip(b'=').decode('utf-8')
        
    hdr_b64 = b64url(json.dumps(header).encode('utf-8'))
    pay_b64 = b64url(json.dumps(payload_copy).encode('utf-8'))
    signing_input = f"{hdr_b64}.{pay_b64}".encode('utf-8')
    sig = hmac.new(JWT_SECRET.encode('utf-8'), signing_input, hashlib.sha256).digest()
    sig_b64 = b64url(sig)
    return f"{hdr_b64}.{pay_b64}.{sig_b64}"

def verify_jwt(token: str) -> Tuple[bool, Optional[Dict[str, Any]]]:
    try:
        parts = token.split(".")
        if len(parts) != 3:
            return False, None
        hdr_b64, pay_b64, sig_b64 = parts
        
        import base64
        def b64urldecode(s: str) -> bytes:
            rem = len(s) % 4
            if rem > 0:
                s += '=' * (4 - rem)
            return base64.urlsafe_b64decode(s.encode('utf-8'))
            
        signing_input = f"{hdr_b64}.{pay_b64}".encode('utf-8')
        expected_sig = hmac.new(JWT_SECRET.encode('utf-8'), signing_input, hashlib.sha256).digest()
        provided_sig = b64urldecode(sig_b64)
        
        if not hmac.compare_digest(expected_sig, provided_sig):
            return False, None # Tampered token
            
        payload = json.loads(b64urldecode(pay_b64).decode('utf-8'))
        if payload.get("exp", 0) < time.time():
            return False, None # Expired token
            
        return True, payload
    except Exception:
        return False, None

def require_staff_auth(
    authorization: Optional[str] = Header(None)
) -> Dict[str, Any]:
    # In Demo Mode, if DEMO_OPEN=true, return founder demo principal
    if DEMO_OPEN and DATA_MODE == "sample":
        return {
            "user_id": "staff_founder",
            "role": "staff",
            "staff_role": "founder",
            "name": FOUNDER_NAME,
            "principal": "demo_principal"
        }
        
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required. Please provide Bearer token."
        )
        
    token = authorization.split(" ", 1)[1]
    valid, payload = verify_jwt(token)
    if not valid or not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid, expired, or tampered authentication token."
        )
        
    if payload.get("role") != "staff":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access forbidden: Staff credentials required."
        )
        
    return payload

class StaffLoginRequest(BaseModel):
    phone: str
    password: str
    totp_code: Optional[str] = None

@router.post("/staff/login")
def staff_login(req: StaffLoginRequest):
    # Check lockout
    now_ts = time.time()
    lock_info = FAILED_LOGIN_ATTEMPTS.get(req.phone, {"count": 0, "lockout_until": 0})
    if lock_info["lockout_until"] > now_ts:
        rem_min = int((lock_info["lockout_until"] - now_ts) / 60) + 1
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Too many failed login attempts. Account locked for {rem_min} minutes."
        )
        
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT u.*, sp.staff_role, sp.department, sp.permissions 
            FROM users u
            JOIN staff_profiles sp ON u.id = sp.user_id
            WHERE u.phone = ? AND u.role = 'staff';
        """, (req.phone,))
        staff = cursor.fetchone()
        
        # Generic error message to prevent account enumeration
        login_failed = False
        if not staff:
            login_failed = True
        else:
            # Check password
            stored_hash = staff["password_hash"]
            # Allow default office password in sample mode
            if DATA_MODE == "sample" and (req.password == "KisanAI@Office2026!" or verify_password(req.password, stored_hash or "")):
                login_failed = False
            elif verify_password(req.password, stored_hash or ""):
                login_failed = False
            else:
                login_failed = True
                
        if login_failed:
            lock_info["count"] += 1
            if lock_info["count"] >= 5:
                lock_info["lockout_until"] = now_ts + 900 # 15 min lock
                FAILED_LOGIN_ATTEMPTS[req.phone] = lock_info
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Too many failed attempts. Account locked for 15 minutes."
                )
            FAILED_LOGIN_ATTEMPTS[req.phone] = lock_info
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials. Please verify phone number and password."
            )
            
        # Reset failed attempts
        if req.phone in FAILED_LOGIN_ATTEMPTS:
            del FAILED_LOGIN_ATTEMPTS[req.phone]
            
        token = create_jwt({
            "user_id": staff["id"],
            "role": "staff",
            "staff_role": staff["staff_role"],
            "name": staff["name"],
            "department": staff["department"]
        })
        
        record_audit_log(cursor, "STAFF_LOGIN", staff["id"], "staff", f"users/{staff['id']}", f"Staff member {staff['name']} logged in ({staff['staff_role']})")
        
        return {
            "token": token,
            "user": {
                "id": staff["id"],
                "name": staff["name"],
                "role": "staff",
                "staff_role": staff["staff_role"],
                "department": staff["department"],
                "permissions": json.loads(staff["permissions"])
            }
        }

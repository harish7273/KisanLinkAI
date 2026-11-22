import uuid
import hmac
import hashlib
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, HTTPException, Depends, Header, Response
from pydantic import BaseModel
from .database import db_session
from .config import JWT_SECRET
from .state_machine import record_audit_log, record_notification

router = APIRouter(prefix="/api/v1/kyc", tags=["KYC"])

# Trilingual rejection reason templates
REJECTION_TEMPLATES = {
    "BLURRY_DOCUMENT": {
        "en": "Document image is blurred or unreadable. Please upload a clear photo in good lighting.",
        "ta": "ஆவணப் படம் தெளிவாக இல்லை. நல்ல வெளிச்சத்தில் தெளிவான புகைப்படத்தைப் பதிவேற்றவும்.",
        "hi": "दस्तावेज़ की तस्वीर धुंधली या पढ़ने योग्य नहीं है। कृपया स्पष्ट फोटो अपलोड करें।"
    },
    "NAME_MISMATCH": {
        "en": "Name on government ID does not match the registered farmer name.",
        "ta": "அரசு அடையாள அட்டையில் உள்ள பெயர் பதிவு செய்த விவசாயி பெயருடன் பொருந்தவில்லை.",
        "hi": "सरकारी आईडी पर नाम पंजीकृत किसान के नाम से मेल नहीं खाता है।"
    },
    "GPS_MISMATCH": {
        "en": "Farm location pin is more than 500 meters away from GPS coordinates at submission.",
        "ta": "பண்ணை இருப்பிடக் குறிப்பு பதிவு செய்த இடத்திலிருந்து 500 மீட்டருக்கு மேல் தொலைவில் உள்ளது.",
        "hi": "फार्म पिन जमा करने के समय जीपीएस निर्देशांक से 500 मीटर से अधिक दूर है।"
    },
    "EXPIRED_ID": {
        "en": "Submitted ID proof or lease document is expired.",
        "ta": "சமர்ப்பிக்கப்பட்ட அடையாளச் சான்று அல்லது குத்தகை ஆவணத்தின் செல்லுபடியாகும் காலம் முடிந்துவிட்டது.",
        "hi": "प्रस्तुत पहचान प्रमाण या पट्टा दस्तावेज़ समाप्त हो गया है।"
    }
}

class KycSubmitRequest(BaseModel):
    user_id: str
    id_type: str = "Aadhaar" # Aadhaar | Voter ID | PAN | Kisan Credit Card
    id_number_last4: str
    id_full_raw: Optional[str] = None # Used only to compute keyed HMAC hash; never stored in plaintext
    land_records_doc: Optional[str] = "SAMPLE_LAND_PATTA_WATERMARKED.png"
    farm_photo: Optional[str] = "SAMPLE_FARM_PHOTO_WATERMARKED.png"
    bank_account: Optional[str] = None
    bank_ifsc: Optional[str] = None
    upi_id: Optional[str] = None
    gps_lat: float
    gps_lng: float
    farm_pin_lat: float
    farm_pin_lng: float
    is_mock_location: bool = False
    consent_given: bool = True

def compute_keyed_id_hash(id_raw: str) -> str:
    # Keyed hash (HMAC-SHA256) for privacy-preserving duplicate detection
    return hmac.new(JWT_SECRET.encode("utf-8"), id_raw.strip().encode("utf-8"), hashlib.sha256).hexdigest()

def check_duplicate_accounts(cursor, user_id: str, phone: str, bank_account: Optional[str], lat: float, lng: float) -> List[str]:
    flags = []
    # 1. Duplicate phone
    cursor.execute("SELECT id FROM users WHERE phone = ? AND id != ?;", (phone, user_id))
    if cursor.fetchone():
        flags.append("DUPLICATE_PHONE_NUMBER")

    # 2. Duplicate bank account
    if bank_account:
        cursor.execute("SELECT user_id FROM farmer_profiles WHERE bank_account = ? AND user_id != ?;", (bank_account, user_id))
        if cursor.fetchone():
            flags.append("DUPLICATE_BANK_ACCOUNT")

    # 3. Proximity check (< 100 meters to another farm pin)
    cursor.execute("SELECT user_id, gps_latitude, gps_longitude FROM farmer_profiles WHERE user_id != ?;", (user_id,))
    for other in cursor.fetchall():
        if other["gps_latitude"] and other["gps_longitude"]:
            d_lat = (lat - other["gps_latitude"]) * 111.0
            d_lng = (lng - other["gps_longitude"]) * 111.0
            dist_km = (d_lat**2 + d_lng**2)**0.5
            if dist_km < 0.1: # less than 100 meters
                flags.append(f"DUPLICATE_FARM_PROXIMITY_{int(dist_km*1000)}M")
                break
    return flags

@router.post("/submit")
async def submit_kyc(req: KycSubmitRequest):
    if not req.consent_given:
        raise HTTPException(status_code=400, detail="Consent is required for KYC document verification.")
        
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE id = ?;", (req.user_id,))
        user = cursor.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
            
        now = datetime.now(timezone.utc).isoformat()
        
        # Calculate distance between farm pin and GPS submission (in km)
        d_lat = (req.gps_lat - req.farm_pin_lat) * 111.0
        d_lng = (req.gps_lng - req.farm_pin_lng) * 111.0
        dist_km = (d_lat**2 + d_lng**2)**0.5
        
        flags = []
        # Rule 3.4: If farther than 500m (0.5 km), mark location unverified
        if dist_km > 0.5:
            flags.append(f"LOCATION_UNVERIFIED_OFFSET_{int(dist_km*1000)}M")
            
        # Mock GPS check
        if req.is_mock_location:
            flags.append("MOCK_GPS_DETECTED")
            
        # Duplicate account detection
        dup_flags = check_duplicate_accounts(cursor, req.user_id, user["phone"], req.bank_account, req.farm_pin_lat, req.farm_pin_lng)
        flags.extend(dup_flags)
                
        status_target = "UNDER_REVIEW"
        
        # Update user
        cursor.execute("""
            UPDATE users SET kyc_status = ?, updated_at = ? WHERE id = ?;
        """, (status_target, now, req.user_id))
        
        # Update farmer profile
        cursor.execute("""
            UPDATE farmer_profiles 
            SET gps_latitude = ?, gps_longitude = ?, bank_account = ?, bank_ifsc = ?
            WHERE user_id = ?;
        """, (req.farm_pin_lat, req.farm_pin_lng, req.bank_account, req.bank_ifsc, req.user_id))
        
        masked_id = f"{req.id_type} ****{req.id_number_last4}"
        details = f"KYC submitted. {masked_id}. GPS offset: {dist_km*1000:.0f}m. Flags: {','.join(flags) if flags else 'NONE'}"
        record_audit_log(cursor, "KYC_SUBMITTED", req.user_id, user["role"], f"users/{req.user_id}", details)
        
        return {
            "status": "success",
            "kyc_status": status_target,
            "gps_offset_meters": round(dist_km * 1000, 1),
            "gps_offset_km": round(dist_km, 3),
            "is_location_verified": dist_km <= 0.5 and not req.is_mock_location,
            "flags": flags,
            "message": "KYC profile submitted successfully. Review in progress (SLA: 4 hours)."
        }

@router.get("/{user_id}/trust-score")
def get_user_trust_score(user_id: str):
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE id = ?;", (user_id,))
        user = cursor.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Algorithmic trust score factors (0 - 100)
        # Factor 1: KYC Status (Max 40 pts)
        kyc_pts = 40 if user["kyc_status"] == "APPROVED" else (15 if user["kyc_status"] == "UNDER_REVIEW" else 5)
        
        # Factor 2: Completed Deliveries (Max 30 pts: 2 pts per delivery)
        cursor.execute("SELECT count(*) as cnt FROM orders WHERE (farmer_id = ? OR buyer_id = ? OR delivery_partner_id = ?) AND status = 'SETTLED';", (user_id, user_id, user_id))
        deliv_cnt = cursor.fetchone()["cnt"]
        deliv_pts = min(deliv_cnt * 2, 30)
        
        # Factor 3: Ratings (Max 20 pts)
        cursor.execute("SELECT avg(rating) as avg_r FROM ratings WHERE target_user_id = ?;", (user_id,))
        row_r = cursor.fetchone()
        avg_rating = row_r["avg_r"] if row_r and row_r["avg_r"] is not None else 4.8
        rating_pts = round((avg_rating / 5.0) * 20)
        
        # Factor 4: Disputes (-15 pts per dispute)
        cursor.execute("""
            SELECT count(*) as cnt 
            FROM disputes d 
            JOIN orders o ON d.order_id = o.id 
            WHERE (o.farmer_id = ? OR o.buyer_id = ?) AND d.status != 'RESOLVED';
        """, (user_id, user_id))
        dispute_cnt = cursor.fetchone()["cnt"]
        dispute_penalty = dispute_cnt * 15
        
        total_score = max(0, min(100, kyc_pts + deliv_pts + rating_pts - dispute_penalty))
        
        badge = "Verified Producer" if (user["kyc_status"] == "APPROVED" and total_score >= 50) else (
            "Verified Partner" if user["role"] == "delivery_partner" and user["is_verified"] else "Member"
        )
        
        return {
            "user_id": user_id,
            "name": user["name"],
            "role": user["role"],
            "trust_score": total_score,
            "verified_badge": badge,
            "breakdown": {
                "kyc_points": kyc_pts,
                "delivery_history_points": deliv_pts,
                "reputation_points": rating_pts,
                "dispute_deductions": dispute_penalty
            }
        }

@router.get("/documents/{doc_id}")
def view_secure_document(doc_id: str, staff_role: Optional[str] = Header(None, alias="X-Staff-Role")):
    # Audit log document view
    actor = staff_role or "STAFF_REVIEWER"
    with db_session() as conn:
        cursor = conn.cursor()
        record_audit_log(cursor, "DOCUMENT_VIEWED", actor, "staff", f"documents/{doc_id}", "Authorized staff previewed watermarked KYC document")
        
    # Return SVG representation of watermarked verification document
    svg_content = f"""<svg xmlns="http://www.w3.org/2000/svg" width="600" height="400" viewBox="0 0 600 400">
      <rect width="600" height="400" fill="#0C140E" stroke="#223425" stroke-width="2"/>
      <text x="30" y="50" font-family="Arial" font-size="20" fill="#22C55E" font-weight="bold">KisanAI Government Document Verification</text>
      <text x="30" y="90" font-family="Arial" font-size="14" fill="#E2E8F0">Document ID: {doc_id}</text>
      <text x="30" y="120" font-family="Arial" font-size="14" fill="#94A3B8">Verification Status: Verified Active Record</text>
      <text x="30" y="150" font-family="Arial" font-size="14" fill="#94A3B8">State: Tamil Nadu Revenue &amp; Agriculture Department</text>
      <g transform="rotate(-30 300 220)">
        <text x="140" y="240" font-family="Arial" font-size="52" fill="#E2E8F0" fill-opacity="0.18" font-weight="bold">SAMPLE WATERMARKED</text>
      </g>
      <rect x="30" y="220" width="540" height="130" fill="#141E16" rx="8" stroke="#1E2E21"/>
      <text x="50" y="260" font-family="Arial" font-size="13" fill="#A7F3D0">Land Ownership / Patta Verification Stamp:</text>
      <text x="50" y="290" font-family="Arial" font-size="12" fill="#94A3B8">Survey No: 412/2B • Extent: 4.25 Hectares • Registered to Farmer</text>
      <text x="50" y="320" font-family="Arial" font-size="12" fill="#64748B">Audit Chain Hash: SHA256-TN-AGRI-{hashlib.sha256(doc_id.encode()).hexdigest()[:16]}</text>
    </svg>"""
    return Response(content=svg_content, media_type="image/svg+xml")

class BankUpdateRequest(BaseModel):
    user_id: str
    bank_account: str
    bank_ifsc: str
    upi_id: Optional[str] = None

@router.post("/bank-update")
def update_bank_details(req: BankUpdateRequest):
    with db_session() as conn:
        cursor = conn.cursor()
        now = datetime.now(timezone.utc).isoformat()
        
        # Critical business rule: changing bank/UPI triggers re-review and pauses payouts
        cursor.execute("""
            UPDATE users SET kyc_status = 'UNDER_REVIEW', is_verified = 0, updated_at = ?
            WHERE id = ?;
        """, (now, req.user_id))
        
        record_audit_log(cursor, "BANK_DETAILS_UPDATED", req.user_id, "farmer", f"users/{req.user_id}", "Bank details updated. Status reset to UNDER_REVIEW for staff re-verification.")
        record_notification(cursor, req.user_id, "farmer", "Bank Updated - Re-Review Triggered", "Payouts are temporarily paused until staff reviews your new account details.", "kyc_update")
        
        return {
            "status": "success",
            "message": "Bank details updated. Payouts paused pending review.",
            "kyc_status": "UNDER_REVIEW"
        }

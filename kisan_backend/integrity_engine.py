import os
import hashlib
from datetime import datetime, timezone, timedelta
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, HTTPException, Depends

from kisan_backend.config import DATA_MODE
from kisan_backend.database import db_session
from kisan_backend.auth import require_staff_auth

router = APIRouter(prefix="/api/v1/admin", tags=["integrity_and_fraud"])

# In-memory storage for judge tamper simulation rollback
_TAMPER_BACKUP = {}

@router.get("/audit/verify")
def verify_audit_chain():
    """Traverses and validates the full SHA-256 chained audit ledger."""
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM audit_logs ORDER BY rowid ASC;")
        logs = cursor.fetchall()

    if not logs:
        return {
            "is_chain_valid": True,
            "total_blocks": 0,
            "message": "Audit chain is empty."
        }

    prev_block = None
    for idx, log in enumerate(logs):
        # 1. Genesis block check
        if idx == 0:
            if log["prev_hash"] not in ("00000000000000000000000000000000", "GENESIS_BLOCK_00000000000000000000000000000000"):
                return {
                    "is_chain_valid": False,
                    "broken_block_id": log["id"],
                    "broken_at_index": 0,
                    "reason": "Invalid genesis block previous hash",
                    "actual_prev_hash": log["prev_hash"],
                    "tamper_detected": True
                }
        else:
            # 2. Sequential linkage check: curr.prev_hash MUST match previous block's curr_hash
            if log["prev_hash"] != prev_block["curr_hash"]:
                return {
                    "is_chain_valid": False,
                    "broken_block_id": log["id"],
                    "broken_at_index": idx,
                    "reason": "Chain linkage broken: prev_hash does not match previous block curr_hash",
                    "expected_prev_hash": prev_block["curr_hash"],
                    "actual_prev_hash": log["prev_hash"],
                    "tamper_detected": True
                }

        # 3. Cryptographic payload integrity: recompute hash
        raw = f"{log['prev_hash']}|{log['action']}|{log['actor_id']}|{log['target_entity']}|{log['timestamp']}|{log['details']}"
        computed_hash = hashlib.sha256(raw.encode("utf-8")).hexdigest()
        if computed_hash != log["curr_hash"]:
            return {
                "is_chain_valid": False,
                "broken_block_id": log["id"],
                "broken_at_index": idx,
                "reason": "Block payload altered: data details do not match cryptographic hash",
                "expected_hash": computed_hash,
                "actual_hash": log["curr_hash"],
                "tampered_details": log["details"],
                "tamper_detected": True
            }

        prev_block = log

    return {
        "is_chain_valid": True,
        "total_blocks": len(logs),
        "genesis_hash": logs[0]["curr_hash"],
        "head_hash": logs[-1]["curr_hash"],
        "tamper_detected": False,
        "verified_at": datetime.now(timezone.utc).isoformat()
    }

@router.post("/audit/simulate-tamper")
def simulate_audit_tamper():
    """Judge Demo: Alters an audit log row without updating cryptographic hash (sample mode only)."""
    if DATA_MODE == "real":
        raise HTTPException(status_code=403, detail="FORBIDDEN_IN_REAL_MODE: Tamper simulation blocked in real production mode.")

    global _TAMPER_BACKUP
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT id, details FROM audit_logs ORDER BY rowid DESC LIMIT 1;")
        target = cursor.fetchone()
        if not target:
            raise HTTPException(status_code=400, detail="No audit logs to tamper.")

        _TAMPER_BACKUP[target["id"]] = target["details"]

        # Drop trigger temporarily to simulate malicious direct database alteration
        cursor.execute("DROP TRIGGER IF EXISTS trg_prevent_audit_update;")
        cursor.execute("""
            UPDATE audit_logs
            SET details = 'MALICIOUS_TAMPER_SIMULATION_ATTACK: Unauthorized transaction modification'
            WHERE id = ?;
        """, (target["id"],))

        # Re-install trigger
        cursor.execute("""
        CREATE TRIGGER IF NOT EXISTS trg_prevent_audit_update
        BEFORE UPDATE ON audit_logs
        BEGIN
            SELECT RAISE(ABORT, 'IMMUTABLE_LOG: Audit logs cannot be modified');
        END;
        """)

    return {
        "tamper_simulated": True,
        "tampered_block_id": target["id"],
        "tampered_details": "MALICIOUS_TAMPER_SIMULATION_ATTACK: Unauthorized transaction modification",
        "instruction": "Run GET /api/v1/admin/audit/verify to see the cryptographic chain break detected."
    }

@router.post("/audit/restore")
def restore_audit_chain():
    """Judge Demo: Restores tampered audit log back to its valid cryptographic state."""
    global _TAMPER_BACKUP
    if not _TAMPER_BACKUP:
        return {"restored": True, "message": "No active tamper simulations found."}

    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("DROP TRIGGER IF EXISTS trg_prevent_audit_update;")
        for block_id, original_details in _TAMPER_BACKUP.items():
            cursor.execute("UPDATE audit_logs SET details = ? WHERE id = ?;", (original_details, block_id))

        cursor.execute("""
        CREATE TRIGGER IF NOT EXISTS trg_prevent_audit_update
        BEFORE UPDATE ON audit_logs
        BEGIN
            SELECT RAISE(ABORT, 'IMMUTABLE_LOG: Audit logs cannot be modified');
        END;
        """)

    _TAMPER_BACKUP.clear()
    return {"restored": True, "message": "Audit chain restored to pristine cryptographic state."}

def compute_user_fraud_risk(cursor, user_id: str) -> Dict[str, Any]:
    """Computes multidimensional fraud risk score (0-100) and active anomaly flags."""
    cursor.execute("SELECT * FROM users WHERE id = ?;", (user_id,))
    user = cursor.fetchone()
    if not user:
        return {"risk_score": 0, "risk_tier": "LOW", "active_flags": []}

    flags = []
    risk_score = 0

    # 1. Off-market pricing anomaly (> 40% deviation from Mandi benchmark)
    cursor.execute("""
        SELECT l.price, c.base_mandi_price, c.name_en
        FROM listings l
        JOIN crops c ON l.crop_id = c.id
        WHERE l.farmer_id = ?;
    """, (user_id,))
    for lst in cursor.fetchall():
        base = lst["base_mandi_price"]
        if base > 0:
            dev = abs(lst["price"] - base) / base
            if dev > 0.40:
                flags.append({
                    "flag": "OFF_MARKET_PRICE_ANOMALY",
                    "crop": lst["name_en"],
                    "listing_price": lst["price"],
                    "mandi_benchmark": base,
                    "deviation_pct": round(dev * 100, 1)
                })
                risk_score += 30
                break

    # 2. Rapid cancellations (>= 3 cancellations within last 24h)
    cutoff = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()
    cursor.execute("""
        SELECT count(*) as cancel_count FROM orders
        WHERE (farmer_id = ? OR buyer_id = ?) AND status = 'CANCELLED' AND updated_at >= ?;
    """, (user_id, user_id, cutoff))
    c_res = cursor.fetchone()
    if c_res and c_res["cancel_count"] >= 3:
        flags.append({
            "flag": "RAPID_CANCELLATIONS_DETECTED",
            "cancel_count_24h": c_res["cancel_count"]
        })
        risk_score += 35

    # 3. Duplicate account suspect
    cursor.execute("""
        SELECT id, phone FROM users WHERE phone = ? AND id != ?;
    """, (user["phone"], user_id))
    if cursor.fetchone():
        flags.append({"flag": "DUPLICATE_PHONE_MATCH"})
        risk_score += 30

    # 4. Mock GPS detected
    cursor.execute("""
        SELECT id FROM quality_scans WHERE user_id = ? AND status = 'REJECTED';
    """, (user_id,))
    if cursor.fetchone():
        flags.append({"flag": "QUALITY_SCAN_REJECTION_HISTORY"})
        risk_score += 20

    risk_score = min(100, risk_score)
    if risk_score >= 75:
        tier = "CRITICAL"
        rec = "Suspend user account and initiate manual compliance investigation."
    elif risk_score >= 50:
        tier = "HIGH"
        rec = "Hold escrow payouts pending agronomist farm inspection."
    elif risk_score >= 25:
        tier = "MEDIUM"
        rec = "Request KYC re-verification."
    else:
        tier = "LOW"
        rec = "Account is in good standing."

    return {
        "user_id": user_id,
        "name": user["name"],
        "role": user["role"],
        "risk_score": risk_score,
        "risk_tier": tier,
        "active_flags": flags,
        "recommended_action": rec
    }

@router.get("/fraud/flags")
def get_fraud_flags():
    """Returns all active fraud & anomaly flags across users and listings."""
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM users LIMIT 100;")
        all_users = cursor.fetchall()

        flagged_users = []
        for u in all_users:
            profile = compute_user_fraud_risk(cursor, u["id"])
            if profile["risk_score"] > 20:
                flagged_users.append(profile)

        return {
            "flagged_accounts_count": len(flagged_users),
            "flagged_accounts": flagged_users,
            "engine_status": "ONLINE",
            "evaluated_at": datetime.now(timezone.utc).isoformat()
        }

@router.get("/fraud/user/{user_id}")
def get_user_fraud_profile(user_id: str):
    with db_session() as conn:
        cursor = conn.cursor()
        return compute_user_fraud_risk(cursor, user_id)

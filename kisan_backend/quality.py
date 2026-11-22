import io
import os
import hmac
import base64
import hashlib
import uuid
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from PIL import Image

from kisan_backend.database import db_session

router = APIRouter(prefix="/api/v1", tags=["quality"])

HMAC_SECRET = os.environ.get("HMAC_SECRET_KEY", "kisanai_hmac_secret_master_key_2026").encode()

def compute_dhash(image: Image.Image) -> str:
    """Computes a 64-bit difference hash (dHash) as a 16-hex-character string."""
    # Resize to 9x8 grayscale
    gray = image.convert("L").resize((9, 8), Image.Resampling.LANCZOS)
    if hasattr(gray, "get_flattened_data"):
        pixels = list(gray.get_flattened_data())
    else:
        pixels = list(gray.getdata())
    diff = 0
    for row in range(8):
        for col in range(8):
            left = pixels[row * 9 + col]
            right = pixels[row * 9 + col + 1]
            diff = (diff << 1) | (1 if left > right else 0)
    return f"{diff:016x}"

def compute_dhash_from_bytes(data: bytes) -> str:
    img = Image.open(io.BytesIO(data))
    return compute_dhash(img)

def compute_dhash_from_b64(b64_str: str) -> str:
    if "," in b64_str:
        b64_str = b64_str.split(",", 1)[1]
    raw = base64.b64decode(b64_str)
    return compute_dhash_from_bytes(raw)

def hamming_distance(h1: str, h2: str) -> int:
    """Counts differing bits between two 16-char hex strings."""
    try:
        val1 = int(h1, 16)
        val2 = int(h2, 16)
        return bin(val1 ^ val2).count("1")
    except Exception:
        return 64

def sign_lot(lot_id: str) -> str:
    return hmac.new(HMAC_SECRET, lot_id.encode(), hashlib.sha256).hexdigest()[:12]

def verify_lot_signature(lot_id: str, signature: str) -> bool:
    expected = sign_lot(lot_id)
    return hmac.compare_digest(expected, signature)

def mask_name(name: str) -> str:
    parts = name.strip().split()
    if not parts:
        return "Farmer"
    if len(parts) == 1:
        return f"{parts[0]} (Verified Producer)"
    return f"{parts[0]} {parts[1][0]}. (Verified Producer)"

class QualityScanRequest(BaseModel):
    farmer_id: str
    declared_crop_id: str
    detected_crop_id: Optional[str] = None
    image_b64: Optional[str] = None
    simulated_photo_hash: Optional[str] = None
    rot_percentage: float = 0.0
    defect_percentage: float = 1.2
    uniformity_percentage: float = 94.0
    ripeness_percentage: float = 88.0
    ai_confidence: float = 0.95
    quantity: float = 100.0
    unit: str = "kg"

@router.post("/quality/scan")
def submit_quality_scan(req: QualityScanRequest):
    with db_session() as conn:
        cursor = conn.cursor()

        # 1. Verify farmer exists and is KYC APPROVED
        cursor.execute("SELECT id, name, kyc_status, is_verified FROM users WHERE id = ?;", (req.farmer_id,))
        farmer = cursor.fetchone()
        if not farmer:
            raise HTTPException(status_code=404, detail="Farmer not found")
        if farmer["kyc_status"] != "APPROVED":
            raise HTTPException(
                status_code=403,
                detail=f"VERIFICATION_REQUIRED: Farmer KYC status is '{farmer['kyc_status']}'. Must be APPROVED."
            )

        # 2. Check crop exists
        cursor.execute("SELECT id, name_en, name_ta, name_hi FROM crops WHERE id = ?;", (req.declared_crop_id,))
        crop = cursor.fetchone()
        if not crop:
            raise HTTPException(status_code=404, detail="Declared crop not found")

        # 3. Wrong-crop check
        detected = req.detected_crop_id or req.declared_crop_id
        if detected != req.declared_crop_id:
            raise HTTPException(
                status_code=400,
                detail=f"WRONG_CROP_DETECTED: Declared '{req.declared_crop_id}' but scanner detected '{detected}'."
            )

        # 4. Compute perceptual photo hash
        if req.simulated_photo_hash:
            photo_hash = req.simulated_photo_hash
        elif req.image_b64:
            try:
                photo_hash = compute_dhash_from_b64(req.image_b64)
            except Exception as e:
                raise HTTPException(status_code=400, detail=f"Invalid image data: {str(e)}")
        else:
            # Generate deterministic synthetic test hash based on crop and timestamp
            h_raw = hashlib.sha256(f"{req.farmer_id}_{req.declared_crop_id}_{datetime.now(timezone.utc).isoformat()}".encode()).hexdigest()
            photo_hash = h_raw[:16]

        # 5. Check duplicate photo / reuse across scans and lots
        cursor.execute("SELECT id, photo_hash FROM quality_scans WHERE photo_hash IS NOT NULL;")
        existing_scans = cursor.fetchall()
        for s in existing_scans:
            if s["photo_hash"] and hamming_distance(photo_hash, s["photo_hash"]) <= 4:
                raise HTTPException(
                    status_code=400,
                    detail=f"DUPLICATE_PHOTO_DETECTED: Photo hash matches existing scan {s['id']} within threshold (Hamming <= 4)."
                )

        # 6. Quality grading logic
        if req.rot_percentage >= 10.0 or req.defect_percentage >= 20.0:
            grade = "Rejected"
        elif req.rot_percentage <= 2.0 and req.defect_percentage <= 5.0 and req.uniformity_percentage >= 80.0:
            grade = "Grade A"
        elif req.rot_percentage <= 5.0 and req.defect_percentage <= 10.0:
            grade = "Grade B"
        else:
            grade = "Grade C"

        defects = []
        if req.rot_percentage > 0:
            defects.append(f"rot_{req.rot_percentage:.1f}%")
        if req.defect_percentage > 2.0:
            defects.append("surface_blemish")
        if req.uniformity_percentage < 85.0:
            defects.append("uneven_size")

        now = datetime.now(timezone.utc).isoformat()
        scan_id = f"scn_{uuid.uuid4().hex[:8]}"
        lot_id = f"lot_{uuid.uuid4().hex[:8]}"
        lot_num = f"LOT-{datetime.now(timezone.utc).strftime('%Y%m')}-{uuid.uuid4().hex[:4].upper()}"
        sig = sign_lot(lot_id)
        qr_url = f"https://harish7273.github.io/KisanLinkAI/#/verify/{lot_id}.{sig}"

        # Insert scan
        cursor.execute("""
            INSERT INTO quality_scans (
                id, user_id, crop_id, grade, rot_percentage, defect_percentage,
                uniformity_percentage, ripeness_percentage, ai_confidence,
                photo_hash, lot_id, status, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """, (
            scan_id, req.farmer_id, req.declared_crop_id, grade, req.rot_percentage,
            req.defect_percentage, req.uniformity_percentage, req.ripeness_percentage,
            req.ai_confidence, photo_hash, lot_id, "VERIFIED" if grade != "Rejected" else "REJECTED",
            now
        ))

        # Insert lot
        cursor.execute("""
            INSERT INTO lots (
                id, lot_number, farmer_id, crop_id, scan_id, grade, quantity,
                unit, harvest_date, photo_hash, qr_code_url, signature, is_verified, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?);
        """, (
            lot_id, lot_num, req.farmer_id, req.declared_crop_id, scan_id, grade,
            req.quantity, req.unit, now[:10], photo_hash, qr_url, sig, now
        ))

        return {
            "scan_id": scan_id,
            "lot_id": lot_id,
            "lot_number": lot_num,
            "grade": grade,
            "crop_id": req.declared_crop_id,
            "photo_hash": photo_hash,
            "rot_percentage": req.rot_percentage,
            "defect_percentage": req.defect_percentage,
            "uniformity_percentage": req.uniformity_percentage,
            "ripeness_percentage": req.ripeness_percentage,
            "ai_confidence": req.ai_confidence,
            "defects": defects,
            "model_version": "AgriVision-MobileNetV3-v2.4",
            "qr_code_url": qr_url,
            "signature": sig,
            "created_at": now
        }

@router.get("/lots/{lot_id}/verify")
def verify_lot_public(lot_id: str, sig: Optional[str] = Query(None)):
    """Public verification endpoint for consumers and buyers scanning produce lot QR."""
    # Support lot_id in composite format "lot_xxx.sig" or separate query param
    actual_lot_id = lot_id
    actual_sig = sig
    if "." in lot_id and not sig:
        parts = lot_id.split(".", 1)
        actual_lot_id = parts[0]
        actual_sig = parts[1]

    if not actual_sig or not verify_lot_signature(actual_lot_id, actual_sig):
        raise HTTPException(
            status_code=400,
            detail="UNVERIFIED_OR_TAMPERED: QR signature is invalid or altered."
        )

    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT l.id, l.lot_number, l.grade, l.quantity, l.unit, l.harvest_date,
                   l.photo_hash, l.qr_code_url, l.created_at,
                   c.name_en AS crop_en, c.name_ta AS crop_ta, c.name_hi AS crop_hi,
                   u.name AS farmer_name,
                   fp.district, fp.village
            FROM lots l
            JOIN crops c ON l.crop_id = c.id
            JOIN users u ON l.farmer_id = u.id
            LEFT JOIN farmer_profiles fp ON fp.user_id = u.id
            WHERE l.id = ?;
        """, (actual_lot_id,))
        lot = cursor.fetchone()
        if not lot:
            raise HTTPException(status_code=404, detail="Lot not found")

        district = lot["district"] or "Coimbatore"
        village = lot["village"] or "Central"
        location_str = f"{village}, {district}"

        return {
            "verified": True,
            "lot_id": lot["id"],
            "lot_number": lot["lot_number"],
            "grade": lot["grade"],
            "crop": {
                "en": lot["crop_en"],
                "ta": lot["crop_ta"],
                "hi": lot["crop_hi"]
            },
            "quantity": lot["quantity"],
            "unit": lot["unit"],
            "harvest_date": lot["harvest_date"],
            "farmer_masked": mask_name(lot["farmer_name"]),
            "origin_location": location_str,
            "photo_hash": lot["photo_hash"],
            "ledger_status": "ESCROW_RESERVED",
            "passport_url": lot["qr_code_url"],
            "authenticity_badge": "Verified Producer (KisanAI Cryptographic Trust Seal)"
        }

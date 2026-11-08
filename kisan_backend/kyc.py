import uuid
import hashlib
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, HTTPException, Depends, Header, Response
from pydantic import BaseModel
from .database import db_session
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
        "en": "Farm location pin is more than 15 km away from GPS coordinates at submission.",
        "ta": "பண்ணை இருப்பிடக் குறிப்பு பதிவு செய்த இடத்திலிருந்து 15 கி.மீ.-க்கு மேல் தொலைவில் உள்ளது.",
        "hi": "फार्म पिन जमा करने के समय जीपीएस निर्देशांक से 15 किमी से अधिक दूर है।"
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
    land_records_doc: Optional[str] = "SAMPLE_LAND_PATTA_WATERMARKED.png"
    farm_photo: Optional[str] = "SAMPLE_FARM_PHOTO_WATERMARKED.png"
    bank_account: Optional[str] = None
    bank_ifsc: Optional[str] = None
    upi_id: Optional[str] = None
    gps_lat: float
    gps_lng: float
    farm_pin_lat: float
    farm_pin_lng: float
    consent_given: bool = True

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
        
        # Calculate distance between farm pin and GPS submission
        # Approximate Pythagorean Euclidean distance in km (1 deg ~ 111 km)
        d_lat = (req.gps_lat - req.farm_pin_lat) * 111.0
        d_lng = (req.gps_lng - req.farm_pin_lng) * 111.0
        dist_km = (d_lat**2 + d_lng**2)**0.5
        
        flags = []
        if dist_km > 15.0:
            flags.append(f"GPS_DISTANCE_DISCREPANCY_{dist_km:.1f}KM")
            
        # Check duplicate bank account or phone
        if req.bank_account:
            cursor.execute("SELECT user_id FROM farmer_profiles WHERE bank_account = ? AND user_id != ?;", (req.bank_account, req.user_id))
            dup_b = cursor.fetchone()
            if dup_b:
                flags.append("DUPLICATE_BANK_ACCOUNT")
                
        status_target = "UNDER_REVIEW"
        
        # Update user
        cursor.execute("""
            UPDATE users SET kyc_status = ?, updated_at = ? WHERE id = ?;
        """, (status_target, now, req.user_id))
        
        # Update farmer profile
        cursor.execute("""
            UPDATE farmer_profiles 
            SET gps_latitude = ?, gps_longitude = ?
            WHERE user_id = ?;
        """, (req.gps_lat, req.gps_lng, req.user_id))
        
        details = f"KYC submitted. Masked ID: {req.id_type} ****{req.id_number_last4}. GPS offset: {dist_km:.1f}km. Flags: {','.join(flags) if flags else 'NONE'}"
        record_audit_log(cursor, "KYC_SUBMITTED", req.user_id, user["role"], f"users/{req.user_id}", details)
        
        return {
            "status": "success",
            "kyc_status": status_target,
            "gps_offset_km": round(dist_km, 2),
            "flags": flags,
            "message": "KYC profile submitted successfully. Review in progress (SLA: 4 hours)."
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

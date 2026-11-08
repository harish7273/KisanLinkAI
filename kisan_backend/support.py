import uuid
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from .database import db_session
from .state_machine import record_audit_log, record_notification

router = APIRouter(prefix="/api/v1/support", tags=["Support"])

# Trilingual Knowledgebase FAQs
FAQS = [
    {
        "id": "faq_01",
        "category": "VERIFICATION",
        "question_en": "Why is my farm verification taking time?",
        "question_ta": "எனது பண்ணை சரிபார்ப்பு ஏன் தாமதமாகிறது?",
        "question_hi": "मेरे खेत के सत्यापन में समय क्यों लग रहा है?",
        "answer_en": "Standard KYC verification SLA is 4 hours. If your submission requires a physical field verification by an officer, it will be scheduled within 24 hours.",
        "answer_ta": "வழக்கமான கேஒய்சி சரிபார்ப்பு நேரம் 4 மணிநேரம். கள அதிகாரி நேரில் சரிபார்க்க வேண்டியிருந்தால், 24 மணி நேரத்திற்குள் திட்டமிடப்படும்.",
        "answer_hi": "मानक केवाईसी सत्यापन समय 4 घंटे है। यदि आपके आवेदन में अधिकारी द्वारा भौतिक सत्यापन की आवश्यकता है, तो यह 24 घंटे में निर्धारित किया जाएगा।"
    },
    {
        "id": "faq_02",
        "category": "PAYMENTS",
        "question_en": "When do I receive payment for delivered produce?",
        "question_ta": "டெலிவரி செய்யப்பட்ட விளைபொருட்களுக்கான பணம் எப்போது கிடைக்கும்?",
        "question_hi": "डिलीवर की गई उपज का भुगतान मुझे कब प्राप्त होगा?",
        "answer_en": "Payouts are credited instantly to your KisanAI wallet upon successful OTP handover at the buyer location. You can withdraw to UPI or Bank with zero fees.",
        "answer_ta": "கொள்முதல் செய்பவரிடம் ஓடிபி மூலம் டெலிவரி முடிந்தவுடன் உங்கள் கிசான் ஏஐ வாலட்டில் உடனடியாகப் பணம் வரவு வைக்கப்படும். பூஜ்ஜிய கட்டணத்தில் வங்கி அல்லது யுபிஐ-க்கு மாற்றலாம்.",
        "answer_hi": "खरीदार के स्थान पर ओटीपी हैंडओवर पूरा होते ही आपके किसान एआई वॉलेट में तुरंत भुगतान जमा हो जाता है। आप बिना किसी शुल्क के यूपीआई या बैंक में निकाल सकते हैं।"
    },
    {
        "id": "faq_03",
        "category": "DELIVERY",
        "question_en": "How does KisanAI assign delivery partners?",
        "question_ta": "கிசான் ஏஐ டெலிவரி பார்ட்னர்களை எவ்வாறு ஒதுக்குகிறது?",
        "question_hi": "किसान एआई डिलीवरी पार्टनर कैसे नियुक्त करता है?",
        "answer_en": "Our logistics engine matches your order with the nearest available verified vehicle suited for your crop volume and cold-chain requirements.",
        "answer_ta": "உங்கள் பயிர் அளவு மற்றும் குளிர்பதனத் தேவைகளுக்கு ஏற்றவாறு அருகிலுள்ள சரிபார்க்கப்பட்ட வாகனத்தை எங்கள் அமைப்பு தானாகவே ஒதுக்குகிறது.",
        "answer_hi": "हमारा लॉजिस्टिक्स इंजन आपकी फसल की मात्रा और कोल्ड-चेन आवश्यकताओं के अनुसार निकटतम उपलब्ध सत्यापित वाहन से मेल कराता है।"
    },
    {
        "id": "faq_04",
        "category": "QUALITY",
        "question_en": "How is the AGMARK crop quality grade determined?",
        "question_ta": "அக்மார்க் பயிர் தர மதிப்பீடு எவ்வாறு தீர்மானிக்கப்படுகிறது?",
        "question_hi": "एगमार्क फसल गुणवत्ता ग्रेड कैसे निर्धारित किया जाता है?",
        "answer_en": "The on-device KisanAI Quality Scanner evaluates uniformity, surface defect percentage, ripeness, and rot to certify AGMARK Grade A, B, or C.",
        "answer_ta": "கிசான் ஏஐ தர ஸ்கேனர் பயிரின் சீரான தன்மை, குறைபாடு சதவீதம் மற்றும் பழுத்த தன்மையை மதிப்பீடு செய்து அக்மார்க் கிரேடு ஏ, பி அல்லது சி சான்றளிக்கிறது.",
        "answer_hi": "डिवाइस पर किसान एआई स्कैनर एकरूपता, दोष प्रतिशत और पकने की स्थिति का मूल्यांकन करके एगमार्क ग्रेड ए, बी या सी प्रमाणित करता है।"
    }
]

@router.get("/config")
def get_support_config():
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT setting_key, setting_value FROM platform_settings WHERE setting_key LIKE 'SUPPORT_%' OR setting_key = 'OPERATING_HOURS';")
        rows = {r["setting_key"]: r["setting_value"] for r in cursor.fetchall()}
        
        return {
            "helpline_phone": rows.get("SUPPORT_PHONE_NUMBER", "+91 94433 00000"),
            "whatsapp_phone": rows.get("SUPPORT_WHATSAPP_NUMBER", "+91 94433 00001"),
            "operating_hours": rows.get("OPERATING_HOURS", "06:00 AM - 09:00 PM IST"),
            "support_email": "support@kisanai.com",
            "sos_number": "112"
        }

@router.get("/faq")
def get_faqs(query: Optional[str] = None):
    if not query:
        return FAQS
    q = query.lower()
    return [
        f for f in FAQS
        if q in f["question_en"].lower() or q in f["question_ta"] or q in f["question_hi"] or q in f["answer_en"].lower()
    ]

class CallbackRequest(BaseModel):
    user_id: str
    phone: str
    preferred_language: str = "ta"
    reason: Optional[str] = "Assistance requested"

@router.post("/callback")
def request_callback(req: CallbackRequest):
    with db_session() as conn:
        cursor = conn.cursor()
        tid = f"CALL-{uuid.uuid4().hex[:6].upper()}"
        now = datetime.now(timezone.utc).isoformat()
        
        cursor.execute("""
            INSERT INTO support_tickets (id, ticket_number, user_id, user_role, category, priority, status, subject, description, created_at, updated_at)
            VALUES (?, ?, ?, 'user', 'CALLBACK', 'HIGH', 'OPEN', 'Immediate Call Back Request', ?, ?, ?);
        """, (tid, tid, req.user_id, f"User requested phone callback to {req.phone} (Lang: {req.preferred_language}). Reason: {req.reason}", now, now))
        
        record_audit_log(cursor, "CALLBACK_REQUESTED", req.user_id, "user", f"support_tickets/{tid}", f"Phone: {req.phone}")
        
    return {"status": "success", "ticket_number": tid, "message": "Call back scheduled. Agent will call within 15 minutes."}

class ReplyRequest(BaseModel):
    sender_id: str
    sender_role: str
    message: str

@router.post("/tickets/{ticket_id}/reply")
def reply_ticket(ticket_id: str, req: ReplyRequest):
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM support_tickets WHERE id = ? OR ticket_number = ?;", (ticket_id, ticket_id))
        ticket = cursor.fetchone()
        if not ticket:
            raise HTTPException(status_code=404, detail="Ticket not found")
            
        mid = f"msg_{uuid.uuid4().hex[:10]}"
        now = datetime.now(timezone.utc).isoformat()
        
        cursor.execute("""
            INSERT INTO support_messages (id, ticket_id, sender_id, sender_role, message, timestamp)
            VALUES (?, ?, ?, ?, ?, ?);
        """, (mid, ticket["id"], req.sender_id, req.sender_role, req.message, now))
        
        # If staff replied, notify user
        if req.sender_role == "staff":
            record_notification(cursor, ticket["user_id"], ticket["user_role"], f"Support Reply: {ticket['ticket_number']}", req.message, "support_reply")
            cursor.execute("UPDATE support_tickets SET status = 'IN_PROGRESS', updated_at = ? WHERE id = ?;", (now, ticket["id"]))
            
        return {"status": "success", "message_id": mid}

@router.get("/tickets/{ticket_id}")
def get_ticket_thread(ticket_id: str):
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM support_tickets WHERE id = ? OR ticket_number = ?;", (ticket_id, ticket_id))
        ticket = cursor.fetchone()
        if not ticket:
            raise HTTPException(status_code=404, detail="Ticket not found")
            
        cursor.execute("SELECT * FROM support_messages WHERE ticket_id = ? ORDER BY timestamp ASC;", (ticket["id"],))
        messages = [dict(m) for m in cursor.fetchall()]
        
        return {"ticket": dict(ticket), "messages": messages}

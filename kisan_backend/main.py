import json
import uuid
import asyncio
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from fastapi import FastAPI, HTTPException, Depends, Query, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel, Field

from .config import APP_ENV, DEMO_OPEN, DATA_MODE, FOUNDER_NAME, FOUNDER_PHONE, API_PORT
from .database import db_session
from .state_machine import (
    transition_order, record_audit_log, record_notification,
    STATE_DEMAND_POSTED, STATE_ACCEPTED, STATE_PARTNER_ASSIGNED,
    STATE_READY_FOR_PICKUP, STATE_IN_TRANSIT, STATE_DELIVERED, STATE_SETTLED, STATE_CANCELLED, STATE_DISPUTED
)
from .seed import seed_database
from .integrity import check_integrity
from .kyc import router as kyc_router

app = FastAPI(
    title="KisanAI Unified Cloud API",
    description="Authoritative backend for KisanAI Farmer, Buyer, Delivery apps & Enterprise Admin Dashboard",
    version="2.1.0"
)

# CORS configuration for GitHub Pages and local development
app.include_router(kyc_router)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://harish7273.github.io",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "http://localhost:3000",
        "*"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Realtime pub/sub listeners
event_subscribers = []

async def broadcast_event(event_type: str, data: Dict[str, Any]):
    msg = f"event: {event_type}\ndata: {json.dumps(data)}\n\n"
    dead = []
    for q in event_subscribers:
        try:
            await q.put(msg)
        except Exception:
            dead.append(q)
    for q in dead:
        if q in event_subscribers:
            event_subscribers.remove(q)

# ============================================================
# HEALTH & VERSION
# ============================================================

@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "app_env": APP_ENV,
        "demo_open": DEMO_OPEN,
        "data_mode": DATA_MODE,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "brand": "KisanAI"
    }

@app.get("/version")
def version_info():
    return {
        "version": "2.1.0",
        "build": 20261108,
        "name": "KisanAI Enterprise Core",
        "min_mobile_version": "2.0.0"
    }

# ============================================================
# AUTHENTICATION & SESSIONS
# ============================================================

class OtpRequest(BaseModel):
    phone: str
    role: str = "farmer" # farmer | buyer | delivery_partner

class OtpVerifyRequest(BaseModel):
    phone: str
    otp: str
    name: Optional[str] = None
    role: Optional[str] = "farmer"

@app.post("/api/v1/auth/otp/send")
async def send_otp(req: OtpRequest):
    # In sample mode or demo mode, support standard demo numbers & fixed OTP
    return {
        "status": "success",
        "message": f"OTP sent to {req.phone}",
        "expires_in_seconds": 300,
        "demo_hint": "In sample mode, OTP 123456 is accepted." if DATA_MODE == "sample" else None
    }

@app.post("/api/v1/auth/otp/verify")
async def verify_otp(req: OtpVerifyRequest):
    # Verification rule: in sample mode accept 123456 or 4821
    if DATA_MODE == "sample" and req.otp not in ["123456", "4821", "1923"]:
        raise HTTPException(status_code=400, detail="Invalid OTP code.")
        
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE phone = ?;", (req.phone,))
        user = cursor.fetchone()
        
        now = datetime.now(timezone.utc).isoformat()
        if not user:
            # Create user
            uid = f"{req.role[:3]}_{uuid.uuid4().hex[:8]}"
            name = req.name or f"New {req.role.capitalize()}"
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, 'REGISTERED', 0, ?, ?);
            """, (uid, req.phone, name, f"{uid}@kisanai.app", req.role, now, now))
            
            # Create role profile
            if req.role == "farmer":
                cursor.execute("""
                    INSERT INTO farmer_profiles (user_id, farm_name, farm_size_acres, district, village, location_id)
                    VALUES (?, 'New Farm', 2.0, 'Coimbatore', 'Ukkadam', 'loc_ukkadam');
                """, (uid,))
            elif req.role == "buyer":
                cursor.execute("""
                    INSERT INTO buyer_profiles (user_id, business_name, delivery_location_id)
                    VALUES (?, ?, 'loc_cbe_central');
                """, (uid, name))
            elif req.role == "delivery_partner":
                veh_id = f"veh_{uid}"
                cursor.execute("""
                    INSERT INTO vehicles (id, partner_id, vehicle_type, plate_number, capacity_kg, has_cold_chain)
                    VALUES (?, ?, 'Tata Ace', 'TN-38-TMP-101', 1500, 0);
                """, (veh_id, uid))
                cursor.execute("""
                    INSERT INTO delivery_profiles (user_id, vehicle_id, driving_licence, rc_number, insurance)
                    VALUES (?, ?, 'DL-TMP', 'RC-TMP', 'INS-TMP');
                """, (uid, veh_id))
                
            # Create wallet
            cursor.execute("INSERT INTO wallets (id, user_id, balance, pending_withdrawal, updated_at) VALUES (?, ?, 0.0, 0.0, ?);", (f"wal_{uid}", uid, now))
            
            cursor.execute("SELECT * FROM users WHERE id = ?;", (uid,))
            user = cursor.fetchone()

        token = f"kisan_jwt_{user['id']}_{uuid.uuid4().hex[:16]}"
        return {
            "token": token,
            "user": dict(user),
            "demo_open": DEMO_OPEN,
            "data_mode": DATA_MODE
        }

@app.get("/api/v1/auth/me")
def get_current_user(phone: Optional[str] = None, role: Optional[str] = None):
    with db_session() as conn:
        cursor = conn.cursor()
        if phone:
            cursor.execute("SELECT * FROM users WHERE phone = ?;", (phone,))
        elif role == "founder" or DEMO_OPEN:
            cursor.execute("SELECT * FROM users WHERE role = 'staff' AND phone = ?;", (FOUNDER_PHONE,))
        else:
            cursor.execute("SELECT * FROM users WHERE role = ? LIMIT 1;", (role or "farmer",))
            
        user = cursor.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return dict(user)

# ============================================================
# CROPS & MANDI PRICES
# ============================================================

@app.get("/api/v1/crops")
def list_crops(category: Optional[str] = None):
    with db_session() as conn:
        cursor = conn.cursor()
        if category:
            cursor.execute("SELECT * FROM crops WHERE category = ? ORDER BY name_en;", (category,))
        else:
            cursor.execute("SELECT * FROM crops ORDER BY name_en;")
        return [dict(row) for row in cursor.fetchall()]

@app.get("/api/v1/crops/{crop_id}/mandi")
def get_crop_mandi_rates(crop_id: str):
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM crops WHERE id = ? OR canonical_code = ?;", (crop_id, crop_id))
        crop = cursor.fetchone()
        if not crop:
            raise HTTPException(status_code=404, detail="Crop not found")
        return {
            "crop": dict(crop),
            "modal_price": crop["base_mandi_price"],
            "direct_price": crop["direct_price"],
            "min_price": round(crop["base_mandi_price"] * 0.85, 2),
            "max_price": round(crop["base_mandi_price"] * 1.15, 2),
            "trend": "UP",
            "last_updated": datetime.now(timezone.utc).isoformat()
        }

# ============================================================
# LOCATIONS
# ============================================================

@app.get("/api/v1/locations")
def list_locations():
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM locations ORDER BY name;")
        return [dict(r) for r in cursor.fetchall()]

# ============================================================
# ORDERS & STATE MACHINE
# ============================================================

@app.get("/api/v1/orders")
def list_orders(
    status: Optional[str] = None,
    buyer_id: Optional[str] = None,
    farmer_id: Optional[str] = None,
    partner_id: Optional[str] = None,
    limit: int = 50,
    offset: int = 0
):
    with db_session() as conn:
        cursor = conn.cursor()
        query = """
            SELECT o.*, c.name_en as crop_name, c.name_ta as crop_name_ta, c.name_hi as crop_name_hi,
                   u_b.name as buyer_name, u_f.name as farmer_name, u_p.name as partner_name,
                   loc_p.name as pickup_location_name, loc_d.name as drop_location_name
            FROM orders o
            JOIN crops c ON o.crop_id = c.id
            JOIN users u_b ON o.buyer_id = u_b.id
            LEFT JOIN users u_f ON o.farmer_id = u_f.id
            LEFT JOIN users u_p ON o.delivery_partner_id = u_p.id
            LEFT JOIN locations loc_p ON o.pickup_location_id = loc_p.id
            LEFT JOIN locations loc_d ON o.drop_location_id = loc_d.id
            WHERE 1=1
        """
        params = []
        if status:
            query += " AND o.status = ?"
            params.append(status)
        if buyer_id:
            query += " AND o.buyer_id = ?"
            params.append(buyer_id)
        if farmer_id:
            query += " AND o.farmer_id = ?"
            params.append(farmer_id)
        if partner_id:
            query += " AND o.delivery_partner_id = ?"
            params.append(partner_id)
            
        query += " ORDER BY o.created_at DESC LIMIT ? OFFSET ?;"
        params.extend([limit, offset])
        
        cursor.execute(query, params)
        return [dict(r) for r in cursor.fetchall()]

@app.get("/api/v1/orders/{order_id}")
def get_order_dossier(order_id: str):
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT o.*, c.name_en as crop_name, c.name_ta as crop_name_ta, c.name_hi as crop_name_hi,
                   u_b.name as buyer_name, u_b.phone as buyer_phone,
                   u_f.name as farmer_name, u_f.phone as farmer_phone,
                   u_p.name as partner_name, u_p.phone as partner_phone,
                   loc_p.name as pickup_name, loc_p.latitude as pickup_lat, loc_p.longitude as pickup_lng,
                   loc_d.name as drop_name, loc_d.latitude as drop_lat, loc_d.longitude as drop_lng
            FROM orders o
            JOIN crops c ON o.crop_id = c.id
            JOIN users u_b ON o.buyer_id = u_b.id
            LEFT JOIN users u_f ON o.farmer_id = u_f.id
            LEFT JOIN users u_p ON o.delivery_partner_id = u_p.id
            LEFT JOIN locations loc_p ON o.pickup_location_id = loc_p.id
            LEFT JOIN locations loc_d ON o.drop_location_id = loc_d.id
            WHERE o.id = ?;
        """, (order_id,))
        order = cursor.fetchone()
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")
            
        cursor.execute("SELECT * FROM order_events WHERE order_id = ? ORDER BY timestamp ASC;", (order_id,))
        events = [dict(e) for e in cursor.fetchall()]
        
        cursor.execute("SELECT * FROM deliveries WHERE order_id = ?;", (order_id,))
        delivery = cursor.fetchone()
        
        return {
            "order": dict(order),
            "events": events,
            "delivery": dict(delivery) if delivery else None
        }

class DemandCreateRequest(BaseModel):
    buyer_id: str
    crop_id: str
    quantity: float
    target_price: float
    destination_location_id: str
    delivery_mode: str = "delivery_partner"
    cold_chain_required: bool = False

@app.post("/api/v1/orders/demand")
async def create_demand(req: DemandCreateRequest):
    with db_session() as conn:
        cursor = conn.cursor()
        now = datetime.now(timezone.utc).isoformat()
        
        oid = f"ORD-{uuid.uuid4().hex[:6].upper()}"
        produce_tot = round(req.quantity * req.target_price, 2)
        deliv_fee = 450.0 if req.delivery_mode == "delivery_partner" else 0.0
        tot_amt = produce_tot + deliv_fee
        
        cursor.execute("""
            INSERT INTO orders (
                id, order_number, buyer_id, crop_id, agreed_price, quantity, unit,
                total_amount, produce_total, delivery_fee, fulfillment_mode, status, payment_status,
                drop_location_id, delivery_otp, pickup_otp, is_seed, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, 'kg', ?, ?, ?, ?, 'DEMAND_POSTED', 'ESCROW_RESERVED', ?, '4821', '1923', 0, ?, ?);
        """, (oid, oid, req.buyer_id, req.crop_id, req.target_price, req.quantity, tot_amt, produce_tot, deliv_fee, req.delivery_mode, req.destination_location_id, now, now))
        
        # Order event
        cursor.execute("""
            INSERT INTO order_events (id, order_id, previous_status, new_status, actor_id, actor_role, note, timestamp)
            VALUES (?, ?, NULL, 'DEMAND_POSTED', ?, 'buyer', 'Buyer broadcasted produce demand', ?);
        """, (f"evt_{oid}_01", oid, req.buyer_id, now))
        
        record_audit_log(cursor, "DEMAND_CREATED", req.buyer_id, "buyer", f"orders/{oid}", f"Demand for {req.quantity}kg at Rs {req.target_price}/kg")
        
        cursor.execute("SELECT * FROM orders WHERE id = ?;", (oid,))
        new_order = dict(cursor.fetchone())
        
    await broadcast_event("demand_created", new_order)
    return new_order

class StateTransitionRequest(BaseModel):
    actor_id: str
    actor_role: str
    note: Optional[str] = ""
    otp: Optional[str] = None
    partner_id: Optional[str] = None

@app.post("/api/v1/orders/{order_id}/accept")
async def accept_order(order_id: str, req: StateTransitionRequest):
    ok, msg, order_data = transition_order(
        order_id=order_id,
        target_status=STATE_ACCEPTED,
        actor_id=req.actor_id,
        actor_role=req.actor_role,
        note=req.note or "Farmer accepted order"
    )
    if not ok:
        status_code = 403 if "VERIFICATION_REQUIRED" in msg else 400
        raise HTTPException(status_code=status_code, detail=msg)
        
    # Auto transition to partner assigned if branch B
    if order_data.get("fulfillment_mode") == "branch_b_partner" or order_data.get("delivery_fee", 0) > 0:
        # Find nearest partner
        with db_session() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT id FROM users WHERE role = 'delivery_partner' AND is_verified = 1 LIMIT 1;")
            p_row = cursor.fetchone()
            partner_id = p_row["id"] if p_row else "drv_selvam_4412"
            
        transition_order(
            order_id=order_id,
            target_status=STATE_PARTNER_ASSIGNED,
            actor_id="system",
            actor_role="system",
            partner_id=partner_id,
            note="Auto-assigned qualified logistics partner"
        )
        
    await broadcast_event("order_updated", {"order_id": order_id, "status": "ACCEPTED"})
    return {"status": "success", "message": msg, "order": order_data}

@app.post("/api/v1/orders/{order_id}/pickup")
async def pickup_order(order_id: str, req: StateTransitionRequest):
    ok, msg, order_data = transition_order(
        order_id=order_id,
        target_status=STATE_IN_TRANSIT,
        actor_id=req.actor_id,
        actor_role=req.actor_role,
        note="Produce picked up from farm",
        otp=req.otp
    )
    if not ok:
        raise HTTPException(status_code=400, detail=msg)
    await broadcast_event("order_updated", {"order_id": order_id, "status": "IN_TRANSIT"})
    return {"status": "success", "message": msg}

@app.post("/api/v1/orders/{order_id}/deliver")
async def deliver_order(order_id: str, req: StateTransitionRequest):
    ok, msg, order_data = transition_order(
        order_id=order_id,
        target_status=STATE_DELIVERED,
        actor_id=req.actor_id,
        actor_role=req.actor_role,
        note="Handover confirmed with OTP",
        otp=req.otp
    )
    if not ok:
        raise HTTPException(status_code=400, detail=msg)
        
    # Auto trigger atomic settlement
    transition_order(
        order_id=order_id,
        target_status=STATE_SETTLED,
        actor_id="system",
        actor_role="system",
        note="Automated instant ledger settlement"
    )
    await broadcast_event("order_updated", {"order_id": order_id, "status": "SETTLED"})
    return {"status": "success", "message": "Delivery completed and settled to wallets."}

# ============================================================
# LISTINGS (Farmer supply)
# ============================================================

class ListingCreateRequest(BaseModel):
    farmer_id: str
    crop_id: str
    quantity: float
    price: float
    unit: str = "kg"
    location_id: str
    quality_grade: str = "Grade A"

@app.post("/api/v1/listings")
def create_listing(req: ListingCreateRequest):
    with db_session() as conn:
        cursor = conn.cursor()
        
        # Enforce server-side KYC verification: unverified farmer CANNOT post listings!
        cursor.execute("SELECT kyc_status, is_verified FROM users WHERE id = ?;", (req.farmer_id,))
        u = cursor.fetchone()
        if not u or u["kyc_status"] != "APPROVED":
            raise HTTPException(
                status_code=403,
                detail="HTTP 403 VERIFICATION_REQUIRED: You must be a verified farmer to post crop listings."
            )
            
        lid = f"LST-{uuid.uuid4().hex[:6].upper()}"
        now = datetime.now(timezone.utc).isoformat()
        
        cursor.execute("""
            INSERT INTO listings (id, farmer_id, crop_id, quantity, unit, price, quality_grade, location_id, is_available, is_seed, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, 0, ?);
        """, (lid, req.farmer_id, req.crop_id, req.quantity, req.unit, req.price, req.quality_grade, req.location_id, now))
        
        record_audit_log(cursor, "LISTING_CREATED", req.farmer_id, "farmer", f"listings/{lid}", f"Posted {req.quantity}{req.unit} at Rs {req.price}/{req.unit}")
        
        cursor.execute("SELECT * FROM listings WHERE id = ?;", (lid,))
        return dict(cursor.fetchone())

@app.get("/api/v1/listings")
def list_listings(crop_id: Optional[str] = None, limit: int = 50):
    with db_session() as conn:
        cursor = conn.cursor()
        query = """
            SELECT l.*, c.name_en as crop_name, c.name_ta as crop_name_ta, c.name_hi as crop_name_hi,
                   u.name as farmer_name, u.phone as farmer_phone, loc.name as location_name
            FROM listings l
            JOIN crops c ON l.crop_id = c.id
            JOIN users u ON l.farmer_id = u.id
            JOIN locations loc ON l.location_id = loc.id
            WHERE l.is_available = 1
        """
        params = []
        if crop_id:
            query += " AND l.crop_id = ?"
            params.append(crop_id)
        query += " ORDER BY l.created_at DESC LIMIT ?;"
        params.append(limit)
        cursor.execute(query, params)
        return [dict(r) for r in cursor.fetchall()]

# ============================================================
# KYC VERIFICATION
# ============================================================

@app.get("/api/v1/kyc/queue")
def get_kyc_queue():
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT u.id, u.name, u.phone, u.role, u.kyc_status, u.is_verified, u.created_at,
                   fp.farm_name, fp.district, fp.village, fp.gps_latitude, fp.gps_longitude
            FROM users u
            LEFT JOIN farmer_profiles fp ON u.id = fp.user_id
            WHERE u.role IN ('farmer', 'delivery_partner')
            ORDER BY CASE WHEN u.kyc_status = 'UNDER_REVIEW' THEN 0 WHEN u.kyc_status = 'REGISTERED' THEN 1 ELSE 2 END, u.created_at DESC;
        """)
        return [dict(r) for r in cursor.fetchall()]

class KycReviewRequest(BaseModel):
    action: str # APPROVE | REJECT | NEEDS_INFO
    reason: Optional[str] = ""
    reviewer_id: str

@app.post("/api/v1/kyc/{user_id}/review")
async def review_kyc(user_id: str, req: KycReviewRequest):
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE id = ?;", (user_id,))
        user = cursor.fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
            
        new_status = "APPROVED" if req.action == "APPROVE" else ("REJECTED" if req.action == "REJECT" else "NEEDS_INFO")
        is_ver = 1 if req.action == "APPROVE" else 0
        now = datetime.now(timezone.utc).isoformat()
        
        cursor.execute("""
            UPDATE users SET kyc_status = ?, is_verified = ?, updated_at = ? WHERE id = ?;
        """, (new_status, is_ver, now, user_id))
        
        record_audit_log(cursor, f"KYC_{req.action}", req.reviewer_id, "staff", f"users/{user_id}", f"KYC status changed to {new_status}. Reason: {req.reason}")
        record_notification(cursor, user_id, user["role"], f"KYC Verification {new_status}", req.reason or "Your account KYC profile has been reviewed.", "kyc_update")
        
    await broadcast_event("kyc_updated", {"user_id": user_id, "status": new_status})
    return {"status": "success", "new_status": new_status}

# ============================================================
# WALLET & PAYOUTS
# ============================================================

@app.get("/api/v1/wallets/{user_id}")
def get_user_wallet(user_id: str):
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM wallets WHERE user_id = ?;", (user_id,))
        wal = cursor.fetchone()
        if not wal:
            raise HTTPException(status_code=404, detail="Wallet not found")
        cursor.execute("SELECT * FROM wallet_transactions WHERE user_id = ? ORDER BY timestamp DESC LIMIT 20;", (user_id,))
        txs = [dict(t) for t in cursor.fetchall()]
        return {"wallet": dict(wal), "transactions": txs}

class PayoutCreateRequest(BaseModel):
    user_id: str
    amount: float
    payout_method: str = "UPI"
    upi_id: Optional[str] = None
    bank_account: Optional[str] = None
    bank_ifsc: Optional[str] = None

@app.post("/api/v1/wallets/withdraw")
def request_payout(req: PayoutCreateRequest):
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT kyc_status, is_verified FROM users WHERE id = ?;", (req.user_id,))
        u = cursor.fetchone()
        if not u or u["kyc_status"] != "APPROVED":
            raise HTTPException(
                status_code=403,
                detail="HTTP 403 VERIFICATION_REQUIRED: Only verified accounts can receive payouts."
            )
        cursor.execute("SELECT * FROM wallets WHERE user_id = ?;", (req.user_id,))
        wal = cursor.fetchone()
        if not wal or wal["balance"] < req.amount:
            raise HTTPException(status_code=400, detail="Insufficient wallet balance.")
            
        pid = f"pay_{uuid.uuid4().hex[:10]}"
        now = datetime.now(timezone.utc).isoformat()
        
        # Deduct balance and record transaction
        new_bal = round(wal["balance"] - req.amount, 2)
        cursor.execute("UPDATE wallets SET balance = ?, pending_withdrawal = pending_withdrawal + ?, updated_at = ? WHERE id = ?;", (new_bal, req.amount, now, wal["id"]))
        
        cursor.execute("""
            INSERT INTO payout_requests (id, user_id, amount, payout_method, upi_id, bank_account, bank_ifsc, status, requested_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'PENDING', ?);
        """, (pid, req.user_id, req.amount, req.payout_method, req.upi_id, req.bank_account, req.bank_ifsc, now))
        
        tx_id = f"tx_{uuid.uuid4().hex[:12]}"
        cursor.execute("""
            INSERT INTO wallet_transactions (id, wallet_id, user_id, transaction_type, amount, balance_after, reference_note, timestamp)
            VALUES (?, ?, ?, 'DEBIT_WITHDRAWAL', ?, ?, ?, ?);
        """, (tx_id, wal["id"], req.user_id, req.amount, new_bal, f"Withdrawal request via {req.payout_method}", now))
        
        record_audit_log(cursor, "PAYOUT_REQUESTED", req.user_id, "farmer", f"payout_requests/{pid}", f"Requested Rs {req.amount}")
        return {"status": "success", "payout_id": pid, "new_balance": new_bal}

# ============================================================
# SUPPORT TICKETS & SOS
# ============================================================

class TicketCreateRequest(BaseModel):
    user_id: str
    user_role: str
    category: str
    priority: str = "MEDIUM"
    subject: str
    description: str

@app.post("/api/v1/support/tickets")
async def create_ticket(req: TicketCreateRequest):
    with db_session() as conn:
        cursor = conn.cursor()
        tid = f"TCK-{uuid.uuid4().hex[:6].upper()}"
        now = datetime.now(timezone.utc).isoformat()
        
        cursor.execute("""
            INSERT INTO support_tickets (id, ticket_number, user_id, user_role, category, priority, status, subject, description, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, 'OPEN', ?, ?, ?, ?);
        """, (tid, tid, req.user_id, req.user_role, req.category, req.priority, req.subject, req.description, now, now))
        
        record_audit_log(cursor, "TICKET_CREATED", req.user_id, req.user_role, f"support_tickets/{tid}", req.subject)
        
    await broadcast_event("ticket_created", {"ticket_number": tid, "subject": req.subject})
    return {"status": "success", "ticket_number": tid}

class SosAlertRequest(BaseModel):
    partner_id: str
    latitude: float
    longitude: float
    order_id: Optional[str] = None
    note: Optional[str] = "Emergency SOS Triggered by Delivery Partner"

@app.post("/api/v1/support/sos")
async def trigger_sos(req: SosAlertRequest):
    with db_session() as conn:
        cursor = conn.cursor()
        now = datetime.now(timezone.utc).isoformat()
        tid = f"SOS-{uuid.uuid4().hex[:6].upper()}"
        
        desc = f"URGENT SOS! Delivery Partner {req.partner_id} triggered emergency assistance at Lat: {req.latitude}, Lng: {req.longitude}. Order: {req.order_id or 'N/A'}."
        cursor.execute("""
            INSERT INTO support_tickets (id, ticket_number, user_id, user_role, category, priority, status, subject, description, created_at, updated_at)
            VALUES (?, ?, ?, 'delivery_partner', 'SOS', 'URGENT', 'OPEN', 'EMERGENCY SOS ALERT', ?, ?, ?);
        """, (tid, tid, req.partner_id, desc, now, now))
        
        record_audit_log(cursor, "SOS_TRIGGERED", req.partner_id, "delivery_partner", f"support_tickets/{tid}", desc)
        
    await broadcast_event("sos_alert", {"ticket_number": tid, "partner_id": req.partner_id, "lat": req.latitude, "lng": req.longitude})
    return {"status": "success", "alert": "Emergency response center notified.", "ticket_number": tid}

# ============================================================
# ADMIN WEBSITE ENDPOINTS
# ============================================================

@app.get("/api/v1/admin/overview")
def admin_overview():
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT count(*) FROM users WHERE role = 'farmer';")
        total_farmers = cursor.fetchone()[0]
        cursor.execute("SELECT count(*) FROM users WHERE role = 'buyer';")
        total_buyers = cursor.fetchone()[0]
        cursor.execute("SELECT count(*) FROM users WHERE role = 'delivery_partner';")
        total_partners = cursor.fetchone()[0]
        cursor.execute("SELECT count(*) FROM orders;")
        total_orders = cursor.fetchone()[0]
        cursor.execute("SELECT sum(total_amount) FROM orders WHERE status = 'SETTLED';")
        gmv_settled = cursor.fetchone()[0] or 0.0
        cursor.execute("SELECT count(*) FROM users WHERE kyc_status = 'UNDER_REVIEW';")
        pending_kyc = cursor.fetchone()[0]
        cursor.execute("SELECT count(*) FROM support_tickets WHERE status = 'OPEN';")
        open_tickets = cursor.fetchone()[0]
        
        return {
            "total_farmers": total_farmers,
            "total_buyers": total_buyers,
            "total_delivery_partners": total_partners,
            "total_orders": total_orders,
            "settled_gmv": round(gmv_settled, 2),
            "pending_kyc": pending_kyc,
            "open_tickets": open_tickets,
            "demo_open": DEMO_OPEN,
            "data_mode": DATA_MODE
        }

@app.get("/api/v1/admin/audit-logs")
def get_audit_logs(limit: int = 50):
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM audit_logs ORDER BY timestamp DESC LIMIT ?;", (limit,))
        return [dict(r) for r in cursor.fetchall()]

@app.get("/api/v1/admin/platform-settings")
def get_platform_settings():
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM platform_settings;")
        return [dict(r) for r in cursor.fetchall()]

@app.post("/api/v1/admin/reset-demo")
def reset_demo():
    if DATA_MODE != "sample":
        raise HTTPException(status_code=403, detail="Reset demo data is only permitted in sample mode.")
    seed_database()
    return {"status": "success", "message": "Sample world reset to pristine seed state."}

# ============================================================
# REALTIME STREAM (Server-Sent Events)
# ============================================================

@app.get("/api/v1/realtime/stream")
async def realtime_stream(request: Request):
    async def event_generator():
        q = asyncio.Queue()
        event_subscribers.append(q)
        try:
            # Send initial keepalive
            yield f"event: connected\ndata: {json.dumps({'status': 'connected', 'timestamp': datetime.now(timezone.utc).isoformat()})}\n\n"
            while True:
                if await request.is_disconnected():
                    break
                try:
                    data = await asyncio.wait_for(q.get(), timeout=15.0)
                    yield data
                except asyncio.TimeoutError:
                    yield ": keepalive\n\n"
        finally:
            if q in event_subscribers:
                event_subscribers.remove(q)

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no"
        }
    )

import math
import uuid
import json
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from kisan_backend.database import db_session
from kisan_backend.state_machine import transition_order, STATE_DELIVERED, STATE_SETTLED

router = APIRouter(prefix="/api/v1", tags=["delivery_trust"])

def point_to_segment_distance(p_lat: float, p_lng: float, a_lat: float, a_lng: float, b_lat: float, b_lng: float) -> float:
    """Calculates perpendicular distance in meters from point P to line segment A-B using equirectangular projection."""
    lat_mid = math.radians((a_lat + b_lat) / 2.0)
    kx = 111320.0 * math.cos(lat_mid)
    ky = 110540.0

    ax, ay = 0.0, 0.0
    bx = (b_lng - a_lng) * kx
    by = (b_lat - a_lat) * ky
    px = (p_lng - a_lng) * kx
    py = (p_lat - a_lat) * ky

    seg_len_sq = bx * bx + by * by
    if seg_len_sq == 0:
        return math.hypot(px, py)

    # Project point onto segment: t = dot(P-A, B-A) / |B-A|^2
    t = max(0.0, min(1.0, (px * bx + py * by) / seg_len_sq))
    proj_x = t * bx
    proj_y = t * by
    return math.hypot(px - proj_x, py - proj_y)

class HandoverOTPRequest(BaseModel):
    otp: str
    actor_id: str
    actor_role: str = "delivery_partner"

@router.post("/orders/{order_id}/handover")
def verify_delivery_handover(order_id: str, req: HandoverOTPRequest):
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM orders WHERE id = ?;", (order_id,))
        order = cursor.fetchone()
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")

        # 1. Check if OTP is locked
        otp_attempts = order["otp_attempts"] or 0
        otp_locked = order["otp_locked"] or 0
        if otp_locked == 1 or otp_attempts >= 3:
            raise HTTPException(
                status_code=403,
                detail="DELIVERY_OTP_LOCKED: 3 failed attempts reached. Handover is locked. Contact operations support."
            )

        # 2. Validate OTP
        expected_otp = order["delivery_otp"].strip()
        provided_otp = req.otp.strip()

        if provided_otp != expected_otp:
            new_attempts = otp_attempts + 1
            new_locked = 1 if new_attempts >= 3 else 0
            now = datetime.now(timezone.utc).isoformat()
            cursor.execute("""
                UPDATE orders SET otp_attempts = ?, otp_locked = ?, updated_at = ? WHERE id = ?;
            """, (new_attempts, new_locked, now, order_id))

            if new_locked == 1:
                evt_id = f"evt_{uuid.uuid4().hex[:12]}"
                cursor.execute("""
                    INSERT INTO order_events (id, order_id, previous_status, new_status, actor_id, actor_role, note, timestamp)
                    VALUES (?, ?, ?, ?, ?, ?, 'DELIVERY_OTP_LOCKED: Maximum failed attempts exceeded', ?);
                """, (evt_id, order_id, order["status"], order["status"], req.actor_id, req.actor_role, now))
                conn.commit()
                raise HTTPException(
                    status_code=403,
                    detail="DELIVERY_OTP_LOCKED: Maximum 3 attempts exceeded. Order handover locked."
                )
            else:
                conn.commit()
                remaining = 3 - new_attempts
                raise HTTPException(
                    status_code=400,
                    detail=f"INVALID_OTP: Incorrect delivery handover OTP. {remaining} attempt(s) remaining."
                )

        # 3. OTP is correct -> check farmer KYC status before escrow release
        farmer_id = order["farmer_id"]
        if farmer_id:
            cursor.execute("SELECT kyc_status FROM users WHERE id = ?;", (farmer_id,))
            farmer = cursor.fetchone()
            if not farmer or farmer["kyc_status"] != "APPROVED":
                raise HTTPException(
                    status_code=403,
                    detail=f"VERIFICATION_REQUIRED: Farmer KYC status is '{farmer['kyc_status'] if farmer else 'UNKNOWN'}'. Escrow payout blocked."
                )

        # Reset attempts
        now = datetime.now(timezone.utc).isoformat()
        cursor.execute("UPDATE orders SET otp_attempts = 0, otp_locked = 0, updated_at = ? WHERE id = ?;", (now, order_id))

    # 4. Transition order to DELIVERED and then SETTLED outside the block to prevent sqlite connection nesting
    ok_del, msg_del, ord_del = transition_order(
        order_id, STATE_DELIVERED, req.actor_id, req.actor_role,
        note="Delivery handover confirmed with valid OTP",
        otp=provided_otp
    )
    if not ok_del:
        raise HTTPException(status_code=400, detail=msg_del)

    ok_set, msg_set, ord_set = transition_order(
        order_id, STATE_SETTLED, req.actor_id, req.actor_role,
        note="Escrow payout released to farmer and partner wallets upon verified handover"
    )
    if not ok_set:
        raise HTTPException(status_code=400, detail=msg_set)

    with db_session() as conn:
        cursor = conn.cursor()
        # Fetch wallet balances
        cursor.execute("SELECT balance FROM wallets WHERE user_id = ?;", (farmer_id,))
        fw = cursor.fetchone()
        farmer_balance = fw["balance"] if fw else 0.0

        partner_balance = 0.0
        if order["delivery_partner_id"]:
            cursor.execute("SELECT balance FROM wallets WHERE user_id = ?;", (order["delivery_partner_id"],))
            pw = cursor.fetchone()
            partner_balance = pw["balance"] if pw else 0.0

    return {
        "status": "DELIVERED_AND_SETTLED",
        "order_id": order_id,
        "order_number": order["order_number"],
        "payment_status": "SETTLED",
        "escrow_released": True,
        "farmer_payout_amount": order["produce_total"],
        "farmer_wallet_balance": farmer_balance,
        "delivery_fee_payout": order["delivery_fee"],
        "delivery_partner_wallet_balance": partner_balance,
        "message": "Delivery OTP verified. Produce handed over, escrow released."
    }

class TelematicsRequest(BaseModel):
    latitude: float
    longitude: float
    speed_kmh: float = 35.0
    heading: float = 0.0
    temperature_celsius: Optional[float] = None
    is_mock: bool = False

@router.post("/deliveries/{delivery_id}/telematics")
def ingest_telematics(delivery_id: str, req: TelematicsRequest):
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT d.*, o.id as order_id, o.order_number, o.pickup_location_id, o.drop_location_id,
                   v.has_cold_chain, v.plate_number
            FROM deliveries d
            JOIN orders o ON d.order_id = o.id
            LEFT JOIN vehicles v ON d.vehicle_id = v.id
            WHERE d.id = ?;
        """, (delivery_id,))
        deliv = cursor.fetchone()
        if not deliv:
            raise HTTPException(status_code=404, detail="Delivery record not found")

        # Fetch coordinates of pickup and drop locations
        cursor.execute("SELECT latitude, longitude FROM locations WHERE id = ?;", (deliv["pickup_location_id"],))
        p_loc = cursor.fetchone()
        cursor.execute("SELECT latitude, longitude FROM locations WHERE id = ?;", (deliv["drop_location_id"],))
        d_loc = cursor.fetchone()

        alerts_triggered = []
        now = datetime.now(timezone.utc).isoformat()
        deviation_meters = 0.0

        if p_loc and d_loc:
            deviation_meters = point_to_segment_distance(
                req.latitude, req.longitude,
                p_loc["latitude"], p_loc["longitude"],
                d_loc["latitude"], d_loc["longitude"]
            )
            # Route corridor threshold: 2.0 km (2000 m)
            if deviation_meters > 2000.0:
                alert_id = f"alt_{uuid.uuid4().hex[:10]}"
                msg = f"ROUTE_CORRIDOR_BREACH: Vehicle deviated {deviation_meters/1000.0:.2f} km outside authorized transport corridor."
                alerts_triggered.append({
                    "alert_type": "ROUTE_CORRIDOR_BREACH",
                    "severity": "HIGH",
                    "message": msg,
                    "deviation_km": round(deviation_meters / 1000.0, 2)
                })
                cursor.execute("""
                    INSERT INTO delivery_alerts (id, delivery_id, order_id, alert_type, severity, message, telematics_data, created_at)
                    VALUES (?, ?, ?, 'ROUTE_CORRIDOR_BREACH', 'HIGH', ?, ?, ?);
                """, (alert_id, delivery_id, deliv["order_id"], msg, json.dumps(req.model_dump()), now))

                evt_id = f"evt_{uuid.uuid4().hex[:12]}"
                cursor.execute("""
                    INSERT INTO order_events (id, order_id, previous_status, new_status, actor_id, actor_role, note, timestamp)
                    VALUES (?, ?, 'IN_TRANSIT', 'IN_TRANSIT', deliv_partner, 'system', ?, ?);
                """.replace("deliv_partner", f"'{deliv['partner_id']}'"), (evt_id, deliv["order_id"], msg, now))

        # Check cold-chain reefer temperature breach
        if deliv["has_cold_chain"] == 1 and req.temperature_celsius is not None:
            # Cold-chain tolerance: 0.0°C - 12.0°C
            if req.temperature_celsius > 12.0 or req.temperature_celsius < 0.0:
                alert_id = f"alt_{uuid.uuid4().hex[:10]}"
                msg = f"REEFER_TEMPERATURE_EXCURSION: Cargo temperature {req.temperature_celsius:.1f}C breached cold-chain safety range (0C - 12C)."
                alerts_triggered.append({
                    "alert_type": "REEFER_TEMPERATURE_EXCURSION",
                    "severity": "CRITICAL",
                    "message": msg,
                    "temperature_celsius": req.temperature_celsius
                })
                cursor.execute("""
                    INSERT INTO delivery_alerts (id, delivery_id, order_id, alert_type, severity, message, telematics_data, created_at)
                    VALUES (?, ?, ?, 'REEFER_TEMPERATURE_EXCURSION', 'CRITICAL', ?, ?, ?);
                """, (alert_id, delivery_id, deliv["order_id"], msg, json.dumps(req.model_dump()), now))

                evt_id = f"evt_{uuid.uuid4().hex[:12]}"
                cursor.execute("""
                    INSERT INTO order_events (id, order_id, previous_status, new_status, actor_id, actor_role, note, timestamp)
                    VALUES (?, ?, 'IN_TRANSIT', 'IN_TRANSIT', deliv_partner, 'system', ?, ?);
                """.replace("deliv_partner", f"'{deliv['partner_id']}'"), (evt_id, deliv["order_id"], msg, now))

        # Insert tracking point
        tp_id = f"tp_{uuid.uuid4().hex[:12]}"
        cursor.execute("""
            INSERT INTO tracking_points (id, delivery_id, partner_id, latitude, longitude, speed_kmh, heading, temperature_celsius, timestamp)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
        """, (tp_id, delivery_id, deliv["partner_id"], req.latitude, req.longitude, req.speed_kmh, req.heading, req.temperature_celsius, now))

        return {
            "status": "TELEMATICS_RECORDED",
            "delivery_id": delivery_id,
            "corridor_deviation_meters": round(deviation_meters, 1),
            "alerts_triggered": alerts_triggered,
            "recorded_at": now
        }

@router.get("/deliveries/{delivery_id}/alerts")
def get_delivery_alerts(delivery_id: str):
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM delivery_alerts WHERE delivery_id = ? ORDER BY created_at DESC;", (delivery_id,))
        alerts = [dict(r) for r in cursor.fetchall()]
        return {"delivery_id": delivery_id, "alerts": alerts, "total": len(alerts)}

import uuid
import hashlib
from datetime import datetime, timezone
from typing import Optional, Dict, Any, Tuple
from .database import db_session

# Canonical Lifecycle States
STATE_DEMAND_POSTED = "DEMAND_POSTED"
STATE_ACCEPTED = "ACCEPTED"
STATE_PARTNER_ASSIGNED = "PARTNER_ASSIGNED"
STATE_READY_FOR_PICKUP = "READY_FOR_PICKUP"
STATE_IN_TRANSIT = "IN_TRANSIT"
STATE_DELIVERED = "DELIVERED"
STATE_SETTLED = "SETTLED"
STATE_CANCELLED = "CANCELLED"
STATE_DISPUTED = "DISPUTED"

ALLOWED_TRANSITIONS = {
    STATE_DEMAND_POSTED: [STATE_ACCEPTED, STATE_CANCELLED],
    STATE_ACCEPTED: [STATE_PARTNER_ASSIGNED, STATE_READY_FOR_PICKUP, STATE_CANCELLED],
    STATE_PARTNER_ASSIGNED: [STATE_IN_TRANSIT, STATE_CANCELLED, STATE_DISPUTED],
    STATE_READY_FOR_PICKUP: [STATE_DELIVERED, STATE_CANCELLED, STATE_DISPUTED],
    STATE_IN_TRANSIT: [STATE_DELIVERED, STATE_DISPUTED],
    STATE_DELIVERED: [STATE_SETTLED, STATE_DISPUTED],
    STATE_DISPUTED: [STATE_SETTLED, STATE_CANCELLED],
    STATE_SETTLED: [], # Terminal
    STATE_CANCELLED: [] # Terminal
}

def record_audit_log(cursor, action: str, actor_id: str, actor_role: str, target_entity: str, details: str):
    now = datetime.now(timezone.utc).isoformat()
    # Get last hash
    cursor.execute("SELECT curr_hash FROM audit_logs ORDER BY rowid DESC LIMIT 1;")
    row = cursor.fetchone()
    prev_hash = row["curr_hash"] if row else "GENESIS_BLOCK_00000000000000000000000000000000"
    
    raw = f"{prev_hash}|{action}|{actor_id}|{target_entity}|{now}|{details}"
    curr_hash = hashlib.sha256(raw.encode("utf-8")).hexdigest()
    
    log_id = f"aud_{uuid.uuid4().hex[:12]}"
    cursor.execute("""
        INSERT INTO audit_logs (id, action, actor_id, actor_role, target_entity, details, prev_hash, curr_hash, timestamp)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
    """, (log_id, action, actor_id, actor_role, target_entity, details, prev_hash, curr_hash, now))

def record_notification(cursor, recipient_id: str, recipient_role: str, title: str, message: str, n_type: str, order_id: Optional[str] = None):
    now = datetime.now(timezone.utc).isoformat()
    n_id = f"notif_{uuid.uuid4().hex[:12]}"
    cursor.execute("""
        INSERT INTO notifications (id, recipient_id, recipient_role, title, message, type, order_id, is_read, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?);
    """, (n_id, recipient_id, recipient_role, title, message, n_type, order_id, now))

def transition_order(
    order_id: str,
    target_status: str,
    actor_id: str,
    actor_role: str,
    note: str = "",
    otp: Optional[str] = None,
    partner_id: Optional[str] = None
) -> Tuple[bool, str, Dict[str, Any]]:
    with db_session() as conn:
        cursor = conn.cursor()
        
        cursor.execute("SELECT * FROM orders WHERE id = ?;", (order_id,))
        order = cursor.fetchone()
        if not order:
            return False, f"Order {order_id} not found.", {}
        
        current_status = order["status"]
        
        # Idempotency check: if already in target status, return success safely
        if current_status == target_status:
            return True, f"Order {order_id} is already in status {target_status}.", dict(order)
            
        # Check transition validity
        allowed = ALLOWED_TRANSITIONS.get(current_status, [])
        if target_status not in allowed:
            return False, f"Invalid transition from {current_status} to {target_status}.", {}
            
        now = datetime.now(timezone.utc).isoformat()
        
        # Validation by state
        if target_status == STATE_ACCEPTED:
            # Check farmer KYC verification on server
            cursor.execute("SELECT kyc_status, is_verified FROM users WHERE id = ?;", (actor_id,))
            user = cursor.fetchone()
            if not user or user["kyc_status"] != "APPROVED":
                return False, "HTTP 403 VERIFICATION_REQUIRED: Only verified farmers can accept demands.", {}
            
            # Bind farmer to order
            cursor.execute("""
                UPDATE orders SET farmer_id = ?, status = ?, updated_at = ? WHERE id = ?;
            """, (actor_id, target_status, now, order_id))
            
            # Notify Buyer
            record_notification(
                cursor, order["buyer_id"], "buyer",
                "Demand Accepted by Farmer",
                f"A verified farmer accepted your order for {order['quantity']} {order['unit']}.",
                "order_update", order_id
            )
            
        elif target_status == STATE_PARTNER_ASSIGNED:
            assigned_partner = partner_id or actor_id
            cursor.execute("""
                UPDATE orders SET delivery_partner_id = ?, status = ?, updated_at = ? WHERE id = ?;
            """, (assigned_partner, target_status, now, order_id))
            
            record_notification(
                cursor, assigned_partner, "delivery_partner",
                "New Delivery Assigned",
                f"You have been assigned order {order['order_number']}. Head to farm for pickup.",
                "delivery_assigned", order_id
            )
            
        elif target_status == STATE_IN_TRANSIT:
            if otp and otp.strip() != order["pickup_otp"]:
                return False, "Invalid pickup OTP.", {}
            cursor.execute("""
                UPDATE orders SET status = ?, updated_at = ? WHERE id = ?;
            """, (target_status, now, order_id))
            cursor.execute("""
                UPDATE deliveries SET pickup_time = ?, status = 'IN_TRANSIT' WHERE order_id = ?;
            """, (now, order_id))
            
            # Notify Buyer & Farmer
            record_notification(cursor, order["buyer_id"], "buyer", "Order In Transit", "Produce has been picked up from farm and is on the way.", "tracking", order_id)
            if order["farmer_id"]:
                record_notification(cursor, order["farmer_id"], "farmer", "Pickup Completed", "Partner collected produce with verified OTP.", "order_update", order_id)

        elif target_status == STATE_DELIVERED:
            if otp and otp.strip() != order["delivery_otp"]:
                return False, "Invalid delivery handover OTP.", {}
            cursor.execute("""
                UPDATE orders SET status = ?, updated_at = ? WHERE id = ?;
            """, (target_status, now, order_id))
            cursor.execute("""
                UPDATE deliveries SET drop_time = ?, status = 'DELIVERED' WHERE order_id = ?;
            """, (now, order_id))
            
            record_notification(cursor, order["buyer_id"], "buyer", "Order Delivered", "Delivery completed successfully.", "order_update", order_id)

        elif target_status == STATE_SETTLED:
            # Double settlement check
            if order["payment_status"] == "SETTLED":
                return True, "Order already settled.", dict(order)
                
            farmer_id = order["farmer_id"]
            partner_id_val = order["delivery_partner_id"]
            produce_total = float(order["produce_total"])
            delivery_fee = float(order["delivery_fee"])
            
            # Credit farmer wallet
            if farmer_id:
                cursor.execute("SELECT id, balance FROM wallets WHERE user_id = ?;", (farmer_id,))
                fw = cursor.fetchone()
                if fw:
                    new_bal = fw["balance"] + produce_total
                    cursor.execute("UPDATE wallets SET balance = ?, updated_at = ? WHERE id = ?;", (new_bal, now, fw["id"]))
                    tx_id = f"tx_{uuid.uuid4().hex[:12]}"
                    cursor.execute("""
                        INSERT INTO wallet_transactions (id, wallet_id, user_id, order_id, transaction_type, amount, balance_after, reference_note, timestamp)
                        VALUES (?, ?, ?, ?, 'CREDIT_SALE', ?, ?, ?, ?);
                    """, (tx_id, fw["id"], farmer_id, order_id, produce_total, new_bal, f"Sale proceeds for order {order['order_number']}", now))
                    record_notification(cursor, farmer_id, "farmer", "Payment Credited", f"Rs {produce_total:.2f} credited to your wallet for order {order['order_number']}.", "wallet_credit", order_id)
            
            # Credit delivery partner wallet if branch B
            if partner_id_val and delivery_fee > 0:
                cursor.execute("SELECT id, balance FROM wallets WHERE user_id = ?;", (partner_id_val,))
                pw = cursor.fetchone()
                if pw:
                    new_bal = pw["balance"] + delivery_fee
                    cursor.execute("UPDATE wallets SET balance = ?, updated_at = ? WHERE id = ?;", (new_bal, now, pw["id"]))
                    tx_id = f"tx_{uuid.uuid4().hex[:12]}"
                    cursor.execute("""
                        INSERT INTO wallet_transactions (id, wallet_id, user_id, order_id, transaction_type, amount, balance_after, reference_note, timestamp)
                        VALUES (?, ?, ?, ?, 'CREDIT_DELIVERY', ?, ?, ?, ?);
                    """, (tx_id, pw["id"], partner_id_val, order_id, delivery_fee, new_bal, f"Delivery fee for order {order['order_number']}", now))
                    record_notification(cursor, partner_id_val, "delivery_partner", "Earnings Credited", f"Rs {delivery_fee:.2f} delivery fee credited.", "wallet_credit", order_id)

            cursor.execute("""
                UPDATE orders SET status = ?, payment_status = 'SETTLED', updated_at = ? WHERE id = ?;
            """, (STATE_SETTLED, now, order_id))
            
        else:
            # Generic update for other states like CANCELLED, DISPUTED, READY_FOR_PICKUP
            cursor.execute("""
                UPDATE orders SET status = ?, updated_at = ? WHERE id = ?;
            """, (target_status, now, order_id))

        # Record order event
        event_id = f"evt_{uuid.uuid4().hex[:12]}"
        cursor.execute("""
            INSERT INTO order_events (id, order_id, previous_status, new_status, actor_id, actor_role, note, timestamp)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """, (event_id, order_id, current_status, target_status, actor_id, actor_role, note or f"Status changed to {target_status}", now))

        # Record audit log
        record_audit_log(cursor, f"ORDER_TRANSITION_{target_status}", actor_id, actor_role, f"orders/{order_id}", f"Transition from {current_status} to {target_status}. Note: {note}")

        # Fetch updated order
        cursor.execute("SELECT * FROM orders WHERE id = ?;", (order_id,))
        updated_order = cursor.fetchone()
        
        return True, f"Order successfully transitioned to {target_status}.", dict(updated_order)

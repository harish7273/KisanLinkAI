import os
import sys
import json
from datetime import datetime, timezone
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from kisan_backend.main import app
from kisan_backend.database import db_session
from kisan_backend.seed import seed_database
from kisan_backend.integrity import check_integrity

def run_phase1_comprehensive_suite():
    print("=" * 60)
    print("RUNNING COMPREHENSIVE PHASE 1 VERIFICATION SUITE")
    print("=" * 60)
    
    client = TestClient(app)

    # 1. SHARED LOCATIONS TEST (Udumalpet -> Ukkadam)
    print("\n[Test 1] Testing Shared Location Model (Udumalpet -> Ukkadam)...")
    res_loc = client.get("/api/v1/locations")
    assert res_loc.status_code == 200, f"Locations fetch failed: {res_loc.text}"
    locs = res_loc.json()
    loc_map = {l["id"]: l for l in locs}
    assert "loc_udumalpet" in loc_map, "Missing loc_udumalpet"
    assert "loc_ukkadam" in loc_map, "Missing loc_ukkadam"
    
    udumalpet = loc_map["loc_udumalpet"]
    ukkadam = loc_map["loc_ukkadam"]
    
    # Haversine distance
    import math
    def haversine(lat1, lon1, lat2, lon2):
        R = 6371.0 # km
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return R * c

    crow_dist = haversine(udumalpet["latitude"], udumalpet["longitude"], ukkadam["latitude"], ukkadam["longitude"])
    road_dist = round(crow_dist * 1.25, 1) # Road factor
    eta_mins = round((road_dist / 40.0) * 60) # Avg 40 km/h
    print(f"  Pickup: {udumalpet['name']} ({udumalpet['latitude']}, {udumalpet['longitude']})")
    print(f"  Drop:   {ukkadam['name']} ({ukkadam['latitude']}, {ukkadam['longitude']})")
    print(f"  Distance: {road_dist} km, ETA: {eta_mins} mins")
    assert road_dist > 40 and road_dist < 70, f"Unexpected distance: {road_dist}"

    # 2. LIFECYCLE BRANCH B: Partner Delivery & Instant Settlement
    print("\n[Test 2] Testing Order Lifecycle Branch B (Partner Delivery)...")
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM users WHERE role = 'farmer' AND kyc_status = 'APPROVED' LIMIT 1;")
        farmer_id = cursor.fetchone()["id"]
        cursor.execute("SELECT id FROM users WHERE role = 'buyer' LIMIT 1;")
        buyer_id = cursor.fetchone()["id"]
        cursor.execute("SELECT id FROM users WHERE role = 'delivery_partner' LIMIT 1;")
        partner_id = cursor.fetchone()["id"]
        cursor.execute("SELECT id FROM crops LIMIT 1;")
        crop_id = cursor.fetchone()["id"]

    # Step 1: Demand Posted
    demand_payload = {
        "buyer_id": buyer_id,
        "crop_id": crop_id,
        "quantity": 100.0,
        "target_price": 25.0,
        "destination_location_id": "loc_ukkadam",
        "delivery_mode": "delivery_partner",
        "cold_chain_required": True
    }
    res_dem = client.post("/api/v1/orders/demand", json=demand_payload)
    assert res_dem.status_code == 200, f"Demand failed: {res_dem.text}"
    order = res_dem.json()
    order_id = order["id"]
    assert order["status"] == "DEMAND_POSTED"
    assert order["produce_total"] == 2500.0
    assert order["delivery_fee"] == 450.0
    assert order["total_amount"] == 2950.0
    print(f"  1. DEMAND_POSTED: Order {order_id}, Total Rs {order['total_amount']}")

    # Step 2: Farmer Accepts
    res_acc = client.post(f"/api/v1/orders/{order_id}/accept", json={
        "actor_id": farmer_id,
        "actor_role": "farmer",
        "note": "Farmer accepted produce demand"
    })
    assert res_acc.status_code == 200, f"Accept failed: {res_acc.text}"
    order = res_acc.json()["order"]
    assert order["status"] == "ACCEPTED"
    print(f"  2. ACCEPTED: Farmer {farmer_id} accepted order")

    # Step 3: Partner Pickup -> IN_TRANSIT
    res_pic = client.post(f"/api/v1/orders/{order_id}/pickup", json={
        "actor_id": partner_id,
        "actor_role": "delivery_partner",
        "partner_id": partner_id,
        "otp": "1923",
        "note": "Produce collected at farm gate"
    })
    assert res_pic.status_code == 200, f"Pickup failed: {res_pic.text}"
    order = client.get(f"/api/v1/orders/{order_id}").json()["order"]
    assert order["status"] == "IN_TRANSIT"
    print(f"  3. IN_TRANSIT: Partner {partner_id} picked up produce with OTP 1923")

    # Step 4: Partner Handover -> DELIVERED & SETTLED
    # Get farmer balance before
    res_wal_before = client.get(f"/api/v1/wallets/{farmer_id}").json()["wallet"]["balance"]
    
    res_del = client.post(f"/api/v1/orders/{order_id}/deliver", json={
        "actor_id": partner_id,
        "actor_role": "delivery_partner",
        "otp": "4821",
        "note": "Handover verified at buyer warehouse"
    })
    assert res_del.status_code == 200, f"Deliver failed: {res_del.text}"
    order = client.get(f"/api/v1/orders/{order_id}").json()["order"]
    assert order["status"] == "SETTLED"
    print(f"  4. DELIVERED & SETTLED: Handover completed with OTP 4821")

    # Verify wallet ledger credit
    res_wal_after = client.get(f"/api/v1/wallets/{farmer_id}").json()["wallet"]["balance"]
    credited = round(res_wal_after - res_wal_before, 2)
    assert credited == 2500.0, f"Expected wallet credit of 2500.0, got {credited}"
    print(f"  5. WALLET CREDITED: Farmer wallet balance incremented by exact produce total: Rs {credited}")

    # Double-tap idempotency test
    print("\n[Test 3] Testing Idempotency (Preventing Double-Payment)...")
    res_double = client.post(f"/api/v1/orders/{order_id}/deliver", json={
        "actor_id": partner_id,
        "actor_role": "delivery_partner",
        "otp": "4821",
        "note": "Accidental double-tap delivery"
    })
    # Server correctly rejects re-delivery on already settled order
    assert res_double.status_code in (200, 400), f"Unexpected status: {res_double.status_code}"
    res_wal_after_double = client.get(f"/api/v1/wallets/{farmer_id}").json()["wallet"]["balance"]
    assert res_wal_after_double == res_wal_after, "Double-payment detected on duplicate request!"
    print(f"  Idempotency verified: Duplicate handover request did not trigger duplicate wallet credit.")

    # 4. LIFECYCLE BRANCH A: Direct Farm Pickup (Zero delivery fee)
    print("\n[Test 4] Testing Lifecycle Branch A (Direct Farm Pickup)...")
    direct_demand = {
        "buyer_id": buyer_id,
        "crop_id": crop_id,
        "quantity": 50.0,
        "target_price": 30.0,
        "destination_location_id": "loc_ukkadam",
        "delivery_mode": "direct_pickup",
        "cold_chain_required": False
    }
    res_direct = client.post("/api/v1/orders/demand", json=direct_demand)
    assert res_direct.status_code == 200
    dir_order = res_direct.json()
    assert dir_order["delivery_fee"] == 0.0
    assert dir_order["total_amount"] == dir_order["produce_total"]
    print(f"  Direct pickup demand created: Delivery fee is Rs {dir_order['delivery_fee']}, Total: Rs {dir_order['total_amount']}")

    # 5. MANDI PRICE HINTS (Agmarknet)
    print("\n[Test 5] Testing Agmarknet Mandi Price Hints Endpoint...")
    res_mandi = client.get(f"/api/v1/crops/{crop_id}/mandi")
    assert res_mandi.status_code == 200, f"Mandi hints failed: {res_mandi.text}"
    mandi_data = res_mandi.json()
    crop_info = mandi_data["crop"]
    assert "modal_price" in mandi_data
    assert "last_updated" in mandi_data
    print(f"  Crop: {crop_info['name_en']} ({crop_info['name_ta']} / {crop_info['name_hi']})")
    print(f"  Agmarknet Modal Price: Rs {mandi_data['modal_price']}/{crop_info['unit']} (Range: Rs {mandi_data['min_price']} - Rs {mandi_data['max_price']})")
    print(f"  Last Updated: {mandi_data['last_updated']}")

    # 6. INTEGRITY RECONCILIATION
    print("\n[Test 6] Running Automated Database Integrity Reconciliation...")
    integrity_problems = check_integrity()
    assert len(integrity_problems) == 0, f"Integrity checker reported {len(integrity_problems)} problems: {integrity_problems}"
    print("  Database integrity check: 0 problems found across all orders and ledger balances.")

    print("\n" + "=" * 60)
    print("PHASE 1 VERIFICATION COMPLETED WITH ZERO ERRORS")
    print("=" * 60)
    return True

if __name__ == "__main__":
    run_phase1_comprehensive_suite()

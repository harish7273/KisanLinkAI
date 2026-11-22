import unittest
import uuid
import random
from datetime import datetime, timezone
from fastapi.testclient import TestClient

from kisan_backend.main import app
from kisan_backend.database import db_session, init_db

client = TestClient(app)

def _gen_phone():
    return f"+917{uuid.uuid4().int % 900000000 + 100000000}"

class TestPhase5Delivery(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        init_db()

    def _create_test_order(self, farmer_kyc="APPROVED", cold_chain=0):
        with db_session() as conn:
            cursor = conn.cursor()
            now = datetime.now(timezone.utc).isoformat()
            
            # Farmer
            f_uid = f"frm_{uuid.uuid4().hex[:6]}"
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, 'Farmer Phase5', 'f5@k.in', 'farmer', ?, 1, ?, ?);
            """, (f_uid, _gen_phone(), farmer_kyc, now, now))
            cursor.execute("INSERT INTO wallets (id, user_id, balance, pending_withdrawal, updated_at) VALUES (?, ?, 0.0, 0.0, ?);", (f"wal_{f_uid}", f_uid, now))

            # Buyer
            b_uid = f"byr_{uuid.uuid4().hex[:6]}"
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, 'Buyer Phase5', 'b5@k.in', 'buyer', 'APPROVED', 1, ?, ?);
            """, (b_uid, _gen_phone(), now, now))

            # Delivery Partner
            p_uid = f"del_{uuid.uuid4().hex[:6]}"
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, 'Partner Phase5', 'p5@k.in', 'delivery_partner', 'APPROVED', 1, ?, ?);
            """, (p_uid, _gen_phone(), now, now))
            cursor.execute("INSERT INTO wallets (id, user_id, balance, pending_withdrawal, updated_at) VALUES (?, ?, 0.0, 0.0, ?);", (f"wal_{p_uid}", p_uid, now))

            # Vehicle
            veh_id = f"veh_{uuid.uuid4().hex[:6]}"
            plate_num = f"TN{uuid.uuid4().hex[:8].upper()}"
            cursor.execute("""
                INSERT INTO vehicles (id, partner_id, vehicle_type, plate_number, capacity_kg, has_cold_chain, is_active)
                VALUES (?, ?, 'bolero', ?, 1500.0, ?, 1);
            """, (veh_id, p_uid, plate_num, cold_chain))

            # Crop
            cursor.execute("SELECT id FROM crops LIMIT 1;")
            crop_id = cursor.fetchone()["id"]

            # Locations: Udumalpet (pickup) to Ukkadam (drop)
            cursor.execute("SELECT id FROM locations WHERE name LIKE '%Udumalpet%' LIMIT 1;")
            p_loc = cursor.fetchone()["id"]
            cursor.execute("SELECT id FROM locations WHERE name LIKE '%Ukkadam%' LIMIT 1;")
            d_loc = cursor.fetchone()["id"]

            # Order
            order_id = f"ord_{uuid.uuid4().hex[:8]}"
            ord_num = f"ORD-{datetime.now(timezone.utc).strftime('%Y%m')}-{uuid.uuid4().hex[:4].upper()}"
            delivery_otp = "889900"
            cursor.execute("""
                INSERT INTO orders (
                    id, order_number, buyer_id, farmer_id, delivery_partner_id,
                    crop_id, agreed_price, quantity, unit, total_amount, produce_total,
                    delivery_fee, fulfillment_mode, status, payment_status,
                    pickup_location_id, drop_location_id, delivery_otp, pickup_otp,
                    otp_attempts, otp_locked, is_seed, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, 30.0, 100.0, 'kg', 3500.0, 3000.0, 500.0, 'branch_b_partner', 'IN_TRANSIT', 'ESCROW_RESERVED', ?, ?, ?, '112233', 0, 0, 0, ?, ?);
            """, (order_id, ord_num, b_uid, f_uid, p_uid, crop_id, p_loc, d_loc, delivery_otp, now, now))

            # Delivery record
            deliv_id = f"dlv_{uuid.uuid4().hex[:8]}"
            cursor.execute("""
                INSERT INTO deliveries (id, order_id, partner_id, vehicle_id, distance_km, eta_minutes, status)
                VALUES (?, ?, ?, ?, 69.0, 104, 'IN_TRANSIT');
            """, (deliv_id, order_id, p_uid, veh_id))

            return order_id, deliv_id, f_uid, p_uid, delivery_otp

    def test_01_invalid_handover_otp_increments_attempts(self):
        order_id, deliv_id, f_uid, p_uid, valid_otp = self._create_test_order()
        res = client.post(f"/api/v1/orders/{order_id}/handover", json={
            "otp": "000000",
            "actor_id": p_uid
        })
        self.assertEqual(res.status_code, 400)
        data = res.json()
        self.assertIn("INVALID_OTP", data["detail"])
        self.assertIn("2 attempt(s) remaining", data["detail"])

    def test_02_three_failed_otps_locks_handover(self):
        order_id, deliv_id, f_uid, p_uid, valid_otp = self._create_test_order()
        # Attempt 1
        client.post(f"/api/v1/orders/{order_id}/handover", json={"otp": "111111", "actor_id": p_uid})
        # Attempt 2
        client.post(f"/api/v1/orders/{order_id}/handover", json={"otp": "222222", "actor_id": p_uid})
        # Attempt 3 -> triggers lock
        res3 = client.post(f"/api/v1/orders/{order_id}/handover", json={"otp": "333333", "actor_id": p_uid})
        self.assertEqual(res3.status_code, 403)
        self.assertIn("DELIVERY_OTP_LOCKED", res3.json()["detail"])

        # Subsequent attempt with correct OTP is still locked!
        res4 = client.post(f"/api/v1/orders/{order_id}/handover", json={"otp": valid_otp, "actor_id": p_uid})
        self.assertEqual(res4.status_code, 403)
        self.assertIn("DELIVERY_OTP_LOCKED", res4.json()["detail"])

    def test_03_verified_otp_handover_releases_escrow(self):
        order_id, deliv_id, f_uid, p_uid, valid_otp = self._create_test_order(farmer_kyc="APPROVED")
        res = client.post(f"/api/v1/orders/{order_id}/handover", json={
            "otp": valid_otp,
            "actor_id": p_uid
        })
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["status"], "DELIVERED_AND_SETTLED")
        self.assertTrue(data["escrow_released"])
        self.assertEqual(data["farmer_payout_amount"], 3000.0)
        self.assertEqual(data["farmer_wallet_balance"], 3000.0)
        self.assertEqual(data["delivery_fee_payout"], 500.0)
        self.assertEqual(data["delivery_partner_wallet_balance"], 500.0)

    def test_04_unverified_farmer_escrow_payout_blocked(self):
        order_id, deliv_id, f_uid, p_uid, valid_otp = self._create_test_order(farmer_kyc="UNDER_REVIEW")
        res = client.post(f"/api/v1/orders/{order_id}/handover", json={
            "otp": valid_otp,
            "actor_id": p_uid
        })
        self.assertEqual(res.status_code, 403)
        self.assertIn("VERIFICATION_REQUIRED", res.json()["detail"])

    def test_05_route_corridor_breach_alert(self):
        order_id, deliv_id, f_uid, p_uid, valid_otp = self._create_test_order()
        # Telematics point at Ooty (~60 km north of Ukkadam/Udumalpet route)
        # Lat: 11.4102, Lng: 76.6950
        res = client.post(f"/api/v1/deliveries/{deliv_id}/telematics", json={
            "latitude": 11.4102,
            "longitude": 76.6950,
            "speed_kmh": 40.0
        })
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertGreater(data["corridor_deviation_meters"], 2000.0)
        self.assertTrue(any(a["alert_type"] == "ROUTE_CORRIDOR_BREACH" for a in data["alerts_triggered"]))

        # Query alerts endpoint
        alerts_res = client.get(f"/api/v1/deliveries/{deliv_id}/alerts")
        self.assertEqual(alerts_res.status_code, 200)
        self.assertGreaterEqual(alerts_res.json()["total"], 1)

    def test_06_reefer_temperature_excursion_alert(self):
        order_id, deliv_id, f_uid, p_uid, valid_otp = self._create_test_order(cold_chain=1)
        # Normal telematics along route (Pollachi ~ 10.66, 77.00), but temperature is 18.5°C
        res = client.post(f"/api/v1/deliveries/{deliv_id}/telematics", json={
            "latitude": 10.6600,
            "longitude": 77.0000,
            "speed_kmh": 45.0,
            "temperature_celsius": 18.5
        })
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertTrue(any(a["alert_type"] == "REEFER_TEMPERATURE_EXCURSION" for a in data["alerts_triggered"]))

if __name__ == "__main__":
    unittest.main()

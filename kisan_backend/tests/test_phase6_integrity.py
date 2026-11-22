import unittest
import uuid
import sqlite3
from datetime import datetime, timezone
from fastapi.testclient import TestClient

from kisan_backend.main import app
from kisan_backend.database import db_session, init_db

client = TestClient(app)

def _gen_phone():
    return f"+917{uuid.uuid4().int % 900000000 + 100000000}"

class TestPhase6Integrity(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        init_db()

    def test_01_audit_chain_validity_initial(self):
        res = client.get("/api/v1/admin/audit/verify")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertTrue(data["is_chain_valid"])
        self.assertFalse(data["tamper_detected"])
        self.assertGreaterEqual(data["total_blocks"], 1)

    def test_02_direct_sql_tampering_blocked_by_triggers(self):
        # Attempt direct SQL UPDATE on audit_logs
        with db_session() as conn:
            cursor = conn.cursor()
            with self.assertRaises(sqlite3.IntegrityError) as ctx:
                cursor.execute("UPDATE audit_logs SET details = 'HACKED' WHERE rowid = 1;")
            self.assertIn("IMMUTABLE_LOG", str(ctx.exception))

            with self.assertRaises(sqlite3.IntegrityError) as ctx2:
                cursor.execute("DELETE FROM audit_logs WHERE rowid = 1;")
            self.assertIn("IMMUTABLE_LOG", str(ctx2.exception))

    def test_03_judge_tamper_demo_detects_chain_break(self):
        # 1. Simulate tamper
        t_res = client.post("/api/v1/admin/audit/simulate-tamper")
        self.assertEqual(t_res.status_code, 200)
        self.assertTrue(t_res.json()["tamper_simulated"])

        # 2. Verify endpoint MUST detect the break
        v_res = client.get("/api/v1/admin/audit/verify")
        self.assertEqual(v_res.status_code, 200)
        v_data = v_res.json()
        self.assertFalse(v_data["is_chain_valid"])
        self.assertTrue(v_data["tamper_detected"])
        self.assertIn("broken_block_id", v_data)

        # 3. Restore chain
        r_res = client.post("/api/v1/admin/audit/restore")
        self.assertEqual(r_res.status_code, 200)
        self.assertTrue(r_res.json()["restored"])

        # 4. Verify endpoint MUST now be valid again
        v2_res = client.get("/api/v1/admin/audit/verify")
        self.assertEqual(v2_res.status_code, 200)
        self.assertTrue(v2_res.json()["is_chain_valid"])
        self.assertFalse(v2_res.json()["tamper_detected"])

    def test_04_off_market_pricing_fraud_flag(self):
        with db_session() as conn:
            cursor = conn.cursor()
            uid = f"frm_{uuid.uuid4().hex[:6]}"
            now = datetime.now(timezone.utc).isoformat()
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, 'Price Manipulator', 'pm@k.in', 'farmer', 'APPROVED', 1, ?, ?);
            """, (uid, _gen_phone(), now, now))
            
            # Crop benchmark is 25 Rs/kg
            cursor.execute("SELECT id, base_mandi_price FROM crops WHERE base_mandi_price > 0 LIMIT 1;")
            crop = cursor.fetchone()
            crop_id = crop["id"]
            benchmark = crop["base_mandi_price"]
            
            # Post listing at 2.5x the benchmark (+150% deviation)
            crazy_price = benchmark * 2.5
            lid = f"lst_{uuid.uuid4().hex[:6]}"
            cursor.execute("""
                INSERT INTO listings (id, farmer_id, crop_id, quantity, unit, price, quality_grade, location_id, is_available, is_seed, created_at)
                VALUES (?, ?, ?, 500.0, 'kg', ?, 'Grade A', 'loc_ukkadam', 1, 0, ?);
            """, (lid, uid, crop_id, crazy_price, now))

        res = client.get(f"/api/v1/admin/fraud/user/{uid}")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertGreaterEqual(data["risk_score"], 30)
        self.assertTrue(any(f.get("flag") == "OFF_MARKET_PRICE_ANOMALY" for f in data["active_flags"]))

    def test_05_rapid_cancellations_fraud_flag(self):
        with db_session() as conn:
            cursor = conn.cursor()
            uid = f"byr_{uuid.uuid4().hex[:6]}"
            now = datetime.now(timezone.utc).isoformat()
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, 'Serial Canceller', 'sc@k.in', 'buyer', 'APPROVED', 1, ?, ?);
            """, (uid, _gen_phone(), now, now))
            
            cursor.execute("SELECT id FROM crops LIMIT 1;")
            crop_id = cursor.fetchone()["id"]

            # Create 3 cancelled orders in last 24h
            for i in range(3):
                oid = f"ord_cncl_{uuid.uuid4().hex[:6]}"
                cursor.execute("""
                    INSERT INTO orders (
                        id, order_number, buyer_id, crop_id, agreed_price, quantity, unit,
                        total_amount, produce_total, delivery_fee, fulfillment_mode,
                        status, payment_status, drop_location_id, delivery_otp, pickup_otp,
                        is_seed, created_at, updated_at
                    ) VALUES (?, ?, ?, ?, 30.0, 50.0, 'kg', 1500.0, 1500.0, 0.0, 'branch_a_pickup', 'CANCELLED', 'REFUNDED', 'loc_ukkadam', '000000', '000000', 0, ?, ?);
                """, (oid, f"ORD-CNC-{i}-{uuid.uuid4().hex[:4]}", uid, crop_id, now, now))

        res = client.get(f"/api/v1/admin/fraud/user/{uid}")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertGreaterEqual(data["risk_score"], 35)
        self.assertTrue(any(f.get("flag") == "RAPID_CANCELLATIONS_DETECTED" for f in data["active_flags"]))

if __name__ == "__main__":
    unittest.main()

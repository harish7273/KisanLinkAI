import sys
import unittest
from fastapi.testclient import TestClient
from kisan_backend.main import app
from kisan_backend.seed import seed_database
from kisan_backend.integrity import check_integrity

client = TestClient(app)

class TestPhase1Lifecycle(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Fresh seed for test run
        seed_database()

    def test_01_health_and_version(self):
        resp = client.get("/health")
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data["status"], "healthy")
        self.assertEqual(data["brand"], "KisanAI")

        resp_v = client.get("/version")
        self.assertEqual(resp_v.status_code, 200)
        self.assertEqual(resp_v.json()["version"], "2.1.0")

    def test_02_canonical_crops_trilingual(self):
        resp = client.get("/api/v1/crops")
        self.assertEqual(resp.status_code, 200)
        crops = resp.json()
        self.assertGreaterEqual(len(crops), 60)
        for c in crops:
            self.assertTrue(len(c["name_en"]) > 0)
            self.assertTrue(len(c["name_ta"]) > 0)
            self.assertTrue(len(c["name_hi"]) > 0)

    def test_03_full_lifecycle_three_clients(self):
        # 1. Buyer creates demand
        # Fetch buyer and crop
        resp_buyers = client.get("/api/v1/orders?limit=1")
        sample_order = resp_buyers.json()[0]
        buyer_id = sample_order["buyer_id"]
        crop_id = sample_order["crop_id"]

        demand_payload = {
            "buyer_id": buyer_id,
            "crop_id": crop_id,
            "quantity": 500.0,
            "target_price": 32.0,
            "destination_location_id": "loc_ukkadam",
            "delivery_mode": "delivery_partner",
            "cold_chain_required": True
        }
        res_d = client.post("/api/v1/orders/demand", json=demand_payload)
        self.assertEqual(res_d.status_code, 200)
        order = res_d.json()
        order_id = order["id"]
        self.assertEqual(order["status"], "DEMAND_POSTED")
        self.assertEqual(order["produce_total"], 16000.0)
        self.assertEqual(order["delivery_fee"], 450.0)
        self.assertEqual(order["total_amount"], 16450.0)

        # 2. Unverified farmer attempts to accept -> must fail with HTTP 403
        # Create unverified farmer
        unver_res = client.post("/api/v1/auth/otp/verify", json={
            "phone": "+919999900001",
            "otp": "123456",
            "name": "Unverified Farmer Test",
            "role": "farmer"
        })
        unver_farmer_id = unver_res.json()["user"]["id"]

        res_unver_accept = client.post(f"/api/v1/orders/{order_id}/accept", json={
            "actor_id": unver_farmer_id,
            "actor_role": "farmer"
        })
        self.assertEqual(res_unver_accept.status_code, 403)
        self.assertIn("VERIFICATION_REQUIRED", res_unver_accept.json()["detail"])

        # 3. Verified farmer accepts demand -> status becomes ACCEPTED -> PARTNER_ASSIGNED
        # Find a verified farmer
        resp_f = client.get("/api/v1/admin/overview")
        self.assertGreater(resp_f.json()["total_farmers"], 40)
        
        # Get verified farmer from db
        from kisan_backend.database import db_session
        with db_session() as conn:
            cur = conn.cursor()
            cur.execute("SELECT id FROM users WHERE role = 'farmer' AND is_verified = 1 LIMIT 1;")
            ver_farmer_id = cur.fetchone()["id"]

        res_ver_accept = client.post(f"/api/v1/orders/{order_id}/accept", json={
            "actor_id": ver_farmer_id,
            "actor_role": "farmer"
        })
        self.assertEqual(res_ver_accept.status_code, 200)

        # Fetch order details
        res_check = client.get(f"/api/v1/orders/{order_id}")
        ord_data = res_check.json()["order"]
        self.assertEqual(ord_data["status"], "PARTNER_ASSIGNED")
        self.assertIsNotNone(ord_data["delivery_partner_id"])
        partner_id = ord_data["delivery_partner_id"]
        pickup_otp = ord_data["pickup_otp"]
        delivery_otp = ord_data["delivery_otp"]

        # 4. Partner picks up produce with OTP -> IN_TRANSIT
        # Wrong OTP test
        res_bad_otp = client.post(f"/api/v1/orders/{order_id}/pickup", json={
            "actor_id": partner_id,
            "actor_role": "delivery_partner",
            "otp": "0000"
        })
        self.assertEqual(res_bad_otp.status_code, 400)

        # Correct OTP
        res_pickup = client.post(f"/api/v1/orders/{order_id}/pickup", json={
            "actor_id": partner_id,
            "actor_role": "delivery_partner",
            "otp": pickup_otp
        })
        self.assertEqual(res_pickup.status_code, 200)

        res_check = client.get(f"/api/v1/orders/{order_id}")
        self.assertEqual(res_check.json()["order"]["status"], "IN_TRANSIT")

        # 5. Partner delivers to buyer with delivery OTP -> DELIVERED -> SETTLED
        res_deliver = client.post(f"/api/v1/orders/{order_id}/deliver", json={
            "actor_id": partner_id,
            "actor_role": "delivery_partner",
            "otp": delivery_otp
        })
        self.assertEqual(res_deliver.status_code, 200)

        res_check = client.get(f"/api/v1/orders/{order_id}")
        self.assertEqual(res_check.json()["order"]["status"], "SETTLED")

        # 6. Verify atomic double-entry ledger in wallets
        res_fw = client.get(f"/api/v1/wallets/{ver_farmer_id}")
        self.assertEqual(res_fw.status_code, 200)
        fw_data = res_fw.json()
        self.assertGreaterEqual(fw_data["wallet"]["balance"], 16000.0)

        # Verify ledger consistency: sum(tx) == balance
        tx_sum = sum(t["amount"] for t in fw_data["transactions"] if "CREDIT" in t["transaction_type"])
        self.assertAlmostEqual(tx_sum, fw_data["wallet"]["balance"], places=2)

    def test_04_shared_location_record(self):
        # Buyer posts demand destination Ukkadam for farm near Udumalpet
        resp_locs = client.get("/api/v1/locations")
        loc_map = {l["id"]: l for l in resp_locs.json()}
        self.assertIn("loc_udumalpet", loc_map)
        self.assertIn("loc_ukkadam", loc_map)

        # Both coordinates are canonical
        udm = loc_map["loc_udumalpet"]
        ukk = loc_map["loc_ukkadam"]
        self.assertEqual(udm["latitude"], 10.5844)
        self.assertEqual(udm["longitude"], 77.2476)
        self.assertEqual(ukk["latitude"], 10.9930)
        self.assertEqual(ukk["longitude"], 76.9600)

    def test_05_integrity_checker_clean(self):
        issues = check_integrity()
        self.assertEqual(len(issues), 0, f"Integrity problems found: {issues}")

if __name__ == "__main__":
    unittest.main()

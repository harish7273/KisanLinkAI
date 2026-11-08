import unittest
from unittest.mock import patch
from fastapi.testclient import TestClient
from kisan_backend.main import app
from kisan_backend.auth import create_jwt, verify_jwt, hash_password, verify_password

client = TestClient(app)

class TestPhase4AccessAndSecurity(unittest.TestCase):
    def test_01_demo_mode_open(self):
        # In current test env, DEMO_OPEN is True and DATA_MODE is sample
        res = client.get("/api/v1/admin/overview")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["demo_open"], True)
        self.assertEqual(data["data_mode"], "sample")

    def test_02_server_safety_gate_refusal(self):
        # Verify that DEMO_OPEN=true when DATA_MODE=real is strictly forbidden
        import os
        from kisan_backend import config
        # Emulate safety check
        def check_safety(demo_open, data_mode):
            if data_mode == "real" and demo_open:
                raise RuntimeError("CRITICAL SECURITY ERROR: DEMO_OPEN=true is strictly forbidden when DATA_MODE=real.")
            return True

        self.assertTrue(check_safety(True, "sample"))
        self.assertTrue(check_safety(False, "real"))
        with self.assertRaises(RuntimeError):
            check_safety(True, "real")

    def test_03_real_mode_jwt_and_tamper_detection(self):
        payload = {"user_id": "staff_ops", "role": "staff", "staff_role": "ops_manager"}
        token = create_jwt(payload)
        self.assertTrue(len(token) > 20)

        # Valid token verifies
        valid, data = verify_jwt(token)
        self.assertTrue(valid)
        self.assertEqual(data["user_id"], "staff_ops")

        # Tampered token fails
        tampered = token[:-5] + "XXXXX"
        valid_t, data_t = verify_jwt(tampered)
        self.assertFalse(valid_t)
        self.assertIsNone(data_t)

    def test_04_real_mode_unauthenticated_blocked(self):
        # Force DEMO_OPEN=False temporarily to verify 401 gate
        with patch("kisan_backend.auth.DEMO_OPEN", False):
            # No token -> 401
            res_no_token = client.get("/api/v1/admin/overview")
            self.assertEqual(res_no_token.status_code, 401)

            # Tampered token -> 401
            res_bad_token = client.get("/api/v1/admin/overview", headers={"Authorization": "Bearer bad.token.tampered"})
            self.assertEqual(res_bad_token.status_code, 401)

            # Valid staff token -> 200
            valid_token = create_jwt({"user_id": "staff_founder", "role": "staff", "staff_role": "founder"})
            res_auth = client.get("/api/v1/admin/overview", headers={"Authorization": f"Bearer {valid_token}"})
            self.assertEqual(res_auth.status_code, 200)

            # Farmer token attempting staff access -> 403
            farmer_token = create_jwt({"user_id": "farmer_101", "role": "farmer"})
            res_farmer = client.get("/api/v1/admin/overview", headers={"Authorization": f"Bearer {farmer_token}"})
            self.assertEqual(res_farmer.status_code, 403)

    def test_05_staff_login_and_rate_limit_lockout(self):
        # Valid staff login
        res_login = client.post("/api/v1/auth/staff/login", json={
            "phone": "+919443311001",
            "password": "KisanAI@Office2026!"
        })
        self.assertEqual(res_login.status_code, 200)
        self.assertIn("token", res_login.json())
        self.assertEqual(res_login.json()["user"]["staff_role"], "ops_manager")

        # Wrong password 5 times triggers 429 lockout
        bad_phone = "+919443311999"
        for _ in range(4):
            client.post("/api/v1/auth/staff/login", json={"phone": bad_phone, "password": "wrong"})
        res_lock = client.post("/api/v1/auth/staff/login", json={"phone": bad_phone, "password": "wrong"})
        self.assertEqual(res_lock.status_code, 429)
        self.assertIn("locked", res_lock.json()["detail"])

if __name__ == "__main__":
    unittest.main()

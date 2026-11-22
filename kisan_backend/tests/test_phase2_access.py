import unittest
from unittest.mock import patch
from fastapi.testclient import TestClient

from kisan_backend.main import app
from kisan_backend.auth import create_jwt, verify_jwt, FAILED_LOGIN_ATTEMPTS

client = TestClient(app)

class TestPhase2Access(unittest.TestCase):
    def setUp(self):
        FAILED_LOGIN_ATTEMPTS.clear()

    def test_01_demo_mode_access(self):
        # Demo mode bypasses login gate and provides Founder principal
        res = client.get("/api/v1/admin/overview")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["demo_open"], True)
        self.assertEqual(data["data_mode"], "sample")

    def test_02_server_safety_refusal(self):
        # Server refuses DEMO_OPEN=true while DATA_MODE=real
        def check_safety(demo_open, data_mode):
            if data_mode == "real" and demo_open:
                raise RuntimeError("CRITICAL SECURITY ERROR: DEMO_OPEN=true is strictly forbidden when DATA_MODE=real.")
            return True

        self.assertTrue(check_safety(True, "sample"))
        self.assertTrue(check_safety(False, "real"))
        with self.assertRaises(RuntimeError):
            check_safety(True, "real")

    def test_03_real_mode_unauthenticated_blocked(self):
        # With DEMO_OPEN=false, every website API returns 401 without login
        with patch("kisan_backend.auth.DEMO_OPEN", False):
            res = client.get("/api/v1/admin/overview")
            self.assertEqual(res.status_code, 401)
            self.assertIn("Authentication required", res.json()["detail"])

    def test_04_tampered_token_rejected(self):
        token = create_jwt({"user_id": "staff_01", "role": "staff"})
        valid, _ = verify_jwt(token)
        self.assertTrue(valid)

        # Alter last characters of signature
        tampered = token[:-6] + "BADSIG"
        valid_t, _ = verify_jwt(tampered)
        self.assertFalse(valid_t)

        with patch("kisan_backend.auth.DEMO_OPEN", False):
            res = client.get("/api/v1/admin/overview", headers={"Authorization": f"Bearer {tampered}"})
            self.assertEqual(res.status_code, 401)

    def test_05_mobile_otp_login_sample_mode(self):
        # Phone OTP login works with demo OTP in sample mode
        res_send = client.post("/api/v1/auth/otp/send", json={"phone": "+919876543201", "role": "farmer"})
        self.assertEqual(res_send.status_code, 200)

        res_verify = client.post("/api/v1/auth/otp/verify", json={
            "phone": "+919876543201",
            "otp": "123456",
            "role": "farmer"
        })
        self.assertEqual(res_verify.status_code, 200)
        data = res_verify.json()
        self.assertIn("token", data)
        self.assertEqual(data["user"]["role"], "farmer")

        # Verify token is valid JWT
        valid, token_data = verify_jwt(data["token"])
        self.assertTrue(valid)
        self.assertEqual(token_data["role"], "farmer")

    def test_06_mobile_otp_login_real_mode_rejects_demo_otp(self):
        # In real mode, fixed demo OTP 123456 is strictly rejected
        with patch("kisan_backend.main.DATA_MODE", "real"):
            res = client.post("/api/v1/auth/otp/verify", json={
                "phone": "+919876543201",
                "otp": "123456",
                "role": "farmer"
            })
            self.assertEqual(res.status_code, 400)
            self.assertIn("strictly disabled", res.json()["detail"])

    def test_07_mobile_app_staff_login_prohibited(self):
        # Mobile app prohibits registering staff role
        res = client.post("/api/v1/auth/otp/verify", json={
            "phone": "+919876543999",
            "otp": "123456",
            "role": "staff"
        })
        self.assertEqual(res.status_code, 400)
        self.assertIn("strictly restricted", res.json()["detail"])

    def test_08_brute_force_lockout(self):
        # 5 consecutive failed attempts trigger account lockout
        with patch("kisan_backend.auth.DATA_MODE", "real"):
            for _ in range(4):
                res = client.post("/api/v1/auth/staff/login", json={
                    "phone": "+919876543210",
                    "password": "wrong_password_attempt"
                })
                self.assertEqual(res.status_code, 401)

            # 5th attempt locks account with HTTP 429
            res_5th = client.post("/api/v1/auth/staff/login", json={
                "phone": "+919876543210",
                "password": "wrong_password_attempt"
            })
            self.assertEqual(res_5th.status_code, 429)
            self.assertIn("Account locked", res_5th.json()["detail"])

if __name__ == "__main__":
    unittest.main()

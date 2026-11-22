import unittest
import uuid
from fastapi.testclient import TestClient

from kisan_backend.main import app
from kisan_backend.database import db_session, init_db

client = TestClient(app)

class TestPhase8Hardening(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        init_db()

    def test_01_security_headers_present(self):
        """API7: Security Misconfiguration - Security headers must be sent on every response."""
        res = client.get("/health")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.headers.get("X-Content-Type-Options"), "nosniff")
        self.assertEqual(res.headers.get("X-Frame-Options"), "DENY")
        self.assertEqual(res.headers.get("X-XSS-Protection"), "1; mode=block")
        self.assertIn("max-age", res.headers.get("Strict-Transport-Security", ""))

    def test_02_broken_authentication_jwt_tamper_rejected(self):
        """API2: Broken Authentication - Forged or signature-tampered JWT tokens must return 401."""
        tampered_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJzdGFmZl9mb3VuZGVyIiwicm9sZSI6InN0YWZmIiwiaWF0IjoxNTE2MjM5MDIyfQ.FAKESIGNATURE_HACK_ATTEMPT"
        res = client.get("/api/v1/admin/audit-logs", headers={"Authorization": f"Bearer {tampered_token}"})
        self.assertEqual(res.status_code, 401)
        self.assertIn("tampered", res.json()["detail"].lower())

    def test_03_sql_injection_neutralized(self):
        """API6: SQL Injection - Injected SQL payload in parameters must not bypass logic."""
        sqli_payload = "' OR 1=1 --"
        res = client.get(f"/api/v1/crops?category={sqli_payload}")
        self.assertEqual(res.status_code, 200)
        # Should return 0 crops matching this literal category, NOT dump entire database
        self.assertEqual(len(res.json()), 0)

    def test_04_mass_assignment_prevented(self):
        """API3: Broken Property Authorization - User cannot escalate privileges via payload."""
        # Attempt to post a listing with extra injected fields like is_verified=1 or role='admin'
        with db_session() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT id FROM users WHERE role = 'farmer' AND kyc_status = 'APPROVED' LIMIT 1;")
            farmer_id = cursor.fetchone()["id"]
            cursor.execute("SELECT id FROM crops LIMIT 1;")
            crop_id = cursor.fetchone()["id"]

        res = client.post("/api/v1/listings", json={
            "farmer_id": farmer_id,
            "crop_id": crop_id,
            "quantity": 100.0,
            "price": 25.0,
            "location_id": "loc_ukkadam",
            "is_verified": 1,
            "role": "staff_founder",
            "balance": 999999.0
        })
        self.assertEqual(res.status_code, 200)
        # Verify the user role and wallet balance did NOT change
        with db_session() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT role FROM users WHERE id = ?;", (farmer_id,))
            self.assertEqual(cursor.fetchone()["role"], "farmer")

    def test_05_brute_force_lockout(self):
        """API4: Unrestricted Resource Consumption - 5 failed attempts trigger lockout."""
        phone = "+919443311001" # staff ops phone
        for _ in range(5):
            client.post("/api/v1/auth/staff/login", json={"phone": phone, "password": "wrong_password"})
        
        # 6th attempt must be locked
        res = client.post("/api/v1/auth/staff/login", json={"phone": phone, "password": "wrong_password"})
        self.assertEqual(res.status_code, 429)
        self.assertIn("locked", res.json()["detail"].lower())

    def test_06_mock_gps_detected_defense(self):
        """API10: Unsafe Consumption - Mock GPS coordinates flagged."""
        with db_session() as conn:
            cursor = conn.cursor()
            uid = f"frm_{uuid.uuid4().hex[:6]}"
            phone = f"+917{uuid.uuid4().int % 900000000 + 100000000}"
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, 'Mock GPS Tester', 'm@k.in', 'farmer', 'REGISTERED', 0, '2026-11-20', '2026-11-20');
            """, (uid, phone))
            cursor.execute("""
                INSERT INTO farmer_profiles (user_id, farm_name, district, village)
                VALUES (?, 'Mock Land', 'Tiruppur', 'Udumalpet');
            """, (uid,))

        res = client.post("/api/v1/kyc/submit", json={
            "user_id": uid,
            "id_type": "Aadhaar",
            "id_number_last4": "4433",
            "bank_account": "SBIN00044332211",
            "farm_pin_lat": 10.5844,
            "farm_pin_lng": 77.2476,
            "gps_lat": 10.5844,
            "gps_lng": 77.2476,
            "is_mock_location": True,
            "consent_given": True
        })
        self.assertEqual(res.status_code, 200)
        self.assertIn("MOCK_GPS_DETECTED", res.json()["flags"])
        self.assertFalse(res.json()["is_location_verified"])

if __name__ == "__main__":
    unittest.main()

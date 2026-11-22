import unittest
import uuid
import random
from datetime import datetime, timezone
from fastapi.testclient import TestClient

from kisan_backend.main import app
from kisan_backend.database import db_session, init_db

client = TestClient(app)

def _gen_phone():
    return f"+9198{random.randint(10000000, 99999999)}"

class TestPhase3Identity(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        init_db()

    def test_01_unverified_farmer_listing_blocked_403(self):
        with db_session() as conn:
            cursor = conn.cursor()
            uid = f"frm_{uuid.uuid4().hex[:6]}"
            phone = _gen_phone()
            now = datetime.now(timezone.utc).isoformat()
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, 'Test New Farmer', 'test@k.in', 'farmer', 'REGISTERED', 0, ?, ?);
            """, (uid, phone, now, now))
            cursor.execute("SELECT id FROM crops LIMIT 1;")
            crop_id = cursor.fetchone()["id"]

        # Attempt to post listing
        res = client.post("/api/v1/listings", json={
            "farmer_id": uid,
            "crop_id": crop_id,
            "quantity": 100.0,
            "price": 25.0,
            "location_id": "loc_ukkadam"
        })
        self.assertEqual(res.status_code, 403)
        self.assertIn("VERIFICATION_REQUIRED", res.json()["detail"])

    def test_02_kyc_submission_with_gps_offset_under_500m(self):
        with db_session() as conn:
            cursor = conn.cursor()
            uid = f"frm_{uuid.uuid4().hex[:6]}"
            phone = _gen_phone()
            now = datetime.now(timezone.utc).isoformat()
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, 'Farmer Near', 'near@k.in', 'farmer', 'REGISTERED', 0, ?, ?);
            """, (uid, phone, now, now))
            cursor.execute("""
                INSERT INTO farmer_profiles (user_id, farm_name, farm_size_acres, district, village, location_id)
                VALUES (?, 'Near Farm', 3.0, 'Coimbatore', 'Ukkadam', 'loc_ukkadam');
            """, (uid,))

        # Submit with ~150m offset
        res = client.post("/api/v1/kyc/submit", json={
            "user_id": uid,
            "id_type": "Aadhaar",
            "id_number_last4": "5512",
            "bank_account": "SBIN00011223344",
            "bank_ifsc": "SBIN0001234",
            "farm_pin_lat": 10.9930,
            "farm_pin_lng": 76.9600,
            "gps_lat": 10.9940, # ~111m away
            "gps_lng": 76.9600,
            "is_mock_location": False,
            "consent_given": True
        })
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["kyc_status"], "UNDER_REVIEW")
        self.assertTrue(data["is_location_verified"])
        self.assertLessEqual(data["gps_offset_meters"], 500.0)

    def test_03_kyc_submission_with_gps_offset_over_500m(self):
        with db_session() as conn:
            cursor = conn.cursor()
            uid = f"frm_{uuid.uuid4().hex[:6]}"
            phone = _gen_phone()
            now = datetime.now(timezone.utc).isoformat()
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, 'Farmer Far', 'far@k.in', 'farmer', 'REGISTERED', 0, ?, ?);
            """, (uid, phone, now, now))
            cursor.execute("""
                INSERT INTO farmer_profiles (user_id, farm_name, farm_size_acres, district, village, location_id)
                VALUES (?, 'Far Farm', 3.0, 'Coimbatore', 'Ukkadam', 'loc_ukkadam');
            """, (uid,))

        # Submit with ~2.2 km offset (0.02 deg ~ 2.22 km)
        res = client.post("/api/v1/kyc/submit", json={
            "user_id": uid,
            "id_type": "Aadhaar",
            "id_number_last4": "9988",
            "bank_account": "HDFC00099887766",
            "bank_ifsc": "HDFC0001234",
            "farm_pin_lat": 10.9930,
            "farm_pin_lng": 76.9600,
            "gps_lat": 11.0130, # ~2.2 km away
            "gps_lng": 76.9600,
            "is_mock_location": False,
            "consent_given": True
        })
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertFalse(data["is_location_verified"])
        self.assertTrue(any("LOCATION_UNVERIFIED_OFFSET" in f for f in data["flags"]))

    def test_04_mock_gps_detected_flag(self):
        with db_session() as conn:
            cursor = conn.cursor()
            uid = f"frm_{uuid.uuid4().hex[:6]}"
            phone = _gen_phone()
            now = datetime.now(timezone.utc).isoformat()
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, 'Mock GPS Farmer', 'mock@k.in', 'farmer', 'REGISTERED', 0, ?, ?);
            """, (uid, phone, now, now))
            cursor.execute("""
                INSERT INTO farmer_profiles (user_id, farm_name, farm_size_acres, district, village, location_id)
                VALUES (?, 'Mock Farm', 1.5, 'Coimbatore', 'Ukkadam', 'loc_ukkadam');
            """, (uid,))

        res = client.post("/api/v1/kyc/submit", json={
            "user_id": uid,
            "id_type": "Voter ID",
            "id_number_last4": "1234",
            "bank_account": "ICIC00012345678",
            "farm_pin_lat": 10.9930,
            "farm_pin_lng": 76.9600,
            "gps_lat": 10.9930,
            "gps_lng": 76.9600,
            "is_mock_location": True,
            "consent_given": True
        })
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertFalse(data["is_location_verified"])
        self.assertIn("MOCK_GPS_DETECTED", data["flags"])

    def test_05_staff_kyc_approval_unlocks_farmer(self):
        with db_session() as conn:
            cursor = conn.cursor()
            uid = f"frm_{uuid.uuid4().hex[:6]}"
            phone = _gen_phone()
            now = datetime.now(timezone.utc).isoformat()
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, 'Pending Farmer', 'pending@k.in', 'farmer', 'UNDER_REVIEW', 0, ?, ?);
            """, (uid, phone, now, now))
            cursor.execute("""
                INSERT INTO farmer_profiles (user_id, farm_name, farm_size_acres, district, village, location_id)
                VALUES (?, 'Pending Farm', 4.0, 'Coimbatore', 'Ukkadam', 'loc_ukkadam');
            """, (uid,))
            cursor.execute("SELECT id FROM crops LIMIT 1;")
            crop_id = cursor.fetchone()["id"]

        # Staff approves farmer
        res_appr = client.post(f"/api/v1/kyc/{uid}/review", json={
            "action": "APPROVE",
            "reason": "Patta land ownership and government ID verified.",
            "reviewer_id": "staff_quality_01"
        })
        self.assertEqual(res_appr.status_code, 200)
        self.assertEqual(res_appr.json()["new_status"], "APPROVED")

        # Now farmer can post listing
        res_list = client.post("/api/v1/listings", json={
            "farmer_id": uid,
            "crop_id": crop_id,
            "quantity": 150.0,
            "price": 28.0,
            "location_id": "loc_ukkadam"
        })
        self.assertEqual(res_list.status_code, 200)
        self.assertEqual(res_list.json()["quantity"], 150.0)

    def test_06_bank_detail_change_resets_to_under_review(self):
        with db_session() as conn:
            cursor = conn.cursor()
            uid = f"frm_{uuid.uuid4().hex[:6]}"
            phone = _gen_phone()
            now = datetime.now(timezone.utc).isoformat()
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, 'Approved Farmer', 'appr@k.in', 'farmer', 'APPROVED', 1, ?, ?);
            """, (uid, phone, now, now))
            cursor.execute("INSERT INTO wallets (id, user_id, balance, pending_withdrawal, updated_at) VALUES (?, ?, 5000.0, 0.0, ?);", (f"wal_{uid}", uid, now))

        # Farmer edits bank account
        res_upd = client.post("/api/v1/kyc/bank-update", json={
            "user_id": uid,
            "bank_account": "NEW_ACC_998877",
            "bank_ifsc": "SBIN0009999",
            "upi_id": "newfarmer@oksbi"
        })
        self.assertEqual(res_upd.status_code, 200)
        self.assertEqual(res_upd.json()["kyc_status"], "UNDER_REVIEW")

        # Payout withdrawal must now be blocked with HTTP 403
        res_pay = client.post("/api/v1/wallets/withdraw", json={
            "user_id": uid,
            "amount": 1000.0,
            "payout_method": "UPI",
            "upi_id": "newfarmer@oksbi"
        })
        self.assertEqual(res_pay.status_code, 403)
        self.assertIn("VERIFICATION_REQUIRED", res_pay.json()["detail"])

    def test_07_trust_score_calculation(self):
        with db_session() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT id FROM users WHERE role = 'farmer' AND kyc_status = 'APPROVED' LIMIT 1;")
            farmer_id = cursor.fetchone()["id"]

        res = client.get(f"/api/v1/kyc/{farmer_id}/trust-score")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("trust_score", data)
        self.assertGreaterEqual(data["trust_score"], 40)
        self.assertEqual(data["verified_badge"], "Verified Producer")
        self.assertIn("breakdown", data)

if __name__ == "__main__":
    unittest.main()

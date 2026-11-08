import unittest
from fastapi.testclient import TestClient
from kisan_backend.main import app

client = TestClient(app)

class TestPhase2KYC(unittest.TestCase):
    def setUp(self):
        # Create fresh test farmer
        self.phone = "+919888877771"
        res = client.post("/api/v1/auth/otp/verify", json={
            "phone": self.phone,
            "otp": "123456",
            "name": "Murugan Palanisamy",
            "role": "farmer"
        })
        self.user = res.json()["user"]
        self.uid = self.user["id"]

    def test_01_unverified_farmer_locks(self):
        # 1. Posting listing must return 403
        res_lst = client.post("/api/v1/listings", json={
            "farmer_id": self.uid,
            "crop_id": "crop_001",
            "quantity": 100.0,
            "price": 30.0,
            "location_id": "loc_udumalpet"
        })
        self.assertEqual(res_lst.status_code, 403)
        self.assertIn("VERIFICATION_REQUIRED", res_lst.json()["detail"])

        # 2. Payout withdrawal must return 403
        res_pay = client.post("/api/v1/wallets/withdraw", json={
            "user_id": self.uid,
            "amount": 500.0,
            "payout_method": "UPI",
            "upi_id": "murugan@upi"
        })
        self.assertEqual(res_pay.status_code, 403)
        self.assertIn("VERIFICATION_REQUIRED", res_pay.json()["detail"])

    def test_02_submit_kyc_and_gps_audit(self):
        res_sub = client.post("/api/v1/kyc/submit", json={
            "user_id": self.uid,
            "id_type": "Aadhaar",
            "id_number_last4": "5821",
            "gps_lat": 10.5844,
            "gps_lng": 77.2476,
            "farm_pin_lat": 10.5850,
            "farm_pin_lng": 77.2480,
            "consent_given": True
        })
        self.assertEqual(res_sub.status_code, 200)
        data = res_sub.json()
        self.assertEqual(data["kyc_status"], "UNDER_REVIEW")
        self.assertLess(data["gps_offset_km"], 1.0) # Coordinates are close

    def test_03_secure_document_viewer_audit(self):
        res_doc = client.get("/api/v1/kyc/documents/doc_patta_murugan_01", headers={"X-Staff-Role": "FIELD_VERIFICATION_OFFICER"})
        self.assertEqual(res_doc.status_code, 200)
        self.assertIn("image/svg+xml", res_doc.headers["content-type"])
        self.assertIn("SAMPLE WATERMARKED", res_doc.text)

        # Verify view was audit logged
        res_audit = client.get("/api/v1/admin/audit-logs?limit=5")
        self.assertEqual(res_audit.status_code, 200)
        actions = [a["action"] for a in res_audit.json()]
        self.assertIn("DOCUMENT_VIEWED", actions)

    def test_04_staff_approval_unlocks_farmer(self):
        # Staff approves farmer
        res_app = client.post(f"/api/v1/kyc/{self.uid}/review", json={
            "action": "APPROVE",
            "reason": "All documents verified and land ownership authenticated.",
            "reviewer_id": "staff_field"
        })
        self.assertEqual(res_app.status_code, 200)
        self.assertEqual(res_app.json()["new_status"], "APPROVED")

        # Now farmer can post listing
        res_lst = client.post("/api/v1/listings", json={
            "farmer_id": self.uid,
            "crop_id": "crop_001",
            "quantity": 150.0,
            "price": 35.0,
            "location_id": "loc_udumalpet"
        })
        self.assertEqual(res_lst.status_code, 200)
        self.assertIn("LST-", res_lst.json()["id"])

    def test_05_bank_update_triggers_re_review(self):
        # Farmer updates bank info -> must pause verification
        res_bk = client.post("/api/v1/kyc/bank-update", json={
            "user_id": self.uid,
            "bank_account": "123456789012",
            "bank_ifsc": "SBIN0001234",
            "upi_id": "newmurugan@upi"
        })
        self.assertEqual(res_bk.status_code, 200)
        self.assertEqual(res_bk.json()["kyc_status"], "UNDER_REVIEW")

        # Payout should now be blocked again
        res_pay = client.post("/api/v1/wallets/withdraw", json={
            "user_id": self.uid,
            "amount": 200.0,
            "payout_method": "UPI",
            "upi_id": "newmurugan@upi"
        })
        self.assertEqual(res_pay.status_code, 403)

if __name__ == "__main__":
    unittest.main()

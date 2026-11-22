import unittest
import uuid
import random
import io
from datetime import datetime, timezone
from fastapi.testclient import TestClient
from PIL import Image

from kisan_backend.main import app
from kisan_backend.database import db_session, init_db
from kisan_backend.quality import compute_dhash, hamming_distance, sign_lot

client = TestClient(app)

def _gen_phone():
    return f"+917{uuid.uuid4().int % 900000000 + 100000000}"

class TestPhase4Quality(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        init_db()

    def test_01_unverified_farmer_cannot_create_scan(self):
        with db_session() as conn:
            cursor = conn.cursor()
            uid = f"frm_{uuid.uuid4().hex[:6]}"
            phone = _gen_phone()
            now = datetime.now(timezone.utc).isoformat()
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, 'Unverified Guy', 'unver@k.in', 'farmer', 'REGISTERED', 0, ?, ?);
            """, (uid, phone, now, now))
            cursor.execute("SELECT id FROM crops LIMIT 1;")
            crop_id = cursor.fetchone()["id"]

        res = client.post("/api/v1/quality/scan", json={
            "farmer_id": uid,
            "declared_crop_id": crop_id
        })
        self.assertEqual(res.status_code, 403)
        self.assertIn("VERIFICATION_REQUIRED", res.json()["detail"])

    def test_02_wrong_crop_detection_blocked(self):
        with db_session() as conn:
            cursor = conn.cursor()
            uid = f"frm_{uuid.uuid4().hex[:6]}"
            now = datetime.now(timezone.utc).isoformat()
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, 'Approved Farmer', 'appr@k.in', 'farmer', 'APPROVED', 1, ?, ?);
            """, (uid, _gen_phone(), now, now))
            cursor.execute("SELECT id FROM crops LIMIT 2;")
            crops = cursor.fetchall()
            crop1, crop2 = crops[0]["id"], crops[1]["id"]

        res = client.post("/api/v1/quality/scan", json={
            "farmer_id": uid,
            "declared_crop_id": crop1,
            "detected_crop_id": crop2
        })
        self.assertEqual(res.status_code, 400)
        self.assertIn("WRONG_CROP_DETECTED", res.json()["detail"])

    def test_03_quality_scan_and_lot_creation_success(self):
        with db_session() as conn:
            cursor = conn.cursor()
            uid = f"frm_{uuid.uuid4().hex[:6]}"
            now = datetime.now(timezone.utc).isoformat()
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, 'Palanisamy Murugesan', 'palani@k.in', 'farmer', 'APPROVED', 1, ?, ?);
            """, (uid, _gen_phone(), now, now))
            cursor.execute("""
                INSERT INTO farmer_profiles (user_id, farm_name, farm_size_acres, district, village)
                VALUES (?, 'Green Agro Farm', 4.5, 'Tiruppur', 'Udumalpet');
            """, (uid,))
            cursor.execute("SELECT id FROM crops LIMIT 1;")
            crop_id = cursor.fetchone()["id"]

        test_hash = f"a1b2c3d4{uuid.uuid4().hex[:8]}"
        res = client.post("/api/v1/quality/scan", json={
            "farmer_id": uid,
            "declared_crop_id": crop_id,
            "simulated_photo_hash": test_hash,
            "rot_percentage": 0.0,
            "defect_percentage": 1.2,
            "uniformity_percentage": 94.0,
            "ripeness_percentage": 90.0,
            "quantity": 250.0
        })
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["grade"], "Grade A")
        self.assertEqual(data["photo_hash"], test_hash)
        self.assertTrue(data["lot_id"].startswith("lot_"))
        self.assertIn("https://harish7273.github.io/KisanLinkAI/#/verify/", data["qr_code_url"])
        self.assertTrue(len(data["signature"]) >= 10)

    def test_04_duplicate_photo_hash_detection_blocked(self):
        with db_session() as conn:
            cursor = conn.cursor()
            uid = f"frm_{uuid.uuid4().hex[:6]}"
            now = datetime.now(timezone.utc).isoformat()
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, 'Second Farmer', 'second@k.in', 'farmer', 'APPROVED', 1, ?, ?);
            """, (uid, _gen_phone(), now, now))
            cursor.execute("SELECT id FROM crops LIMIT 1;")
            crop_id = cursor.fetchone()["id"]

        # First scan succeeds
        first_hash = f"99887766{uuid.uuid4().hex[:8]}"
        res1 = client.post("/api/v1/quality/scan", json={
            "farmer_id": uid,
            "declared_crop_id": crop_id,
            "simulated_photo_hash": first_hash
        })
        self.assertEqual(res1.status_code, 200)

        # Attempt to reuse the exact same photo hash
        res2 = client.post("/api/v1/quality/scan", json={
            "farmer_id": uid,
            "declared_crop_id": crop_id,
            "simulated_photo_hash": first_hash
        })
        self.assertEqual(res2.status_code, 400)
        self.assertIn("DUPLICATE_PHOTO_DETECTED", res2.json()["detail"])

        # Also test near-duplicate differing by 1 bit in last char
        # If last char is '0' (0000), '1' is (0001) -> Hamming distance 1 <= 4
        near_duplicate = first_hash[:-1] + ('1' if first_hash[-1] != '1' else '0')
        res3 = client.post("/api/v1/quality/scan", json={
            "farmer_id": uid,
            "declared_crop_id": crop_id,
            "simulated_photo_hash": near_duplicate
        })
        self.assertEqual(res3.status_code, 400)
        self.assertIn("DUPLICATE_PHOTO_DETECTED", res3.json()["detail"])

    def test_05_public_lot_verification_qr_valid(self):
        with db_session() as conn:
            cursor = conn.cursor()
            uid = f"frm_{uuid.uuid4().hex[:6]}"
            now = datetime.now(timezone.utc).isoformat()
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, 'Murugesan Palanisamy', 'muru@k.in', 'farmer', 'APPROVED', 1, ?, ?);
            """, (uid, _gen_phone(), now, now))
            cursor.execute("""
                INSERT INTO farmer_profiles (user_id, farm_name, farm_size_acres, district, village)
                VALUES (?, 'Heritage Farm', 5.0, 'Tiruppur', 'Udumalpet');
            """, (uid,))
            cursor.execute("SELECT id FROM crops LIMIT 1;")
            crop_id = cursor.fetchone()["id"]

        test_hash = f"f0e1d2c3{uuid.uuid4().hex[:8]}"
        scan_res = client.post("/api/v1/quality/scan", json={
            "farmer_id": uid,
            "declared_crop_id": crop_id,
            "simulated_photo_hash": test_hash,
            "quantity": 500.0
        })
        self.assertEqual(scan_res.status_code, 200)
        scan_data = scan_res.json()
        lot_id = scan_data["lot_id"]
        sig = scan_data["signature"]

        # Call public verification endpoint
        verify_res = client.get(f"/api/v1/lots/{lot_id}/verify?sig={sig}")
        self.assertEqual(verify_res.status_code, 200)
        v_data = verify_res.json()
        self.assertTrue(v_data["verified"])
        self.assertEqual(v_data["farmer_masked"], "Murugesan P. (Verified Producer)")
        self.assertNotIn("phone", v_data)
        self.assertNotIn("bank", v_data)
        self.assertIn("Udumalpet, Tiruppur", v_data["origin_location"])
        self.assertEqual(v_data["photo_hash"], test_hash)

        # Also test composite dot notation "lot_id.sig"
        comp_res = client.get(f"/api/v1/lots/{lot_id}.{sig}/verify")
        self.assertEqual(comp_res.status_code, 200)
        self.assertTrue(comp_res.json()["verified"])

    def test_06_tampered_qr_code_verification_blocked(self):
        # Fake or tampered signature
        res = client.get("/api/v1/lots/lot_fake123/verify?sig=bad_sig_abc123")
        self.assertEqual(res.status_code, 400)
        self.assertIn("UNVERIFIED_OR_TAMPERED", res.json()["detail"])

    def test_07_real_image_dhash_calculation(self):
        img1 = Image.new("RGB", (100, 100), color=(200, 50, 50))
        img2 = Image.new("RGB", (100, 100), color=(200, 50, 50))
        h1 = compute_dhash(img1)
        h2 = compute_dhash(img2)
        self.assertEqual(h1, h2)
        self.assertEqual(len(h1), 16)
        self.assertEqual(hamming_distance(h1, h2), 0)

if __name__ == "__main__":
    unittest.main()

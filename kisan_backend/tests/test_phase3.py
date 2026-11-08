import unittest
from fastapi.testclient import TestClient
from kisan_backend.main import app
from kisan_backend.database import db_session

client = TestClient(app)

class TestPhase3Support(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with db_session() as conn:
            cur = conn.cursor()
            cur.execute("SELECT id FROM users WHERE role = 'farmer' LIMIT 1;")
            cls.farmer_id = cur.fetchone()["id"]
            cur.execute("SELECT id FROM users WHERE role = 'delivery_partner' LIMIT 1;")
            cls.partner_id = cur.fetchone()["id"]

    def test_01_support_config_dynamic_from_db(self):
        res = client.get("/api/v1/support/config")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("helpline_phone", data)
        self.assertIn("whatsapp_phone", data)
        self.assertEqual(data["sos_number"], "112")

    def test_02_raise_ticket_and_reply_thread(self):
        # 1. User raises ticket
        res_t = client.post("/api/v1/support/tickets", json={
            "user_id": self.farmer_id,
            "user_role": "farmer",
            "category": "PAYMENT",
            "priority": "HIGH",
            "subject": "Delay in Mandi Settlement",
            "description": "Produce was delivered at 8am, settlement pending."
        })
        self.assertEqual(res_t.status_code, 200)
        tid = res_t.json()["ticket_number"]

        # 2. Staff replies to ticket
        res_rep = client.post(f"/api/v1/support/tickets/{tid}/reply", json={
            "sender_id": "staff_support",
            "sender_role": "staff",
            "message": "We have checked the escrow ledger. The UPI settlement has been pushed."
        })
        self.assertEqual(res_rep.status_code, 200)

        # 3. Fetch ticket thread
        res_thread = client.get(f"/api/v1/support/tickets/{tid}")
        self.assertEqual(res_thread.status_code, 200)
        t_data = res_thread.json()
        self.assertEqual(t_data["ticket"]["ticket_number"], tid)
        self.assertEqual(len(t_data["messages"]), 1)
        self.assertEqual(t_data["messages"][0]["sender_role"], "staff")

    def test_03_trilingual_faq(self):
        res_faq = client.get("/api/v1/support/faq")
        self.assertEqual(res_faq.status_code, 200)
        faqs = res_faq.json()
        self.assertGreaterEqual(len(faqs), 4)
        for f in faqs:
            self.assertTrue(len(f["question_en"]) > 0)
            self.assertTrue(len(f["question_ta"]) > 0)
            self.assertTrue(len(f["question_hi"]) > 0)

        # Search FAQ
        res_search = client.get("/api/v1/support/faq?query=kyc")
        self.assertEqual(res_search.status_code, 200)
        self.assertGreaterEqual(len(res_search.json()), 1)

    def test_04_delivery_sos_alert(self):
        res_sos = client.post("/api/v1/support/sos", json={
            "partner_id": self.partner_id,
            "latitude": 10.6609,
            "longitude": 77.0048,
            "order_id": "ORD-1001",
            "note": "Flat tire on Pollachi highway."
        })
        self.assertEqual(res_sos.status_code, 200)
        data = res_sos.json()
        self.assertIn("SOS-", data["ticket_number"])

if __name__ == "__main__":
    unittest.main()

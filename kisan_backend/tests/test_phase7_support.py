import unittest
import uuid
from datetime import datetime, timezone
from fastapi.testclient import TestClient

from kisan_backend.main import app
from kisan_backend.database import db_session, init_db

client = TestClient(app)

class TestPhase7Support(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        init_db()

    def test_01_trilingual_faq_endpoint(self):
        res = client.get("/api/v1/support/faq")
        self.assertEqual(res.status_code, 200)
        faqs = res.json()
        self.assertGreaterEqual(len(faqs), 4)
        for faq in faqs:
            self.assertIn("question_en", faq)
            self.assertIn("question_ta", faq)
            self.assertIn("question_hi", faq)
            self.assertIn("answer_en", faq)
            self.assertIn("answer_ta", faq)
            self.assertIn("answer_hi", faq)
            # Ensure no nulls
            self.assertTrue(len(faq["question_ta"]) > 5)
            self.assertTrue(len(faq["question_hi"]) > 5)

        # Test filter
        q_res = client.get("/api/v1/support/faq?query=AGMARK")
        self.assertEqual(q_res.status_code, 200)
        self.assertGreaterEqual(len(q_res.json()), 1)

    def test_02_dynamic_support_config(self):
        res = client.get("/api/v1/support/config")
        self.assertEqual(res.status_code, 200)
        cfg = res.json()
        self.assertIn("helpline_phone", cfg)
        self.assertIn("whatsapp_phone", cfg)
        self.assertIn("operating_hours", cfg)
        self.assertEqual(cfg["sos_number"], "112")

    def test_03_create_and_reply_support_ticket(self):
        with db_session() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT id FROM users WHERE role = 'farmer' LIMIT 1;")
            user_id = cursor.fetchone()["id"]

        create_res = client.post("/api/v1/support/tickets", json={
            "user_id": user_id,
            "user_role": "farmer",
            "category": "PAYMENT",
            "priority": "HIGH",
            "subject": "Delay in UPI withdrawal credit",
            "description": "My withdrawal of Rs 3,000 is showing pending for 2 hours."
        })
        self.assertEqual(create_res.status_code, 200)
        ticket_id = create_res.json()["ticket_id"]
        t_num = create_res.json()["ticket_number"]

        # Staff replies
        reply_res = client.post(f"/api/v1/support/tickets/{ticket_id}/reply", json={
            "sender_id": "staff_finance",
            "sender_role": "staff",
            "message": "Bank server was reconciling. Your transaction ref UTR-998811 has cleared."
        })
        self.assertEqual(reply_res.status_code, 200)

        # Fetch thread
        thread_res = client.get(f"/api/v1/support/tickets/{ticket_id}")
        self.assertEqual(thread_res.status_code, 200)
        t_data = thread_res.json()
        self.assertEqual(t_data["ticket_number"], t_num)
        self.assertEqual(t_data["status"], "IN_PROGRESS")
        self.assertEqual(len(t_data["messages"]), 2)
        self.assertEqual(t_data["messages"][1]["sender_id"], "staff_finance")

    def test_04_emergency_sos_dispatch(self):
        with db_session() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT id FROM users WHERE role = 'delivery_partner' LIMIT 1;")
            partner_id = cursor.fetchone()["id"]

        sos_res = client.post("/api/v1/support/sos", json={
            "user_id": partner_id,
            "user_role": "delivery_partner",
            "latitude": 10.6609,
            "longitude": 77.0048,
            "emergency_type": "VEHICLE_ACCIDENT_HIGHWAY",
            "details": "Truck hit by oncoming vehicle on Pollachi road, produce damaged, driver injured"
        })
        self.assertEqual(sos_res.status_code, 200)
        data = sos_res.json()
        self.assertEqual(data["status"], "SOS_DISPATCHED")
        self.assertEqual(data["emergency_number"], "112")
        self.assertTrue(data["kisanai_operations_alerted"])

        # Check that an URGENT ticket was generated
        with db_session() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT priority, category FROM support_tickets WHERE ticket_number = ?;", (data["ticket_number"],))
            ticket = cursor.fetchone()
            self.assertIsNotNone(ticket)
            self.assertEqual(ticket["priority"], "URGENT")
            self.assertEqual(ticket["category"], "SOS")

if __name__ == "__main__":
    unittest.main()

import os
import sys
import json

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from kisan_backend.database import db_session

def extract_5_orders():
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT o.id, o.order_number, o.status, o.quantity, o.unit, o.agreed_price, 
                   o.produce_total, o.delivery_fee, o.total_amount, o.fulfillment_mode,
                   c.name_en, c.name_ta, c.name_hi,
                   u_f.name as farmer_name, u_b.name as buyer_name, u_p.name as partner_name,
                   loc_p.name as pickup_loc, loc_d.name as drop_loc
            FROM orders o
            JOIN crops c ON o.crop_id = c.id
            JOIN users u_b ON o.buyer_id = u_b.id
            LEFT JOIN users u_f ON o.farmer_id = u_f.id
            LEFT JOIN users u_p ON o.delivery_partner_id = u_p.id
            LEFT JOIN locations loc_p ON o.drop_location_id = loc_p.id
            LEFT JOIN locations loc_d ON o.drop_location_id = loc_d.id
            ORDER BY o.created_at DESC
            LIMIT 5;
        """)
        orders = [dict(r) for r in cursor.fetchall()]
        print(json.dumps(orders, indent=2))
        return orders

if __name__ == "__main__":
    extract_5_orders()

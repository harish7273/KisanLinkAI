import json
import uuid
import random
import hashlib
from datetime import datetime, timezone, timedelta
from .database import db_session, init_db
from .config import FOUNDER_NAME, FOUNDER_PHONE

random.seed(42)

def seed_database():
    init_db()
    with db_session() as conn:
        cursor = conn.cursor()
        
        # Clear existing seed data if any
        cursor.execute("SELECT count(*) as cnt FROM users WHERE phone = ?;", (FOUNDER_PHONE,))
        row = cursor.fetchone()
        if row and row["cnt"] > 0:
            print("[Seed] Database already seeded. Resetting seed data...")
            cursor.execute("DELETE FROM order_events;")
            cursor.execute("DELETE FROM tracking_points;")
            cursor.execute("DELETE FROM deliveries;")
            cursor.execute("DELETE FROM wallet_transactions;")
            cursor.execute("DELETE FROM payout_requests;")
            cursor.execute("DELETE FROM wallets;")
            cursor.execute("DELETE FROM disputes;")
            cursor.execute("DELETE FROM support_messages;")
            cursor.execute("DELETE FROM support_tickets;")
            cursor.execute("DELETE FROM notifications;")
            cursor.execute("DELETE FROM quality_scans;")
            cursor.execute("DELETE FROM orders;")
            cursor.execute("DELETE FROM demands;")
            cursor.execute("DELETE FROM listings;")
            cursor.execute("DELETE FROM vehicles;")
            cursor.execute("DELETE FROM staff_profiles;")
            cursor.execute("DELETE FROM delivery_profiles;")
            cursor.execute("DELETE FROM buyer_profiles;")
            cursor.execute("DELETE FROM farmer_profiles;")
            cursor.execute("DELETE FROM users;")
            cursor.execute("DELETE FROM crops;")
            cursor.execute("DELETE FROM locations;")
            cursor.execute("DELETE FROM platform_settings;")
            cursor.execute("DELETE FROM audit_logs;")

        now = datetime.now(timezone.utc).isoformat()
        
        # 1. Shared Locations
        locations_data = [
            ("loc_udumalpet", "Udumalpet Central", "Tiruppur", "Tamil Nadu", "Agri Market Road, Udumalpet", 10.5844, 77.2476),
            ("loc_pollachi", "Pollachi Coconut Hub", "Coimbatore", "Tamil Nadu", "Coimbatore Main Road, Pollachi", 10.6609, 77.0048),
            ("loc_ukkadam", "Ukkadam Central Market", "Coimbatore", "Tamil Nadu", "Ukkadam Bus Stand Road, Coimbatore", 10.9930, 76.9600),
            ("loc_cbe_central", "Coimbatore Wholesale Mandi", "Coimbatore", "Tamil Nadu", "Mettupalayam Road, Coimbatore", 11.0168, 76.9558),
            ("loc_kinathukadavu", "Kinathukadavu Farm Depot", "Coimbatore", "Tamil Nadu", "NH 209, Kinathukadavu", 10.8173, 77.0197),
            ("loc_tiruppur", "Tiruppur Agri Logistics Hub", "Tiruppur", "Tamil Nadu", "Palladam Road, Tiruppur", 11.1085, 77.3411),
            ("loc_kangeyam", "Kangeyam Grain Center", "Tiruppur", "Tamil Nadu", "Erode Road, Kangeyam", 11.0047, 77.5617),
            ("loc_dharapuram", "Dharapuram Farmers Hub", "Tiruppur", "Tamil Nadu", "Oddanchatram Road, Dharapuram", 10.7289, 77.5255),
            ("loc_perundurai", "Perundurai Agro Park", "Erode", "Tamil Nadu", "SIPCOT Industrial Complex, Perundurai", 11.2774, 77.5852),
            ("loc_gobi", "Gobichettipalayam Terminal", "Erode", "Tamil Nadu", "Sathy Road, Gobichettipalayam", 11.4552, 77.4374),
            ("loc_salem", "Salem Mango & Agri Mandi", "Salem", "Tamil Nadu", "Attur By-Pass Road, Salem", 11.6643, 78.1460),
            ("loc_madurai", "Madurai Mattuthavani Market", "Madurai", "Tamil Nadu", "Mattuthavani Terminal, Madurai", 9.9252, 78.1198),
            ("loc_theni", "Theni Banana & Cardamom Hub", "Theni", "Tamil Nadu", "Chinnamanur Main Road, Theni", 10.0104, 77.4768),
            ("loc_oddanchatram", "Oddanchatram Vegetable Market", "Dindigul", "Tamil Nadu", "National Highway 83, Oddanchatram", 10.4855, 77.7472),
            ("loc_karur", "Karur Agri Hub", "Karur", "Tamil Nadu", "Aravakurichi Road, Karur", 10.9601, 78.0766),
        ]
        
        for loc_id, name, dist, st, addr, lat, lng in locations_data:
            cursor.execute("""
                INSERT INTO locations (id, name, district, state, address, latitude, longitude, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?);
            """, (loc_id, name, dist, st, addr, lat, lng, now))
            
        print(f"[Seed] Inserted {len(locations_data)} shared location records.")

        # 2. Crops (65 Crops)
        with open("data/production_seed_data.json", "r", encoding="utf-8") as f:
            raw_seed = json.load(f)
            
        crops_list = raw_seed.get("crops", [])
        for idx, c in enumerate(crops_list):
            cid = f"crop_{idx+1:03d}"
            code = c["name"].lower().replace(" ", "_").replace("(", "").replace(")", "").replace("-", "_")
            grade_rules = json.dumps({
                "Grade A": {"maxRot": 0.0, "maxDefect": 2.0, "minUniformity": 90, "minRipeness": 85},
                "Grade B": {"maxRot": 0.0, "maxDefect": 6.0, "minUniformity": 75, "minRipeness": 70},
                "Grade C": {"maxRot": 0.0, "maxDefect": 12.0, "minUniformity": 60, "minRipeness": 60},
                "standard": "AGMARK-TN-SPEC-2026"
            })
            cursor.execute("""
                INSERT INTO crops (id, canonical_code, name_en, name_ta, name_hi, category, base_mandi_price, direct_price, unit, grade_rules_json)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """, (cid, code, c["name"], c["ta"], c["hi"], c["cat"], c["mandi"], c["direct"], c["unit"], grade_rules))
            
        print(f"[Seed] Inserted {len(crops_list)} crops into canonical catalog.")

        # 3. Staff Accounts (6 Enterprise Roles)
        staff_data = [
            ("staff_founder", FOUNDER_PHONE, FOUNDER_NAME, "founder@kisanai.com", "staff", "founder", "Executive Board", json.dumps(["ALL_ACCESS", "SUPER_ADMIN", "PLATFORM_CONTROLS"])),
            ("staff_ops", "+919443311001", "V. Raghavan", "raghavan.ops@kisanai.com", "staff", "ops_manager", "Logistics & Fleet", json.dumps(["DISPATCH_MANAGE", "FLEET_TRACK", "DISPUTE_INVESTIGATE"])),
            ("staff_finance", "+919443311002", "K. Meenakshi", "meenakshi.fin@kisanai.com", "staff", "finance_officer", "Treasury & Reconciliation", json.dumps(["PAYOUT_APPROVE", "LEDGER_AUDIT", "ESCROW_MANAGE"])),
            ("staff_support", "+919443311003", "S. Priya", "priya.sup@kisanai.com", "staff", "support_agent", "Customer Operations", json.dumps(["TICKET_RESOLVE", "CHAT_RESPOND", "SOS_MONITOR"])),
            ("staff_quality", "+919443311004", "Dr. A. Swaminathan", "swaminathan.agr@kisanai.com", "staff", "quality_agronomist", "Agronomy & Grading", json.dumps(["SCAN_VERIFY", "AGMARK_OVERRIDE", "FARM_AUDIT"])),
            ("staff_field", "+919443311005", "M. Senthil", "senthil.fvo@kisanai.com", "staff", "field_verification_officer", "Field Verification", json.dumps(["KYC_VERIFY", "GPS_AUDIT", "FARM_VISIT_SCHEDULE"])),
        ]
        
        # Default staff password hash (bcrypt / argon2 mock hash for demo, salt: kisanai)
        mock_staff_hash = hashlib.sha256("KisanAI@Office2026!".encode("utf-8")).hexdigest()
        
        for uid, phone, name, email, role, s_role, dept, perms in staff_data:
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, password_hash, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, 'APPROVED', 1, ?, ?, ?);
            """, (uid, phone, name, email, role, mock_staff_hash, now, now))
            
            cursor.execute("""
                INSERT INTO staff_profiles (user_id, staff_role, department, permissions)
                VALUES (?, ?, ?, ?);
            """, (uid, s_role, dept, perms))
            
        print("[Seed] Inserted 6 Staff accounts.")

        # 4. Farmers (85 verified farmers)
        raw_farmers = raw_seed.get("farmers", [])
        loc_keys = [l[0] for l in locations_data]
        
        for idx, f in enumerate(raw_farmers):
            f_uid = f["uid"]
            loc_id = loc_keys[idx % len(loc_keys)]
            is_ver = 1 if idx >= 6 else 0
            kyc_st = "APPROVED" if is_ver else "UNDER_REVIEW"
            
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, ?, ?, 'farmer', ?, ?, ?, ?);
            """, (f_uid, f["phone"], f["name"], f"{f_uid}@kisanai.app", kyc_st, is_ver, f["createdAt"], now))
            
            cursor.execute("""
                INSERT INTO farmer_profiles (user_id, farm_name, farm_size_acres, district, village, location_id, gps_latitude, gps_longitude)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?);
            """, (f_uid, f"{f['name']}'s Farm", f["farmSizeAcres"], f["district"], f["location"].split(",")[0], loc_id, f["lat"], f["lng"]))
            
            # Initialize wallet
            w_id = f"wal_{f_uid}"
            cursor.execute("""
                INSERT INTO wallets (id, user_id, balance, pending_withdrawal, updated_at)
                VALUES (?, ?, 0.0, 0.0, ?);
            """, (w_id, f_uid, now))
            
        print(f"[Seed] Inserted {len(raw_farmers)} Farmers.")

        # 5. Buyers (85 verified buyers)
        raw_buyers = raw_seed.get("buyers", [])
        for idx, b in enumerate(raw_buyers):
            b_uid = b["uid"]
            loc_id = loc_keys[(idx + 2) % len(loc_keys)]
            
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, ?, ?, 'buyer', 'APPROVED', 1, ?, ?);
            """, (b_uid, b["phone"], b["name"], f"{b_uid}@kisanai.app", b["createdAt"], now))
            
            cursor.execute("""
                INSERT INTO buyer_profiles (user_id, business_name, gstin, delivery_location_id, address)
                VALUES (?, ?, ?, ?, ?);
            """, (b_uid, b["name"], f"33AAACL{random.randint(1000,9999)}A1Z{random.randint(1,9)}", loc_id, b["location"]))
            
            w_id = f"wal_{b_uid}"
            cursor.execute("""
                INSERT INTO wallets (id, user_id, balance, pending_withdrawal, updated_at)
                VALUES (?, ?, 500000.0, 0.0, ?);
            """, (w_id, b_uid, now))
            
        print(f"[Seed] Inserted {len(raw_buyers)} Buyers.")

        # 6. Delivery Partners (45 verified partners)
        raw_partners = raw_seed.get("delivery_partners", [])
        for idx, d in enumerate(raw_partners):
            d_uid = d["uid"]
            veh_id = f"veh_{d_uid}"
            has_cold = 1 if "reefer" in d["vehicleCategory"].lower() or "cold" in d["vehicleType"].lower() else 0
            
            cursor.execute("""
                INSERT INTO users (id, phone, name, email, role, kyc_status, is_verified, created_at, updated_at)
                VALUES (?, ?, ?, ?, 'delivery_partner', 'APPROVED', 1, ?, ?);
            """, (d_uid, d["phone"], d["name"], f"{d_uid}@kisanai.app", d["createdAt"], now))
            
            cursor.execute("""
                INSERT INTO vehicles (id, partner_id, vehicle_type, plate_number, capacity_kg, has_cold_chain, is_active)
                VALUES (?, ?, ?, ?, ?, ?, 1);
            """, (veh_id, d_uid, d["vehicleType"], d["vehiclePlate"], d["capacityKg"], has_cold))
            
            cursor.execute("""
                INSERT INTO delivery_profiles (user_id, vehicle_id, driving_licence, rc_number, insurance, is_online, rating, active_orders_count)
                VALUES (?, ?, ?, ?, 'INS-TN-2026-VAL', ?, ?, 0);
            """, (d_uid, veh_id, f"DL-TN-{random.randint(10000000, 99999999)}", f"RC-{d['vehiclePlate']}", 1 if d["isOnline"] else 0, d["rating"]))
            
            w_id = f"wal_{d_uid}"
            cursor.execute("""
                INSERT INTO wallets (id, user_id, balance, pending_withdrawal, updated_at)
                VALUES (?, ?, 0.0, 0.0, ?);
            """, (w_id, d_uid, now))
            
        print(f"[Seed] Inserted {len(raw_partners)} Delivery Partners with Vehicles.")

        # 7. Listings
        raw_listings = raw_seed.get("listings", [])
        for l in raw_listings:
            lid = l["listingId"]
            cursor.execute("SELECT id FROM crops WHERE name_en = ?;", (l["cropName"],))
            c_row = cursor.fetchone()
            crop_id = c_row["id"] if c_row else "crop_001"
            loc_id = loc_keys[random.randint(0, len(loc_keys)-1)]
            
            cursor.execute("""
                INSERT INTO listings (id, farmer_id, crop_id, quantity, unit, price, quality_grade, location_id, is_available, is_seed, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?);
            """, (lid, l["farmerId"], crop_id, l["quantity"], l["unit"], l["pricePerUnit"], l["qualityGrade"], loc_id, 1 if l["status"] == "active" else 0, l["createdAt"]))

        print(f"[Seed] Inserted {len(raw_listings)} Farmer Listings.")

        # 8. Orders & Authoritative Ledger Transactions
        raw_orders = raw_seed.get("orders", [])
        
        status_map = {
            "posted": "DEMAND_POSTED",
            "accepted": "ACCEPTED",
            "assigned": "PARTNER_ASSIGNED",
            "in_transit": "IN_TRANSIT",
            "delivered": "DELIVERED",
            "cancelled": "CANCELLED",
            "disputed": "DISPUTED"
        }
        
        for idx, o in enumerate(raw_orders):
            oid = o["orderId"]
            mapped_status = status_map.get(o["orderStatus"], "DELIVERED")
            
            crop_name = o["items"][0]["cropName"] if o.get("items") else "Tomato"
            cursor.execute("SELECT id FROM crops WHERE name_en = ?;", (crop_name,))
            c_row = cursor.fetchone()
            crop_id = c_row["id"] if c_row else "crop_001"
            
            item = o["items"][0] if o.get("items") else {"quantity": 100, "pricePerUnit": 30, "unit": "kg"}
            qty = float(item.get("quantity", 100))
            agreed_price = float(item.get("pricePerUnit", 30))
            produce_tot = float(o.get("subtotal", qty * agreed_price))
            deliv_fee = float(o.get("deliveryFee", 450.0))
            tot_amt = produce_tot + deliv_fee
            
            pickup_loc = loc_keys[idx % len(loc_keys)]
            drop_loc = loc_keys[(idx + 3) % len(loc_keys)]
            
            partner_id = o.get("deliveryPartnerId")
            mode = "branch_a_pickup" if deliv_fee == 0 else "branch_b_partner"
            
            cursor.execute("""
                INSERT INTO orders (
                    id, order_number, buyer_id, farmer_id, delivery_partner_id, crop_id, agreed_price, quantity, unit,
                    total_amount, produce_total, delivery_fee, fulfillment_mode, status, payment_status,
                    pickup_location_id, drop_location_id, delivery_otp, pickup_otp, is_seed, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?);
            """, (
                oid, oid, o["buyerId"], o["farmerId"], partner_id, crop_id, agreed_price, qty, item.get("unit", "kg"),
                tot_amt, produce_tot, deliv_fee, mode, mapped_status,
                "SETTLED" if mapped_status == "DELIVERED" else "ESCROW_RESERVED",
                pickup_loc, drop_loc, o.get("deliveryOtp", "4821"), o.get("pickupOtp", "1923"),
                o["createdAt"], o["updatedAt"]
            ))
            
            # Insert Order Event
            cursor.execute("""
                INSERT INTO order_events (id, order_id, previous_status, new_status, actor_id, actor_role, note, timestamp)
                VALUES (?, ?, NULL, ?, ?, 'system', 'Seeded lifecycle state', ?);
            """, (f"evt_{oid}_01", oid, mapped_status, o["farmerId"], o["createdAt"]))
            
            # If partner assigned, insert delivery record
            if partner_id:
                dist_km = float(o.get("distanceKm", 45.0))
                eta_mins = int(o.get("etaMinutes", 65))
                cursor.execute("""
                    INSERT INTO deliveries (id, order_id, partner_id, vehicle_id, distance_km, eta_minutes, status)
                    VALUES (?, ?, ?, ?, ?, ?, ?);
                """, (f"del_{oid}", oid, partner_id, f"veh_{partner_id}", dist_km, eta_mins, mapped_status))
                
            # If DELIVERED -> Record ledger transactions and update wallet balances
            if mapped_status == "DELIVERED":
                # Farmer Ledger Credit
                cursor.execute("SELECT id, balance FROM wallets WHERE user_id = ?;", (o["farmerId"],))
                f_wal = cursor.fetchone()
                if f_wal:
                    new_f_bal = round(f_wal["balance"] + produce_tot, 2)
                    cursor.execute("UPDATE wallets SET balance = ?, updated_at = ? WHERE id = ?;", (new_f_bal, o["updatedAt"], f_wal["id"]))
                    cursor.execute("""
                        INSERT INTO wallet_transactions (id, wallet_id, user_id, order_id, transaction_type, amount, balance_after, reference_note, timestamp)
                        VALUES (?, ?, ?, ?, 'CREDIT_SALE', ?, ?, ?, ?);
                    """, (f"tx_{oid}_farm", f_wal["id"], o["farmerId"], oid, produce_tot, new_f_bal, f"Sale payment for {oid}", o["updatedAt"]))
                    
                # Delivery Partner Ledger Credit
                if partner_id and deliv_fee > 0:
                    cursor.execute("SELECT id, balance FROM wallets WHERE user_id = ?;", (partner_id,))
                    d_wal = cursor.fetchone()
                    if d_wal:
                        new_d_bal = round(d_wal["balance"] + deliv_fee, 2)
                        cursor.execute("UPDATE wallets SET balance = ?, updated_at = ? WHERE id = ?;", (new_d_bal, o["updatedAt"], d_wal["id"]))
                        cursor.execute("""
                            INSERT INTO wallet_transactions (id, wallet_id, user_id, order_id, transaction_type, amount, balance_after, reference_note, timestamp)
                            VALUES (?, ?, ?, ?, 'CREDIT_DELIVERY', ?, ?, ?, ?);
                        """, (f"tx_{oid}_drv", d_wal["id"], partner_id, oid, deliv_fee, new_d_bal, f"Delivery fee for {oid}", o["updatedAt"]))

        print(f"[Seed] Inserted {len(raw_orders)} Orders and reconciled ledger balances.")

        # 9. Platform Controls / Settings
        settings = [
            ("SUPPORT_PHONE_NUMBER", "+91 94433 00000", "Central KisanAI Customer Support Helpline"),
            ("SUPPORT_WHATSAPP_NUMBER", "+91 94433 00001", "WhatsApp Farmer & Buyer Assistant Desk"),
            ("OPERATING_HOURS", "06:00 AM - 09:00 PM IST", "Live support desk operating window"),
            ("PLATFORM_COMMISSION_PERCENT", "0.0", "Zero commission direct farmer-to-buyer guarantee"),
            ("KYC_REVIEW_SLA_HOURS", "4", "Standard SLA target for verification reviews"),
            ("MAX_UNVERIFIED_LISTING_KG", "0", "Strict 0 kg listing limit for unverified farmers"),
            ("EMERGENCY_SOS_NUMBER", "112", "National Emergency SOS Dispatch link"),
        ]
        for skey, sval, sdesc in settings:
            cursor.execute("""
                INSERT INTO platform_settings (id, setting_key, setting_value, description, updated_by, updated_at)
                VALUES (?, ?, ?, ?, 'staff_founder', ?);
            """, (f"set_{skey.lower()}", skey, sval, sdesc, now))
            
        print("[Seed] Inserted Platform Settings.")

        # 10. Chained Audit Log Genesis Block
        gen_raw = f"GENESIS|SYSTEM_INIT|staff_founder|platform|{now}|KisanAI Enterprise Master Seed World Generated"
        gen_hash = hashlib.sha256(gen_raw.encode("utf-8")).hexdigest()
        cursor.execute("""
            INSERT INTO audit_logs (id, action, actor_id, actor_role, target_entity, details, prev_hash, curr_hash, timestamp)
            VALUES (?, 'SYSTEM_INIT', 'staff_founder', 'founder', 'system', 'KisanAI Master Dataset Initialized', '00000000000000000000000000000000', ?, ?);
        """, (f"aud_{uuid.uuid4().hex[:12]}", gen_hash, now))

    print("[Seed] Database seeding completed successfully.")

if __name__ == "__main__":
    seed_database()

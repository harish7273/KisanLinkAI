import sqlite3
import json
import hashlib
from datetime import datetime, timezone
from contextlib import contextmanager
from .config import DB_PATH

def get_connection():
    conn = sqlite3.connect(DB_PATH, timeout=20.0, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.execute("PRAGMA foreign_keys=ON;")
    return conn

@contextmanager
def db_session():
    conn = get_connection()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

def init_db():
    with db_session() as conn:
        cursor = conn.cursor()
        
        # 1. Locations (Single source of geographic truth)
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS locations (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            district TEXT NOT NULL,
            state TEXT NOT NULL DEFAULT 'Tamil Nadu',
            address TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            created_at TEXT NOT NULL
        );
        """)

        # 2. Users & Staff Directory
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            phone TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            email TEXT,
            role TEXT NOT NULL, -- farmer | buyer | delivery_partner | staff
            kyc_status TEXT NOT NULL DEFAULT 'REGISTERED', -- REGISTERED | DOCS_SUBMITTED | UNDER_REVIEW | APPROVED | NEEDS_INFO | REJECTED | SUSPENDED
            is_verified INTEGER NOT NULL DEFAULT 0,
            password_hash TEXT,
            two_factor_secret TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );
        """)

        # 3. Farmer Profiles
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS farmer_profiles (
            user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
            farm_name TEXT,
            farm_size_acres REAL DEFAULT 2.5,
            district TEXT NOT NULL,
            village TEXT NOT NULL,
            location_id TEXT REFERENCES locations(id),
            gps_latitude REAL,
            gps_longitude REAL
        );
        """)

        # 4. Buyer Profiles
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS buyer_profiles (
            user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
            business_name TEXT,
            gstin TEXT,
            delivery_location_id TEXT REFERENCES locations(id),
            address TEXT
        );
        """)

        # 5. Delivery Profiles
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS delivery_profiles (
            user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
            vehicle_id TEXT,
            driving_licence TEXT,
            rc_number TEXT,
            insurance TEXT,
            is_online INTEGER NOT NULL DEFAULT 1,
            rating REAL NOT NULL DEFAULT 4.9,
            active_orders_count INTEGER NOT NULL DEFAULT 0
        );
        """)

        # 6. Staff Profiles
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS staff_profiles (
            user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
            staff_role TEXT NOT NULL, -- founder | ops_manager | finance_officer | support_agent | quality_agronomist | field_verification_officer
            department TEXT NOT NULL,
            permissions TEXT NOT NULL -- JSON array
        );
        """)

        # 7. Vehicles
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS vehicles (
            id TEXT PRIMARY KEY,
            partner_id TEXT REFERENCES users(id) ON DELETE CASCADE,
            vehicle_type TEXT NOT NULL, -- bike | mini_truck | tata_ace | bolero | reefer
            plate_number TEXT NOT NULL UNIQUE,
            capacity_kg REAL NOT NULL,
            has_cold_chain INTEGER NOT NULL DEFAULT 0,
            is_active INTEGER NOT NULL DEFAULT 1
        );
        """)

        # 8. Crops Catalog (65 crops)
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS crops (
            id TEXT PRIMARY KEY,
            canonical_code TEXT UNIQUE NOT NULL,
            name_en TEXT NOT NULL,
            name_ta TEXT NOT NULL,
            name_hi TEXT NOT NULL,
            category TEXT NOT NULL, -- Vegetables | Fruits | Grains | Plantation | Spices
            base_mandi_price REAL NOT NULL,
            direct_price REAL NOT NULL,
            unit TEXT NOT NULL DEFAULT 'kg',
            grade_rules_json TEXT NOT NULL
        );
        """)

        # 9. Listings (Farmer Supply)
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS listings (
            id TEXT PRIMARY KEY,
            farmer_id TEXT NOT NULL REFERENCES users(id),
            crop_id TEXT NOT NULL REFERENCES crops(id),
            quantity REAL NOT NULL,
            unit TEXT NOT NULL DEFAULT 'kg',
            price REAL NOT NULL,
            quality_grade TEXT NOT NULL DEFAULT 'Grade A',
            location_id TEXT NOT NULL REFERENCES locations(id),
            is_available INTEGER NOT NULL DEFAULT 1,
            is_seed INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
        );
        """)

        # 10. Demands (Buyer Requests)
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS demands (
            id TEXT PRIMARY KEY,
            demand_number TEXT UNIQUE NOT NULL,
            buyer_id TEXT NOT NULL REFERENCES users(id),
            crop_id TEXT NOT NULL REFERENCES crops(id),
            quantity REAL NOT NULL,
            target_price REAL NOT NULL,
            destination_location_id TEXT NOT NULL REFERENCES locations(id),
            needed_by TEXT,
            delivery_mode TEXT NOT NULL DEFAULT 'delivery_partner', -- direct_pickup | delivery_partner
            cold_chain_required INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'DEMAND_POSTED',
            created_at TEXT NOT NULL
        );
        """)

        # 11. Orders (Authoritative Lifecycle)
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS orders (
            id TEXT PRIMARY KEY,
            order_number TEXT UNIQUE NOT NULL,
            buyer_id TEXT NOT NULL REFERENCES users(id),
            farmer_id TEXT REFERENCES users(id),
            delivery_partner_id TEXT REFERENCES users(id),
            crop_id TEXT NOT NULL REFERENCES crops(id),
            agreed_price REAL NOT NULL,
            quantity REAL NOT NULL,
            unit TEXT NOT NULL DEFAULT 'kg',
            total_amount REAL NOT NULL,
            produce_total REAL NOT NULL,
            delivery_fee REAL NOT NULL DEFAULT 0.0,
            fulfillment_mode TEXT NOT NULL, -- branch_a_pickup | branch_b_partner
            status TEXT NOT NULL, -- DEMAND_POSTED | ACCEPTED | PARTNER_ASSIGNED | READY_FOR_PICKUP | IN_TRANSIT | DELIVERED | SETTLED | CANCELLED | DISPUTED
            payment_status TEXT NOT NULL DEFAULT 'ESCROW_RESERVED',
            pickup_location_id TEXT REFERENCES locations(id),
            drop_location_id TEXT NOT NULL REFERENCES locations(id),
            delivery_otp TEXT NOT NULL,
            pickup_otp TEXT NOT NULL,
            is_seed INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );
        """)

        # 12. Order Events (Audit history for every transition)
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS order_events (
            id TEXT PRIMARY KEY,
            order_id TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
            previous_status TEXT,
            new_status TEXT NOT NULL,
            actor_id TEXT NOT NULL,
            actor_role TEXT NOT NULL,
            note TEXT,
            timestamp TEXT NOT NULL
        );
        """)

        # 13. Deliveries & Telematics
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS deliveries (
            id TEXT PRIMARY KEY,
            order_id TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
            partner_id TEXT NOT NULL REFERENCES users(id),
            vehicle_id TEXT REFERENCES vehicles(id),
            pickup_time TEXT,
            drop_time TEXT,
            distance_km REAL NOT NULL,
            eta_minutes INTEGER NOT NULL,
            route_geojson TEXT,
            status TEXT NOT NULL DEFAULT 'ASSIGNED'
        );
        """)

        cursor.execute("""
        CREATE TABLE IF NOT EXISTS tracking_points (
            id TEXT PRIMARY KEY,
            delivery_id TEXT NOT NULL REFERENCES deliveries(id) ON DELETE CASCADE,
            partner_id TEXT NOT NULL REFERENCES users(id),
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            speed_kmh REAL NOT NULL DEFAULT 35.0,
            heading REAL NOT NULL DEFAULT 0.0,
            timestamp TEXT NOT NULL
        );
        """)

        # 14. Quality Scans
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS quality_scans (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL REFERENCES users(id),
            crop_id TEXT NOT NULL REFERENCES crops(id),
            grade TEXT NOT NULL, -- Grade A | Grade B | Grade C | Rejected
            rot_percentage REAL NOT NULL DEFAULT 0.0,
            defect_percentage REAL NOT NULL DEFAULT 1.5,
            uniformity_percentage REAL NOT NULL DEFAULT 92.0,
            ripeness_percentage REAL NOT NULL DEFAULT 88.0,
            ai_confidence REAL NOT NULL DEFAULT 0.94,
            image_url TEXT,
            status TEXT NOT NULL DEFAULT 'VERIFIED',
            created_at TEXT NOT NULL
        );
        """)

        # 15. Wallets & Double-Entry Ledger Transactions
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS wallets (
            id TEXT PRIMARY KEY,
            user_id TEXT UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            balance REAL NOT NULL DEFAULT 0.0,
            pending_withdrawal REAL NOT NULL DEFAULT 0.0,
            updated_at TEXT NOT NULL
        );
        """)

        cursor.execute("""
        CREATE TABLE IF NOT EXISTS wallet_transactions (
            id TEXT PRIMARY KEY,
            wallet_id TEXT NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
            user_id TEXT NOT NULL REFERENCES users(id),
            order_id TEXT REFERENCES orders(id),
            transaction_type TEXT NOT NULL, -- CREDIT_SALE | CREDIT_DELIVERY | DEBIT_WITHDRAWAL | DEBIT_ESCROW | REFUND
            amount REAL NOT NULL,
            balance_after REAL NOT NULL,
            reference_note TEXT NOT NULL,
            timestamp TEXT NOT NULL
        );
        """)

        cursor.execute("""
        CREATE TABLE IF NOT EXISTS payout_requests (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL REFERENCES users(id),
            amount REAL NOT NULL,
            payout_method TEXT NOT NULL, -- UPI | BANK
            upi_id TEXT,
            bank_account TEXT,
            bank_ifsc TEXT,
            status TEXT NOT NULL DEFAULT 'PENDING', -- PENDING | APPROVED | REJECTED | PROCESSED
            requested_at TEXT NOT NULL,
            processed_at TEXT
        );
        """)

        # 16. Immutable SHA-256 Chained Audit Logs
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS audit_logs (
            id TEXT PRIMARY KEY,
            action TEXT NOT NULL,
            actor_id TEXT NOT NULL,
            actor_role TEXT NOT NULL,
            target_entity TEXT NOT NULL,
            details TEXT NOT NULL,
            prev_hash TEXT NOT NULL,
            curr_hash TEXT NOT NULL,
            timestamp TEXT NOT NULL
        );
        """)

        # 17. Notifications
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS notifications (
            id TEXT PRIMARY KEY,
            recipient_id TEXT NOT NULL,
            recipient_role TEXT NOT NULL,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            type TEXT NOT NULL,
            order_id TEXT,
            is_read INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
        );
        """)

        # 18. Support Tickets & Chat
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS support_tickets (
            id TEXT PRIMARY KEY,
            ticket_number TEXT UNIQUE NOT NULL,
            user_id TEXT NOT NULL REFERENCES users(id),
            user_role TEXT NOT NULL,
            category TEXT NOT NULL, -- VERIFICATION | PAYMENT | DELIVERY | QUALITY | APP_ISSUE | SOS
            priority TEXT NOT NULL DEFAULT 'MEDIUM', -- LOW | MEDIUM | HIGH | URGENT
            status TEXT NOT NULL DEFAULT 'OPEN', -- OPEN | IN_PROGRESS | RESOLVED | ESCALATED
            subject TEXT NOT NULL,
            description TEXT NOT NULL,
            assigned_agent_id TEXT REFERENCES users(id),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );
        """)

        cursor.execute("""
        CREATE TABLE IF NOT EXISTS support_messages (
            id TEXT PRIMARY KEY,
            ticket_id TEXT NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
            sender_id TEXT NOT NULL,
            sender_role TEXT NOT NULL,
            message TEXT NOT NULL,
            timestamp TEXT NOT NULL
        );
        """)

        # 19. Disputes
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS disputes (
            id TEXT PRIMARY KEY,
            order_id TEXT UNIQUE NOT NULL REFERENCES orders(id),
            raised_by TEXT NOT NULL REFERENCES users(id),
            reason TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'OPEN', -- OPEN | INVESTIGATING | RESOLVED | REJECTED
            resolution_notes TEXT,
            resolution_amount REAL DEFAULT 0.0,
            resolved_by TEXT REFERENCES users(id),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );
        """)

        # 20. Platform Settings
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS platform_settings (
            id TEXT PRIMARY KEY,
            setting_key TEXT UNIQUE NOT NULL,
            setting_value TEXT NOT NULL,
            description TEXT,
            updated_by TEXT,
            updated_at TEXT NOT NULL
        );
        """)

        # Indices for high performance
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_orders_buyer ON orders(buyer_id);")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_orders_farmer ON orders(farmer_id);")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_orders_partner ON orders(delivery_partner_id);")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_listings_crop ON listings(crop_id);")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications(recipient_id);")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs(timestamp);")

    print("[Database] Schema initialized successfully.")

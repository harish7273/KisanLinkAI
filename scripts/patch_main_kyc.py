with open('kisan_backend/main.py', 'r', encoding='utf-8') as f:
    text = f.read()

if 'from .kyc import router as kyc_router' not in text:
    text = text.replace('from .integrity import check_integrity', 'from .integrity import check_integrity\nfrom .kyc import router as kyc_router')
    text = text.replace('app = FastAPI(', 'app = FastAPI(')
    text = text.replace('app.add_middleware(', 'app.include_router(kyc_router)\napp.add_middleware(')

old_withdraw = """@app.post("/api/v1/wallets/withdraw")
def request_payout(req: PayoutCreateRequest):
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM wallets WHERE user_id = ?;", (req.user_id,))"""

new_withdraw = """@app.post("/api/v1/wallets/withdraw")
def request_payout(req: PayoutCreateRequest):
    with db_session() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT kyc_status, is_verified FROM users WHERE id = ?;", (req.user_id,))
        u = cursor.fetchone()
        if not u or u["kyc_status"] != "APPROVED":
            raise HTTPException(
                status_code=403,
                detail="HTTP 403 VERIFICATION_REQUIRED: Only verified accounts can receive payouts."
            )
        cursor.execute("SELECT * FROM wallets WHERE user_id = ?;", (req.user_id,))"""

if old_withdraw in text:
    text = text.replace(old_withdraw, new_withdraw)

with open('kisan_backend/main.py', 'w', encoding='utf-8') as f:
    f.write(text)

print("Successfully patched kisan_backend/main.py")

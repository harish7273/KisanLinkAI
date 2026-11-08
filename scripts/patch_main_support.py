with open('kisan_backend/main.py', 'r', encoding='utf-8') as f:
    text = f.read()

if 'from .support import router as support_router' not in text:
    text = text.replace('from .kyc import router as kyc_router', 'from .kyc import router as kyc_router\nfrom .support import router as support_router')
    text = text.replace('app.include_router(kyc_router)', 'app.include_router(kyc_router)\napp.include_router(support_router)')

with open('kisan_backend/main.py', 'w', encoding='utf-8') as f:
    f.write(text)

print("Successfully mounted support router in kisan_backend/main.py")

with open('kisan_backend/main.py', 'r', encoding='utf-8') as f:
    text = f.read()

if 'from .auth import router as auth_router, require_staff_auth' not in text:
    text = text.replace('from .support import router as support_router', 'from .support import router as support_router\nfrom .auth import router as auth_router, require_staff_auth')
    text = text.replace('app.include_router(support_router)', 'app.include_router(support_router)\napp.include_router(auth_router)')

# Protect admin endpoints with require_staff_auth
text = text.replace(
    '@app.get("/api/v1/admin/overview")',
    '@app.get("/api/v1/admin/overview")\ndef admin_overview(staff: Dict[str, Any] = Depends(require_staff_auth)):'
)
# Remove the duplicate def line
text = text.replace(
    'def admin_overview(staff: Dict[str, Any] = Depends(require_staff_auth)):\ndef admin_overview():',
    'def admin_overview(staff: Dict[str, Any] = Depends(require_staff_auth)):'
)

text = text.replace(
    '@app.get("/api/v1/admin/audit-logs")',
    '@app.get("/api/v1/admin/audit-logs")\ndef get_audit_logs(limit: int = 50, staff: Dict[str, Any] = Depends(require_staff_auth)):'
)
text = text.replace(
    'def get_audit_logs(limit: int = 50, staff: Dict[str, Any] = Depends(require_staff_auth)):\ndef get_audit_logs(limit: int = 50):',
    'def get_audit_logs(limit: int = 50, staff: Dict[str, Any] = Depends(require_staff_auth)):'
)

with open('kisan_backend/main.py', 'w', encoding='utf-8') as f:
    f.write(text)

print("Successfully patched main.py with auth router and staff security guard.")

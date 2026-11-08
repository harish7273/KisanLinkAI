import os
from pathlib import Path

# Base directory
BASE_DIR = Path(__file__).resolve().parent.parent

# Read .env if present
env_path = BASE_DIR / ".env"
if env_path.exists():
    with open(env_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip())

APP_ENV = os.environ.get("APP_ENV", "production")
DATA_MODE = os.environ.get("DATA_MODE", "sample")
DEMO_OPEN_STR = os.environ.get("DEMO_OPEN", "true").lower()
DEMO_OPEN = DEMO_OPEN_STR in ("true", "1", "yes")

# Safety rule: DEMO_OPEN cannot be True if DATA_MODE is real
if DATA_MODE == "real" and DEMO_OPEN:
    raise RuntimeError("CRITICAL SECURITY ERROR: DEMO_OPEN=true is strictly forbidden when DATA_MODE=real.")

FOUNDER_NAME = os.environ.get("FOUNDER_NAME", "Founder")
FOUNDER_PHONE = os.environ.get("FOUNDER_PHONE", "+919876543210")
JWT_SECRET = os.environ.get("JWT_SECRET", "kisanai_enterprise_secure_token_secret_2026")
API_PORT = int(os.environ.get("PORT", "8000"))

# Database path
DB_PATH = BASE_DIR / "kisan_backend" / f"kisanai_{DATA_MODE}.db"
DATABASE_URL = os.environ.get("DATABASE_URL", f"sqlite:///{DB_PATH}")

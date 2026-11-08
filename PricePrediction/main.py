from fastapi import FastAPI
from api.smart_pricing import router as smart_router

app = FastAPI(title="KisanAI Smart Pricing Backend")

app.include_router(smart_router)


@app.get("/")
def home():
    return {
        "service": "KisanAI Smart Pricing Engine",
        "status": "Running",
        "version": "2.0.0"
    }

from fastapi import FastAPI
from api.smart_pricing import router as smart_router

app = FastAPI(title="VIDHAI AI Backend")

app.include_router(smart_router)


@app.get("/")
def home():
    return {
        "message": "VIDHAI AI Backend Running 🚀"
    }
FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

# Install dependencies
RUN pip install --no-cache-dir fastapi uvicorn pydantic httpx cryptography

# Copy backend source
COPY kisan_backend/ /app/kisan_backend/
COPY data/ /app/data/

# Initialize and seed database
RUN python -m kisan_backend.seed

EXPOSE 8000

CMD ["uvicorn", "kisan_backend.main:app", "--host", "0.0.0.0", "--port", "8000"]

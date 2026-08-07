import os
import requests
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("API_KEY")

# Replace this with the Resource ID shown in the API documentation URL
RESOURCE_ID = "35985678-0d79-46b4-9ed6-6f13308a1d24"

BASE_URL = f"https://api.data.gov.in/resource/{RESOURCE_ID}"

def get_market_price(
    commodity: str,
    state: str = "Tamil Nadu",
    district: str = None,
    limit: int = 10
):
    params = {
        "api-key": API_KEY,
        "format": "json",
        "limit": limit,
        "filters[State]": state,
        "filters[Commodity]": commodity
    }

    if district:
        params["filters[District]"] = district

    response = requests.get(BASE_URL, params=params)

    response.raise_for_status()

    return response.json()
from fastapi import APIRouter
from pydantic import BaseModel

from services.pricing_engine import calculate_price

router = APIRouter()


class PricingRequest(BaseModel):
    crop: str
    location: str
    quantity: int
    cost: float
    quality: str
    organic: bool


# Temporary Market Prices
MARKET_PRICES = {
    "Tomato": 35,
    "Potato": 28,
    "Onion": 30,
    "Carrot": 40,
    "Brinjal": 26,
    "Rice": 32,
    "Wheat": 29,
    "Banana": 45,
    "Cabbage": 24,
    "Chilli": 60,
    "Beans": 48,
    "Mango": 75,
}


@router.post("/smart-price")
def smart_price(request: PricingRequest):

    # Current market price
    market_price = MARKET_PRICES.get(request.crop, 30)

    # AI Pricing Engine
    result = calculate_price(
        market_price=market_price,
        cost_price=request.cost,
        quantity=request.quantity,
        quality=request.quality,
        organic=request.organic,
    )

    recommendations = []

    # Selling Recommendation
    if result["suggestedPrice"] > market_price:
        recommendations.append(
            "Sell within the next 2-3 days. Market prices are favourable."
        )
    else:
        recommendations.append(
            "Current market is stable. Monitor prices before selling."
        )

    # Quality Recommendation
    if request.quality == "High":
        recommendations.append(
            "High-quality produce can be sold at a premium price."
        )

    elif request.quality == "Medium":
        recommendations.append(
            "Improve sorting and grading to increase selling price."
        )

    else:
        recommendations.append(
            "Low quality may reduce buyer interest."
        )

    # Organic Recommendation
    if request.organic:
        recommendations.append(
            "Organic products generally attract better prices."
        )

    # Quantity Recommendation
    if request.quantity > 100:
        recommendations.append(
            "Large stock detected. Selling in batches may maximize profit."
        )

    elif request.quantity < 20:
        recommendations.append(
            "Small quantity available. Selling immediately is recommended."
        )

    # Profit Recommendation
    if result["expectedProfit"] < 5:
        recommendations.append(
            "Profit margin is low. Consider waiting for better market conditions."
        )

    elif result["expectedProfit"] > 15:
        recommendations.append(
            "Excellent expected profit. This is a good time to sell."
        )

    # AI Explanation
    reason = (
        f"The AI analysed the current market price (₹{market_price}/kg), "
        f"production cost (₹{request.cost}/kg), "
        f"{request.quality.lower()} quality produce, "
        f"{'organic' if request.organic else 'non-organic'} farming, "
        f"and quantity ({request.quantity} kg). "
        f"It recommends selling at ₹{result['suggestedPrice']}/kg "
        f"to maximize profit while staying competitive."
    )

    response = {
        "success": True,

        "crop": request.crop,
        "location": request.location,

        "marketPrice": result["marketPrice"],
        "suggestedPrice": result["suggestedPrice"],
        "minimumSellingPrice": result["minimumSellingPrice"],

        "expectedProfit": result["expectedProfit"],
        "profitMargin": result["profitMargin"],

        "confidence": result["confidence"],

        "trend": (
            "Increasing"
            if result["suggestedPrice"] > market_price
            else "Stable"
        ),

        "demand": (
            "High"
            if request.quality == "High"
            else "Medium"
        ),

        "reason": reason,

        "recommendations": recommendations,
    }

    return response
import datetime

PERISHABLE_CROPS = {
    "tomato", "banana", "mango", "brinjal", "carrot", "cabbage", "cauliflower", "chilli", "beans", "apple", "orange"
}

HIGH_DEMAND_METROS = {
    "coimbatore", "chennai", "bangalore", "mumbai", "delhi", "hyderabad", "kochi", "madurai"
}

def calculate_price(
    market_price: float,
    cost_price: float,
    quantity: int,
    quality: str,
    organic: bool,
    crop: str = "",
    location: str = "",
):
    suggested_price = float(market_price)
    confidence = 88

    # ---------- 1. Quality Factor ----------
    if quality.lower() == "high":
        suggested_price *= 1.12
        confidence += 4
    elif quality.lower() == "medium":
        suggested_price *= 1.04
        confidence += 2
    else:
        suggested_price *= 0.95
        confidence -= 3

    # ---------- 2. Organic Certification Premium ----------
    if organic:
        suggested_price *= 1.18
        confidence += 3

    # ---------- 3. Regional / Location Demand Multiplier ----------
    loc_clean = location.trim().lower() if hasattr(location, 'trim') else location.strip().lower()
    is_metro = any(city in loc_clean for city in HIGH_DEMAND_METROS)
    if is_metro:
        suggested_price *= 1.08
        confidence += 2

    # ---------- 4. Quantity Bulk Adjustments ----------
    if quantity >= 100:
        suggested_price *= 0.96  # Bulk discount factor for buyers
    elif quantity <= 25:
        suggested_price *= 1.04  # Retail premium for small quantities

    # ---------- 5. Minimum Floor Price & Profit Checks ----------
    minimum_price = cost_price * 1.15 if cost_price > 0 else market_price * 0.85
    if suggested_price < minimum_price:
        suggested_price = minimum_price

    # ---------- 6. Risk Level & Perishability ----------
    crop_clean = crop.strip().lower()
    is_perishable = crop_clean in PERISHABLE_CROPS
    if is_perishable and quantity > 80:
        risk_level = "High Risk (Perishable - Sell Quickly)"
    elif is_perishable:
        risk_level = "Medium Risk (Moderate Shelf Life)"
    else:
        risk_level = "Low Risk (Storable Produce)"

    # ---------- 7. Financial Calculations ----------
    unit_profit = max(0.0, suggested_price - cost_price)
    total_cost = cost_price * quantity
    total_revenue = suggested_price * quantity
    total_profit = total_revenue - total_cost

    profit_margin = round(
        (unit_profit / cost_price) * 100, 1
    ) if cost_price > 0 else 25.0

    return {
        "marketPrice": round(market_price, 2),
        "suggestedPrice": round(suggested_price, 2),
        "minimumSellingPrice": round(minimum_price, 2),
        "expectedProfit": round(total_profit, 2),
        "unitProfit": round(unit_profit, 2),
        "profitMargin": profit_margin,
        "confidence": min(confidence, 98),
        "riskLevel": risk_level,
        "totalRevenue": round(total_revenue, 2),
        "totalCost": round(total_cost, 2),
    }
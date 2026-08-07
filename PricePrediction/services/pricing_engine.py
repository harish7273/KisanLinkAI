def calculate_price(
    market_price,
    cost_price,
    quantity,
    quality,
    organic
):
    suggested_price = market_price

    confidence = 85

    # ---------- Quality ----------
    if quality == "High":
        suggested_price += 2
        confidence += 3

    elif quality == "Medium":
        suggested_price += 1

    # ---------- Organic ----------
    if organic:
        suggested_price += 2
        confidence += 2

    # ---------- Quantity ----------
    if quantity > 100:
        suggested_price -= 1

    elif quantity < 20:
        suggested_price += 1

    # ---------- Profit ----------
    minimum_price = cost_price * 1.20

    if suggested_price < minimum_price:
        suggested_price = minimum_price

    expected_profit = round(
        suggested_price - cost_price,
        2,
    )

    profit_margin = round(
        (expected_profit / cost_price) * 100,
        1,
    ) if cost_price > 0 else 0

    return {
        "marketPrice": round(market_price, 2),
        "suggestedPrice": round(suggested_price, 2),
        "minimumSellingPrice": round(minimum_price, 2),
        "expectedProfit": expected_profit,
        "profitMargin": profit_margin,
        "confidence": min(confidence, 99),
    }
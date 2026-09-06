import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'product_preview_screen.dart';

class AiPricingScreen extends StatefulWidget {
  final String crop;
  final String category;
  final String location;
  final int quantity;
  final String unit;
  final double cost;
  final bool organic;
  final String description;

  const AiPricingScreen({
    super.key,
    required this.crop,
    required this.category,
    required this.location,
    required this.quantity,
    required this.unit,
    required this.cost,
    required this.organic,
    required this.description,
  });

  @override
  State<AiPricingScreen> createState() =>
      _AiPricingScreenState();
}

class _AiPricingScreenState
    extends State<AiPricingScreen> {

  // ============================================================
  // SAME COLORS AS YOUR FARMER HUB
  // ============================================================

  static const Color bg =
      Color(0xFF0B0B0B);

  static const Color card =
      Color(0xFF161616);

  static const Color card2 =
      Color(0xFF181818);

  static const Color green =
      Color(0xFF00E676);

  static const Color cyan =
      Color(0xFF00E5FF);

  static const Color orange =
      Color(0xFFFF9100);

  // ============================================================
  // AI DATA
  // ============================================================

  bool isLoading = true;

  double marketPrice = 0;
  double suggestedPrice = 0;
  double minimumSellingPrice = 0;
  double expectedProfit = 0;
  double profitMargin = 0;

  int confidence = 0;

  String marketTrend = "Increasing";
  String demandLevel = "High";

  List<String> recommendations = [];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _generateSmartPrice();
  }

  // ============================================================
  // AI PRICING
  // ============================================================

  Future<void> _generateSmartPrice() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse(
              "http://10.0.2.2:8000/smart-price",
            ),
            headers: {
              "Content-Type":
                  "application/json",
            },
            body: jsonEncode({
              "crop": widget.crop,
              "location":
                  widget.location,
              "quantity":
                  widget.quantity,
              "cost": widget.cost,
              "organic":
                  widget.organic,
            }),
          )
          .timeout(
            const Duration(seconds: 5),
          );

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body);

        setState(() {
          marketPrice =
              (data["marketPrice"]
                      as num)
                  .toDouble();

          suggestedPrice =
              (data["suggestedPrice"]
                      as num)
                  .toDouble();

          minimumSellingPrice =
              (data["minimumSellingPrice"]
                      as num)
                  .toDouble();

          expectedProfit =
              (data["expectedProfit"]
                      as num)
                  .toDouble();

          profitMargin =
              (data["profitMargin"]
                      as num)
                  .toDouble();

          confidence =
              data["confidence"] ?? 90;

          marketTrend =
              data["trend"] ??
                  "Increasing";

          demandLevel =
              data["demand"] ??
                  "High";

          recommendations =
              List<String>.from(
            data["recommendations"] ??
                [],
          );

          isLoading = false;
        });

        return;
      }
    } catch (_) {
      // fallback
    }

    _fallbackPrice();
  }

  // ============================================================
  // FALLBACK
  // ============================================================

  void _fallbackPrice() {
    final baseMarket =
        widget.cost * 1.35;

    final organicMultiplier =
        widget.organic
            ? 1.20
            : 1.0;

    final calculatedSuggested =
        baseMarket *
            organicMultiplier;

    final minimum =
        widget.cost * 1.10;

    final profitPerUnit =
        calculatedSuggested -
            widget.cost;

    final margin =
        widget.cost > 0
            ? (profitPerUnit /
                    widget.cost) *
                100
            : 0;

    setState(() {
      marketPrice =
          double.parse(
        baseMarket
            .toStringAsFixed(0),
      );

      suggestedPrice =
          double.parse(
        calculatedSuggested
            .toStringAsFixed(0),
      );

      minimumSellingPrice =
          double.parse(
        minimum.toStringAsFixed(0),
      );

      expectedProfit =
          double.parse(
        profitPerUnit
            .toStringAsFixed(0),
      );

      profitMargin =
          double.parse(
        margin.toStringAsFixed(0),
      );

      confidence = 92;

      marketTrend = "Increasing";
      demandLevel = "High";

      recommendations = [
        "Prices may increase in the next 2–3 days.",

        if (widget.organic)
          "Organic produce can attract premium buyers.",

        "Consider selling directly to buyers for better margins.",

        "Bulk orders can help improve overall returns.",
      ];

      isLoading = false;
    });
  }

  // ============================================================
  // PREVIEW
  // ============================================================

  void _continueToPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProductPreviewScreen(
          crop: widget.crop,
          category:
              widget.category,
          location:
              widget.location,
          quantity:
              widget.quantity,
          unit: widget.unit,
          cost: widget.cost,
          organic:
              widget.organic,
          description:
              widget.description,

          suggestedPrice:
              suggestedPrice,

          marketPrice:
              marketPrice,

          minimumSellingPrice:
              minimumSellingPrice,

          expectedProfit:
              expectedProfit,

          profitMargin:
              profitMargin,

          confidence:
              confidence,

          marketTrend:
              marketTrend,

          demandLevel:
              demandLevel,

          recommendations:
              recommendations,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,

      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },

          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Colors.white,
          ),
        ),

        title: const Text(
          "Add New Product",
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.help_outline,
              size: 19,
              color: Colors.white70,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(),

          padding:
              const EdgeInsets.fromLTRB(
            20,
            5,
            20,
            30,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              _stepIndicator(),

              const SizedBox(height: 26),

              _header(),

              const SizedBox(height: 18),

              _productCard(),

              const SizedBox(height: 15),

              if (isLoading)
                _loadingCard()
              else ...[
                _mainPricingCard(),

                const SizedBox(height: 16),

                _marketInsights(),

                const SizedBox(height: 16),

                _bestTimeCard(),

                const SizedBox(height: 16),

                _forecastCard(),

                const SizedBox(height: 16),

                _recommendations(),

                const SizedBox(height: 20),

                _continueButton(),

                const SizedBox(height: 10),

                _backButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP INDICATOR
  // ============================================================

  Widget _stepIndicator() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: card2,
        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color:
              Colors.white.withOpacity(
            0.06,
          ),
        ),
      ),

      child: Column(
        children: [
          Row(
            children: [
              _stepCircle(
                "✓",
                true,
              ),

              Expanded(
                child: Container(
                  height: 2,
                  color: green
                      .withOpacity(.75),
                ),
              ),

              _stepCircle(
                "2",
                true,
              ),

              Expanded(
                child: Container(
                  height: 2,
                  color: Colors.white
                      .withOpacity(.10),
                ),
              ),

              _stepCircle(
                "3",
                false,
              ),
            ],
          ),

          const SizedBox(height: 6),

          const Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children: [
              Text(
                "Product Info",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                ),
              ),

              Text(
                "AI Pricing",
                style: TextStyle(
                  color: green,
                  fontSize: 9,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              Text(
                "Preview",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepCircle(
    String text,
    bool active,
  ) {
    return Container(
      width: 22,
      height: 22,

      decoration: BoxDecoration(
        shape:
            BoxShape.circle,

        color: active
            ? green
            : Colors.transparent,

        border: Border.all(
          color: active
              ? green
              : Colors.white24,
        ),
      ),

      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: active
                ? Colors.black
                : Colors.white38,
            fontSize: 9,
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 45,
          height: 45,

          decoration: BoxDecoration(
            color:
                const Color(0xFF211C0A),

            borderRadius:
                BorderRadius.circular(
              13,
            ),

            border: Border.all(
              color:
                  orange.withOpacity(
                .22,
              ),
            ),
          ),

          child: const Icon(
            Icons.auto_awesome,
            color: orange,
            size: 23,
          ),
        ),

        const SizedBox(width: 12),

        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                "AI Smart Pricing",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              SizedBox(height: 3),

              Text(
                "Find the right price for your produce",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),

          decoration: BoxDecoration(
            color:
                green.withOpacity(.10),
            borderRadius:
                BorderRadius.circular(8),
            border: Border.all(
              color:
                  green.withOpacity(.20),
            ),
          ),

          child: const Text(
            "AI",
            style: TextStyle(
              color: green,
              fontSize: 9,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PRODUCT CARD
  // ============================================================

  Widget _productCard() {
    return Container(
      padding:
          const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color:
              Colors.white.withOpacity(
            .07,
          ),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,

            decoration: BoxDecoration(
              color:
                  green.withOpacity(.07),

              borderRadius:
                  BorderRadius.circular(
                13,
              ),

              border: Border.all(
                color:
                    green.withOpacity(
                  .12,
                ),
              ),
            ),

            child: Center(
              child: Text(
                _cropEmoji(
                  widget.crop,
                ),
                style:
                    const TextStyle(
                  fontSize: 41,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.crop,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "${widget.category} • ${widget.location}",
                  style:
                      const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 9),

                Row(
                  children: [
                    _smallTag(
                      "${widget.quantity} ${widget.unit}",
                      cyan,
                    ),

                    if (widget.organic) ...[
                      const SizedBox(
                        width: 6,
                      ),

                      _smallTag(
                        "🌿 Organic",
                        green,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _loadingCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.symmetric(
        vertical: 42,
        horizontal: 20,
      ),

      decoration: BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color:
              Colors.white.withOpacity(
            .07,
          ),
        ),
      ),

      child: Column(
        children: [
          Container(
            width: 55,
            height: 55,

            decoration: BoxDecoration(
              color:
                  green.withOpacity(.08),
              shape:
                  BoxShape.circle,
            ),

            child: const Padding(
              padding:
                  EdgeInsets.all(16),
              child:
                  CircularProgressIndicator(
                strokeWidth: 2.5,
                color: green,
              ),
            ),
          ),

          const SizedBox(height: 17),

          const Text(
            "Analyzing Market Data",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            "Checking demand, regional prices\nand current market trends...",
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN PRICING CARD
  // ============================================================

  Widget _mainPricingCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(15),

      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF12251B),
            Color(0xFF0F1912),
          ],

          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,
        ),

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color:
              green.withOpacity(.22),
        ),

        boxShadow: [
          BoxShadow(
            color:
                green.withOpacity(.06),
            blurRadius: 18,
            offset:
                const Offset(0, 7),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: green,
                size: 18,
              ),

              const SizedBox(width: 7),

              const Expanded(
                child: Text(
                  "AI Recommended Price",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),

              _confidenceTag(),
            ],
          ),

          const SizedBox(height: 14),

          // MAIN PRICE
          Container(
            width: double.infinity,

            padding:
                const EdgeInsets.symmetric(
              vertical: 17,
              horizontal: 16,
            ),

            decoration: BoxDecoration(
              color:
                  Colors.black.withOpacity(
                .28,
              ),

              borderRadius:
                  BorderRadius.circular(
                15,
              ),

              border: Border.all(
                color:
                    green.withOpacity(
                  .10,
                ),
              ),
            ),

            child: Column(
              children: [
                const Text(
                  "Suggested Selling Price",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .baseline,
                  textBaseline:
                      TextBaseline.alphabetic,
                  children: [
                    Text(
                      "₹${suggestedPrice.toStringAsFixed(0)}",
                      style:
                          const TextStyle(
                        color: green,
                        fontSize: 34,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing:
                            -1,
                      ),
                    ),

                    Text(
                      " / ${widget.unit}",
                      style:
                          const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: green,
                      size: 14,
                    ),

                    const SizedBox(
                      width: 4,
                    ),

                    Text(
                      "₹${(suggestedPrice - marketPrice).abs().toStringAsFixed(0)} above market",
                      style:
                          const TextStyle(
                        color: green,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _priceBox(
                  "Market Price",
                  marketPrice,
                  Colors.white,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _priceBox(
                  "Minimum Price",
                  minimumSellingPrice,
                  Colors.white,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _priceBox(
                  "Profit",
                  expectedProfit,
                  green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceBox(
    String title,
    double value,
    Color valueColor,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 6,
      ),

      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(
          .04,
        ),

        borderRadius:
            BorderRadius.circular(
          10,
        ),

        border: Border.all(
          color:
              Colors.white.withOpacity(
            .06,
          ),
        ),
      ),

      child: Column(
        children: [
          Text(
            title,
            style:
                const TextStyle(
              color: Colors.white38,
              fontSize: 7,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            "₹${value.toStringAsFixed(0)}",
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _confidenceTag() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color:
            green.withOpacity(.10),

        borderRadius:
            BorderRadius.circular(8),

        border: Border.all(
          color:
              green.withOpacity(.18),
        ),
      ),

      child: Text(
        "$confidence% Confidence",
        style:
            const TextStyle(
          color: green,
          fontSize: 8,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // MARKET INSIGHTS
  // ============================================================

  Widget _marketInsights() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        _sectionTitle(
          "Market Insights",
          Icons.insights_outlined,
          green,
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _insightBox(
                "Demand",
                demandLevel,
                Icons.people_outline,
                cyan,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: _insightBox(
                "Supply",
                "Medium",
                Icons.inventory_2_outlined,
                orange,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: _insightBox(
                "Trend",
                marketTrend,
                Icons.trending_up,
                green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _insightBox(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 5,
      ),

      decoration: BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(13),

        border: Border.all(
          color:
              Colors.white.withOpacity(
            .07,
          ),
        ),
      ),

      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 17,
          ),

          const SizedBox(height: 5),

          Text(
            title,
            style:
                const TextStyle(
              color: Colors.white38,
              fontSize: 8,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BEST TIME
  // ============================================================

  Widget _bestTimeCard() {
    return Container(
      padding:
          const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color:
              cyan.withOpacity(.12),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color:
                  cyan.withOpacity(.08),
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),

            child: const Icon(
              Icons.calendar_month_outlined,
              color: cyan,
              size: 21,
            ),
          ),

          const SizedBox(width: 11),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  "Best Time to Sell",
                  style: TextStyle(
                    color: cyan,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  "Tomorrow Morning",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  "Market conditions look favorable",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              const Text(
                "Expected",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 8,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                "₹${(suggestedPrice + 1).toStringAsFixed(0)}",
                style: const TextStyle(
                  color: cyan,
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORECAST
  // ============================================================

  Widget _forecastCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color:
              Colors.white.withOpacity(
            .07,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          _sectionTitle(
            "Price Forecast",
            Icons.show_chart,
            cyan,
          ),

          const SizedBox(height: 3),

          const Text(
            "Expected movement over the next 3 days",
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9,
            ),
          ),

          const SizedBox(height: 17),

          Row(
            children: [
              Expanded(
                child:
                    _forecastPoint(
                  "Today",
                  marketPrice,
                ),
              ),

              _forecastConnector(),

              Expanded(
                child:
                    _forecastPoint(
                  "Tomorrow",
                  suggestedPrice + 1,
                ),
              ),

              _forecastConnector(),

              Expanded(
                child:
                    _forecastPoint(
                  "+3 Days",
                  suggestedPrice + 4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _forecastPoint(
    String day,
    double price,
  ) {
    return Column(
      children: [
        Text(
          day,
          style:
              const TextStyle(
            color: Colors.white38,
            fontSize: 8,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          "₹${price.toStringAsFixed(0)}",
          style:
              const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight:
                FontWeight.w800,
          ),
        ),

        const SizedBox(height: 6),

        Container(
          width: 9,
          height: 9,

          decoration:
              const BoxDecoration(
            color: green,
            shape:
                BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _forecastConnector() {
    return Expanded(
      child: Container(
        height: 2,
        color:
            green.withOpacity(.25),
      ),
    );
  }

  // ============================================================
  // RECOMMENDATIONS
  // ============================================================

  Widget _recommendations() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color:
              orange.withOpacity(.12),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          _sectionTitle(
            "AI Recommendations",
            Icons.psychology_outlined,
            orange,
          ),

          const SizedBox(height: 10),

          ...recommendations
              .take(4)
              .map(
            (item) {
              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 8,
                ),

                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    const Icon(
                      Icons
                          .check_circle_outline,
                      color: green,
                      size: 14,
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child: Text(
                        item,
                        style:
                            const TextStyle(
                          color:
                              Colors.white60,
                          fontSize: 9,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTINUE
  // ============================================================

  Widget _continueButton() {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color:
                green.withOpacity(.16),
            blurRadius: 15,
            offset:
                const Offset(0, 6),
          ),
        ],
      ),

      child: ElevatedButton(
        onPressed:
            _continueToPreview,

        style:
            ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor:
              Colors.black,
          elevation: 0,

          minimumSize:
              const Size(
            double.infinity,
            52,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
        ),

        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 18,
            ),

            const SizedBox(width: 7),

            Text(
              "Use ₹${suggestedPrice.toStringAsFixed(0)} / ${widget.unit}",
              style:
                  const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BACK
  // ============================================================

  Widget _backButton() {
    return SizedBox(
      width: double.infinity,
      height: 45,

      child: OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
        },

        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              Colors.white70,

          side: BorderSide(
            color:
                Colors.white.withOpacity(
              .10,
            ),
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),

        child: const Text(
          "Back to Product Info",
          style: TextStyle(
            fontSize: 11,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
    String title,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: color,
        ),

        const SizedBox(width: 7),

        Text(
          title,
          style:
              const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TAG
  // ============================================================

  Widget _smallTag(
    String text,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color:
            color.withOpacity(.08),

        borderRadius:
            BorderRadius.circular(7),

        border: Border.all(
          color:
              color.withOpacity(.15),
        ),
      ),

      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // EMOJI
  // ============================================================

  String _cropEmoji(
    String crop,
  ) {
    switch (crop) {
      case "Tomato":
        return "🍅";

      case "Potato":
        return "🥔";

      case "Onion":
        return "🧅";

      case "Carrot":
        return "🥕";

      case "Banana":
        return "🍌";

      case "Mango":
        return "🥭";

      case "Apple":
        return "🍎";

      case "Orange":
        return "🍊";

      case "Coconut":
        return "🥥";

      case "Chilli":
        return "🌶️";

      case "Rice":
      case "Wheat":
        return "🌾";

      default:
        return "🌱";
    }
  }
}
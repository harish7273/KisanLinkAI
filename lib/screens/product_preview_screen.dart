import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';
import 'sell_screen.dart';

class ProductPreviewScreen extends StatefulWidget {
  final String crop;
  final String category;
  final String location;
  final int quantity;
  final String unit;
  final double cost;
  final bool organic;
  final String description;

  // AI Pricing
  final double suggestedPrice;
  final double marketPrice;
  final double minimumSellingPrice;
  final double expectedProfit;
  final double profitMargin;

  final int confidence;

  final String marketTrend;
  final String demandLevel;

  final List<String> recommendations;

  const ProductPreviewScreen({
    super.key,
    required this.crop,
    required this.category,
    required this.location,
    required this.quantity,
    required this.unit,
    required this.cost,
    required this.organic,
    required this.description,
    required this.suggestedPrice,
    required this.marketPrice,
    required this.minimumSellingPrice,
    required this.expectedProfit,
    required this.profitMargin,
    required this.confidence,
    required this.marketTrend,
    required this.demandLevel,
    required this.recommendations,
  });

  @override
  State<ProductPreviewScreen> createState() =>
      _ProductPreviewScreenState();
}

class _ProductPreviewScreenState
    extends State<ProductPreviewScreen> {
  // ============================================================
  // COLORS
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
  // SERVICE
  // ============================================================

  final ProductService _productService =
      ProductService();

  bool _isPublishing = false;

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
          onPressed: _isPublishing
              ? null
              : () {
                  Navigator.of(context).pop();
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

              const SizedBox(
                height: 26,
              ),

              _header(),

              const SizedBox(
                height: 18,
              ),

              _productListing(),

              const SizedBox(
                height: 15,
              ),

              _finalPriceCard(),

              const SizedBox(
                height: 15,
              ),

              _detailsCard(),

              const SizedBox(
                height: 15,
              ),

              _aiSummary(),

              const SizedBox(
                height: 15,
              ),

              if (widget.recommendations.isNotEmpty)
                _sellingTips(),

              const SizedBox(
                height: 22,
              ),

              _publishButton(context),

              const SizedBox(
                height: 10,
              ),

              _backButton(context),
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
              Colors.white.withOpacity(.06),
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
                  color:
                      green.withOpacity(.75),
                ),
              ),
              _stepCircle(
                "✓",
                true,
              ),
              Expanded(
                child: Container(
                  height: 2,
                  color:
                      green.withOpacity(.75),
                ),
              ),
              _stepCircle(
                "3",
                true,
              ),
            ],
          ),
          const SizedBox(
            height: 6,
          ),
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
                  color: Colors.white38,
                  fontSize: 9,
                ),
              ),
              Text(
                "Preview",
                style: TextStyle(
                  color: green,
                  fontSize: 9,
                  fontWeight:
                      FontWeight.w800,
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
        shape: BoxShape.circle,
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
          decoration:
              BoxDecoration(
            color:
                cyan.withOpacity(.08),
            borderRadius:
                BorderRadius.circular(13),
            border: Border.all(
              color:
                  cyan.withOpacity(.20),
            ),
          ),
          child: const Icon(
            Icons.preview_outlined,
            color: cyan,
            size: 23,
          ),
        ),
        const SizedBox(
          width: 12,
        ),
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                "Preview Your Product",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              SizedBox(
                height: 3,
              ),
              Text(
                "Review your listing before publishing",
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
          decoration:
              BoxDecoration(
            color:
                green.withOpacity(.08),
            borderRadius:
                BorderRadius.circular(8),
            border: Border.all(
              color:
                  green.withOpacity(.18),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: green,
                size: 12,
              ),
              SizedBox(
                width: 4,
              ),
              Text(
                "Ready",
                style: TextStyle(
                  color: green,
                  fontSize: 8,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PRODUCT LISTING
  // ============================================================

  Widget _productListing() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              Colors.white.withOpacity(.07),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration:
                    BoxDecoration(
                  gradient:
                      const LinearGradient(
                    colors: [
                      Color(0xFF13281B),
                      Color(0xFF0E1711),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(15),
                  border: Border.all(
                    color:
                        green.withOpacity(.15),
                  ),
                ),
                child: Center(
                  child: Text(
                    _cropEmoji(
                      widget.crop,
                    ),
                    style:
                        const TextStyle(
                      fontSize: 48,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      widget.crop,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      widget.category,
                      style:
                          const TextStyle(
                        color: cyan,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    Row(
                      children: [
                        _tag(
                          "${widget.quantity} ${widget.unit}",
                          cyan,
                        ),
                        if (widget.organic) ...[
                          const SizedBox(
                            width: 6,
                          ),
                          _tag(
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

          const SizedBox(
            height: 14,
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 10,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.white.withOpacity(.025),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Colors.redAccent,
                  size: 16,
                ),
                const SizedBox(
                  width: 7,
                ),
                Expanded(
                  child: Text(
                    widget.location,
                    style:
                        const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (widget.description
              .trim()
              .isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),
            const Text(
              "Description",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              widget.description,
              style:
                  const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // FINAL PRICE
  // ============================================================

  Widget _finalPriceCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF12251B),
            Color(0xFF0E1711),
          ],
        ),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              green.withOpacity(.23),
        ),
        boxShadow: [
          BoxShadow(
            color:
                green.withOpacity(.05),
            blurRadius: 18,
            offset:
                const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: green,
                size: 18,
              ),
              const SizedBox(
                width: 7,
              ),
              const Expanded(
                child: Text(
                  "Final Selling Price",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      green.withOpacity(.10),
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: Text(
                  "${widget.confidence}% AI",
                  style:
                      const TextStyle(
                    color: green,
                    fontSize: 8,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              vertical: 17,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.black.withOpacity(.28),
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color:
                    green.withOpacity(.10),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "SELLING PRICE",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 8,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .baseline,
                  textBaseline:
                      TextBaseline.alphabetic,
                  children: [
                    Text(
                      "₹${widget.suggestedPrice.toStringAsFixed(0)}",
                      style:
                          const TextStyle(
                        color: green,
                        fontSize: 35,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: -1,
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
                const SizedBox(
                  height: 6,
                ),
                const Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: green,
                      size: 12,
                    ),
                    SizedBox(
                      width: 4,
                    ),
                    Text(
                      "AI optimized price",
                      style:
                          TextStyle(
                        color:
                            Colors.white54,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Row(
            children: [
              Expanded(
                child: _priceMini(
                  "Market",
                  widget.marketPrice,
                  Colors.white70,
                ),
              ),
              const SizedBox(
                width: 7,
              ),
              Expanded(
                child: _priceMini(
                  "Minimum",
                  widget.minimumSellingPrice,
                  Colors.white70,
                ),
              ),
              const SizedBox(
                width: 7,
              ),
              Expanded(
                child: _priceMini(
                  "Profit",
                  widget.expectedProfit,
                  green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceMini(
    String title,
    double value,
    Color valueColor,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 9,
        horizontal: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white.withOpacity(.035),
        borderRadius:
            BorderRadius.circular(9),
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
          const SizedBox(
            height: 3,
          ),
          Text(
            "₹${value.toStringAsFixed(0)}",
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT DETAILS
  // ============================================================

  Widget _detailsCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color:
              Colors.white.withOpacity(.07),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            "Product Details",
            Icons.inventory_2_outlined,
            green,
          ),

          const SizedBox(
            height: 13,
          ),

          _detailRow(
            Icons.inventory_2_outlined,
            "Quantity",
            "${widget.quantity} ${widget.unit}",
          ),

          _detailRow(
            Icons.location_on_outlined,
            "Location",
            widget.location,
          ),

          _detailRow(
            Icons.payments_outlined,
            "Production Cost",
            "₹${widget.cost.toStringAsFixed(0)} / ${widget.unit}",
          ),

          _detailRow(
            Icons.category_outlined,
            "Category",
            widget.category,
          ),

          _detailRow(
            Icons.people_outline,
            "Demand",
            widget.demandLevel,
            valueColor: cyan,
          ),

          _detailRow(
            Icons.trending_up,
            "Market Trend",
            widget.marketTrend,
            valueColor: green,
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String title,
    String value, {
    Color valueColor = Colors.white,
    bool last = false,
  }) {
    return Padding(
      padding:
          EdgeInsets.only(
        bottom: last ? 0 : 11,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration:
                BoxDecoration(
              color:
                  Colors.white.withOpacity(.035),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 15,
              color: green,
            ),
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child: Text(
              title,
              style:
                  const TextStyle(
                color: Colors.white54,
                fontSize: 9,
              ),
            ),
          ),

          Flexible(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor,
                fontSize: 9,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AI SUMMARY
  // ============================================================

  Widget _aiSummary() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color:
              cyan.withOpacity(.13),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            "AI Pricing Summary",
            Icons.psychology_outlined,
            cyan,
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            "Based on current market conditions, "
            "${widget.crop} can be listed at "
            "₹${widget.suggestedPrice.toStringAsFixed(0)} "
            "/ ${widget.unit}. "
            "This price considers the market price, "
            "your production cost and current demand"
            "${widget.organic ? " for organic produce" : ""}.",
            style:
                const TextStyle(
              color: Colors.white60,
              fontSize: 10,
              height: 1.5,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [
              Expanded(
                child: _summaryStat(
                  "Profit Margin",
                  "${widget.profitMargin.toStringAsFixed(0)}%",
                  green,
                  Icons.percent,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: _summaryStat(
                  "Demand",
                  widget.demandLevel,
                  cyan,
                  Icons.people_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(10),
      decoration:
          BoxDecoration(
        color:
            color.withOpacity(.05),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: color,
          ),
          const SizedBox(
            width: 7,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        Colors.white38,
                    fontSize: 7,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  value,
                  style:
                      TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SELLING TIPS
  // ============================================================

  Widget _sellingTips() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(15),
      decoration:
          BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color:
              orange.withOpacity(.13),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            "Selling Tips",
            Icons.lightbulb_outline,
            orange,
          ),

          const SizedBox(
            height: 10,
          ),

          ...widget.recommendations
              .take(3)
              .map(
            (item) {
              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 8,
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
  // PUBLISH BUTTON
  // ============================================================

  Widget _publishButton(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                green.withOpacity(.18),
            blurRadius: 16,
            offset:
                const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isPublishing
            ? null
            : () {
                _publishProduct(context);
              },
        style:
            ElevatedButton.styleFrom(
          backgroundColor: green,
          disabledBackgroundColor:
              green.withOpacity(.45),
          foregroundColor: Colors.black,
          elevation: 0,
          minimumSize:
              const Size(
            double.infinity,
            52,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
        child: _isPublishing
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.black,
                ),
              )
            : const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 19,
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Text(
                    "Publish Product",
                    style:
                        TextStyle(
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
  // PUBLISH TO FIREBASE
  // ============================================================

  Future<void> _publishProduct(
    BuildContext context,
  ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showError(
        context,
        "Please login before publishing.",
      );
      return;
    }

    final farmerId = user.uid;

    debugPrint(
      "========================================",
    );

    debugPrint(
      "🌾 FARMER PRODUCT PUBLISH",
    );

    debugPrint(
      "Firebase Auth UID: $farmerId",
    );

    debugPrint(
      "Firebase Display Name: "
      "${user.displayName ?? "Farmer"}",
    );

    debugPrint(
      "Product: ${widget.crop}",
    );

    debugPrint(
      "========================================",
    );

    setState(() {
      _isPublishing = true;
    });

    try {
      final product =
          ProductModel(
        id: "",

        farmerId: farmerId,

        farmerName:
            user.displayName ??
                "Farmer",

        name:
            widget.crop,

        category:
            widget.category,

        price:
            widget.suggestedPrice,

        quantity:
            widget.quantity,

        unit:
            widget.unit,

        location:
            widget.location,

        image: _getCropAsset(widget.crop),

        description:
            widget.description,

        available:
            true,

        createdAt:
            DateTime.now(),

        marketPrice:
            widget.marketPrice,

        suggestedPrice:
            widget.suggestedPrice,

        minimumSellingPrice:
            widget.minimumSellingPrice,

        expectedProfit:
            widget.expectedProfit,

        profitMargin:
            widget.profitMargin,

        confidence:
            widget.confidence,

        marketTrend:
            widget.marketTrend,

        demandLevel:
            widget.demandLevel,

        aiReason:
            "AI optimized price based on current market conditions.",

        aiRecommendations:
            widget.recommendations,

        organic:
            widget.organic,

        quality: "",
      );

      debugPrint(
        "📦 PRODUCT FARMER ID: "
        "${product.farmerId}",
      );

      debugPrint(
        "👤 AUTH USER UID: "
        "${user.uid}",
      );

      if (product.farmerId !=
          user.uid) {
        throw Exception(
          "Farmer ID mismatch detected before saving.",
        );
      }

      await _productService
          .addProduct(product);

      debugPrint(
        "✅ PRODUCT SAVED SUCCESSFULLY",
      );

      if (!mounted) return;

      setState(() {
        _isPublishing = false;
      });

      // ========================================================
      // SUCCESS DIALOG
      // ========================================================

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: card2,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(22),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(22),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration:
                        BoxDecoration(
                      color:
                          green.withOpacity(.10),
                      shape:
                          BoxShape.circle,
                      border:
                          Border.all(
                        color:
                            green.withOpacity(.25),
                      ),
                    ),
                    child:
                        const Icon(
                      Icons.check_circle,
                      color: green,
                      size: 38,
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  const Text(
                    "Product Published!",
                    style:
                        TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  Text(
                    "${widget.crop} is now listed at "
                    "₹${widget.suggestedPrice.toStringAsFixed(0)} "
                    "/ ${widget.unit}.",
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color:
                          Colors.white60,
                      fontSize: 10,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // ==================================================
                  // DONE -> FARMER HOME
                  // ==================================================

                  SizedBox(
                    width:
                        double.infinity,
                    height: 45,
                    child:
                        ElevatedButton(
                      onPressed: () {
                        // Close success dialog
                        Navigator.of(
                          dialogContext,
                        ).pop();

                        // Go directly to Farmer Home
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil(
                          '/farmer-home',
                          (route) => false,
                        );
                      },
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            green,
                        foregroundColor:
                            Colors.black,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            13,
                          ),
                        ),
                      ),
                      child:
                          const Text(
                        "Done",
                        style:
                            TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint(
        "❌ PRODUCT PUBLISH ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        _isPublishing = false;
      });

      _showError(
        context,
        "Failed to publish product.\n$e",
      );
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor:
            const Color(0xFF1B0D0D),
        behavior:
            SnackBarBehavior.floating,
        content: Text(
          message,
          style:
              const TextStyle(
            color: Colors.white,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BACK BUTTON
  // ============================================================

  Widget _backButton(
    BuildContext context,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: OutlinedButton(
        onPressed: _isPublishing
            ? null
            : () {
                Navigator.of(context)
                    .pop();
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
                BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          "Back to AI Pricing",
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
        const SizedBox(
          width: 7,
        ),
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

  Widget _tag(
    String text,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
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
  // CROP ASSET
  // ============================================================

  String _getCropAsset(String crop) {
    final c = crop.trim().toLowerCase();
    if (c.contains('banana') || c.contains('nendran')) return 'assets/products/banana.png';
    if (c.contains('corn') || c.contains('maize')) return 'assets/products/corn.png';
    if (c.contains('cabbage')) return 'assets/products/cabbage.png';
    if (c.contains('brinjal') || c.contains('eggplant')) return 'assets/products/brinjal.png';
    if (c.contains('mango') || c.contains('alphonso')) return 'assets/products/mango.png';
    if (c.contains('spinach') || c.contains('palak')) return 'assets/products/spinach.png';
    if (c.contains('carrot')) return 'assets/products/carrot.png';
    if (c.contains('tomato')) return 'assets/products/tomato.png';
    if (c.contains('potato')) return 'assets/products/potato.png';
    if (c.contains('onion')) return 'assets/products/onion.png';
    if (c.contains('chilli') || c.contains('chili')) return 'assets/products/chilli.png';
    if (c.contains('fruit') || c.contains('apple') || c.contains('orange')) return 'assets/products/fruits.png';
    if (c.contains('grain') || c.contains('rice') || c.contains('wheat')) return 'assets/products/grains.png';
    if (c.contains('dairy') || c.contains('milk')) return 'assets/products/dairy.png';
    if (c.contains('spice') || c.contains('pepper') || c.contains('turmeric')) return 'assets/products/spices.png';
    return 'assets/products/vegetables.png';
  }

  // ============================================================
  // CROP EMOJI
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
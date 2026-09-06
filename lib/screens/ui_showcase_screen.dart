import 'package:flutter/material.dart';

/// Constants for the showcase design system
const Color kShowBg = Color(0xFF121212); // main background
const Color kShowSurface = Color(0xFF1A1F1E); // phone screen surface
const Color kShowCard = Color(0xFF1E2420); // card surface
const Color kShowCardAlt = Color(0xFF242B27); // elevated card
const Color kShowEmerald = Color(0xFF00E676); // primary emerald
const Color kShowMint = Color(0xFF69F0AE); // mint accent
const Color kShowSub = Color(0xFF5F6B64); // subtitle text
const Color kShowBorder = Color(0xFF2A312D);

class UiShowcaseScreen extends StatelessWidget {
  const UiShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kShowBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: kShowEmerald.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.agriculture_rounded,
                      color: kShowEmerald,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "FarmDirect UI/UX Showcase",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Farmer Experience · AI Smart Pricing & Product Management",
                        style: TextStyle(color: kShowSub, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Phones row
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool wide = constraints.maxWidth >= 760;
                  final phoneWidth = wide ? 360.0 : constraints.maxWidth - 64;
                  final phoneHeight = phoneWidth * 2.08;

                  final PhoneMockup left = PhoneMockup(
                    title: "AI Smart Pricing",
                    label: "ANALYTICS",
                    child: const AISmartPricingPanel(),
                  );
                  final PhoneMockup right = PhoneMockup(
                    title: "My Products",
                    label: "MANAGEMENT",
                    child: const MyProductsPanel(),
                  );

                  if (wide) {
                    return Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: phoneWidth * 2 + 92,
                          height: phoneHeight + 40,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(width: phoneWidth, child: left),
                              const SizedBox(width: 40),
                              SizedBox(width: phoneWidth, child: right),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Narrow: horizontally scrollable
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: phoneWidth, child: left),
                        const SizedBox(width: 40),
                        SizedBox(width: phoneWidth, child: right),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Footer
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 8, 28, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: kShowEmerald, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "Designed in Figma style · 8K crisp · Dark mode aesthetic",
                    style: TextStyle(color: kShowSub, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A reusable phone mockup frame
class PhoneMockup extends StatelessWidget {
  final String title;
  final String label;
  final Widget child;

  const PhoneMockup({
    super.key,
    required this.title,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Phone label
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kShowEmerald.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kShowEmerald.withOpacity(0.3)),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: kShowEmerald,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Phone bezel
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(38),
            border: Border.all(color: const Color(0xFF3A3A3A), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 30,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: kShowSurface,
              child: Stack(
                children: [
                  Positioned.fill(child: child),
                  // Notch
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 90,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.circle,
                            size: 9,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ================= LEFT SCREEN: AI SMART PRICING =================

class AISmartPricingPanel extends StatelessWidget {
  const AISmartPricingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kShowBg,
      padding: const EdgeInsets.only(top: 38, left: 14, right: 14, bottom: 14),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: kShowEmerald, size: 18),
                SizedBox(width: 8),
                Text(
                  "AI Smart Pricing",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3-step progress bar
            const Row(
              children: [
                _StepDot(active: true, label: "Crop"),
                _StepLine(active: true),
                _StepDot(active: true, label: "Analyze"),
                _StepLine(active: true),
                _StepDot(active: true, label: "Price"),
              ],
            ),
            const SizedBox(height: 18),

            // Crop summary card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kShowCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kShowBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                      image: const DecorationImage(
                        image: AssetImage('assets/crops/tomato.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tomato",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Vegetable · High Quality",
                        style: TextStyle(color: kShowSub, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: kShowEmerald.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.eco, color: kShowMint, size: 13),
                        SizedBox(width: 4),
                        Text(
                          "Organic",
                          style: TextStyle(
                            color: kShowMint,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2x2 price metrics grid
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: "Suggested Price",
                    value: "₹42",
                    unit: "/Kg",
                    icon: Icons.auto_graph_rounded,
                    color: kShowEmerald,
                    highlight: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: "Market Price",
                    value: "₹39",
                    unit: "/Kg",
                    icon: Icons.storefront_rounded,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: "Min Selling Price",
                    value: "₹30",
                    unit: "/Kg",
                    icon: Icons.sell_outlined,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: "Expected Profit",
                    value: "₹18",
                    unit: "/Kg",
                    icon: Icons.trending_up_rounded,
                    color: Colors.lightGreenAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Market insight badges
            const Row(
              children: [
                _InsightBadge(
                  icon: Icons.local_fire_department_rounded,
                  label: "Demand",
                  value: "High",
                  color: Color(0xFFFF7043),
                ),
                SizedBox(width: 10),
                _InsightBadge(
                  icon: Icons.inventory_2_outlined,
                  label: "Supply",
                  value: "Medium",
                  color: kShowMint,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _InsightBadge(
                    icon: Icons.show_chart_rounded,
                    label: "Trend",
                    value: "↑ 4.2%",
                    color: Colors.amberAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Price line graph
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kShowCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kShowBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        "Price Trend",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Text(
                        "Last 7 days",
                        style: TextStyle(color: kShowSub, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 70,
                    child: CustomPaint(
                      painter: _LineGraphPainter(),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3-day forecast
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kShowCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kShowBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "3-Day Price Forecast",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _ForecastBar(day: "Today", price: "₹42", value: 0.85),
                      _ForecastBar(day: "Tmrw", price: "₹44", value: 1.0),
                      _ForecastBar(day: "Day 3", price: "₹43", value: 0.9),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // AI insights
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kShowCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kShowBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AI Insights",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 10),
                  _InsightRow(text: "93% confidence on suggested price"),
                  SizedBox(height: 8),
                  _InsightRow(text: "Best time to sell: this weekend"),
                  SizedBox(height: 8),
                  _InsightRow(text: "0% middleman commission applied"),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Dual action buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: kShowEmerald,
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 18, color: Colors.black),
                          SizedBox(width: 6),
                          Text(
                            "Apply Price",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kShowBorder),
                    ),
                    child: const Center(
                      child: Text(
                        "Regenerate",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  final String label;
  const _StepDot({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: active ? kShowEmerald : kShowSub,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : kShowSub,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool active;
  const _StepLine({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: active ? kShowEmerald.withOpacity(0.5) : kShowBorder,
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool highlight;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? kShowEmerald.withOpacity(0.1) : kShowCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? kShowEmerald.withOpacity(0.35) : kShowBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const Spacer(),
              if (highlight)
                const Icon(Icons.star, color: Colors.amber, size: 14),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: highlight ? kShowEmerald : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                unit,
                style: const TextStyle(color: kShowSub, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: kShowSub, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _InsightBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: kShowSub, fontSize: 9),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String text;
  const _InsightRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded, color: kShowEmerald, size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
        ),
      ],
    );
  }
}

class _ForecastBar extends StatelessWidget {
  final String day;
  final String price;
  final double value;
  const _ForecastBar({required this.day, required this.price, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            price,
            style: const TextStyle(
              color: kShowEmerald,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 46,
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 18,
              height: 46 * value,
decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kShowEmerald, const Color(0x3300E676)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(day, style: const TextStyle(color: kShowSub, fontSize: 10)),
        ],
      ),
    );
  }
}

class _LineGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = kShowBorder.withOpacity(0.5)
      ..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[
      Offset(0, size.height * 0.75),
      Offset(size.width * 0.15, size.height * 0.55),
      Offset(size.width * 0.3, size.height * 0.65),
      Offset(size.width * 0.45, size.height * 0.38),
      Offset(size.width * 0.6, size.height * 0.5),
      Offset(size.width * 0.75, size.height * 0.22),
      Offset(size.width * 0.9, size.height * 0.32),
      Offset(size.width, size.height * 0.12),
    ];

    // fill
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(points.last.dx, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            kShowEmerald.withOpacity(0.35),
            kShowEmerald.withOpacity(0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    // line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = kShowEmerald
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // end dot glow
    canvas.drawCircle(
      points.last,
      4,
      Paint()..color = kShowEmerald,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= RIGHT SCREEN: MY PRODUCTS =================

class MyProductsPanel extends StatelessWidget {
  const MyProductsPanel({super.key});

static const List<_ProductData> _products = [
    _ProductData(
      name: "Tomatoes",
      image: 'assets/crops/tomato.png',
      price: "₹42/kg",
      quality: "Premium",
      time: "2 hrs ago",
      status: 'Available',
      thumbColor: Color(0x33E53935),
    ),
    _ProductData(
      name: "Green Chilli",
      image: 'assets/crops/chilli.png',
      price: "₹65/kg",
      quality: "Fresh",
      time: "5 hrs ago",
      status: 'Available',
      thumbColor: Color(0x334CAF50),
    ),
    _ProductData(
      name: "Onion",
      image: 'assets/crops/onion.png',
      price: "₹32/kg",
      quality: "Medium",
      time: "Yesterday",
      status: 'Sold Out',
      thumbColor: Color(0x33FF9800),
    ),
    _ProductData(
      name: "Carrot",
      image: 'assets/crops/carrot.png',
      price: "₹48/kg",
      quality: "Premium",
      time: "2 days ago",
      status: 'Available',
      thumbColor: Color(0x33FF7043),
    ),
  ];

  static const String available = 'Available';
  static const String soldOut = 'Sold Out';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kShowBg,
      padding: const EdgeInsets.only(top: 38, left: 14, right: 14, bottom: 14),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + location
            const Row(
              children: [
                Expanded(
                  child: Text(
                    "My Products",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _LocationChip(),
              ],
            ),
            const SizedBox(height: 14),

            // Metric summary cards
            const Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: "Active",
                    value: "12",
                    icon: Icons.inventory_2_rounded,
                    color: kShowEmerald,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: "Revenue",
                    value: "₹48K",
                    icon: Icons.currency_rupee_rounded,
                    color: Colors.orangeAccent,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: "Orders",
                    value: "86",
                    icon: Icons.shopping_bag_rounded,
                    color: Colors.lightBlueAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Add new product button
            Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kShowEmerald, kShowMint],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kShowEmerald.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Add New Product",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Tab toggles
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: kShowCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: _TabPill(label: "My Listings", active: true),
                  ),
                  Expanded(
                    child: _TabPill(label: "Sold Out", active: false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Product list
            ..._products.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ProductCard(data: p),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kShowCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kShowBorder),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, color: kShowEmerald, size: 14),
          SizedBox(width: 4),
          Text(
            "Coimbatore",
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Icon(Icons.arrow_drop_down, color: kShowSub, size: 16),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kShowCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kShowBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: const TextStyle(color: kShowSub, fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool active;
  const _TabPill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: active ? kShowEmerald : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: active ? Colors.black : Colors.white60,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic data;
  const _ProductCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = data.status == MyProductsPanel.available;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kShowCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kShowBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: data.thumbColor,
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: AssetImage(data.image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? kShowEmerald.withOpacity(0.12)
                            : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data.status,
                        style: TextStyle(
                          color: isAvailable ? kShowMint : Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: kShowEmerald.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data.price,
                        style: const TextStyle(
                          color: kShowEmerald,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 10, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            data.quality,
                            style: TextStyle(
                              color: Colors.amber[200],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.schedule, color: kShowSub, size: 11),
                    const SizedBox(width: 4),
                    Text(
                      data.time,
                      style: const TextStyle(color: kShowSub, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductData {
  final String name;
  final String image;
  final String price;
  final String quality;
  final String time;
  final String status;
  final Color thumbColor;

  const _ProductData({
    required this.name,
    required this.image,
    required this.price,
    required this.quality,
    required this.time,
    required this.status,
    required this.thumbColor,
  });
}

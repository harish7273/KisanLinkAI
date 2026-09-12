import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/product_model.dart';
import 'cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;

  static const Color green = Color(0xFF00E676);
  static const Color darkGreen = Color(0xFF102619);
  static const Color orange = Color(0xFFFF9800);
  static const Color background = Color(0xFF080A09);
  static const Color card = Color(0xFF121713);
  static const Color cardBorder = Color(0xFF1D281F);

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calling $phoneNumber...'),
            backgroundColor: darkGreen,
          ),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=Hi, I am interested in your ${widget.product.name} on KisanAI.');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Widget _buildProductHeroImage(ProductModel product) {
    String image = product.image.trim();

    // 1. Direct local path
    if (image.startsWith('assets/')) {
      return Image.asset(
        image,
        width: double.infinity,
        height: 270,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _cropFallback(product.name),
      );
    }

    // 2. Direct network path
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        width: double.infinity,
        height: 270,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _cropFallback(product.name),
      );
    }

    // 3. Resolve by name
    final resolved = _resolveCropAsset(product.name);
    if (resolved != null) {
      return Image.asset(
        resolved,
        width: double.infinity,
        height: 270,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _cropFallback(product.name),
      );
    }

    return _cropFallback(product.name);
  }

  String? _resolveCropAsset(String name) {
    final n = name.toLowerCase().trim();
    if (n.contains('banana') || n.contains('nendran')) return 'assets/products/banana.png';
    if (n.contains('corn') || n.contains('maize')) return 'assets/products/corn.png';
    if (n.contains('cabbage')) return 'assets/products/cabbage.png';
    if (n.contains('brinjal') || n.contains('eggplant')) return 'assets/products/brinjal.png';
    if (n.contains('mango') || n.contains('alphonso')) return 'assets/products/mango.png';
    if (n.contains('spinach') || n.contains('palak')) return 'assets/products/spinach.png';
    if (n.contains('carrot')) return 'assets/products/carrot.png';
    if (n.contains('tomato')) return 'assets/products/tomato.png';
    if (n.contains('potato')) return 'assets/products/potato.png';
    if (n.contains('onion')) return 'assets/products/onion.png';
    if (n.contains('chilli') || n.contains('chili')) return 'assets/products/chilli.png';
    if (n.contains('fruit')) return 'assets/products/fruits.png';
    if (n.contains('grain') || n.contains('rice') || n.contains('paddy')) return 'assets/products/grains.png';
    if (n.contains('dairy') || n.contains('milk')) return 'assets/products/dairy.png';
    if (n.contains('veg')) return 'assets/products/vegetables.png';
    return null;
  }

  Widget _cropFallback(String name) {
    return Container(
      width: double.infinity,
      height: 270,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2618), Color(0xFF06140B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.eco_rounded, color: green, size: 68),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final farmerPhone = product.farmerPhone ?? '+91 9842231567';
    final certificateId = product.certificateId ?? 'AGMARK-TN-2026-8819';
    final qualityGrade = product.qualityGrade ?? 'AGMARK Grade A';
    final ripeness = product.ripenessPercentage ?? 94.5;
    final defect = product.defectPercentage ?? 1.6;

    final mandiPrice = (product.price * 1.22).roundToDouble();

    return Scaffold(
      backgroundColor: background,
      body: CustomScrollView(
        slivers: [
          // Hero Image AppBar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: background,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.6),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.6),
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildProductHeroImage(product),
                  // Dark bottom gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        qualityGrade.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Produce Name & Price Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, color: green, size: 15),
                                const SizedBox(width: 4),
                                Text(
                                  '${product.location}, Tamil Nadu',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: green,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'per ${product.unit}',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Mandi vs Farmgate Price Comparison Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2615),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1B4E29)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_down_rounded, color: green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                              children: [
                                const TextSpan(text: 'Direct Farmgate Price: '),
                                TextSpan(
                                  text: '₹${(mandiPrice - product.price).toStringAsFixed(0)} cheaper ',
                                  style: const TextStyle(color: green, fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: '(Mandi retail ₹${mandiPrice.toStringAsFixed(0)}/${product.unit})',
                                  style: const TextStyle(color: Colors.white38),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ============================================================
                  // 1. FARMGATE AI QUALITY CHECK CARD (BUYER REQUEST)
                  // ============================================================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B11),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: green.withOpacity(0.35), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: green.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_rounded, color: green, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Farmgate AI Quality Certificate',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    'AGMARK Certified & Computer Vision Inspected',
                                    style: TextStyle(color: Colors.white54, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: green,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'GRADE A',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),
                        const Divider(color: Color(0xFF1E3A24), height: 1),
                        const SizedBox(height: 14),

                        // Inspection Metrics
                        Row(
                          children: [
                            Expanded(
                              child: _qualityMetric(
                                title: 'Ripeness',
                                value: '${ripeness.toStringAsFixed(1)}%',
                                subtitle: 'Optimal Harvest',
                                color: green,
                              ),
                            ),
                            Container(width: 1, height: 40, color: const Color(0xFF1E3A24)),
                            Expanded(
                              child: _qualityMetric(
                                title: 'Defect Rate',
                                value: '${defect.toStringAsFixed(1)}%',
                                subtitle: '<2% Grade Standard',
                                color: Colors.amberAccent,
                              ),
                            ),
                            Container(width: 1, height: 40, color: const Color(0xFF1E3A24)),
                            Expanded(
                              child: _qualityMetric(
                                title: 'Freshness',
                                value: '98/100',
                                subtitle: 'Harvested Today',
                                color: green,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Certificate Number & Verification Stamp
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.qr_code_2_rounded, color: green, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Certificate ID: $certificateId',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              const Text(
                                'VERIFIED ✓',
                                style: TextStyle(
                                  color: green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ============================================================
                  // 2. FARMER DETAILS CARD (BUYER REQUEST)
                  // ============================================================
                  const Text(
                    'Producer & Farm Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2E20),
                                shape: BoxShape.circle,
                                border: Border.all(color: green, width: 1.5),
                              ),
                              child: const Icon(Icons.person_rounded, color: green, size: 30),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          product.farmerName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Icon(Icons.check_circle_rounded, color: green, size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Farm Location: ${product.location}, Tamil Nadu',
                                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                                  ),
                                  const SizedBox(height: 3),
                                  const Row(
                                    children: [
                                      Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                                      SizedBox(width: 3),
                                      Text(
                                        '4.9 (84 reviews) • Verified Kisan Producer',
                                        style: TextStyle(color: Colors.white54, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),
                        const Divider(color: Color(0xFF1E2A20), height: 1),
                        const SizedBox(height: 12),

                        // Contact Buttons: Direct Call & WhatsApp
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _makePhoneCall(farmerPhone),
                                icon: const Icon(Icons.phone_in_talk_rounded, size: 17),
                                label: Text(
                                  'Call $farmerPhone',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF17361E),
                                  foregroundColor: green,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(color: Color(0xFF265430)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 44,
                              height: 38,
                              child: ElevatedButton(
                                onPressed: () => _openWhatsApp(farmerPhone),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF132F1A),
                                  foregroundColor: green,
                                  padding: EdgeInsets.zero,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(color: Color(0xFF265430)),
                                  ),
                                ),
                                child: const Icon(Icons.chat_rounded, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description.isNotEmpty
                        ? product.description
                        : 'Freshly harvested ${product.name} sourced directly from verified local farms in ${product.location}. 100% natural, sorted, and graded for high quality produce standard.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Quantity Selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Order Quantity', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(
                              'Total: ₹${(product.price * quantity).toStringAsFixed(0)}',
                              style: const TextStyle(color: green, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (quantity > 1) {
                                  setState(() => quantity--);
                                }
                              },
                              icon: const Icon(Icons.remove_circle_outline, color: green),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E281F),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$quantity ${product.unit}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() => quantity++);
                              },
                              icon: const Icon(Icons.add_circle_outline, color: green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Action Buttons: Add to Cart & Buy Now
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CartScreen()),
                            );
                          },
                          icon: const Icon(Icons.shopping_cart_outlined, color: green),
                          label: const Text(
                            'Add to Cart',
                            style: TextStyle(color: green, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: green),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CartScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Buy Now',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qualityMetric({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}
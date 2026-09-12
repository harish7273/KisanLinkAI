import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/data_seed_service.dart';
import '../services/language_service.dart';

class FarmerAnalyticsScreen extends StatefulWidget {
  const FarmerAnalyticsScreen({super.key});

  @override
  State<FarmerAnalyticsScreen> createState() => _FarmerAnalyticsScreenState();
}

class _FarmerAnalyticsScreenState extends State<FarmerAnalyticsScreen> {
  static const Color green = Color(0xFF22C55E);
  static const Color background = Color(0xFF0B0B0B);
  static const Color card = Color(0xFF151816);
  static const Color cardLight = Color(0xFF1E2420);

  @override
  void initState() {
    super.initState();
    LanguageService.currentLocaleNotifier.addListener(_onLocaleChanged);
    _ensureFarmerData();
  }

  @override
  void dispose() {
    LanguageService.currentLocaleNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _ensureFarmerData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await DataSeedService.ensureFarmerDataSeeded(
        farmerUid: user.uid,
        farmerName: user.displayName ?? 'Farmer',
        phone: user.phoneNumber,
      );
    }
  }

  bool _belongsToFarmer(Map<String, dynamic> order, String farmerUid) {
    final topLevelFarmerId = order['farmerId']?.toString().trim() ?? '';
    if (topLevelFarmerId == farmerUid) return true;
    final items = order['items'];
    if (items is List) {
      for (final item in items) {
        if (item is Map && item['farmerId']?.toString().trim() == farmerUid) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr('analytics', defaultText: 'Analytics & Insights'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: uid.isEmpty
          ? Center(
              child: Text(
                tr('unable_to_load_orders'),
                style: const TextStyle(color: Colors.white54),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .snapshots(),
              builder: (context, ordersSnap) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .where('farmerId', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, productsSnap) {
                    if (ordersSnap.connectionState == ConnectionState.waiting &&
                        !ordersSnap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: green),
                      );
                    }

                    final allOrderDocs = ordersSnap.data?.docs ?? [];
                    final productDocs = productsSnap.data?.docs ?? [];

                    // Filter orders belonging to this farmer
                    final orderDocs = allOrderDocs.where((doc) {
                      return _belongsToFarmer(doc.data(), uid);
                    }).toList();

                    double totalRevenue = 0.0;
                    int completedOrders = 0;
                    int activeOrders = 0;
                    final Set<String> uniqueBuyers = {};
                    final Map<String, double> cropSalesKg = {};
                    final Map<String, double> cropRevenue = {};

                    for (final doc in orderDocs) {
                      final d = doc.data();
                      final total = (d['orderTotal'] ?? d['totalAmount'] ?? d['amount'] ?? 0);
                      final totalVal = total is num ? total.toDouble() : (double.tryParse('$total') ?? 0.0);

                      final status = (d['orderStatus'] ?? '').toString().toLowerCase();
                      final isCompleted = status == 'delivered' || status == 'completed';
                      final isCancelled = status == 'cancelled';

                      if (isCompleted) {
                        completedOrders++;
                        totalRevenue += totalVal;
                      } else if (!isCancelled) {
                        activeOrders++;
                      }

                      final buyerId = d['buyerId']?.toString() ?? d['buyerName']?.toString() ?? '';
                      if (buyerId.isNotEmpty) {
                        uniqueBuyers.add(buyerId);
                      }

                      // Crop items aggregation
                      final items = d['items'] as List<dynamic>? ?? [];
                      for (final it in items) {
                        if (it is Map<String, dynamic>) {
                          final cName = it['name']?.toString() ?? it['cropName']?.toString() ?? 'Produce';
                          final qtyNum = it['quantity'];
                          final qtyVal = qtyNum is num ? qtyNum.toDouble() : (double.tryParse('$qtyNum') ?? 1.0);
                          final itemTotalNum = it['itemTotal'];
                          final itemTotalVal = itemTotalNum is num
                              ? itemTotalNum.toDouble()
                              : (double.tryParse('$itemTotalNum') ?? 0.0);

                          cropSalesKg[cName] = (cropSalesKg[cName] ?? 0.0) + qtyVal;
                          cropRevenue[cName] = (cropRevenue[cName] ?? 0.0) + itemTotalVal;
                        }
                      }
                    }

                    // Fallback top crops if order items not recorded yet: use farmer products
                    if (cropSalesKg.isEmpty) {
                      for (final p in productDocs) {
                        final data = p.data();
                        final pName = data['name']?.toString() ?? 'Produce';
                        final pQty = data['quantity'];
                        final pVal = pQty is num ? pQty.toDouble() : (double.tryParse('$pQty') ?? 10.0);
                        cropSalesKg[pName] = pVal;
                      }
                    }

                    final sortedCrops = cropSalesKg.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    final formattedRevenue = totalRevenue >= 100000
                        ? '₹${(totalRevenue / 100000).toStringAsFixed(1)}L'
                        : totalRevenue >= 1000
                            ? '₹${(totalRevenue / 1000).toStringAsFixed(1)}K'
                            : '₹${totalRevenue.toStringAsFixed(0)}';

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top 4 Stat Grid Cards
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: tr('today_earnings', defaultText: 'Revenue'),
                                  value: formattedRevenue,
                                  subtitle: '$completedOrders ${tr('completed')}',
                                  icon: Icons.currency_rupee_rounded,
                                  color: const Color(0xFF22C55E),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: tr('all_orders', defaultText: 'Orders'),
                                  value: '${orderDocs.length}',
                                  subtitle: '$activeOrders ${tr('in_progress')}',
                                  icon: Icons.shopping_bag_rounded,
                                  color: const Color(0xFFFF9800),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: tr('Products', defaultText: 'Produce Listed'),
                                  value: '${productDocs.length}',
                                  subtitle: tr('direct_from_origin', defaultText: 'Active Listings'),
                                  icon: Icons.eco_rounded,
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: tr('buyer', defaultText: 'Customers'),
                                  value: '${uniqueBuyers.length}',
                                  subtitle: tr('verified_driver', defaultText: 'Direct Buyers'),
                                  icon: Icons.people_alt_rounded,
                                  color: const Color(0xFFA855F7),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Top Selling Crops Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.trending_up_rounded,
                                      color: green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      tr('Produce', defaultText: 'Top Selling Produce'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tr('direct_delivery_desc', defaultText: 'Breakdown of farm sales volume and performance'),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                if (sortedCrops.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    child: Center(
                                      child: Text(
                                        tr('no_orders', defaultText: 'No sales data yet'),
                                        style: const TextStyle(color: Colors.white38),
                                      ),
                                    ),
                                  )
                                else
                                  ...sortedCrops.take(5).map((entry) {
                                    final cropName = entry.key;
                                    final kg = entry.value;
                                    final rev = cropRevenue[cropName] ?? 0.0;
                                    final emoji = _cropEmoji(cropName);

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: cardLight,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.05),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(emoji, style: const TextStyle(fontSize: 24)),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tr(cropName),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${kg.toStringAsFixed(0)} kg ${tr('completed', defaultText: 'fulfilled')}',
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (rev > 0)
                                            Text(
                                              '₹${rev.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                color: green,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  static String _cropEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('mango')) return '🥭';
    if (n.contains('tomato')) return '🍅';
    if (n.contains('banana')) return '🍌';
    if (n.contains('corn') || n.contains('maize')) return '🌽';
    if (n.contains('carrot')) return '🥕';
    if (n.contains('potato')) return '🥔';
    if (n.contains('onion')) return '🧅';
    if (n.contains('chilli') || n.contains('chili')) return '🌶️';
    if (n.contains('brinjal') || n.contains('eggplant')) return '🍆';
    if (n.contains('cabbage')) return '🥬';
    if (n.contains('spinach')) return '🌿';
    if (n.contains('rice') || n.contains('paddy')) return '🌾';
    if (n.contains('wheat')) return '🌾';
    if (n.contains('coconut')) return '🥥';
    if (n.contains('apple')) return '🍎';
    return '🌱';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151816),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.trending_up_rounded, color: color.withValues(alpha: 0.8), size: 16),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
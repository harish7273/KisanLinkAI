import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/order_model.dart';
import 'tracking/buyer_order_details_screen.dart';
import 'tracking/buyer_live_tracking_screen.dart';


// ==================================================================
// PRODUCT IMAGE FROM LOCAL ASSETS
// ==================================================================

Widget buildProductImage(
  String productName, {
  String imageUrl = '',
  double size = 42,
  double radius = 10,
}) {
  final assetPath = _cropAssetForProduct(productName, imageUrl);

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xFFFF9800).withValues(alpha: .07),
      borderRadius: BorderRadius.circular(radius),
    ),
    clipBehavior: Clip.antiAlias,
    child: assetPath != null
        ? Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _cropFallback();
            },
          )
        : _cropFallback(),
  );
}

String? _cropAssetForProduct(
  String productName,
  String imageUrl,
) {
  final name = productName.toLowerCase().trim();

  // If the order already contains a local asset path, use it.
  if (imageUrl.startsWith('assets/products/')) {
    return imageUrl;
  }

  if (name.contains('carrot')) {
    return 'assets/products/carrot.png';
  }

  if (name.contains('tomato')) {
    return 'assets/products/tomato.png';
  }

  if (name.contains('potato')) {
    return 'assets/products/potato.png';
  }

  if (name.contains('onion')) {
    return 'assets/products/onion.png';
  }

  if (name.contains('chilli') ||
      name.contains('chili')) {
    return 'assets/products/chilli.png';
  }

  return null;
}

Widget _cropFallback() {
  return Container(
    color: const Color(0xFFFF9800).withValues(alpha: .07),
    alignment: Alignment.center,
    child: Icon(
      Icons.eco_rounded,
      color: const Color(0xFFFF9800).withValues(alpha: .65),
      size: 20,
    ),
  );
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {

  static const Color green = Color(0xFF20E85A);
  static const Color yellow = Color(0xFFFFB800);
  static const Color background = Color(0xFF05090A);
  static const Color card = Color(0xFF0B1212);
  static const Color cardLight = Color(0xFF121A1A);
  static const Color muted = Color(0xFF929999);

  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(
          child: Text(
            'Please login to view your orders.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _ordersList(context, user.uid)),
            _bottomNavigation(context),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MAIN ORDERS LIST
  // ============================================================

  Widget _ordersList(BuildContext context, String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorState(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: green,
              strokeWidth: 2.5,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Column(
            children: [
              _header(
                allCount: 0,
                ongoingCount: 0,
                deliveredCount: 0,
                cancelledCount: 0,
              ),
              Expanded(child: _emptyState()),
            ],
          );
        }

        final sortedDocs = [...docs]..sort((a, b) {
            final aTime = _timestampValue(a.data()['createdAt']);
            final bTime = _timestampValue(b.data()['createdAt']);
            return bTime.compareTo(aTime);
          });

        final ongoingDocs = sortedDocs.where((doc) {
          final status =
              doc.data()['orderStatus']?.toString().toLowerCase().trim() ?? '';
          return status != 'delivered' &&
              status != 'completed' &&
              status != 'cancelled';
        }).toList();

        final deliveredDocs = sortedDocs.where((doc) {
          final status =
              doc.data()['orderStatus']?.toString().toLowerCase().trim() ?? '';
          return status == 'delivered' || status == 'completed';
        }).toList();

        final cancelledDocs = sortedDocs.where((doc) {
          final status =
              doc.data()['orderStatus']?.toString().toLowerCase().trim() ?? '';
          return status == 'cancelled';
        }).toList();

        final visibleDocs = selectedTab == 0
            ? sortedDocs
            : selectedTab == 1
                ? ongoingDocs
                : selectedTab == 2
                    ? deliveredDocs
                    : cancelledDocs;

        return Column(
          children: [
            _header(
              allCount: sortedDocs.length,
              ongoingCount: ongoingDocs.length,
              deliveredCount: deliveredDocs.length,
              cancelledCount: cancelledDocs.length,
            ),
            Expanded(
              child: RefreshIndicator(
                color: green,
                backgroundColor: card,
                onRefresh: () async {
                  await Future.delayed(
                    const Duration(milliseconds: 400),
                  );
                },
                child: visibleDocs.isEmpty
                    ? _filteredEmptyState()
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding:
                            const EdgeInsets.fromLTRB(14, 4, 14, 24),
                        itemCount: visibleDocs.length,
                        itemBuilder: (context, index) {
                          final doc = visibleDocs[index];
                          return _orderCard(
                            context,
                            doc.id,
                            doc.data(),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header({
    int allCount = 0,
    int ongoingCount = 0,
    int deliveredCount = 0,
    int cancelledCount = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'My Orders',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF101718),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .08),
                  ),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 27,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'Track and manage your orders',
            style: TextStyle(
              color: muted,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          _filterTabs(
            allCount: allCount,
            ongoingCount: ongoingCount,
            deliveredCount: deliveredCount,
            cancelledCount: cancelledCount,
          ),
        ],
      ),
    );
  }

  Widget _filterTabs({
    required int allCount,
    required int ongoingCount,
    required int deliveredCount,
    required int cancelledCount,
  }) {
    final tabs = [
      'All Orders ($allCount)',
      'Ongoing ($ongoingCount)',
      'Delivered ($deliveredCount)',
      'Cancelled ($cancelledCount)',
    ];

    return SizedBox(
      height: 51,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = selectedTab == index;

          return GestureDetector(
            onTap: () => setState(() => selectedTab = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? green
                    : const Color(0xFF111718),
                borderRadius: BorderRadius.circular(27),
                border: Border.all(
                  color: selected
                      ? green
                      : Colors.white.withValues(alpha: .08),
                ),
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                  color: selected
                      ? Colors.black
                      : const Color(0xFFA5AAAA),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget _orderCard(
    BuildContext context,
    String documentId,
    Map<String, dynamic> order,
  ) {
    final items = _items(order['items']);
    final firstItem = items.isNotEmpty ? items.first : <String, dynamic>{};

    final total = _number(order['totalAmount']);
    final itemTotal = _number(firstItem['itemTotal']);
    final orderStatus =
        order['orderStatus']?.toString() ?? 'Placed';
    final paymentStatus =
        order['paymentStatus']?.toString() ?? 'Pending';
    final paymentMethod =
        order['paymentMethod']?.toString() ?? 'UPI';
    final createdAt = _formatDate(order['createdAt']);

    final normalized = orderStatus.toLowerCase().trim();
    final isDelivered =
        normalized == 'delivered' || normalized == 'completed';
    final isCancelled = normalized == 'cancelled';

    final currentStep = _currentStep(normalized);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BuyerOrderDetailsScreen(
              order: OrderModel.fromMap(order, documentId),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 22),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: Colors.white.withValues(alpha: .10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .30),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // ORDER HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 18, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${documentId.length > 10 ? documentId.substring(0, 10) : documentId}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          createdAt.isEmpty
                              ? 'Recently'
                              : createdAt,
                          style: const TextStyle(
                            color: muted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusChip(orderStatus),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: Colors.white.withValues(alpha: .07),
            ),

            // PRODUCT + TRACKING
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildProductImage(
                    firstItem['name']?.toString() ?? 'Product',
                    imageUrl:
                        firstItem['imageUrl']?.toString() ??
                            firstItem['image']?.toString() ??
                            '',
                    size: 142,
                    radius: 25,
                  ),
                  const SizedBox(width: 17),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                firstItem['name']?.toString() ??
                                    _orderTitle(items),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (firstItem.isNotEmpty)
                              Text(
                                '₹${_price(itemTotal)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          firstItem.isEmpty
                              ? '${items.length} item(s)'
                              : '${firstItem['farmerName']?.toString() ?? 'Farmer'} • ${_quantity(_number(firstItem['quantity']))} ${firstItem['unit']?.toString() ?? 'kg'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: muted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 23),
                        _progressTracker(
                          currentStep: currentStep,
                          placedTime: _formatTime(order['createdAt']),
                          pickedTime: _formatTime(
                            order['pickedUpAt'] ??
                                order['pickedAt'],
                          ),
                          deliveryTime: _formatTime(
                            order['outForDeliveryAt'],
                          ),
                          deliveredTime: _formatTime(
                            order['deliveredAt'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // DELIVERY MESSAGE
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 5, 18, 14),
              child: _deliveryMessage(
                context,
                documentId,
                order,
                isDelivered: isDelivered,
                isCancelled: isCancelled,
              ),
            ),

            // PAYMENT FOOTER
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 14, 17),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .13),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: .06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          color: muted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '₹${_price(total)}',
                        style: const TextStyle(
                          color: yellow,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    height: 52,
                    width: 1,
                    color: Colors.white.withValues(alpha: .18),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paymentMethod,
                          style: const TextStyle(
                            color: muted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              paymentStatus.toLowerCase() == 'paid'
                                  ? Icons.check_circle
                                  : Icons.schedule,
                              color: paymentStatus.toLowerCase() == 'paid'
                                  ? green
                                  : yellow,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                paymentStatus.toLowerCase() == 'paid'
                                    ? 'Payment Paid'
                                    : 'Payment $paymentStatus',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      paymentStatus.toLowerCase() == 'paid'
                                          ? green
                                          : yellow,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BuyerOrderDetailsScreen(
                            order: OrderModel.fromMap(order, documentId),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12191A),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .11),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 7),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 23,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _statusChip(String status) {
    final normalized = status.toLowerCase().trim();

    Color color = yellow;
    IconData icon = Icons.schedule_rounded;

    if (normalized == 'delivered' ||
        normalized == 'completed') {
      color = green;
      icon = Icons.check_circle_rounded;
    } else if (normalized == 'out for delivery') {
      color = yellow;
      icon = Icons.local_shipping_rounded;
    } else if (normalized == 'cancelled') {
      color = Colors.redAccent;
      icon = Icons.cancel_rounded;
    } else if (normalized == 'accepted') {
      color = green;
      icon = Icons.check_rounded;
    } else if (normalized == 'preparing' ||
        normalized == 'packed') {
      color = yellow;
      icon = Icons.inventory_2_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withValues(alpha: .60),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 7),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROGRESS TRACKER
  // ============================================================

  Widget _progressTracker({
    required int currentStep,
    required String placedTime,
    required String pickedTime,
    required String deliveryTime,
    required String deliveredTime,
  }) {
    final titles = [
      'Order\nPlaced',
      'Picked Up',
      'Out for\nDelivery',
      'Delivered',
    ];

    final times = [
      placedTime,
      pickedTime,
      deliveryTime,
      deliveredTime,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final stepWidth = constraints.maxWidth / 4;

        return SizedBox(
          height: 99,
          child: Stack(
            children: [
              Positioned(
                top: 13,
                left: stepWidth / 2,
                right: stepWidth / 2,
                child: Row(
                  children: List.generate(3, (index) {
                    final completed = index < currentStep;
                    return Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: completed
                              ? green
                              : const Color(0xFF4A5253),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Row(
                children: List.generate(4, (index) {
                  final completed = index <= currentStep;
                  final active = index == currentStep;

                  return SizedBox(
                    width: stepWidth,
                    child: Column(
                      children: [
                        Container(
                          width: 29,
                          height: 29,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active
                                ? const Color(0xFF07110B)
                                : completed
                                    ? green
                                    : const Color(0xFF12191A),
                            border: Border.all(
                              color: completed
                                  ? green
                                  : const Color(0xFF596164),
                              width: active ? 4 : 3,
                            ),
                          ),
                          child: completed && !active
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.black,
                                  size: 17,
                                )
                              : active
                                  ? Container(
                                      margin: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: green,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          titles[index],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          times[index].isEmpty ? '--:--' : times[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: active ? green : muted,
                            fontSize: 11,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  int _currentStep(String status) {
    final s = status.toLowerCase().trim();
    switch (s) {
      case 'picked up':
        return 1;
      case 'out for delivery':
        return 2;
      case 'delivered':
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }

  // ============================================================
  // DELIVERY MESSAGE
  // ============================================================

  Widget _deliveryMessage(
    BuildContext context,
    String documentId,
    Map<String, dynamic> order, {
    required bool isDelivered,
    required bool isCancelled,
  }) {
    if (isCancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(19),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.cancel_rounded,
              color: Colors.redAccent,
              size: 30,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This order has been cancelled.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10231B),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          Container(
            width: 51,
            height: 51,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: green.withValues(alpha: .16),
            ),
            child: Icon(
              isDelivered
                  ? Icons.check_circle
                  : Icons.delivery_dining,
              color: green,
              size: 29,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDelivered
                      ? 'Order delivered successfully!'
                      : 'Your order is on the way!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDelivered
                      ? 'Thank you for shopping with us.'
                      : 'Our delivery partner is bringing your order.',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (isDelivered) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Items from this order added to your cart!'),
                    backgroundColor: green,
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BuyerLiveTrackingScreen(
                      order: OrderModel.fromMap(order, documentId),
                    ),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                color: isDelivered
                    ? Colors.transparent
                    : green,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: green,
                  width: 1.3,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDelivered
                        ? Icons.refresh
                        : Icons.location_on,
                    color: isDelivered ? green : Colors.black,
                    size: 19,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isDelivered ? 'Reorder' : 'Live Tracking',
                    style: TextStyle(
                      color: isDelivered ? green : Colors.black,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _bottomNavigation(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.storefront_rounded, 'Market'),
      (Icons.shopping_cart_rounded, 'Cart'),
      (Icons.receipt_long_rounded, 'Orders'),
      (Icons.person_rounded, 'Profile'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 5, 14, 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF101516),
        borderRadius: BorderRadius.circular(31),
        border: Border.all(
          color: Colors.white.withValues(alpha: .10),
        ),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final selected = index == 3;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!selected) {
                  _snack(
                    context,
                    '${items[index].$2} navigation is handled by your app shell.',
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF2A2413)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[index].$1,
                      size: 26,
                      color: selected ? yellow : const Color(0xFF9DA3A4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[index].$2,
                      style: TextStyle(
                        color:
                            selected ? yellow : const Color(0xFF9DA3A4),
                        fontSize: 12,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ============================================================
  // CANCEL ORDER
  // ============================================================

  Future<void> _showCancelDialog(
    BuildContext context,
    String orderId,
    Map<String, dynamic> order,
  ) async {
    String selectedReason = 'Ordered by mistake';

    final reasons = [
      'Ordered by mistake',
      'Found a better price',
      'I don’t need it anymore',
      'Delivery taking too long',
      'Other',
    ];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: .10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cancel_outlined,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Cancel Order?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Are you sure you want to cancel this order?',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Reason',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    ...reasons.map((reason) {
                      final selected = selectedReason == reason;

                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedReason = reason;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? yellow.withValues(alpha: .08)
                                : cardLight,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: selected
                                  ? yellow
                                  : Colors.white.withValues(alpha: .05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 17,
                                height: 17,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? yellow
                                        : Colors.white24,
                                    width: 1.4,
                                  ),
                                  color: selected
                                      ? yellow
                                      : Colors.transparent,
                                ),
                                child: selected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.black,
                                        size: 11,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: TextStyle(
                                    color: selected
                                        ? yellow
                                        : Colors.white70,
                                    fontSize: 8,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    const Text(
                      'For prepaid orders, the order will be marked for refund processing.',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 8,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(
                                color: Colors.white24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            child: const Text(
                              'Keep Order',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              await _cancelOrder(
                                context,
                                orderId,
                                order,
                                selectedReason,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            child: const Text(
                              'Cancel Order',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
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
          },
        );
      },
    );
  }

  Future<void> _cancelOrder(
    BuildContext context,
    String orderId,
    Map<String, dynamic> order,
    String reason,
  ) async {
    try {
      final currentStatus =
          order['orderStatus']?.toString() ?? 'Placed';

      if (!_canCancel(currentStatus)) {
        _snack(
          context,
          'This order can no longer be cancelled.',
        );
        return;
      }

      final paymentMethod =
          order['paymentMethod']?.toString() ?? '';
      final paymentStatus =
          order['paymentStatus']?.toString() ?? '';

      final isPaid =
          paymentMethod == 'UPI' ||
          paymentMethod == 'Card' ||
          paymentStatus == 'Paid';

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'orderStatus': 'Cancelled',
        'paymentStatus': isPaid ? 'Refund Pending' : 'Cancelled',
        'settlementStatus': isPaid ? 'Held' : 'Not Applicable',
        'deliveryStatus': 'Cancelled',
        'disputeStatus': 'None',
        'cancellationReason': reason,
        'cancelledBy': 'Buyer',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      _showCancelledDialog(context, isPaid);
    } catch (e) {
      debugPrint('CANCEL ORDER ERROR: $e');

      if (!context.mounted) return;

      _snack(
        context,
        'Unable to cancel order. Please try again.',
      );
    }
  }

  void _showCancelledDialog(
    BuildContext context,
    bool isPaid,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: .10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.redAccent,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 13),
                const Text(
                  'Order Cancelled',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isPaid
                      ? 'Your payment has been marked for refund processing.'
                      : 'Your order has been cancelled successfully.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 17),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yellow,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
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
  }

  // ============================================================
  // STATES / HELPERS
  // ============================================================

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: green.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: green,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Orders Yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Your confirmed orders will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filteredEmptyState() {
    final messages = [
      ('No Orders Yet', 'Your confirmed orders will appear here.'),
      ('No Ongoing Orders', 'You do not have any active deliveries right now.'),
      ('No Delivered Orders', 'Delivered orders will appear here.'),
      ('No Cancelled Orders', 'Cancelled orders will appear here.'),
    ];

    final message = messages[selectedTab];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        const SizedBox(height: 100),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: .08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: green,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message.$1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  message.$2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorState(String error) {
    return Column(
      children: [
        _header(
          allCount: 0,
          ongoingCount: 0,
          deliveredCount: 0,
          cancelledCount: 0,
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 45,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Unable to load orders',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 8,
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

  bool _canCancel(String status) {
    final normalized = status.toLowerCase();
    return normalized == 'placed' ||
        normalized == 'accepted' ||
        normalized == 'preparing';
  }

  List<Map<String, dynamic>> _items(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _price(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  String _quantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _orderTitle(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return 'FarmDirect Order';
    if (items.length == 1) {
      return items.first['name']?.toString() ?? 'FarmDirect Order';
    }
    return '${items.first['name'] ?? 'Product'} + ${items.length - 1} more';
  }

  DateTime _timestampValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = months[date.month - 1];
      final day = date.day.toString().padLeft(2, '0');

      final hour = date.hour == 0
          ? 12
          : date.hour > 12
              ? date.hour - 12
              : date.hour;

      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';

      return '$day $month ${date.year}, $hour:$minute $period';
    }

    return '';
  }

  String _formatTime(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      final hour = date.hour == 0
          ? 12
          : date.hour > 12
              ? date.hour - 12
              : date.hour;

      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $period';
    }

    return '';
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: card,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ==================================================================
// ORDER DETAILS SCREEN
// ==================================================================

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> order;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.order,
  });

  static const Color orange =
      Color(0xFFFF9800);

  static const Color background =
      Color(0xFF0B0B0B);

  static const Color card =
      Color(0xFF151515);

  static const Color cardLight =
      Color(0xFF1D1D1D);

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        iconTheme:
            const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      // ========================================================
      // LIVE FIRESTORE LISTENER
      // ========================================================

      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: orange,
                strokeWidth: 2.5,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons
                          .error_outline_rounded,
                      color:
                          Colors.redAccent,
                      size: 45,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    const Text(
                      'Unable to load order',
                      style:
                          TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    Text(
                      snapshot.error
                          .toString(),
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color:
                            Colors.white38,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Order no longer exists.',
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),
            );
          }

          // IMPORTANT:
          // Always use the latest Firestore data.
          final liveOrder =
              snapshot.data!.data() ??
                  order;

          return _buildOrderDetails(
            context,
            liveOrder,
          );
        },
      ),
    );
  }

  // ============================================================
  // MAIN ORDER DETAILS
  // ============================================================

  Widget _buildOrderDetails(
    BuildContext context,
    Map<String, dynamic> order,
  ) {
    final items =
        _items(order['items']);

    final total =
        _number(order['totalAmount']);

    final subtotal =
        _number(order['subtotal']);

    final deliveryFee =
        _number(order['deliveryFee']);

    final orderStatus =
        order['orderStatus']
                ?.toString() ??
            'Placed';

    final paymentStatus =
        order['paymentStatus']
                ?.toString() ??
            'Pending';

    final settlementStatus =
        order['settlementStatus']
                ?.toString() ??
            'Held';

    final deliveryStatus =
        order['deliveryStatus']
                ?.toString() ??
            'Pending';

    final canCancel =
        _canCancel(orderStatus);

    return ListView(
      padding:
          const EdgeInsets.all(15),
      physics:
          const BouncingScrollPhysics(),
      children: [

        // ======================================================
        // STATUS HEADER
        // ======================================================

        _orderHeader(
          orderStatus,
        ),

        const SizedBox(height: 12),

        // ======================================================
        // LIVE DELIVERY TRACKING
        // ======================================================

        _trackingSection(
          order,
          orderStatus,
          deliveryStatus,
        ),

        const SizedBox(height: 12),

        // ======================================================
        // PAYMENT PROTECTION
        // ======================================================

        if (settlementStatus ==
                'Held' &&
            orderStatus !=
                'Cancelled')
          _protectedPayment(),

        const SizedBox(height: 12),

        // ======================================================
        // ORDER ITEMS
        // ======================================================

        _section(
          title: 'Order Items',
          child: Column(
            children: items
                .map(
                  (item) =>
                      _detailItem(item),
                )
                .toList(),
          ),
        ),

        const SizedBox(height: 12),

        // ======================================================
        // DELIVERY INFORMATION
        // ======================================================

        _section(
          title: 'Delivery Information',
          child: Column(
            children: [

              _infoRow(
                'Buyer',
                order['buyerName']
                        ?.toString() ??
                    'Buyer',
              ),

              _infoRow(
                'Phone',
                order['buyerPhone']
                        ?.toString() ??
                    '-',
              ),

              _infoRow(
                'Address',
                order[
                            'deliveryAddress']
                        ?.toString() ??
                    '-',
              ),

              if (order['farmerName'] !=
                  null)
                _infoRow(
                  'Farmer',
                  order['farmerName']
                          ?.toString() ??
                      'Farmer',
                ),

              if (order[
                      'deliveryPartnerName'] !=
                  null)
                _infoRow(
                  'Delivery Partner',
                  order[
                              'deliveryPartnerName']
                          ?.toString() ??
                      '-',
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ======================================================
        // PAYMENT
        // ======================================================

        _section(
          title: 'Payment',
          child: Column(
            children: [

              _infoRow(
                'Method',
                order[
                            'paymentMethod']
                        ?.toString() ??
                    '-',
              ),

              _infoRow(
                'Payment',
                paymentStatus,
              ),

              _infoRow(
                'Settlement',
                settlementStatus,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ======================================================
        // ORDER SUMMARY
        // ======================================================

        _section(
          title: 'Order Summary',
          child: Column(
            children: [

              _summaryRow(
                'Subtotal',
                subtotal,
              ),

              _summaryRow(
                'Delivery Fee',
                deliveryFee,
              ),

              const Divider(
                color: Colors.white12,
              ),

              _summaryRow(
                'Total',
                total,
                bold: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        // ======================================================
        // CANCEL BUTTON
        // ======================================================

        if (canCancel)
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                _showCancelDialog(
                  context,
                  orderId,
                  order,
                );
              },
              icon: const Icon(
                Icons.cancel_outlined,
                size: 18,
              ),
              label: const Text(
                'Cancel Order',
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    Colors.redAccent,
                side:
                    const BorderSide(
                  color:
                      Colors.redAccent,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
              ),
            ),
          ),

        // ======================================================
        // CANNOT CANCEL
        // ======================================================

        if (!canCancel &&
            orderStatus ==
                'Out for Delivery')
          _cannotCancelMessage(
            'This order is already out for delivery and cannot be cancelled.',
          ),

        if (!canCancel &&
            orderStatus ==
                'Delivered')
          _cannotCancelMessage(
            'This order has already been delivered.',
          ),

        if (!canCancel &&
            orderStatus ==
                'Completed')
          _cannotCancelMessage(
            'This order has been completed.',
          ),

        // ======================================================
        // CANCELLED
        // ======================================================

        if (orderStatus ==
            'Cancelled')
          _cancelledBanner(
            order,
          ),

        const SizedBox(height: 20),
      ],
    );
  }

  // ============================================================
  // 🚚 LIVE TRACKING
  // ============================================================

  Widget _trackingSection(
    Map<String, dynamic> order,
    String status,
    String deliveryStatus,
  ) {
    final normalized =
        status.toLowerCase().trim();

    final isCancelled =
        normalized == 'cancelled';

    final steps = [
      {
        'title': 'Order Placed',
        'subtitle':
            'Your order has been received',
        'icon':
            Icons.shopping_bag_rounded,
        'active': true,
        'time':
            order['createdAt'],
      },
      {
        'title': 'Order Confirmed',
        'subtitle':
            'Farmer accepted your order',
        'icon':
            Icons.check_circle_outline_rounded,
        'active': _statusReached(
          normalized,
          [
            'accepted',
            'preparing',
            'packed',
            'out for delivery',
            'delivered',
            'completed',
          ],
        ),
        'time':
            order['confirmedAt'],
      },
      {
        'title': 'Preparing',
        'subtitle':
            'Farmer is preparing your order',
        'icon':
            Icons.inventory_2_outlined,
        'active': _statusReached(
          normalized,
          [
            'preparing',
            'packed',
            'out for delivery',
            'delivered',
            'completed',
          ],
        ),
        'time':
            order['preparingAt'],
      },
      {
        'title': 'Packed',
        'subtitle':
            'Your order is ready for delivery',
        'icon':
            Icons.inventory_rounded,
        'active': _statusReached(
          normalized,
          [
            'packed',
            'out for delivery',
            'delivered',
            'completed',
          ],
        ),
        'time':
            order['packedAt'],
      },
      {
        'title': 'Out for Delivery',
        'subtitle':
            'Your order is on the way',
        'icon':
            Icons.local_shipping_rounded,
        'active': _statusReached(
          normalized,
          [
            'out for delivery',
            'delivered',
            'completed',
          ],
        ),
        'time':
            order['outForDeliveryAt'],
      },
      {
        'title': 'Delivered',
        'subtitle':
            'Order delivered successfully',
        'icon':
            Icons.home_rounded,
        'active':
            normalized == 'delivered' ||
            normalized == 'completed',
        'time':
            order['deliveredAt'],
      },
    ];

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              Colors.white.withValues(
            alpha: .07,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          // ====================================================
          // TRACKING HEADER
          // ====================================================

          Row(
            children: [

              Container(
                width: 38,
                height: 38,
                decoration:
                    BoxDecoration(
                  color: orange.withValues(
                    alpha: .10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
                child: const Icon(
                  Icons
                      .local_shipping_rounded,
                  color: orange,
                  size: 20,
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    Text(
                      'Track Your Order',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      'Live delivery status',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),

              // LIVE INDICATOR
              if (!isCancelled)
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors
                        .greenAccent
                        .withValues(
                      alpha: .08,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [

                      Icon(
                        Icons.circle,
                        color:
                            Colors.greenAccent,
                        size: 6,
                      ),

                      SizedBox(width: 5),

                      Text(
                        'LIVE',
                        style: TextStyle(
                          color:
                              Colors.greenAccent,
                          fontSize: 7,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          // ====================================================
          // CANCELLED
          // ====================================================

          if (isCancelled)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(12),
              decoration:
                  BoxDecoration(
                color: Colors.redAccent
                    .withValues(
                  alpha: .07,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                border: Border.all(
                  color: Colors.redAccent
                      .withValues(
                    alpha: .18,
                  ),
                ),
              ),
              child: const Row(
                children: [

                  Icon(
                    Icons.cancel_rounded,
                    color:
                        Colors.redAccent,
                    size: 20,
                  ),

                  SizedBox(width: 9),

                  Expanded(
                    child: Text(
                      'This order has been cancelled.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else

            // ==================================================
            // TIMELINE
            // ==================================================

            Column(
              children: List.generate(
                steps.length,
                (index) {
                  final step =
                      steps[index];

                  return _trackingStep(
                    title:
                        step['title']
                            .toString(),
                    subtitle:
                        step['subtitle']
                            .toString(),
                    icon:
                        step['icon']
                            as IconData,
                    active:
                        step['active'] ==
                            true,
                    last:
                        index ==
                            steps.length - 1,
                    timestamp:
                        step['time'],
                  );
                },
              ),
            ),

          // ====================================================
          // CURRENT STATUS MESSAGE
          // ====================================================

          if (!isCancelled)
            Container(
              width: double.infinity,
              margin:
                  const EdgeInsets.only(
                top: 10,
              ),
              padding:
                  const EdgeInsets.all(11),
              decoration:
                  BoxDecoration(
                color: orange.withValues(
                  alpha: .05,
                ),
                borderRadius:
                    BorderRadius.circular(
                  11,
                ),
              ),
              child: Row(
                children: [

                  const Icon(
                    Icons
                        .info_outline_rounded,
                    color: orange,
                    size: 17,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      _currentStatusMessage(
                        normalized,
                        deliveryStatus,
                      ),
                      style:
                          const TextStyle(
                        color:
                            Colors.white60,
                        fontSize: 8,
                        height: 1.4,
                      ),
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
  // TRACKING STEP
  // ============================================================

  Widget _trackingStep({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool active,
    required bool last,
    dynamic timestamp,
  }) {
    final color =
        active ? orange : Colors.white24;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          // ----------------------------------------------------
          // ICON + LINE
          // ----------------------------------------------------

          SizedBox(
            width: 34,
            child: Column(
              children: [

                Container(
                  width: 30,
                  height: 30,
                  decoration:
                      BoxDecoration(
                    color: active
                        ? orange.withValues(
                            alpha: .12,
                          )
                        : Colors.white
                            .withValues(
                            alpha: .035,
                          ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color,
                      width: 1.4,
                    ),
                  ),
                  child: Icon(
                    active
                        ? Icons.check_rounded
                        : icon,
                    color: color,
                    size: 15,
                  ),
                ),

                if (!last)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin:
                          const EdgeInsets
                              .symmetric(
                        vertical: 4,
                      ),
                      color: active
                          ? orange.withValues(
                              alpha: .45,
                            )
                          : Colors.white12,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 11),

          // ----------------------------------------------------
          // TEXT
          // ----------------------------------------------------

          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.only(
                top: 1,
                bottom: 17,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [

                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: active
                                ? Colors.white
                                : Colors.white38,
                            fontSize: 10,
                            fontWeight: active
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),

                      if (timestamp != null)
                        Text(
                          _formatDate(
                            timestamp,
                          ),
                          style:
                              const TextStyle(
                            color:
                                Colors.white30,
                            fontSize: 7,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: TextStyle(
                      color: active
                          ? Colors.white54
                          : Colors.white24,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS REACHED
  // ============================================================

  bool _statusReached(
    String current,
    List<String> statuses,
  ) {
    return statuses.contains(current);
  }

  // ============================================================
  // CURRENT STATUS MESSAGE
  // ============================================================

  String _currentStatusMessage(
    String status,
    String deliveryStatus,
  ) {
    switch (status) {
      case 'placed':
        return 'Your order has been received and is waiting for farmer confirmation.';

      case 'accepted':
        return 'The farmer has accepted your order and will start preparing it soon.';

      case 'preparing':
        return 'The farmer is currently preparing your fresh products.';

      case 'packed':
        return 'Your order is packed and ready to be handed over for delivery.';

      case 'out for delivery':
        return 'Your order is on the way. Please keep your phone available for the delivery partner.';

      case 'delivered':
      case 'completed':
        return 'Your order has been delivered successfully. Enjoy your fresh products!';

      default:
        if (deliveryStatus
                .toLowerCase() ==
            'cancelled') {
          return 'Delivery for this order has been cancelled.';
        }

        return 'Your order status is being updated.';
    }
  }

  // ============================================================
  // ORDER HEADER
  // ============================================================

  Widget _orderHeader(
    String status,
  ) {
    final color =
        _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(
            alpha: .25,
          ),
        ),
      ),
      child: Row(
        children: [

          Container(
            width: 48,
            height: 48,
            decoration:
                BoxDecoration(
              color:
                  color.withValues(
                alpha: .10,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _statusIcon(status),
              color: color,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                const Text(
                  'Order Status',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w900,
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
  // STATUS COLOR
  // ============================================================

  Color _statusColor(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Colors.greenAccent;

      case 'cancelled':
        return Colors.redAccent;

      case 'out for delivery':
        return Colors.lightBlueAccent;

      case 'preparing':
      case 'packed':
        return Colors.amberAccent;

      case 'accepted':
        return Colors.orangeAccent;

      default:
        return orange;
    }
  }

  // ============================================================
  // STATUS ICON
  // ============================================================

  IconData _statusIcon(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Icons.check_circle_rounded;

      case 'cancelled':
        return Icons.cancel_rounded;

      case 'out for delivery':
        return Icons.local_shipping_rounded;

      case 'preparing':
      case 'packed':
        return Icons.inventory_2_rounded;

      case 'accepted':
        return Icons.check_rounded;

      default:
        return Icons.schedule_rounded;
    }
  }

  // ============================================================
  // PAYMENT PROTECTION
  // ============================================================

  Widget _protectedPayment() {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: orange.withValues(
          alpha: .08,
        ),
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: orange.withValues(
            alpha: .18,
          ),
        ),
      ),
      child: const Row(
        children: [

          Icon(
            Icons.shield_rounded,
            color: orange,
            size: 25,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'Payment Protected\nSettlement will be released after successful delivery confirmation.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 9,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CANNOT CANCEL MESSAGE
  // ============================================================

  Widget _cannotCancelMessage(
    String message,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        top: 12,
      ),
      padding:
          const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: .03,
        ),
        borderRadius:
            BorderRadius.circular(13),
      ),
      child: Row(
        children: [

          const Icon(
            Icons.info_outline_rounded,
            color: Colors.white38,
            size: 18,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 8,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CANCELLED BANNER
  // ============================================================

  Widget _cancelledBanner(
    Map<String, dynamic> order,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        top: 12,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            Colors.redAccent.withValues(
          alpha: .07,
        ),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              Colors.redAccent.withValues(
            alpha: .20,
          ),
        ),
      ),
      child: Row(
        children: [

          const Icon(
            Icons.cancel_rounded,
            color: Colors.redAccent,
            size: 20,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              order['paymentStatus']
                          ?.toString() ==
                      'Refund Pending'
                  ? 'Order cancelled. Refund processing is pending.'
                  : 'Order cancelled successfully.',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 9,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _section({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color:
              Colors.white.withValues(
            alpha: .07,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

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

          const SizedBox(
            height: 12,
          ),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL ITEM
  // ============================================================

  Widget _detailItem(
    Map<String, dynamic> item,
  ) {
    final quantity =
        _number(item['quantity']);

    final total =
        _number(item['itemTotal']);

    final imageUrl =
        item['imageUrl']?.toString() ??
            item['image']?.toString() ??
            '';

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 11,
      ),
      child: Row(
        children: [

          buildProductImage(
            item['name']?.toString() ?? 'Product',
            imageUrl: imageUrl,
            size: 48,
            radius: 12,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  item['name']
                          ?.toString() ??
                      'Product',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Farmer: ${item['farmerName'] ?? 'Farmer'} • ${_quantity(quantity)} ${item['unit'] ?? 'kg'}',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white38,
                    fontSize: 7,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '₹${_price(total)}',
            style:
                const TextStyle(
              color: orange,
              fontSize: 10,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          SizedBox(
            width: 100,
            child: Text(
              title,
              style:
                  const TextStyle(
                color:
                    Colors.white38,
                fontSize: 9,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize: 9,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY ROW
  // ============================================================

  Widget _summaryRow(
    String title,
    double amount, {
    bool bold = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        children: [

          Text(
            title,
            style: TextStyle(
              color: bold
                  ? Colors.white
                  : Colors.white54,
              fontSize:
                  bold ? 12 : 9,
              fontWeight: bold
                  ? FontWeight.w800
                  : FontWeight.w500,
            ),
          ),

          const Spacer(),

          Text(
            '₹${_price(amount)}',
            style: TextStyle(
              color: bold
                  ? orange
                  : Colors.white,
              fontSize:
                  bold ? 15 : 9,
              fontWeight: bold
                  ? FontWeight.w900
                  : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CANCEL DIALOG
  // ============================================================

  Future<void> _showCancelDialog(
    BuildContext context,
    String orderId,
    Map<String, dynamic> order,
  ) async {
    String selectedReason =
        'Ordered by mistake';

    final reasons = [
      'Ordered by mistake',
      'Found a better price',
      'I don’t need it anymore',
      'Delivery taking too long',
      'Other',
    ];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return Dialog(
              backgroundColor: card,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [

                        Container(
                          width: 42,
                          height: 42,
                          decoration:
                              BoxDecoration(
                            color: Colors
                                .redAccent
                                .withValues(
                              alpha: .10,
                            ),
                            shape:
                                BoxShape.circle,
                          ),
                          child:
                              const Icon(
                            Icons
                                .cancel_outlined,
                            color:
                                Colors.redAccent,
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        const Expanded(
                          child: Text(
                            'Cancel Order?',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    const Text(
                      'Are you sure you want to cancel this order?',
                      style: TextStyle(
                        color:
                            Colors.white60,
                        fontSize: 10,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    const Text(
                      'Reason',
                      style: TextStyle(
                        color:
                            Colors.white,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    ...reasons.map(
                      (reason) {
                        final selected =
                            selectedReason ==
                                reason;

                        return GestureDetector(
                          onTap: () {
                            setDialogState(
                              () {
                                selectedReason =
                                    reason;
                              },
                            );
                          },
                          child: Container(
                            margin:
                                const EdgeInsets
                                    .only(
                              bottom: 5,
                            ),
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 9,
                              vertical: 8,
                            ),
                            decoration:
                                BoxDecoration(
                              color: selected
                                  ? orange
                                      .withValues(
                                      alpha: .08,
                                    )
                                  : cardLight,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                9,
                              ),
                              border:
                                  Border.all(
                                color: selected
                                    ? orange
                                    : Colors
                                        .white
                                        .withValues(
                                        alpha:
                                            .05,
                                      ),
                              ),
                            ),
                            child: Row(
                              children: [

                                Container(
                                  width: 17,
                                  height: 17,
                                  decoration:
                                      BoxDecoration(
                                    shape:
                                        BoxShape
                                            .circle,
                                    border:
                                        Border.all(
                                      color: selected
                                          ? orange
                                          : Colors
                                              .white24,
                                      width: 1.4,
                                    ),
                                    color: selected
                                        ? orange
                                        : Colors
                                            .transparent,
                                  ),
                                  child:
                                      selected
                                          ? const Icon(
                                              Icons
                                                  .check_rounded,
                                              color:
                                                  Colors.black,
                                              size: 11,
                                            )
                                          : null,
                                ),

                                const SizedBox(
                                  width: 8,
                                ),

                                Expanded(
                                  child: Text(
                                    reason,
                                    style:
                                        TextStyle(
                                      color: selected
                                          ? orange
                                          : Colors
                                              .white70,
                                      fontSize: 8,
                                      fontWeight:
                                          selected
                                              ? FontWeight
                                                  .w700
                                              : FontWeight
                                                  .w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    const Text(
                      'For prepaid orders, the order will be marked for refund processing.',
                      style: TextStyle(
                        color:
                            Colors.white30,
                        fontSize: 8,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    Row(
                      children: [

                        Expanded(
                          child:
                              OutlinedButton(
                            onPressed: () {
                              Navigator.pop(
                                dialogContext,
                              );
                            },
                            style:
                                OutlinedButton
                                    .styleFrom(
                              foregroundColor:
                                  Colors
                                      .white70,
                              side:
                                  const BorderSide(
                                color:
                                    Colors.white24,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  11,
                                ),
                              ),
                            ),
                            child:
                                const Text(
                              'Keep Order',
                              style:
                                  TextStyle(
                                fontSize: 9,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 9,
                        ),

                        Expanded(
                          child:
                              ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(
                                dialogContext,
                              );

                              await _cancelOrder(
                                context,
                                orderId,
                                order,
                                selectedReason,
                              );
                            },
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  Colors
                                      .redAccent,
                              foregroundColor:
                                  Colors.white,
                              elevation: 0,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  11,
                                ),
                              ),
                            ),
                            child:
                                const Text(
                              'Cancel Order',
                              style:
                                  TextStyle(
                                fontSize: 9,
                                fontWeight:
                                    FontWeight
                                        .w800,
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
          },
        );
      },
    );
  }

  // ============================================================
  // CANCEL ORDER
  // ============================================================

  Future<void> _cancelOrder(
    BuildContext context,
    String orderId,
    Map<String, dynamic> order,
    String reason,
  ) async {
    try {
      final currentStatus =
          order['orderStatus']
                  ?.toString() ??
              'Placed';

      if (!_canCancel(currentStatus)) {
        _snack(
          context,
          'This order can no longer be cancelled.',
        );
        return;
      }

      final paymentMethod =
          order['paymentMethod']
                  ?.toString() ??
              '';

      final paymentStatus =
          order['paymentStatus']
                  ?.toString() ??
              '';

      final isPaid =
          paymentMethod == 'UPI' ||
          paymentMethod == 'Card' ||
          paymentStatus == 'Paid';

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'orderStatus':
            'Cancelled',

        'paymentStatus':
            isPaid
                ? 'Refund Pending'
                : 'Cancelled',

        'settlementStatus':
            isPaid
                ? 'Held'
                : 'Not Applicable',

        'deliveryStatus':
            'Cancelled',

        'disputeStatus':
            'None',

        'cancellationReason':
            reason,

        'cancelledBy':
            'Buyer',

        'cancelledAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!context.mounted) {
        return;
      }

      _showCancelledDialog(
        context,
        isPaid,
      );
    } catch (e) {
      debugPrint(
        'CANCEL ORDER ERROR: $e',
      );

      if (!context.mounted) {
        return;
      }

      _snack(
        context,
        'Unable to cancel order. Please try again.',
      );
    }
  }

  // ============================================================
  // CANCEL SUCCESS
  // ============================================================

  void _showCancelledDialog(
    BuildContext context,
    bool isPaid,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: card,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Padding(
            padding:
                const EdgeInsets.all(22),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [

                Container(
                  width: 68,
                  height: 68,
                  decoration:
                      BoxDecoration(
                    color: Colors
                        .redAccent
                        .withValues(
                      alpha: .10,
                    ),
                    shape:
                        BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons
                        .check_circle_rounded,
                    color:
                        Colors.redAccent,
                    size: 38,
                  ),
                ),

                const SizedBox(
                  height: 13,
                ),

                const Text(
                  'Order Cancelled',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  isPaid
                      ? 'Your payment has been marked for refund processing.'
                      : 'Your order has been cancelled successfully.',
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color:
                        Colors.white54,
                    fontSize: 9,
                    height: 1.5,
                  ),
                ),

                const SizedBox(
                  height: 17,
                ),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                      );
                    },
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          orange,
                      foregroundColor:
                          Colors.black,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 10,
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
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool _canCancel(
    String status,
  ) {
    final normalized =
        status.toLowerCase();

    return normalized == 'placed' ||
        normalized == 'accepted' ||
        normalized == 'preparing';
  }

  List<Map<String, dynamic>> _items(
    dynamic value,
  ) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) =>
              Map<String, dynamic>.from(
            item,
          ),
        )
        .toList();
  }

  double _number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _price(double value) {
    if (value ==
        value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  String _quantity(double value) {
    if (value ==
        value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  String _formatDate(
    dynamic value,
  ) {
    if (value is Timestamp) {
      final date = value.toDate();

      final day =
          date.day.toString().padLeft(
                2,
                '0',
              );

      final month =
          date.month.toString().padLeft(
                2,
                '0',
              );

      final hour =
          date.hour == 0
              ? 12
              : date.hour > 12
                  ? date.hour - 12
                  : date.hour;

      final minute =
          date.minute.toString().padLeft(
                2,
                '0',
              );

      final period =
          date.hour >= 12
              ? 'PM'
              : 'AM';

      return '$day/$month • $hour:$minute $period';
    }

    return '';
  }

  void _snack(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: card,
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }
}
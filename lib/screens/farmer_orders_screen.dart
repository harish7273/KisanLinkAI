import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/order_model.dart';
import 'tracking/buyer_live_tracking_screen.dart';

class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen> {
  // ============================================================
  // THEME
  // ============================================================

  static const Color green = Color(0xFF22C55E);
  static const Color darkGreen = Color(0xFF006B1B);

  static const Color background = Color(0xFF0B0B0B);
  static const Color card = Color(0xFF151515);
  static const Color cardLight = Color(0xFF1D1D1D);

  // ============================================================
  // STATE
  // ============================================================

  int selectedTab = 0;
  String searchText = '';

  final List<String> tabs = const [
    'All Orders',
    'New',
    'In Progress',
    'Completed',
  ];

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(
          child: Text(
            'Please login to view orders.',
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
      appBar: _buildAppBar(),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .snapshots(),
        builder: (context, snapshot) {
          // ------------------------------------------------------
          // LOADING
          // ------------------------------------------------------

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: green,
              ),
            );
          }

          // ------------------------------------------------------
          // ERROR
          // ------------------------------------------------------

          if (snapshot.hasError) {
            return _errorState(
              snapshot.error.toString(),
            );
          }

          // ------------------------------------------------------
          // ALL FIRESTORE ORDERS
          // ------------------------------------------------------

          final allDocs = snapshot.data?.docs ?? [];

          // ======================================================
          // DEBUG
          // ======================================================

          debugPrint('========================================');
          debugPrint('🔥 FARMER ORDERS DEBUG');
          debugPrint('AUTH UID: ${user.uid}');
          debugPrint(
            'TOTAL FIRESTORE ORDERS: ${allDocs.length}',
          );
          debugPrint('========================================');

          for (final doc in allDocs) {
            final data = doc.data();

            debugPrint('----------------------------------------');
            debugPrint('ORDER DOC ID: ${doc.id}');
            debugPrint(
              'TOP LEVEL farmerId: ${data['farmerId']}',
            );
            debugPrint(
              'buyerId: ${data['buyerId']}',
            );
            debugPrint(
              'buyerName: ${data['buyerName']}',
            );
            debugPrint(
              'orderStatus: ${data['orderStatus']}',
            );
            debugPrint(
              'paymentStatus: ${data['paymentStatus']}',
            );

            final items = data['items'];

            debugPrint(
              'ITEMS TYPE: ${items.runtimeType}',
            );

            if (items is List) {
              for (final item in items) {
                if (item is Map) {
                  debugPrint(
                    'ITEM farmerId: ${item['farmerId']}',
                  );
                  debugPrint(
                    'ITEM farmerName: ${item['farmerName']}',
                  );
                  debugPrint(
                    'ITEM name: ${item['name']}',
                  );
                }
              }
            }
          }

          debugPrint('========================================');

          // ======================================================
          // FILTER FOR CURRENT FARMER
          // ======================================================

          final farmerDocs = allDocs.where((doc) {
            return _belongsToFarmer(
              doc.data(),
              user.uid,
            );
          }).toList();

          debugPrint(
            '✅ MATCHED FARMER ORDERS: ${farmerDocs.length}',
          );

          // ======================================================
          // SORT NEWEST FIRST
          // ======================================================

          farmerDocs.sort((a, b) {
            final aDate = _getDate(
              a.data()['createdAt'],
            );

            final bDate = _getDate(
              b.data()['createdAt'],
            );

            return bDate.compareTo(aDate);
          });

          // ======================================================
          // COUNTS
          // ======================================================

          final newCount = farmerDocs.where((doc) {
            final status =
                doc.data()['orderStatus']?.toString() ?? 'Placed';

            return _isNew(status);
          }).length;

          final progressCount = farmerDocs.where((doc) {
            final status =
                doc.data()['orderStatus']?.toString() ?? '';

            return _isInProgress(status);
          }).length;

          final completedCount = farmerDocs.where((doc) {
            final status =
                doc.data()['orderStatus']?.toString() ?? '';

            return _isCompleted(status);
          }).length;

          // ======================================================
          // SEARCH + TAB
          // ======================================================

          final filteredDocs = farmerDocs.where((doc) {
            final order = doc.data();

            final status =
                order['orderStatus']?.toString() ?? 'Placed';

            final buyerName =
                order['buyerName']?.toString() ?? '';

            final orderId =
                order['orderId']?.toString() ?? doc.id;

            final search =
                searchText.trim().toLowerCase();

            final matchesSearch =
                search.isEmpty ||
                buyerName.toLowerCase().contains(search) ||
                orderId.toLowerCase().contains(search) ||
                doc.id.toLowerCase().contains(search);

            if (!matchesSearch) {
              return false;
            }

            switch (selectedTab) {
              case 1:
                return _isNew(status);

              case 2:
                return _isInProgress(status);

              case 3:
                return _isCompleted(status);

              default:
                return true;
            }
          }).toList();

          // ======================================================
          // SCREEN
          // ======================================================

          return Column(
            children: [
              _buildTabs(
                newCount,
                progressCount,
                completedCount,
              ),

              _buildSearch(),

              Expanded(
                child: filteredDocs.isEmpty
                    ? _emptyState(
                        totalOrders: allDocs.length,
                        farmerOrders: farmerDocs.length,
                      )
                    : RefreshIndicator(
                        color: green,
                        backgroundColor: card,
                        onRefresh: () async {
                          await Future.delayed(
                            const Duration(
                              milliseconds: 400,
                            ),
                          );
                        },
                        child: ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(
                            parent:
                                BouncingScrollPhysics(),
                          ),
                          padding:
                              const EdgeInsets.fromLTRB(
                            14,
                            8,
                            14,
                            30,
                          ),
                          children: [
                            if (selectedTab == 0)
                              ..._buildAllSections(
                                filteredDocs,
                              )
                            else ...[
                              _sectionTitle(
                                tabs[selectedTab],
                                filteredDocs.length,
                              ),
                              ...filteredDocs.map(
                                (doc) => _orderCard(
                                  context,
                                  doc,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // IMPORTANT FARMER MATCHING
  // ============================================================

  bool _belongsToFarmer(
    Map<String, dynamic> order,
    String farmerUid,
  ) {
    // ------------------------------------------------------------
    // 1. TOP LEVEL farmerId
    // ------------------------------------------------------------

    final topLevelFarmerId =
        order['farmerId']?.toString().trim() ?? '';

    if (topLevelFarmerId == farmerUid) {
      return true;
    }

    // ------------------------------------------------------------
    // 2. ITEMS farmerId
    // ------------------------------------------------------------

    final items = _items(
      order['items'],
    );

    for (final item in items) {
      final itemFarmerId =
          item['farmerId']?.toString().trim() ?? '';

      if (itemFarmerId == farmerUid) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: background,
      elevation: 0,
      surfaceTintColor: Colors.transparent,

      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 27,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),

      titleSpacing: 0,

      title: const Text(
        'Orders',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),

      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {},
            ),

            Positioned(
              right: 7,
              top: 3,
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .snapshots(),
                builder: (context, snapshot) {
                  final user =
                      FirebaseAuth.instance.currentUser;

                  if (user == null ||
                      !snapshot.hasData) {
                    return const SizedBox();
                  }

                  int count = 0;

                  for (final doc
                      in snapshot.data!.docs) {
                    final order = doc.data();

                    if (!_belongsToFarmer(
                      order,
                      user.uid,
                    )) {
                      continue;
                    }

                    final status =
                        order['orderStatus']
                                ?.toString() ??
                            'Placed';

                    if (_isNew(status)) {
                      count++;
                    }
                  }

                  if (count == 0) {
                    return const SizedBox();
                  }

                  return Container(
                    constraints:
                        const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),
                    decoration:
                        const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      count > 9
                          ? '9+'
                          : '$count',
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(width: 5),
      ],
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs(
    int newCount,
    int progressCount,
    int completedCount,
  ) {
    return Container(
      height: 65,
      color: background,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          14,
          7,
          14,
          8,
        ),
        child: Row(
          children: List.generate(
            tabs.length,
            (index) {
              final selected =
                  selectedTab == index;

              int count = 0;

              if (index == 1) {
                count = newCount;
              }

              if (index == 2) {
                count = progressCount;
              }

              if (index == 3) {
                count = completedCount;
              }

              return Padding(
                padding:
                    const EdgeInsets.only(
                  right: 8,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTab = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration:
                        const Duration(
                      milliseconds: 180,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    decoration:
                        BoxDecoration(
                      color: selected
                          ? green
                          : card,
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      border: Border.all(
                        color: selected
                            ? green
                            : Colors.white
                                .withValues(
                                alpha: .06,
                              ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Text(
                          tabs[index],
                          style: TextStyle(
                            color: selected
                                ? Colors.black
                                : Colors.white70,
                            fontSize: 12,
                            fontWeight:
                                selected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                          ),
                        ),

                        if (count > 0) ...[
                          const SizedBox(
                            width: 6,
                          ),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration:
                                BoxDecoration(
                              color: selected
                                  ? Colors.black
                                      .withValues(
                                      alpha: .15,
                                    )
                                  : index == 1
                                      ? Colors.red
                                      : green,
                              borderRadius:
                                  BorderRadius.circular(
                                8,
                              ),
                            ),
                            child: Text(
                              '$count',
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 8,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        14,
        3,
        14,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 47,
              decoration:
                  BoxDecoration(
                color: card,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                border: Border.all(
                  color: Colors.white
                      .withValues(
                    alpha: .06,
                  ),
                ),
              ),
              child: TextField(
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
                decoration:
                    const InputDecoration(
                  hintText:
                      'Search orders by ID or buyer...',
                  hintStyle: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                  prefixIcon:
                      Icon(
                    Icons.search_rounded,
                    color: Colors.white54,
                    size: 21,
                  ),
                  border:
                      InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          Container(
            width: 47,
            height: 47,
            decoration:
                BoxDecoration(
              color: card,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              border: Border.all(
                color: Colors.white
                    .withValues(
                  alpha: .06,
                ),
              ),
            ),
            child: const Icon(
              Icons.filter_list_rounded,
              color: Colors.white70,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ALL SECTIONS
  // ============================================================

  List<Widget> _buildAllSections(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        docs,
  ) {
    final newDocs = docs.where(
      (doc) => _isNew(
        doc.data()['orderStatus']
                ?.toString() ??
            'Placed',
      ),
    );

    final progressDocs = docs.where(
      (doc) => _isInProgress(
        doc.data()['orderStatus']
                ?.toString() ??
            '',
      ),
    );

    final completedDocs = docs.where(
      (doc) => _isCompleted(
        doc.data()['orderStatus']
                ?.toString() ??
            '',
      ),
    );

    final widgets = <Widget>[];

    if (newDocs.isNotEmpty) {
      widgets.add(
        _sectionTitle(
          'New Orders',
          newDocs.length,
        ),
      );

      widgets.addAll(
        newDocs.map(
          (doc) => _orderCard(
            context,
            doc,
          ),
        ),
      );
    }

    if (progressDocs.isNotEmpty) {
      widgets.add(
        _sectionTitle(
          'In Progress',
          progressDocs.length,
        ),
      );

      widgets.addAll(
        progressDocs.map(
          (doc) => _orderCard(
            context,
            doc,
          ),
        ),
      );
    }

    if (completedDocs.isNotEmpty) {
      widgets.add(
        _sectionTitle(
          'Completed',
          completedDocs.length,
        ),
      );

      widgets.addAll(
        completedDocs.map(
          (doc) => _orderCard(
            context,
            doc,
          ),
        ),
      );
    }

    return widgets;
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
    String title,
    int count,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        3,
        12,
        3,
        9,
      ),
      child: Row(
        children: [
          Text(
            title,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(width: 7),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 3,
            ),
            decoration:
                BoxDecoration(
              color: title ==
                      'New Orders'
                  ? Colors.red
                  : green,
              borderRadius:
                  BorderRadius.circular(
                8,
              ),
            ),
            child: Text(
              '$count',
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),

          const Spacer(),

          const Text(
            'View All',
            style:
                TextStyle(
              color: green,
              fontSize: 11,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget _orderCard(
    BuildContext context,
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc,
  ) {
    final order = doc.data();

    final items =
        _items(order['items']);

    final buyerName =
        order['buyerName']
                ?.toString() ??
            'Buyer';

    final status =
        order['orderStatus']
                ?.toString() ??
            'Placed';

    final total =
        _number(
      order['totalAmount'],
    );

    final createdAt =
        _getDate(
      order['createdAt'],
    );

    final firstItem =
        items.isNotEmpty
            ? items.first
            : <String, dynamic>{};

    final productName =
        firstItem['name']
                ?.toString() ??
            'Fresh Produce';

    final quantity =
        _number(
      firstItem['quantity'],
    );

    final unit =
        firstItem['unit']
                ?.toString() ??
            'kg';

    final negotiated =
        _number(
      firstItem[
          'negotiatedPrice'],
    );

    final normalPrice =
        _number(
      firstItem['price'],
    );

    final price =
        negotiated > 0
            ? negotiated
            : normalPrice;

    final imageUrl =
        firstItem['imageUrl']
                ?.toString() ??
            firstItem['image']
                ?.toString() ??
            '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                FarmerOrderDetailsScreen(
              orderId: doc.id,
              order: order,
            ),
          ),
        );
      },
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 11,
        ),
        padding:
            const EdgeInsets.all(
          11,
        ),
        decoration:
            BoxDecoration(
          color: card,
          borderRadius:
              BorderRadius.circular(
            17,
          ),
          border: Border.all(
            color: _isNew(status)
                ? green.withValues(
                    alpha: .18,
                  )
                : Colors.white
                    .withValues(
                    alpha: .05,
                  ),
          ),
        ),
        child: Row(
          children: [
            _productImage(
              imageUrl,
            ),

            const SizedBox(
              width: 11,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          buyerName,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),

                      Text(
                        _formatTime(
                          createdAt,
                        ),
                        style:
                            const TextStyle(
                          color:
                              Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    productName,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Colors.white70,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    '${_quantity(quantity)} $unit  •  ₹${_price(price)}/$unit',
                    style:
                        const TextStyle(
                      color:
                          Colors.white54,
                      fontSize: 10,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Row(
                    children: [
                      Text(
                        'Total ₹${_price(total)}',
                        style:
                            const TextStyle(
                          color: green,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),

                      const Spacer(),

                      _statusChip(
                        status,
                      ),
                    ],
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
  // PRODUCT IMAGE
  // ============================================================

  Widget _productImage(
    String imageUrl,
  ) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(
          13,
        ),
        child: Image.network(
          imageUrl,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) =>
                  _imageFallback(),
        ),
      );
    }

    return _imageFallback();
  }

  Widget _imageFallback() {
    return Container(
      width: 70,
      height: 70,
      decoration:
          BoxDecoration(
        color:
            green.withValues(
          alpha: .08,
        ),
        borderRadius:
            BorderRadius.circular(
          13,
        ),
      ),
      child: const Icon(
        Icons.eco_rounded,
        color: green,
        size: 30,
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _statusChip(
    String status,
  ) {
    Color color = green;

    switch (
        status.toLowerCase()) {
      case 'accepted':
        color = Colors.blueAccent;
        break;

      case 'preparing':
        color = Colors.amberAccent;
        break;

      case 'ready':
        color = Colors.cyanAccent;
        break;

      case 'out for delivery':
        color =
            Colors.lightBlueAccent;
        break;

      case 'delivered':
      case 'completed':
        color =
            Colors.greenAccent;
        break;

      case 'cancelled':
        color = Colors.redAccent;
        break;

      case 'placed':
      case 'new':
        color = green;
        break;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: .08,
        ),
        borderRadius:
            BorderRadius.circular(
          9,
        ),
        border: Border.all(
          color:
              color.withValues(
            alpha: .18,
          ),
        ),
      ),
      child: Text(
        status,
        style:
            TextStyle(
          color: color,
          fontSize: 8,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState({
    required int totalOrders,
    required int farmerOrders,
  }) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          30,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 85,
              height: 85,
              decoration:
                  BoxDecoration(
                color:
                    green.withValues(
                  alpha: .08,
                ),
                shape:
                    BoxShape.circle,
              ),
              child:
                  const Icon(
                Icons
                    .receipt_long_rounded,
                color: green,
                size: 40,
              ),
            ),

            const SizedBox(
              height: 17,
            ),

            const Text(
              'No Orders Found',
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

            const Text(
              'New buyer orders will appear here.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // DEBUG INFORMATION
            Container(
              padding:
                  const EdgeInsets.all(
                12,
              ),
              decoration:
                  BoxDecoration(
                color: card,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Firestore Orders: $totalOrders',
                    style:
                        const TextStyle(
                      color:
                          Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    'Matched Farmer Orders: $farmerOrders',
                    style:
                        const TextStyle(
                      color:
                          Colors.white54,
                      fontSize: 10,
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
  // ERROR
  // ============================================================

  Widget _errorState(
    String error,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          25,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              color:
                  Colors.redAccent,
              size: 44,
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(
              'Unable to load orders',
              style:
                  TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              error,
              textAlign:
                  TextAlign.center,
              maxLines: 4,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                color: Colors.white38,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS FILTERS
  // ============================================================

  bool _isNew(
    String status,
  ) {
    final s =
        status.trim().toLowerCase();

    return s == 'placed' ||
        s == 'new';
  }

  bool _isInProgress(
    String status,
  ) {
    final s =
        status.trim().toLowerCase();

    return s == 'accepted' ||
        s == 'preparing' ||
        s == 'ready' ||
        s == 'out for delivery';
  }

  bool _isCompleted(
    String status,
  ) {
    final s =
        status.trim().toLowerCase();

    return s == 'delivered' ||
        s == 'completed' ||
        s == 'cancelled';
  }

  // ============================================================
  // ITEMS
  // ============================================================

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

  // ============================================================
  // NUMBER
  // ============================================================

  double _number(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // DATE
  // ============================================================

  DateTime _getDate(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(
            value,
          ) ??
          DateTime
              .fromMillisecondsSinceEpoch(
            0,
          );
    }

    return DateTime
        .fromMillisecondsSinceEpoch(
      0,
    );
  }

  // ============================================================
  // PRICE
  // ============================================================

  String _price(
    double value,
  ) {
    if (value ==
        value.roundToDouble()) {
      return value
          .toStringAsFixed(0);
    }

    return value
        .toStringAsFixed(2);
  }

  // ============================================================
  // QUANTITY
  // ============================================================

  String _quantity(
    double value,
  ) {
    if (value ==
        value.roundToDouble()) {
      return value
          .toStringAsFixed(0);
    }

    return value
        .toStringAsFixed(1);
  }

  // ============================================================
  // TIME
  // ============================================================

  String _formatTime(
    DateTime date,
  ) {
    if (date.millisecondsSinceEpoch ==
        0) {
      return '';
    }

    final hour =
        date.hour == 0
            ? 12
            : date.hour > 12
                ? date.hour - 12
                : date.hour;

    final minute = date.minute
        .toString()
        .padLeft(2, '0');

    final period =
        date.hour >= 12
            ? 'PM'
            : 'AM';

    return '$hour:$minute $period';
  }
}

// ==================================================================
// FARMER ORDER DETAILS SCREEN
// ==================================================================

class FarmerOrderDetailsScreen
    extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> order;

  const FarmerOrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.order,
  });

  @override
  State<FarmerOrderDetailsScreen>
      createState() =>
          _FarmerOrderDetailsScreenState();
}

class _FarmerOrderDetailsScreenState
    extends State<
        FarmerOrderDetailsScreen> {
  static const Color green =
      Color(0xFF22C55E);

  static const Color background =
      Color(0xFF0B0B0B);

  static const Color card =
      Color(0xFF151515);

  static const Color cardLight =
      Color(0xFF1D1D1D);

  late Map<String, dynamic> order;

  @override
  void initState() {
    super.initState();

    order =
        Map<String, dynamic>.from(
      widget.order,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .snapshots(),
      builder: (context, snapshot) {
        final currentOrder = (snapshot.hasData && snapshot.data!.data() != null)
            ? snapshot.data!.data()!
            : order;

        final items = _items(currentOrder['items']);
        final buyerName = currentOrder['buyerName']?.toString() ?? 'Buyer';
        final buyerPhone = currentOrder['buyerPhone']?.toString() ?? '';
        final address = currentOrder['deliveryAddress']?.toString() ?? '';
        final status = currentOrder['orderStatus']?.toString() ?? 'Placed';
        final total = _number(currentOrder['totalAmount']);
        final createdAt = _getDate(currentOrder['createdAt']);
        final hasPartner = currentOrder['deliveryPartnerId'] != null;

        return Scaffold(
          backgroundColor: background,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _header(status, createdAt),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 30),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        if (hasPartner) ...[
                          _deliveryPartnerCard(currentOrder),
                          const SizedBox(height: 10),
                        ],
                        _buyerCard(buyerName, buyerPhone),
                        const SizedBox(height: 10),
                        _itemsCard(items),
                        const SizedBox(height: 10),
                        _summaryCard(total),
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _deliveryCard(address),
                        ],
                        const SizedBox(height: 10),
                        _actionSection(status),
                      ],
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
  // DELIVERY PARTNER CARD (FARMER VIEW)
  // ============================================================

  Widget _deliveryPartnerCard(Map<String, dynamic> currentOrder) {
    final partnerName = currentOrder['deliveryPartnerName']?.toString() ?? 'Assigned Partner';
    final partnerPhone = currentOrder['deliveryPartnerPhone']?.toString() ?? '';
    final partnerVehicle = currentOrder['deliveryPartnerVehicle']?.toString() ?? '';
    final pickupOtp = currentOrder['pickupOtp']?.toString() ?? '';

    return _darkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: green.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delivery_dining_rounded,
                  color: green,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Partner Assigned',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      partnerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (partnerVehicle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        partnerVehicle,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (partnerPhone.isNotEmpty)
                IconButton(
                  onPressed: () async {
                    final uri = Uri.parse('tel:$partnerPhone');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: .15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_rounded,
                      color: green,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          if (pickupOtp.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800).withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFB800).withValues(alpha: .4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.pin_rounded,
                    color: Color(0xFFFFB800),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pickup Verification OTP',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          pickupOtp,
                          style: const TextStyle(
                            color: Color(0xFFFFB800),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Share with partner',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BuyerLiveTrackingScreen(
                      order: OrderModel.fromMap(currentOrder, widget.orderId),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: const Text(
                'Track Delivery Partner Live',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header(
    String status,
    DateTime createdAt,
  ) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        8,
        8,
        8,
        22,
      ),
      decoration:
          const BoxDecoration(
        gradient:
            LinearGradient(
          begin:
              Alignment.topCenter,
          end:
              Alignment.bottomCenter,
          colors: [
            Color(0xFF005D18),
            Color(0xFF008B27),
            Color(0xFF006B1B),
          ],
        ),
        borderRadius:
            BorderRadius.only(
          bottomLeft:
              Radius.circular(30),
          bottomRight:
              Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon:
                    const Icon(
                  Icons
                      .arrow_back_rounded,
                  color:
                      Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(
                    context,
                  );
                },
              ),

              const Spacer(),

              const Icon(
                Icons.eco_rounded,
                color:
                    Colors.white70,
                size: 25,
              ),

              const SizedBox(
                width: 10,
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          const Icon(
            Icons
                .shopping_cart_rounded,
            color: Colors.white,
            size: 45,
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            _headerTitle(status),
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            'Order #${_shortOrderId(widget.orderId)}',
            style:
                const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          if (createdAt
                  .millisecondsSinceEpoch !=
              0)
            Text(
              _formatDateTime(
                createdAt,
              ),
              style:
                  const TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),

          const SizedBox(
            height: 10,
          ),

          _statusChip(status),
        ],
      ),
    );
  }

  String _headerTitle(
    String status,
  ) {
    switch (
        status.toLowerCase()) {
      case 'placed':
      case 'new':
        return 'New Order Received!';

      case 'accepted':
        return 'Order Accepted';

      case 'preparing':
        return 'Order In Preparation';

      case 'ready':
        return 'Order Ready';

      case 'out for delivery':
        return 'Out for Delivery';

      case 'delivered':
      case 'completed':
        return 'Order Completed';

      case 'cancelled':
        return 'Order Cancelled';

      default:
        return 'Order Details';
    }
  }

  // ============================================================
  // BUYER
  // ============================================================

  Widget _buyerCard(
    String name,
    String phone,
  ) {
    return _darkCard(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration:
                BoxDecoration(
              color:
                  green.withValues(
                alpha: .10,
              ),
              shape:
                  BoxShape.circle,
            ),
            child:
                const Icon(
              Icons.person_rounded,
              color: green,
              size: 32,
            ),
          ),

          const SizedBox(
            width: 13,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buyer',
                  style:
                      TextStyle(
                    color:
                        Colors.white38,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                if (phone.isNotEmpty) ...[
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    phone,
                    style:
                        const TextStyle(
                      color:
                          Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ITEMS
  // ============================================================

  Widget _itemsCard(
    List<Map<String, dynamic>>
        items,
  ) {
    return _darkCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Items',
            style:
                TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          if (items.isEmpty)
            const Text(
              'No item information available.',
              style:
                  TextStyle(
                color:
                    Colors.white54,
                fontSize: 11,
              ),
            )
          else
            ...items.map(
              (item) =>
                  _itemCard(item),
            ),
        ],
      ),
    );
  }

  Widget _itemCard(
    Map<String, dynamic> item,
  ) {
    final name =
        item['name']
                ?.toString() ??
            'Product';

    final quantity =
        _number(
      item['quantity'],
    );

    final unit =
        item['unit']
                ?.toString() ??
            'kg';

    final negotiated =
        _number(
      item['negotiatedPrice'],
    );

    final normalPrice =
        _number(
      item['price'],
    );

    final price =
        negotiated > 0
            ? negotiated
            : normalPrice;

    final itemTotal =
        _number(
      item['itemTotal'],
    ) > 0
            ? _number(
                item['itemTotal'],
              )
            : quantity * price;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 9,
      ),
      padding:
          const EdgeInsets.all(
        11,
      ),
      decoration:
          BoxDecoration(
        color: cardLight,
        borderRadius:
            BorderRadius.circular(
          13,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration:
                BoxDecoration(
              color:
                  green.withValues(
                alpha: .08,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child:
                const Icon(
              Icons.eco_rounded,
              color: green,
              size: 28,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  '${_quantity(quantity)} $unit',
                  style:
                      const TextStyle(
                    color:
                        Colors.white38,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  '₹${_price(price)}/$unit',
                  style:
                      const TextStyle(
                    color: green,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '₹${_price(itemTotal)}',
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _summaryCard(
    double total,
  ) {
    final subtotal =
        _number(
      order['subtotal'],
    );

    final delivery =
        _number(
      order['deliveryFee'],
    );

    final displayTotal =
        total > 0
            ? total
            : subtotal + delivery;

    return _darkCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style:
                TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          _summaryRow(
            'Item Total',
            '₹${_price(subtotal)}',
          ),

          const SizedBox(
            height: 10,
          ),

          _summaryRow(
            'Delivery',
            '₹${_price(delivery)}',
          ),

          const Padding(
            padding:
                EdgeInsets.symmetric(
              vertical: 12,
            ),
            child:
                Divider(
              color:
                  Colors.white12,
            ),
          ),

          Row(
            children: [
              const Text(
                'Total Amount',
                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const Spacer(),

              Text(
                '₹${_price(displayTotal)}',
                style:
                    const TextStyle(
                  color: green,
                  fontSize: 20,
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

  Widget _summaryRow(
    String label,
    String value,
  ) {
    return Row(
      children: [
        Text(
          label,
          style:
              const TextStyle(
            color:
                Colors.white54,
            fontSize: 12,
          ),
        ),

        const Spacer(),

        Text(
          value,
          style:
              const TextStyle(
            color:
                Colors.white70,
            fontSize: 12,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DELIVERY
  // ============================================================

  Widget _deliveryCard(
    String address,
  ) {
    return _darkCard(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration:
                BoxDecoration(
              color:
                  green.withValues(
                alpha: .08,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child:
                const Icon(
              Icons
                  .local_shipping_rounded,
              color: green,
              size: 23,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Address',
                  style:
                      TextStyle(
                    color:
                        Colors.white38,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  address,
                  style:
                      const TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 12,
                    height: 1.35,
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
  // ACTION SECTION
  // ============================================================

  Widget _actionSection(
    String status,
  ) {
    final normalized =
        status.toLowerCase();

    // ----------------------------------------------------------
    // NEW
    // ----------------------------------------------------------

    if (normalized == 'placed' ||
        normalized == 'new') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 57,
            child:
                ElevatedButton.icon(
              onPressed: () {
                _updateStatus(
                  'Accepted',
                );
              },
              icon:
                  const Icon(
                Icons
                    .check_circle_rounded,
              ),
              label:
                  const Text(
                'Accept Order',
                style:
                    TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    green,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          SizedBox(
            width: double.infinity,
            height: 52,
            child:
                OutlinedButton.icon(
              onPressed:
                  _showRejectDialog,
              icon:
                  const Icon(
                Icons.close_rounded,
                color:
                    Colors.redAccent,
              ),
              label:
                  const Text(
                'Reject Order',
                style:
                    TextStyle(
                  color:
                      Colors.redAccent,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              style:
                  OutlinedButton
                      .styleFrom(
                side:
                    const BorderSide(
                  color:
                      Colors.redAccent,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // ----------------------------------------------------------
    // ACCEPTED
    // ----------------------------------------------------------

    if (normalized == 'accepted') {
      return _singleAction(
        label: 'Start Preparing',
        icon:
            Icons.inventory_2_rounded,
        color: green,
        nextStatus: 'Preparing',
      );
    }

    // ----------------------------------------------------------
    // PREPARING
    // ----------------------------------------------------------

    if (normalized == 'preparing') {
      return _singleAction(
        label: 'Mark Ready',
        icon: Icons
            .check_circle_outline_rounded,
        color:
            Colors.blueAccent,
        nextStatus: 'Ready',
      );
    }

    // ----------------------------------------------------------
    // READY
    // ----------------------------------------------------------

    if (normalized == 'ready') {
      return _singleAction(
        label: 'Out for Delivery',
        icon:
            Icons.local_shipping_rounded,
        color:
            Colors.lightBlueAccent,
        nextStatus:
            'Out for Delivery',
      );
    }

    // ----------------------------------------------------------
    // OUT FOR DELIVERY
    // ----------------------------------------------------------

    if (normalized ==
        'out for delivery') {
      return _singleAction(
        label: 'Mark Delivered',
        icon:
            Icons.done_all_rounded,
        color:
            Colors.greenAccent,
        nextStatus: 'Delivered',
      );
    }

    // ----------------------------------------------------------
    // COMPLETED
    // ----------------------------------------------------------

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        17,
      ),
      decoration:
          BoxDecoration(
        color:
            normalized == 'cancelled'
                ? Colors.redAccent
                    .withValues(
                    alpha: .06,
                  )
                : green.withValues(
                    alpha: .06,
                  ),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color:
              normalized == 'cancelled'
                  ? Colors.redAccent
                  : green,
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            normalized ==
                    'cancelled'
                ? Icons.cancel_rounded
                : Icons
                    .check_circle_rounded,
            color:
                normalized ==
                        'cancelled'
                    ? Colors.redAccent
                    : green,
          ),

          const SizedBox(
            width: 8,
          ),

          Text(
            normalized ==
                    'cancelled'
                ? 'Order Cancelled'
                : 'Order Completed',
            style:
                TextStyle(
              color:
                  normalized ==
                          'cancelled'
                      ? Colors.redAccent
                      : green,
              fontSize: 13,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SINGLE ACTION
  // ============================================================

  Widget _singleAction({
    required String label,
    required IconData icon,
    required Color color,
    required String nextStatus,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 57,
      child:
          ElevatedButton.icon(
        onPressed: () {
          _updateStatus(
            nextStatus,
          );
        },
        icon:
            Icon(icon),
        label:
            Text(
          label,
          style:
              const TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.w800,
          ),
        ),
        style:
            ElevatedButton
                .styleFrom(
          backgroundColor:
              color,
          foregroundColor:
              Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REJECT
  // ============================================================

  Future<void>
      _showRejectDialog() async {
    String reason =
        'Unable to fulfil order';

    final reasons = [
      'Unable to fulfil order',
      'Insufficient stock',
      'Product unavailable',
      'Price issue',
      'Other',
    ];

    final result =
        await showDialog<String>(
      context: context,
      builder:
          (dialogContext) {
        return StatefulBuilder(
          builder:
              (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              backgroundColor:
                  card,
              title:
                  const Text(
                'Reject Order?',
                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              content:
                  Column(
                mainAxisSize:
                    MainAxisSize.min,
                children:
                    reasons.map(
                  (item) {
                    final selected =
                        reason ==
                            item;

                    return GestureDetector(
                      onTap: () {
                        setDialogState(
                          () {
                            reason =
                                item;
                          },
                        );
                      },
                      child:
                          Container(
                        margin:
                            const EdgeInsets
                                .only(
                          bottom: 7,
                        ),
                        padding:
                            const EdgeInsets
                                .all(
                          11,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              selected
                                  ? Colors
                                      .redAccent
                                      .withValues(
                                      alpha:
                                          .07,
                                    )
                                  : cardLight,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                        child:
                            Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons
                                      .radio_button_checked
                                  : Icons
                                      .radio_button_off,
                              color:
                                  selected
                                      ? Colors
                                          .redAccent
                                      : Colors
                                          .white30,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child:
                                  Text(
                                item,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white70,
                                  fontSize:
                                      11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                      const Text(
                    'Cancel',
                    style:
                        TextStyle(
                      color:
                          Colors.white54,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      reason,
                    );
                  },
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        Colors.redAccent,
                  ),
                  child:
                      const Text(
                    'Reject',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await _rejectOrder(
        result,
      );
    }
  }

  // ============================================================
  // REJECT FIRESTORE
  // ============================================================

  Future<void> _rejectOrder(
    String reason,
  ) async {
    try {
      await FirebaseFirestore
          .instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'orderStatus':
            'Cancelled',
        'deliveryStatus':
            'Cancelled',
        'cancellationReason':
            reason,
        'cancelledBy':
            'Farmer',
        'cancelledAt':
            FieldValue
                .serverTimestamp(),
        'updatedAt':
            FieldValue
                .serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        order['orderStatus'] =
            'Cancelled';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content:
              Text(
            'Order rejected.',
          ),
          backgroundColor:
              Colors.redAccent,
        ),
      );
    } catch (e) {
      debugPrint(
        'REJECT ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content:
              Text(
            'Unable to reject order.',
          ),
          backgroundColor:
              Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> _updateStatus(
    String newStatus,
  ) async {
    try {
      final user =
          FirebaseAuth.instance
              .currentUser;

      final updateData =
          <String, dynamic>{
        'orderStatus':
            newStatus,
        'updatedAt':
            FieldValue
                .serverTimestamp(),
      };

      if (newStatus ==
          'Accepted') {
        updateData['acceptedAt'] =
            FieldValue
                .serverTimestamp();
      }

      if (newStatus ==
          'Preparing') {
        updateData[
                'deliveryStatus'] =
            'Preparing';
      }

      if (newStatus == 'Ready') {
        updateData[
                'deliveryStatus'] =
            'Ready';
      }

      if (newStatus ==
          'Out for Delivery') {
        updateData[
                'deliveryStatus'] =
            'Out for Delivery';
      }

      if (newStatus ==
          'Delivered') {
        updateData[
                'deliveryStatus'] =
            'Delivered';

        updateData[
                'deliveredAt'] =
            FieldValue
                .serverTimestamp();
      }

      if (user != null) {
        updateData[
                'lastUpdatedBy'] =
            user.uid;
      }

      await FirebaseFirestore
          .instance
          .collection('orders')
          .doc(widget.orderId)
          .update(
            updateData,
          );

      if (!mounted) return;

      setState(() {
        order['orderStatus'] =
            newStatus;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(
            'Order updated to $newStatus',
          ),
          backgroundColor:
              green,
          behavior:
              SnackBarBehavior
                  .floating,
        ),
      );
    } catch (e) {
      debugPrint(
        'ORDER UPDATE ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content:
              Text(
            'Unable to update order.',
          ),
          backgroundColor:
              Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _darkCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
              Colors.white
                  .withValues(
            alpha: .055,
          ),
        ),
      ),
      child: child,
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _statusChip(
    String status,
  ) {
    Color color = green;

    switch (
        status.toLowerCase()) {
      case 'accepted':
        color =
            Colors.blueAccent;
        break;

      case 'preparing':
        color =
            Colors.amberAccent;
        break;

      case 'ready':
        color =
            Colors.cyanAccent;
        break;

      case 'out for delivery':
        color =
            Colors.lightBlueAccent;
        break;

      case 'delivered':
      case 'completed':
        color =
            Colors.greenAccent;
        break;

      case 'cancelled':
        color =
            Colors.redAccent;
        break;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: .10,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color:
              color.withValues(
            alpha: .20,
          ),
        ),
      ),
      child: Text(
        status == 'Placed'
            ? 'New Order'
            : status,
        style:
            TextStyle(
          color: color,
          fontSize: 9,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

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

  double _number(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  DateTime _getDate(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(
            value,
          ) ??
          DateTime
              .fromMillisecondsSinceEpoch(
            0,
          );
    }

    return DateTime
        .fromMillisecondsSinceEpoch(
      0,
    );
  }

  String _price(
    double value,
  ) {
    if (value ==
        value.roundToDouble()) {
      return value
          .toStringAsFixed(0);
    }

    return value
        .toStringAsFixed(2);
  }

  String _quantity(
    double value,
  ) {
    if (value ==
        value.roundToDouble()) {
      return value
          .toStringAsFixed(0);
    }

    return value
        .toStringAsFixed(1);
  }

  String _shortOrderId(
    String id,
  ) {
    if (id.length <= 10) {
      return id.toUpperCase();
    }

    return id
        .substring(0, 10)
        .toUpperCase();
  }

  String _formatDateTime(
    DateTime date,
  ) {
    if (date.millisecondsSinceEpoch ==
        0) {
      return '';
    }

    final hour =
        date.hour == 0
            ? 12
            : date.hour > 12
                ? date.hour - 12
                : date.hour;

    final minute = date.minute
        .toString()
        .padLeft(2, '0');

    final period =
        date.hour >= 12
            ? 'PM'
            : 'AM';

    return 'Today, $hour:$minute $period';
  }
}
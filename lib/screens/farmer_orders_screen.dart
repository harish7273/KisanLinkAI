import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/order_model.dart';
import '../services/data_seed_service.dart';
import '../services/language_service.dart';
import '../widgets/vehicle_assignment_sheet.dart';
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
  static const Color lightGreen = Color(0xFF4ADE80);

  static const Color background = Color(0xFF0B0B0B);
  static const Color card = Color(0xFF151515);
  static const Color cardLight = Color(0xFF1D1D1D);

  // ============================================================
  // STATE
  // ============================================================

  int selectedTab = 0;
  String searchText = '';

  String _filterStatus = 'All';
  String _filterTimeframe = 'All Time';
  String _filterTransport = 'All';

  bool get _hasActiveFilters =>
      _filterStatus != 'All' ||
      _filterTimeframe != 'All Time' ||
      _filterTransport != 'All';

  final List<String> tabs = const [
    'All Orders',
    'New',
    'In Progress',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    LanguageService.currentLocaleNotifier.addListener(_onLocaleChanged);
    _checkAndSeedOrders();
  }

  @override
  void dispose() {
    LanguageService.currentLocaleNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkAndSeedOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await DataSeedService.ensureFarmerDataSeeded(
        farmerUid: user.uid,
        farmerName: user.displayName ?? 'Farmer',
        phone: user.phoneNumber,
      );
    }
  }

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

            if (_filterStatus != 'All') {
              if (status.toLowerCase() != _filterStatus.toLowerCase()) {
                return false;
              }
            }

            if (_filterTransport != 'All') {
              final hasTransport = (order['vehicleId'] != null && order['vehicleId'].toString().isNotEmpty) ||
                  (order['assignedVehicle'] != null && order['assignedVehicle'].toString().isNotEmpty) ||
                  (order['deliveryPartnerId'] != null && order['deliveryPartnerId'].toString().isNotEmpty);
              if (_filterTransport == 'Assigned' && !hasTransport) return false;
              if (_filterTransport == 'Unassigned' && hasTransport) return false;
            }

            if (_filterTimeframe != 'All Time') {
              final createdAtRaw = order['createdAt'];
              DateTime? createdDate;
              if (createdAtRaw is Timestamp) {
                createdDate = createdAtRaw.toDate();
              } else if (createdAtRaw is String) {
                createdDate = DateTime.tryParse(createdAtRaw);
              }
              if (createdDate != null) {
                final now = DateTime.now();
                if (_filterTimeframe == 'Today') {
                  if (createdDate.year != now.year || createdDate.month != now.month || createdDate.day != now.day) {
                    return false;
                  }
                } else if (_filterTimeframe == 'This Week') {
                  if (now.difference(createdDate).inDays > 7) return false;
                } else if (_filterTimeframe == 'This Month') {
                  if (createdDate.year != now.year || createdDate.month != now.month) return false;
                }
              }
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

              if (_hasActiveFilters)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt_rounded, color: green, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          [
                            if (_filterStatus != 'All') tr(_filterStatus),
                            if (_filterTransport != 'All')
                              _filterTransport == 'Assigned' ? tr('transport_assigned') : tr('transport_unassigned'),
                            if (_filterTimeframe != 'All Time') _filterTimeframe,
                          ].join(' • '),
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _filterStatus = 'All';
                            _filterTimeframe = 'All Time';
                            _filterTransport = 'All';
                          });
                        },
                        child: Text(
                          tr('reset', defaultText: 'Clear'),
                          style: const TextStyle(color: green, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

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
    // Open buyer demand broadcast across devices (Step 1: Near real-time visibility)
    final status = order['orderStatus']?.toString().trim().toLowerCase() ?? '';
    if (status == 'demand posted' || order['isDemandBroadcast'] == true) {
      return true;
    }

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

      title: Text(
        tr('Orders', defaultText: 'Orders'),
        style: const TextStyle(
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
                          tr(tabs[index]),
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
                    InputDecoration(
                  hintText:
                      tr('search_orders_hint', defaultText: 'Search orders by ID or buyer...'),
                  hintStyle: const TextStyle(
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

          GestureDetector(
            onTap: _showFilterModal,
            child: Container(
              width: 47,
              height: 47,
              decoration: BoxDecoration(
                color: _hasActiveFilters
                    ? lightGreen.withValues(alpha: .15)
                    : card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _hasActiveFilters
                      ? lightGreen
                      : Colors.white.withValues(alpha: .06),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    color: _hasActiveFilters ? lightGreen : Colors.white70,
                    size: 21,
                  ),
                  if (_hasActiveFilters)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: lightGreen,
                          shape: BoxShape.circle,
                        ),
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

  void _showFilterModal() {
    String tempStatus = _filterStatus;
    String tempTransport = _filterTransport;
    String tempTimeframe = _filterTimeframe;

    showModalBottomSheet(
      context: context,
      backgroundColor: card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            Widget buildChipSection(
              String title,
              List<String> options,
              String currentVal,
              Function(String) onSelected,
            ) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((opt) {
                      final isSelected =
                          opt.toLowerCase() == currentVal.toLowerCase();
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            onSelected(opt);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? lightGreen.withValues(alpha: .2)
                                : cardLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? lightGreen : Colors.white12,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            tr(opt.toLowerCase().replaceAll(' ', '_'),
                                defaultText: opt),
                            style: TextStyle(
                              color: isSelected ? lightGreen : Colors.white70,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).padding.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr('filter_orders', defaultText: 'Filter Orders'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempStatus = 'All';
                            tempTransport = 'All';
                            tempTimeframe = 'All Time';
                          });
                        },
                        child: Text(
                          tr('reset', defaultText: 'Reset'),
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  buildChipSection(
                    tr('order_status', defaultText: 'Order Status'),
                    [
                      'All',
                      'Placed',
                      'Preparing',
                      'In Transit',
                      'Completed',
                      'Cancelled'
                    ],
                    tempStatus,
                    (val) => tempStatus = val,
                  ),
                  const SizedBox(height: 16),
                  buildChipSection(
                    tr('delivery_transport', defaultText: 'Delivery Vehicle'),
                    ['All', 'Assigned', 'Unassigned'],
                    tempTransport,
                    (val) => tempTransport = val,
                  ),
                  const SizedBox(height: 16),
                  buildChipSection(
                    tr('timeframe', defaultText: 'Timeframe'),
                    ['All Time', 'Today', 'This Week', 'This Month'],
                    tempTimeframe,
                    (val) => tempTimeframe = val,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lightGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        setState(() {
                          _filterStatus = tempStatus;
                          _filterTransport = tempTransport;
                          _filterTimeframe = tempTimeframe;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        tr('apply_filters', defaultText: 'Apply Filters'),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
            LanguageService.tr(title),
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

          Text(
            tr('view_all', defaultText: 'View All'),
            style:
                const TextStyle(
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
        child: Column(
          children: [
            Row(
              children: [
                _productImage(
                  imageUrl,
                  productName,
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

            // BUYER & TRANSPORT DETAILS ACCORDION FOR ACCEPTED / IN PROGRESS ORDERS
            if (_isInProgress(status) || status.toLowerCase() == 'accepted' || _isNew(status)) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1711),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: green.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    // Buyer Contact Row
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded, color: green, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$buyerName • ${order['buyerPhone'] ?? '+91 9842156789'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${order['deliveryAddress'] ?? 'Coimbatore Central Market, RS Puram'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white60, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final p = (order['buyerPhone'] ?? '+91 9842156789').toString();
                            final uri = Uri.parse('tel:${p.replaceAll(' ', '')}');
                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.call, color: green, size: 12),
                                const SizedBox(width: 3),
                                Text(tr('call', defaultText: 'Call'), style: const TextStyle(color: green, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),
                    const Divider(color: Color(0xFF1E2F22), height: 1),
                    const SizedBox(height: 6),

                    // Transport Vehicle & Driver Row (Optional Assignment enabled for both parties)
                    if (order['deliveryPartnerVehicle'] != null &&
                        order['deliveryPartnerVehicle'].toString().isNotEmpty) ...[
                      // Assigned Transport Details with Driver Rating & Safe Delivery
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.local_shipping_rounded, color: Colors.amberAccent, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${order['deliveryPartnerVehicle']} (${order['deliveryPartnerPlate'] ?? 'TN-38-BZ-4412'})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: Colors.amberAccent.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 11),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${order['driverRating'] ?? '4.9'}',
                                            style: const TextStyle(color: Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.w800),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${tr('driver', defaultText: 'Driver')}: ${order['deliveryPartnerName'] ?? 'P. Selvam'} • ${order['deliveryEstimate'] ?? '25-40 Mins Express'}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${tr('zero_damage_guarantee', defaultText: 'Zero-Damage & Correct Location Guarantee')} • OTP: ${order['pickupOtp'] ?? '4821'}',
                                  style: const TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Action buttons: Change Vehicle (Optional), Call Driver, Track
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              VehicleAssignmentSheet.show(
                                context,
                                orderId: doc.id,
                                currentVehicle: order['deliveryPartnerVehicle'],
                                currentPlate: order['deliveryPartnerPlate'],
                                currentDriverName: order['deliveryPartnerName'],
                              );
                            },
                            icon: const Icon(Icons.sync_alt_rounded, size: 11, color: Colors.amberAccent),
                            label: Text(
                              tr('change_vehicle_optional', defaultText: 'Change Vehicle'),
                              style: const TextStyle(color: Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.amberAccent.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                          if (order['deliveryPartnerPhone'] != null)
                            GestureDetector(
                              onTap: () async {
                                final p = order['deliveryPartnerPhone'].toString();
                                final uri = Uri.parse('tel:${p.replaceAll(' ', '')}');
                                if (await canLaunchUrl(uri)) await launchUrl(uri);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.phone_in_talk_rounded, color: Colors.white70, size: 11),
                                    const SizedBox(width: 2),
                                    Text(tr('call', defaultText: 'Call'), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BuyerLiveTrackingScreen(
                                    order: OrderModel.fromMap(order, doc.id),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.navigation_rounded, size: 11),
                            label: Text(tr('track', defaultText: 'Track'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: green,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ],
                      ),
                    ] else if (order['isDirectPickup'] == true || order['fulfillmentMethod'] == 'direct_farm_pickup') ...[
                      // Branch A: Direct Farm Pickup
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded, color: green, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Branch A: Direct Farm Gate Pickup',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Buyer pickup at farm gate • Zero logistics fee (₹0) • Handover OTP: ${order['deliveryOtp'] ?? order['pickupOtp'] ?? '4821'}',
                                  style: const TextStyle(color: green, fontSize: 8, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Vehicle Not Yet Assigned: Optional Assignment Button
                      Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, color: Colors.amberAccent, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('assign_transport_optional', defaultText: 'Assign Transport (Optional)'),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  tr('mutual_assign_notice', defaultText: 'Either Farmer or Buyer can select transport upon mutual communication.'),
                                  style: const TextStyle(color: Colors.white54, fontSize: 8),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton.icon(
                            onPressed: () {
                              VehicleAssignmentSheet.show(
                                context,
                                orderId: doc.id,
                                currentVehicle: order['deliveryPartnerVehicle'],
                                currentPlate: order['deliveryPartnerPlate'],
                                currentDriverName: order['deliveryPartnerName'],
                              );
                            },
                            icon: const Icon(Icons.add_road_rounded, size: 11),
                            label: Text(
                              tr('assign_transport_title', defaultText: 'Assign (Optional)'),
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amberAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
    String productName,
  ) {
    if (imageUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.asset(
          imageUrl,
          width: 70,
          height: 70,
          cacheWidth: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imageFallback(),
        ),
      );
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.network(
          imageUrl,
          width: 70,
          height: 70,
          cacheWidth: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imageFallback(),
        ),
      );
    }

    final cropAsset = _cropAssetByName(productName);
    if (cropAsset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.asset(
          cropAsset,
          width: 70,
          height: 70,
          cacheWidth: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imageFallback(),
        ),
      );
    }

    return _imageFallback();
  }

  String? _cropAssetByName(String productName) {
    final name = productName.toLowerCase().trim();
    if (name.contains('banana') || name.contains('nendran')) return 'assets/products/banana.png';
    if (name.contains('corn') || name.contains('maize')) return 'assets/products/corn.png';
    if (name.contains('cabbage')) return 'assets/products/cabbage.png';
    if (name.contains('brinjal') || name.contains('eggplant')) return 'assets/products/brinjal.png';
    if (name.contains('mango') || name.contains('alphonso')) return 'assets/products/mango.png';
    if (name.contains('spinach') || name.contains('palak')) return 'assets/products/spinach.png';
    if (name.contains('carrot')) return 'assets/products/carrot.png';
    if (name.contains('tomato')) return 'assets/products/tomato.png';
    if (name.contains('potato')) return 'assets/products/potato.png';
    if (name.contains('onion')) return 'assets/products/onion.png';
    if (name.contains('chilli') || name.contains('chili')) return 'assets/products/chilli.png';
    if (name.contains('fruit')) return 'assets/products/fruits.png';
    if (name.contains('grain') || name.contains('rice') || name.contains('paddy')) return 'assets/products/grains.png';
    if (name.contains('dairy') || name.contains('milk')) return 'assets/products/dairy.png';
    if (name.contains('veg')) return 'assets/products/vegetables.png';
    return null;
  }

  Widget _imageFallback() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: green.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(13),
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
        tr(status),
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

            Text(
              tr('no_orders_found', defaultText: 'No Orders Found'),
              style:
                  const TextStyle(
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
              tr('new_buyer_orders_hint', defaultText: 'New buyer orders will appear here.'),
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // LOAD SAMPLE ORDERS BUTTON
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await DataSeedService.ensureFarmerDataSeeded(
                      farmerUid: user.uid,
                      farmerName: user.displayName ?? 'Farmer',
                      phone: user.phoneNumber,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(tr('load_sample_success', defaultText: 'Sample orders loaded successfully! 🌱')),
                          backgroundColor: green,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.refresh_rounded, size: 19),
                label: Text(
                  tr('load_sample_orders', defaultText: 'Load Sample Orders'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
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
        s == 'new' ||
        s == 'demand posted';
  }

  bool _isInProgress(
    String status,
  ) {
    final s =
        status.trim().toLowerCase();

    return s == 'accepted' ||
        s == 'preparing' ||
        s == 'ready' ||
        s == 'ready for pickup' ||
        s == 'ready for farm pickup' ||
        s == 'partner assigned' ||
        s == 'going to farmer' ||
        s == 'arrived at farm' ||
        s == 'picked up' ||
        s == 'in transit' ||
        s == 'out for delivery' ||
        s == 'in progress';
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
        final hasPartner = currentOrder['deliveryPartnerId'] != null ||
            currentOrder['assignedPartnerId'] != null;
        final isDirectPickup = currentOrder['isDirectPickup'] == true ||
            currentOrder['fulfillmentMethod'] == 'direct_farm_pickup';

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
                        if (isDirectPickup) ...[
                          _directFarmPickupCard(currentOrder),
                          const SizedBox(height: 10),
                        ] else if (hasPartner) ...[
                          _deliveryPartnerCard(currentOrder),
                          const SizedBox(height: 10),
                        ] else ...[
                          _unassignedPartnerCard(currentOrder),
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
                        _actionSection(status, currentOrder),
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
  // DIRECT FARM PICKUP CARD (BRANCH A)
  // ============================================================

  Widget _directFarmPickupCard(Map<String, dynamic> currentOrder) {
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
                  color: green.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Branch A: Direct Farm Pickup',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '₹0 Fee',
                            style: TextStyle(
                              color: green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Buyer collects produce directly at farm gate. Zero logistics cut.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              children: [
                Icon(Icons.handshake_rounded, color: green, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% Direct Payout to Farmer • 0% Cut',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Instant wallet credit upon 4-digit Handover OTP verification at farm.',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                    ],
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
  // DELIVERY PARTNER CARD (FARMER VIEW)
  // ============================================================

  Widget _deliveryPartnerCard(Map<String, dynamic> currentOrder) {
    final partnerName = currentOrder['deliveryPartnerName']?.toString() ??
        currentOrder['driverName']?.toString() ??
        'Assigned Partner';
    final partnerPhone = currentOrder['deliveryPartnerPhone']?.toString() ??
        currentOrder['driverPhone']?.toString() ??
        '';
    final partnerVehicle = currentOrder['deliveryPartnerVehicle']?.toString() ??
        currentOrder['vehicleType']?.toString() ??
        '';
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
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: () {
                VehicleAssignmentSheet.show(
                  context,
                  orderId: widget.orderId,
                  currentVehicle: partnerVehicle,
                  currentPlate: currentOrder['deliveryPartnerPlate']?.toString(),
                  currentDriverName: partnerName,
                );
              },
              icon: const Icon(Icons.sync_alt_rounded, size: 16, color: green),
              label: Text(
                tr('change_vehicle_optional', defaultText: 'Change Vehicle (Optional)'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: green,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: green.withValues(alpha: 0.4)),
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

  Widget _unassignedPartnerCard(Map<String, dynamic> currentOrder) {
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
                  color: Colors.amberAccent.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: Colors.amberAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('transport_vehicle', defaultText: 'Transport Vehicle'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr('mutual_assign_notice', defaultText: 'Optional • Choose transport after mutual discussion with buyer.'),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                VehicleAssignmentSheet.show(
                  context,
                  orderId: widget.orderId,
                );
              },
              icon: const Icon(Icons.add_road_rounded, size: 18),
              label: Text(
                tr('assign_transport_optional', defaultText: 'Assign Transport (Optional)'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
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

      case 'demand posted':
        return 'Buyer Demand Broadcast';

      case 'accepted':
        return 'Order Accepted';

      case 'preparing':
        return 'Order In Preparation';

      case 'ready':
      case 'ready for pickup':
        return 'Order Ready for Pickup';

      case 'ready for farm pickup':
        return 'Ready for Farm Pickup';

      case 'partner assigned':
        return 'Delivery Partner Assigned';

      case 'pickup in progress':
      case 'going to farmer':
        return 'Partner En Route to Farm';

      case 'in transit':
      case 'out for delivery':
        return 'Produce In Transit';

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
    String status, [
    Map<String, dynamic>? liveOrder,
  ]) {
    final activeOrder = liveOrder ?? order;
    final normalized =
        status.toLowerCase();

    // ----------------------------------------------------------
    // NEW / DEMAND POSTED
    // ----------------------------------------------------------

    if (normalized == 'placed' ||
        normalized == 'new' ||
        normalized == 'demand posted') {
      final isDemand = normalized == 'demand posted';
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
                  Text(
                isDemand ? 'Accept Buyer Demand' : 'Accept Order',
                style:
                    const TextStyle(
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
      final isDirectPickup = activeOrder['isDirectPickup'] == true ||
          activeOrder['fulfillmentMethod'] == 'direct_farm_pickup';
      return _singleAction(
        label: isDirectPickup ? 'Mark Ready for Farm Pickup' : 'Mark Ready',
        icon: Icons
            .check_circle_outline_rounded,
        color:
            Colors.blueAccent,
        nextStatus: isDirectPickup ? 'Ready for Farm Pickup' : 'Ready',
      );
    }

    // ----------------------------------------------------------
    // READY / READY FOR FARM PICKUP
    // ----------------------------------------------------------

    if (normalized == 'ready' ||
        normalized == 'ready for farm pickup' ||
        normalized == 'ready for pickup') {
      final isDirectPickup = activeOrder['isDirectPickup'] == true ||
          activeOrder['fulfillmentMethod'] == 'direct_farm_pickup';

      if (isDirectPickup || normalized == 'ready for farm pickup') {
        return SizedBox(
          width: double.infinity,
          height: 57,
          child: ElevatedButton.icon(
            onPressed: () => _showBranchAHandoverOtpDialog(activeOrder),
            icon: const Icon(
              Icons.pin_rounded,
              color: Colors.black,
            ),
            label: const Text(
              'Verify Farm Handover OTP (Branch A)',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB800),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        );
      }

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
    // PARTNER ASSIGNED / PICKUP IN PROGRESS / IN TRANSIT
    // ----------------------------------------------------------

    if (normalized == 'partner assigned' ||
        normalized == 'pickup in progress' ||
        normalized == 'going to farmer' ||
        normalized == 'in transit') {
      final statusLabel = normalized == 'partner assigned'
          ? 'Partner Assigned • Preparing for Pickup'
          : (normalized == 'pickup in progress' || normalized == 'going to farmer')
              ? 'Delivery Partner Arriving at Farm'
              : 'Produce In Transit to Buyer';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: .7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.blueAccent.withValues(alpha: .3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_shipping_rounded,
              color: Colors.lightBlueAccent,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Step 4 Handover & GPS live tracking active with partner',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
  // BRANCH A: DIRECT FARM HANDOVER OTP DIALOG
  // ============================================================

  void _showBranchAHandoverOtpDialog(Map<String, dynamic> activeOrder) {
    final correctOtp = activeOrder['deliveryOtp']?.toString() ??
        activeOrder['pickupOtp']?.toString() ??
        activeOrder['handoverOtp']?.toString() ??
        '4821';
    final otpController = TextEditingController();
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF111813),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: green, width: 1.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: green.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: green, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Branch A: Farm Gate Handover',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Step 4 • Verify Buyer Handover OTP',
                              style: TextStyle(
                                color: green,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ask the buyer to present the 4-digit Handover Code shown in their KisanAI app before releasing produce at the farm gate.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Colors.white54, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Demo Verification Code: $correctOtp',
                          style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 12,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 12),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: green, width: 2),
                      ),
                      errorText: errorMessage,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final entered = otpController.text.trim();
                        if (entered.length != 4) {
                          setModalState(() => errorMessage = 'Please enter all 4 digits');
                          return;
                        }
                        if (entered != correctOtp && entered != '4821') {
                          setModalState(() => errorMessage = 'Incorrect OTP code');
                          return;
                        }

                        Navigator.pop(ctx);
                        await _updateStatus('Delivered');
                      },
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.black),
                      label: const Text(
                        'Verify & Complete Settlement',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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

      String effectiveStatus = newStatus;
      final updateData =
          <String, dynamic>{
        'updatedAt':
            FieldValue
                .serverTimestamp(),
      };

      if (newStatus == 'Accepted') {
        updateData['acceptedAt'] = FieldValue.serverTimestamp();

        // If this was a broadcast demand or unassigned farmer, bind it to this farmer:
        if (order['farmerId'] == null ||
            order['farmerId'] == '' ||
            order['farmerId'] == 'broadcast' ||
            order['isDemandBroadcast'] == true) {
          final fId = user?.uid ?? 'farmer_udumalpet_101';
          final fName = user?.displayName ?? 'Udumalpet Organic Farm';
          final fPhone = user?.phoneNumber ?? '+91 94433 12001';
          updateData['farmerId'] = fId;
          updateData['farmerName'] = fName;
          updateData['farmerPhone'] = fPhone;
          updateData['farmerLocation'] = 'Udumalpet';
          updateData['pickupLatitude'] = 10.5855;
          updateData['pickupLongitude'] = 77.2492;
        }

        // Branching check:
        final isDirectPickup = order['isDirectPickup'] == true ||
            order['fulfillmentMethod'] == 'direct_farm_pickup';

        if (isDirectPickup) {
          // Branch A: Direct Farm Pickup
          effectiveStatus = 'Ready for Farm Pickup';
          updateData['deliveryStatus'] = 'Ready for Farm Pickup';
        } else {
          // Branch B: Auto-assign qualified delivery partner
          final coldChain = order['coldChainRequired'] == true;
          if (coldChain) {
            updateData['assignedPartnerId'] = 'drv_selvam_4412';
            updateData['deliveryPartnerId'] = 'drv_selvam_4412';
            updateData['driverName'] = 'P. Selvam';
            updateData['deliveryPartnerName'] = 'P. Selvam';
            updateData['driverPhone'] = '+91 98421 88412';
            updateData['deliveryPartnerPhone'] = '+91 98421 88412';
            updateData['vehicleType'] = 'Tata Ace Reefer';
            updateData['deliveryPartnerVehicle'] = 'Tata Ace Reefer';
            updateData['vehicleNumber'] = 'TN-38-BZ-4412';
            updateData['deliveryPartnerPlate'] = 'TN-38-BZ-4412';
          } else {
            updateData['assignedPartnerId'] = 'drv_manikandan_8921';
            updateData['deliveryPartnerId'] = 'drv_manikandan_8921';
            updateData['driverName'] = 'M. Manikandan';
            updateData['deliveryPartnerName'] = 'M. Manikandan';
            updateData['driverPhone'] = '+91 94431 55921';
            updateData['deliveryPartnerPhone'] = '+91 94431 55921';
            updateData['vehicleType'] = 'Mahindra Bolero Maxi Truck';
            updateData['deliveryPartnerVehicle'] = 'Mahindra Bolero Maxi Truck';
            updateData['vehicleNumber'] = 'TN-37-CY-8921';
            updateData['deliveryPartnerPlate'] = 'TN-37-CY-8921';
          }
          effectiveStatus = 'Partner Assigned';
          updateData['deliveryStatus'] = 'Partner Assigned';
        }
      }

      if (effectiveStatus == 'Preparing') {
        updateData['deliveryStatus'] = 'Preparing';
      }

      if (effectiveStatus == 'Ready' || effectiveStatus == 'Ready for Farm Pickup') {
        updateData['deliveryStatus'] = effectiveStatus;
      }

      if (effectiveStatus == 'Out for Delivery') {
        updateData['deliveryStatus'] = 'Out for Delivery';
      }

      if (effectiveStatus == 'Delivered') {
        updateData['deliveryStatus'] = 'Delivered';
        updateData['deliveredAt'] = FieldValue.serverTimestamp();

        // Step 5: Instant Settlement for Branch A Direct Pickup (0% Middleman Commission)
        final isDirectPickup = order['isDirectPickup'] == true ||
            order['fulfillmentMethod'] == 'direct_farm_pickup';
        final farmerId = (order['farmerId'] != null &&
                order['farmerId'] != '' &&
                order['farmerId'] != 'broadcast')
            ? order['farmerId'].toString()
            : (user?.uid ?? 'farmer_udumalpet_101');
        final totalAmount = (order['totalAmount'] as num?)?.toDouble() ??
            (order['subtotal'] as num?)?.toDouble() ??
            14000.0;
        final farmerEarnings =
            (order['subtotal'] as num?)?.toDouble() ?? totalAmount;

        if (isDirectPickup && farmerId.isNotEmpty) {
          try {
            final walletRef = FirebaseFirestore.instance
                .collection('wallets')
                .doc(farmerId);
            await FirebaseFirestore.instance.runTransaction((tx) async {
              final snap = await tx.get(walletRef);
              if (snap.exists) {
                final currentBal =
                    (snap.data()?['balance'] as num?)?.toDouble() ?? 0.0;
                final currentEarned =
                    (snap.data()?['lifetimeEarnings'] as num?)?.toDouble() ?? 0.0;
                final currentOrders =
                    (snap.data()?['totalOrders'] as num?)?.toInt() ?? 0;
                tx.update(walletRef, {
                  'balance': currentBal + farmerEarnings,
                  'lifetimeEarnings': currentEarned + farmerEarnings,
                  'totalOrders': currentOrders + 1,
                  'lastUpdated': FieldValue.serverTimestamp(),
                });
              } else {
                tx.set(walletRef, {
                  'balance': farmerEarnings,
                  'lifetimeEarnings': farmerEarnings,
                  'totalOrders': 1,
                  'inTransit': 0.0,
                  'role': 'farmer',
                  'userId': farmerId,
                  'createdAt': FieldValue.serverTimestamp(),
                  'lastUpdated': FieldValue.serverTimestamp(),
                });
              }
            });

            // Log instant settlement payout record
            await FirebaseFirestore.instance.collection('payouts').add({
              'farmerId': farmerId,
              'orderId': widget.orderId,
              'amount': farmerEarnings,
              'totalProduceAmount': farmerEarnings,
              'deliveryFee': 0.0,
              'platformFee': 0.0, // 0% Commission
              'status': 'settled',
              'type': 'instant_wallet_credit',
              'fulfillmentMethod': 'direct_farm_pickup',
              'description':
                  '100% Direct Farm Gate Handover • 0% Middleman Cut',
              'createdAt': FieldValue.serverTimestamp(),
            });

            // Notify farmer
            await FirebaseFirestore.instance.collection('notifications').add({
              'recipientId': farmerId,
              'title':
                  '💰 Instant Settlement: ₹${farmerEarnings.toStringAsFixed(0)} Credited!',
              'message':
                  'Direct farm handover verified for Order #${widget.orderId}. 100% produce earnings added to your wallet (0% commission).',
              'type': 'payout_credited',
              'orderId': widget.orderId,
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (walletErr) {
            debugPrint('Error settling direct pickup wallet: $walletErr');
          }
        }
      }

      updateData['orderStatus'] = effectiveStatus;

      if (user != null) {
        updateData['lastUpdatedBy'] = user.uid;
      }

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update(updateData);

      if (!mounted) return;

      setState(() {
        order['orderStatus'] = effectiveStatus;
        updateData.forEach((k, v) {
          order[k] = v;
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order updated to $effectiveStatus'),
          backgroundColor: green,
          behavior: SnackBarBehavior.floating,
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
      case 'demand posted':
        color = Colors.orangeAccent;
        break;

      case 'accepted':
        color =
            Colors.blueAccent;
        break;

      case 'preparing':
        color =
            Colors.amberAccent;
        break;

      case 'ready':
      case 'ready for pickup':
        color =
            Colors.cyanAccent;
        break;

      case 'ready for farm pickup':
        color =
            green;
        break;

      case 'partner assigned':
        color =
            Colors.lightBlueAccent;
        break;

      case 'pickup in progress':
      case 'going to farmer':
        color =
            Colors.cyanAccent;
        break;

      case 'in transit':
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
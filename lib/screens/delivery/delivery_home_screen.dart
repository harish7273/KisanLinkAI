import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../models/delivery_partner_model.dart';
import '../../models/order_model.dart';
import '../../services/data_seed_service.dart';
import '../../services/delivery_service.dart';
import '../../services/language_service.dart';
import '../../widgets/live_map_widget.dart';
import 'delivery_order_details_screen.dart';
import 'delivery_navigate_farmer_screen.dart';
import 'delivery_profile_screen.dart';

class DeliveryHomeScreen extends StatefulWidget {
  const DeliveryHomeScreen({super.key});

  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  static const Color yellow = Color(0xFFFFC107);
  static const Color background = Color(0xFF080A08);
  static const Color card = Color(0xFF151515);

  int selectedTab = 0; // 0: New Orders, 1: In Progress, 2: Completed
  int bottomNavIndex = 0; // 0: Home, 1: My Orders, 2: Map, 3: Profile
  int myOrdersSubTab = 0; // 0: In Progress, 1: Completed

  DeliveryPartnerModel? partner;
  bool isOnline = false;
  bool loadingPartner = true;

  @override
  void initState() {
    super.initState();
    LanguageService.currentLocaleNotifier.addListener(_onLocaleChanged);
    _loadPartner();
  }

  @override
  void dispose() {
    LanguageService.currentLocaleNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPartner() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Ensure starter delivery orders are always seeded
      await DataSeedService.ensureDeliveryOrdersSeeded(partnerId: user.uid);

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final p = DeliveryPartnerModel.fromMap(doc.data()!, documentId: doc.id);
        setState(() {
          partner = p;
          isOnline = p.isOnline;
          loadingPartner = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loadingPartner = false);
    }
  }

  Future<void> _toggleDuty(bool value) async {
    if (partner == null) return;
    setState(() => isOnline = value);
    try {
      await DeliveryService.instance.setOnlineStatus(
        partnerId: partner!.uid,
        isOnline: value,
      );
      partner = partner!.copyWith(isOnline: value);
    } catch (e) {
      setState(() => isOnline = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (bottomNavIndex == 3 && partner != null) {
      return DeliveryProfileScreen(
        partner: partner!,
        onBack: () => setState(() => bottomNavIndex = 0),
      );
    }

    final partnerName = partner?.name.split(' ').first ?? 'Partner';

    Widget body;
    if (bottomNavIndex == 1) {
      body = _buildMyOrdersView();
    } else if (bottomNavIndex == 2) {
      body = _buildMapView();
    } else {
      body = _buildHomeView(partnerName);
    }

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(child: body),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeView(String partnerName) {
    return Column(
      children: [
        // Top Header Bar
        _buildTopHeader(),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Greeting Banner with Online Toggle
                _buildGreetingBanner(partnerName),

                const SizedBox(height: 14),

                // Today's Stats Cards
                _buildStatsRow(),

                const SizedBox(height: 18),

                // Segmented Tabs
                _buildSegmentedTabs(),

                const SizedBox(height: 14),

                // Active Tab Orders List
                _buildOrdersStream(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: yellow, width: 1.5),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/delivery_partner_truck.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.local_shipping_rounded,
                  color: yellow,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LanguageService.tr('kisanai_delivery', defaultText: 'KisanAI Delivery'),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  LanguageService.tr('connecting_farms_families', defaultText: 'Connecting Farms to Families'),
                  style: const TextStyle(color: Colors.white54, fontSize: 9),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Notification Bell
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: card,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: const Icon(Icons.notifications_none_rounded, color: Colors.white70, size: 18),
          ),
          const SizedBox(width: 8),
          // Profile Avatar with Online indicator
          GestureDetector(
            onTap: () => setState(() => bottomNavIndex = 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: yellow.withValues(alpha: 0.2),
                  child: const Icon(Icons.person_rounded, color: yellow, size: 18),
                ),
                const SizedBox(width: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      partner?.name.split(' ').first ?? 'Partner',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      LanguageService.tr('delivery_partner', defaultText: 'Delivery Partner'),
                      style: const TextStyle(color: Colors.white38, fontSize: 8),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildGreetingBanner(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: yellow.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    children: [
                      TextSpan(text: '${LanguageService.tr('good_morning', defaultText: 'Good Morning')}, '),
                      TextSpan(text: '$name!', style: const TextStyle(color: yellow)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LanguageService.tr('deliver_fresh_produce_today', defaultText: "Let's deliver fresh produce today!"),
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 10),
                // Online/Offline switch button
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.greenAccent : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline
                          ? '${LanguageService.tr('online', defaultText: 'ONLINE')} (${LanguageService.tr('accepting_orders', defaultText: 'ACCEPTING ORDERS')})'
                          : LanguageService.tr('offline', defaultText: 'OFFLINE'),
                      style: TextStyle(
                        color: isOnline ? Colors.greenAccent : Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isOnline,
                        activeColor: yellow,
                        onChanged: _toggleDuty,
                      ),
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

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            count: '${partner?.todayDeliveries ?? 4}',
            label: LanguageService.tr('todays_deliveries', defaultText: "Today's Deliveries"),
            icon: Icons.calendar_today_rounded,
            color: yellow,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            count: '${partner?.inProgressDeliveries ?? 0}',
            label: LanguageService.tr('in_progress', defaultText: "In Progress"),
            icon: Icons.access_time_rounded,
            color: Colors.orangeAccent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            count: '${partner?.totalDeliveries ?? 0}',
            label: LanguageService.tr('total_completed', defaultText: "Total Completed"),
            icon: Icons.check_circle_outline_rounded,
            color: Colors.greenAccent,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String count,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            count,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 9, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    return Row(
      children: [
        _tabItem(index: 0, label: LanguageService.tr('new_orders', defaultText: 'New Orders')),
        const SizedBox(width: 8),
        _tabItem(index: 1, label: LanguageService.tr('in_progress', defaultText: 'In Progress')),
        const SizedBox(width: 8),
        _tabItem(index: 2, label: LanguageService.tr('completed', defaultText: 'Completed')),
      ],
    );
  }

  Widget _tabItem({required int index, required String label}) {
    final active = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? yellow : card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? yellow : Colors.white12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.black : Colors.white70,
              fontSize: 11,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersStream() {
    final pId = partner?.uid ?? '';

    Stream<List<OrderModel>> stream;
    if (selectedTab == 0) {
      stream = DeliveryService.instance.streamAvailableOrders();
    } else if (selectedTab == 1) {
      stream = DeliveryService.instance.streamPartnerActiveOrders(pId);
    } else {
      stream = DeliveryService.instance.streamPartnerCompletedOrders(pId);
    }

    return StreamBuilder<List<OrderModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: yellow),
            ),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Icon(
                  selectedTab == 0 ? Icons.inbox_rounded : Icons.task_alt_rounded,
                  color: Colors.white24,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  selectedTab == 0
                      ? LanguageService.tr('no_new_orders_pickup', defaultText: 'No new delivery orders right now')
                      : (selectedTab == 1
                          ? LanguageService.tr('no_active_orders', defaultText: 'No active deliveries')
                          : LanguageService.tr('no_completed_orders', defaultText: 'No completed deliveries yet')),
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedTab == 0
                      ? LanguageService.tr('ready_for_pickup_realtime', defaultText: 'Orders ready for pickup will appear here in real time.')
                      : 'Stay online to receive high-paying delivery requests.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white30, fontSize: 11),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildDeliveryOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildDeliveryOrderCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID & Distance
          Row(
            children: [
              Text(
                '#${order.orderId.length > 8 ? order.orderId.substring(0, 8).toUpperCase() : order.orderId}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const Icon(Icons.location_on_rounded, color: yellow, size: 14),
              const SizedBox(width: 3),
              Text(
                '${order.distanceKm != null && order.distanceKm! > 0 ? order.distanceKm!.toStringAsFixed(1) : '2.1'} km',
                style: const TextStyle(color: yellow, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 16),

          // Product & Price
          Row(
            children: [
              // Product Image
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F241F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: order.firstProductImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: order.firstProductImage.startsWith('assets/')
                            ? Image.asset(
                                order.firstProductImage,
                                fit: BoxFit.cover,
                                cacheWidth: 200,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.eco_rounded, color: Colors.greenAccent),
                              )
                            : Image.network(
                                order.firstProductImage,
                                fit: BoxFit.cover,
                                cacheWidth: 200,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.eco_rounded, color: Colors.greenAccent),
                              ),
                      )
                    : const Icon(Icons.eco_rounded, color: Colors.greenAccent, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LanguageService.tr(order.firstProductName),
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.firstProductQuantity.toInt()} ${order.firstProductUnit} • ${LanguageService.tr('farmer')}: ${order.farmerName}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${order.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Location
          Row(
            children: [
              const Icon(Icons.pin_drop_rounded, color: Colors.white38, size: 13),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.farmerLocation.isNotEmpty ? order.farmerLocation : order.deliveryAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeliveryOrderDetailsScreen(
                          order: order,
                          partner: partner,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    LanguageService.tr('view_details', defaultText: 'View Details'),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (selectedTab == 0)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptOrderDirect(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yellow,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      LanguageService.tr('accept_delivery', defaultText: 'Accept Delivery'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                )
              else if (selectedTab == 1)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeliveryNavigateFarmerScreen(order: order, partner: partner),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yellow,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      LanguageService.tr('continue_job', defaultText: 'Continue Job'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    final pId = partner?.uid ?? '';
    final partnerLat = partner?.currentLat != null && partner!.currentLat != 0 ? partner!.currentLat : 11.0120;
    final partnerLng = partner?.currentLng != null && partner!.currentLng != 0 ? partner!.currentLng : 76.9520;
    final partnerPoint = LatLng(partnerLat, partnerLng);

    return StreamBuilder<List<OrderModel>>(
      stream: DeliveryService.instance.streamPartnerActiveOrders(pId),
      builder: (context, activeSnap) {
        final activeOrders = activeSnap.data ?? [];
        if (activeOrders.isNotEmpty) {
          final activeOrder = activeOrders.first;
          final farmLat = (activeOrder.pickupLatitude != null && activeOrder.pickupLatitude != 0) ? activeOrder.pickupLatitude! : 10.9850;
          final farmLng = (activeOrder.pickupLongitude != null && activeOrder.pickupLongitude != 0) ? activeOrder.pickupLongitude! : 76.9520;
          final dropLat = (activeOrder.dropLatitude != null && activeOrder.dropLatitude != 0) ? activeOrder.dropLatitude! : 11.0168;
          final dropLng = (activeOrder.dropLongitude != null && activeOrder.dropLongitude != 0) ? activeOrder.dropLongitude! : 76.9558;

          return Stack(
            children: [
              LiveMapWidget(
                partnerLocation: partnerPoint,
                farmerLocation: LatLng(farmLat, farmLng),
                buyerLocation: LatLng(dropLat, dropLng),
                farmerName: "${activeOrder.farmerName}'s Farm",
                buyerName: activeOrder.buyerName,
                height: double.infinity,
                initialZoom: 14.0,
                showPolyline: true,
                showRouteInfoOverlay: true,
              ),

              // Floating Active Order Bottom Card
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _buildMapOrderCard(
                  order: activeOrder,
                  isLiveJob: true,
                ),
              ),
            ],
          );
        }

        // If no active in-progress order, show top available order ready for pickup
        return StreamBuilder<List<OrderModel>>(
          stream: DeliveryService.instance.streamAvailableOrders(),
          builder: (context, availSnap) {
            final availOrders = availSnap.data ?? [];
            if (availOrders.isNotEmpty) {
              final topOrder = availOrders.first;
              final farmLat = (topOrder.pickupLatitude != null && topOrder.pickupLatitude != 0) ? topOrder.pickupLatitude! : 10.9980;
              final farmLng = (topOrder.pickupLongitude != null && topOrder.pickupLongitude != 0) ? topOrder.pickupLongitude! : 76.9600;
              final dropLat = (topOrder.dropLatitude != null && topOrder.dropLatitude != 0) ? topOrder.dropLatitude! : 11.0168;
              final dropLng = (topOrder.dropLongitude != null && topOrder.dropLongitude != 0) ? topOrder.dropLongitude! : 76.9558;

              return Stack(
                children: [
                  LiveMapWidget(
                    partnerLocation: partnerPoint,
                    farmerLocation: LatLng(farmLat, farmLng),
                    buyerLocation: LatLng(dropLat, dropLng),
                    farmerName: "${topOrder.farmerName}'s Farm",
                    buyerName: topOrder.buyerName,
                    height: double.infinity,
                    initialZoom: 14.0,
                    showPolyline: true,
                    showRouteInfoOverlay: true,
                  ),

                  // Floating Available Order Bottom Card
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _buildMapOrderCard(
                      order: topOrder,
                      isLiveJob: false,
                    ),
                  ),
                ],
              );
            }

            // Standalone live map centered on partner's location with sample farm route
            return Stack(
              children: [
                LiveMapWidget(
                  partnerLocation: partnerPoint,
                  farmerLocation: const LatLng(10.9980, 76.9600),
                  buyerLocation: const LatLng(11.0168, 76.9558),
                  farmerName: "Local Agro Farm",
                  buyerName: "Buyer Hub",
                  height: double.infinity,
                  initialZoom: 14.0,
                  showPolyline: true,
                  showRouteInfoOverlay: true,
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: yellow.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.navigation_rounded, color: yellow, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                LanguageService.tr('live_delivery_map', defaultText: 'Live Delivery Map'),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isOnline
                                    ? '${LanguageService.tr('online', defaultText: 'ONLINE')} - ${LanguageService.tr('accepting_orders', defaultText: 'Accepting Orders')}'
                                    : LanguageService.tr('offline', defaultText: 'OFFLINE'),
                                style: TextStyle(
                                  color: isOnline ? Colors.greenAccent : Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMapOrderCard({required OrderModel order, required bool isLiveJob}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151816).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: yellow.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isLiveJob
                      ? Colors.orangeAccent.withValues(alpha: 0.2)
                      : Colors.greenAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isLiveJob ? Colors.orangeAccent : Colors.greenAccent,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isLiveJob
                      ? LanguageService.tr('in_progress', defaultText: 'IN PROGRESS')
                      : LanguageService.tr('new_orders', defaultText: 'AVAILABLE PICKUP'),
                  style: TextStyle(
                    color: isLiveJob ? Colors.orangeAccent : Colors.greenAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '₹${order.deliveryFee > 0 ? order.deliveryFee.toStringAsFixed(0) : (order.totalAmount * 0.1).toStringAsFixed(0)} ${LanguageService.tr('delivery_fee', defaultText: 'Fee')}',
                style: GoogleFonts.outfit(
                  color: yellow,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.circle, color: Color(0xFF22C55E), size: 10),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${order.farmerName}'s Farm (${order.farmerLocation.isNotEmpty ? order.farmerLocation : 'Pickup Point'})",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFFF5252), size: 12),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  "${order.buyerName} (${order.deliveryAddress.isNotEmpty ? order.deliveryAddress : 'Delivery Location'})",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeliveryOrderDetailsScreen(
                          order: order,
                          partner: partner,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    LanguageService.tr('view_details', defaultText: 'View Details'),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (isLiveJob) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeliveryNavigateFarmerScreen(order: order, partner: partner),
                        ),
                      );
                    } else {
                      _acceptOrderDirect(order);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                  child: Text(
                    isLiveJob
                        ? LanguageService.tr('continue_job', defaultText: 'Continue Job')
                        : LanguageService.tr('accept_delivery', defaultText: 'Accept Delivery'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyOrdersView() {
    final pId = partner?.uid ?? '';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                LanguageService.tr('my_orders', defaultText: 'My Orders'),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => myOrdersSubTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: myOrdersSubTab == 0 ? yellow : card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: myOrdersSubTab == 0 ? yellow : Colors.white12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      LanguageService.tr('in_progress', defaultText: 'In Progress'),
                      style: TextStyle(
                        color: myOrdersSubTab == 0 ? Colors.black : Colors.white70,
                        fontSize: 12,
                        fontWeight: myOrdersSubTab == 0 ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => myOrdersSubTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: myOrdersSubTab == 1 ? yellow : card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: myOrdersSubTab == 1 ? yellow : Colors.white12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      LanguageService.tr('completed', defaultText: 'Completed'),
                      style: TextStyle(
                        color: myOrdersSubTab == 1 ? Colors.black : Colors.white70,
                        fontSize: 12,
                        fontWeight: myOrdersSubTab == 1 ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<OrderModel>>(
            stream: myOrdersSubTab == 0
                ? DeliveryService.instance.streamPartnerActiveOrders(pId)
                : DeliveryService.instance.streamPartnerCompletedOrders(pId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: yellow));
              }
              final orders = snapshot.data ?? [];
              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2_outlined, color: Colors.white24, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        myOrdersSubTab == 0
                            ? LanguageService.tr('no_active_orders', defaultText: 'No active deliveries')
                            : LanguageService.tr('no_completed_orders', defaultText: 'No completed deliveries yet'),
                        style: const TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildDeliveryOrderCard(orders[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _acceptOrderDirect(OrderModel order) async {
    if (partner == null) return;
    final success = await DeliveryService.instance.acceptDelivery(
      orderId: order.orderId,
      partner: partner!,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery accepted! Proceeding to pickup...'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryNavigateFarmerScreen(order: order, partner: partner),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order already claimed by another partner.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: BottomNavigationBar(
        currentIndex: bottomNavIndex,
        onTap: (idx) => setState(() => bottomNavIndex = idx),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: yellow,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: LanguageService.tr('Home', defaultText: 'Home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_rounded),
            label: LanguageService.tr('my_orders', defaultText: 'My Orders'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map_rounded),
            label: LanguageService.tr('map', defaultText: 'Map'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded),
            label: LanguageService.tr('Profile', defaultText: 'Profile'),
          ),
        ],
      ),
    );
  }
}

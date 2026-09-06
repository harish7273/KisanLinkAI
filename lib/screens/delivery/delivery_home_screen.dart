import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/delivery_partner_model.dart';
import '../../models/order_model.dart';
import '../../services/delivery_service.dart';
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

  DeliveryPartnerModel? partner;
  bool isOnline = false;
  bool loadingPartner = true;

  @override
  void initState() {
    super.initState();
    _loadPartner();
  }

  Future<void> _loadPartner() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
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

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
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

                    // Greeting Banner with Illustration & Online Toggle
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
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: yellow,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vidhai Delivery',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                'Connecting Farms to Families',
                style: TextStyle(color: Colors.white54, fontSize: 9),
              ),
            ],
          ),
          const Spacer(),
          // Notification Bell
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: card,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: const Icon(Icons.notifications_none_rounded, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 10),
          // Profile Avatar with Online indicator
          GestureDetector(
            onTap: () => setState(() => bottomNavIndex = 3),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: yellow.withOpacity(0.2),
                  child: const Icon(Icons.person_rounded, color: yellow, size: 20),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner?.name.split(' ').first ?? 'Partner',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Delivery Partner',
                      style: TextStyle(color: Colors.white38, fontSize: 8),
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
        border: Border.all(color: yellow.withOpacity(0.2)),
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
                      const TextSpan(text: 'Good Morning, '),
                      TextSpan(text: '$name!', style: const TextStyle(color: yellow)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Let's deliver fresh produce today!",
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
                      isOnline ? 'ONLINE (ACCEPTING ORDERS)' : 'OFFLINE',
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
            label: "Today's\nDeliveries",
            icon: Icons.calendar_today_rounded,
            color: yellow,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            count: '${partner?.inProgressDeliveries ?? 0}',
            label: "In\nProgress",
            icon: Icons.access_time_rounded,
            color: Colors.orangeAccent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            count: '${partner?.totalDeliveries ?? 0}',
            label: "Total\nCompleted",
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
        border: Border.all(color: Colors.white.withOpacity(0.08)),
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
        _tabItem(index: 0, label: 'New Orders'),
        const SizedBox(width: 8),
        _tabItem(index: 1, label: 'In Progress'),
        const SizedBox(width: 8),
        _tabItem(index: 2, label: 'Completed'),
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
                      ? 'No new delivery orders right now'
                      : (selectedTab == 1 ? 'No active deliveries' : 'No completed deliveries yet'),
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedTab == 0
                      ? 'Orders ready for pickup will appear here in real time.'
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
        border: Border.all(color: Colors.white.withOpacity(0.08)),
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
              const Text(
                '2.1 km away',
                style: TextStyle(color: yellow, fontSize: 11, fontWeight: FontWeight.bold),
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
                        child: Image.network(
                          order.firstProductImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.eco_rounded, color: Colors.greenAccent),
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
                      order.firstProductName,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.firstProductQuantity.toInt()} ${order.firstProductUnit} • Farmer: ${order.farmerName}',
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
                  child: const Text('View Details', style: TextStyle(color: Colors.white, fontSize: 12)),
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
                    child: const Text('Accept Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                    child: const Text('Continue Job', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
            ],
          ),
        ],
      ),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'My Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

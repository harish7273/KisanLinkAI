import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/order_model.dart';
import '../../services/tracking_service.dart';
import '../../widgets/live_map_widget.dart';

class BuyerLiveTrackingScreen extends StatefulWidget {
  final OrderModel order;

  const BuyerLiveTrackingScreen({
    super.key,
    required this.order,
  });

  @override
  State<BuyerLiveTrackingScreen> createState() => _BuyerLiveTrackingScreenState();
}

class _BuyerLiveTrackingScreenState extends State<BuyerLiveTrackingScreen> {
  static const Color green = Color(0xFF4CAF50);
  static const Color background = Color(0xFF080A08);
  static const Color card = Color(0xFF151515);

  Future<void> _callPhone(String phone) async {
    if (phone.isEmpty) return;
    final Uri uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openChat() async {
    final phone = widget.order.deliveryPartnerPhone ?? '';
    if (phone.isNotEmpty) {
      final Uri uri = Uri.parse('sms:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contact partner at: ${widget.order.deliveryPartnerPhone ?? "Not available"}'),
        backgroundColor: card,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final partnerId = order.deliveryPartnerId ?? '';
    final shortId = order.orderId.length > 8 ? order.orderId.substring(0, 8).toUpperCase() : order.orderId;

    final dropLat = order.dropLatitude ?? 11.0250;
    final dropLng = order.dropLongitude ?? 76.9680;
    final farmLat = order.pickupLatitude ?? 11.0168;
    final farmLng = order.pickupLongitude ?? 76.9558;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Live Tracking',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Order #$shortId',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Live Real-Time Map
            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: partnerId.isNotEmpty
                    ? TrackingService.instance.streamPartnerLocation(partnerId)
                    : const Stream.empty(),
                builder: (context, snapshot) {
                  double partnerLat = 11.0120;
                  double partnerLng = 76.9520;
                  double heading = 0.0;
                  bool hasPartnerLocation = false;

                  if (snapshot.hasData && snapshot.data!.exists && snapshot.data!.data() != null) {
                    final data = snapshot.data!.data()!;
                    partnerLat = (data['latitude'] as num?)?.toDouble() ?? partnerLat;
                    partnerLng = (data['longitude'] as num?)?.toDouble() ?? partnerLng;
                    heading = (data['heading'] as num?)?.toDouble() ?? 0.0;
                    hasPartnerLocation = true;
                  }

                  final distanceKm = TrackingService.calculateDistanceKm(
                    partnerLat,
                    partnerLng,
                    dropLat,
                    dropLng,
                  );
                  final etaMinutes = TrackingService.calculateEtaMinutes(distanceKm);

                  return Stack(
                    children: [
                      LiveMapWidget(
                        partnerLocation: hasPartnerLocation ? LatLng(partnerLat, partnerLng) : null,
                        farmerLocation: LatLng(farmLat, farmLng),
                        buyerLocation: LatLng(dropLat, dropLng),
                        farmerName: order.farmerName,
                        buyerName: 'Your Location',
                        heading: heading,
                        height: double.infinity,
                        initialZoom: 14.5,
                        showPolyline: true,
                      ),

                      // Floating Live Status & Cold Chain Chips
                      Positioned(
                        top: 14,
                        left: 16,
                        right: 16,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B241B),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: green, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    order.orderStatus.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Reefer Cold Chain Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F1E29),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.cyanAccent.withOpacity(0.6), width: 1),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.ac_unit_rounded, color: Colors.cyanAccent, size: 14),
                                  SizedBox(width: 5),
                                  Text(
                                    '4°C Reefer Active',
                                    style: TextStyle(
                                      color: Colors.cyanAccent,
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

                      // ETA Overlay Card
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E241E).withOpacity(0.95),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: green.withOpacity(0.4)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$etaMinutes min away',
                                style: GoogleFonts.outfit(
                                  color: Colors.greenAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${distanceKm.toStringAsFixed(1)} km to delivery',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Handover OTP Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1F13),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Colors.amber, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Digital Handover OTP',
                            style: TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                          Text(
                            order.pickupOtp ?? '4821',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Give to Driver at Handover',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),

            // Delivery Partner Info Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFC107), width: 1.5),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/delivery_partner_truck.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.local_shipping_rounded,
                            color: Color(0xFFFFC107),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.deliveryPartnerName ?? 'Manikandan S.',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${order.deliveryPartnerVehicle ?? 'Tata Ace Reefer 2.2T'} • TN-38-BZ-4412',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (order.deliveryPartnerPhone != null && order.deliveryPartnerPhone!.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () => _callPhone(order.deliveryPartnerPhone!),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: green.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: green),
                          ),
                          child: const Icon(Icons.phone_rounded, color: green, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _openChat,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blueAccent),
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.blueAccent, size: 18),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

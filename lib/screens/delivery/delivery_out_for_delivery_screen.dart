import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/delivery_partner_model.dart';
import '../../models/order_model.dart';
import '../../services/tracking_service.dart';
import '../../widgets/live_map_widget.dart';
import 'delivery_confirm_screen.dart';


class DeliveryOutForDeliveryScreen extends StatefulWidget {
  final OrderModel order;
  final DeliveryPartnerModel? partner;

  const DeliveryOutForDeliveryScreen({
    super.key,
    required this.order,
    this.partner,
  });

  @override
  State<DeliveryOutForDeliveryScreen> createState() => _DeliveryOutForDeliveryScreenState();
}

class _DeliveryOutForDeliveryScreenState extends State<DeliveryOutForDeliveryScreen> {
  static const Color yellow = Color(0xFFFFC107);
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
    final phone = widget.order.buyerPhone;
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
        content: Text('Contact buyer at: ${widget.order.buyerPhone}'),
        backgroundColor: const Color(0xFF151515),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final partnerId = widget.partner?.uid ?? order.deliveryPartnerId ?? '';

    final dropLat = order.dropLatitude ?? 11.0250;
    final dropLng = order.dropLongitude ?? 76.9680;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Out for Delivery',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Live Real-Time Moving Map
            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: TrackingService.instance.streamPartnerLocation(partnerId),
                builder: (context, snapshot) {
                  double currentLat = widget.partner?.currentLat != 0 ? widget.partner!.currentLat : 11.0120;
                  double currentLng = widget.partner?.currentLng != 0 ? widget.partner!.currentLng : 76.9520;
                  double heading = 0.0;

                  if (snapshot.hasData && snapshot.data!.exists && snapshot.data!.data() != null) {
                    final data = snapshot.data!.data()!;
                    currentLat = (data['latitude'] as num?)?.toDouble() ?? currentLat;
                    currentLng = (data['longitude'] as num?)?.toDouble() ?? currentLng;
                    heading = (data['heading'] as num?)?.toDouble() ?? 0.0;
                  }

                  final distanceKm = TrackingService.calculateDistanceKm(
                    currentLat,
                    currentLng,
                    dropLat,
                    dropLng,
                  );
                  final etaMinutes = TrackingService.calculateEtaMinutes(distanceKm);

                  return Stack(
                    children: [
                      LiveMapWidget(
                        partnerLocation: LatLng(currentLat, currentLng),
                        buyerLocation: LatLng(dropLat, dropLng),
                        buyerName: order.buyerName,
                        heading: heading,
                        height: double.infinity,
                        initialZoom: 15.0,
                        showPolyline: true,
                      ),

                      // Floating ETA / Distance Card Overlay
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E241E).withOpacity(0.95),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: yellow.withOpacity(0.4)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$etaMinutes min',
                                style: GoogleFonts.outfit(
                                  color: yellow,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${distanceKm.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Text(
                                'Estimated arrival',
                                style: TextStyle(color: Colors.white54, fontSize: 9),
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

            // Bottom Customer Details Card with Call & Chat
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.orangeAccent.withOpacity(0.2),
                          child: const Icon(Icons.person_rounded, color: Colors.orangeAccent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.buyerName,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                order.deliveryAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Action Buttons (Call & Chat)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _callPhone(order.buyerPhone.isNotEmpty ? order.buyerPhone : '9876512345'),
                            icon: const Icon(Icons.phone_rounded, color: yellow, size: 16),
                            label: const Text('Call', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: yellow.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openChat,
                            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.greenAccent, size: 16),
                            label: const Text('Chat', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.greenAccent.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Mark as Delivered Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeliveryConfirmScreen(
                          order: order,
                          partner: widget.partner,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle_outline_rounded, color: Colors.black, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Mark as Delivered',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

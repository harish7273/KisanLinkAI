import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/delivery_partner_model.dart';
import '../../models/order_model.dart';
import '../../services/delivery_service.dart';
import '../../services/language_service.dart';
import '../../widgets/live_map_widget.dart';
import 'delivery_arrived_farm_screen.dart';

class DeliveryNavigateFarmerScreen extends StatefulWidget {
  final OrderModel order;
  final DeliveryPartnerModel? partner;

  const DeliveryNavigateFarmerScreen({
    super.key,
    required this.order,
    this.partner,
  });

  @override
  State<DeliveryNavigateFarmerScreen> createState() => _DeliveryNavigateFarmerScreenState();
}

class _DeliveryNavigateFarmerScreenState extends State<DeliveryNavigateFarmerScreen> {
  static const Color yellow = Color(0xFFFFC107);
  static const Color background = Color(0xFF080A08);
  static const Color card = Color(0xFF151515);

  bool loading = false;

  @override
  void initState() {
    super.initState();
    LanguageService.currentLocaleNotifier.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    LanguageService.currentLocaleNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _launchExternalMap(double lat, double lng) async {
    final Uri url = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final Uri webUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _startPickup() async {
    setState(() => loading = true);
    await DeliveryService.instance.startPickup(widget.order.orderId);
    setState(() => loading = false);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryArrivedFarmScreen(
          order: widget.order,
          partner: widget.partner,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final shortId = order.orderId.length > 8 ? order.orderId.substring(0, 8).toUpperCase() : order.orderId;

    final farmLat = order.pickupLatitude ?? 11.0168;
    final farmLng = order.pickupLongitude ?? 76.9558;

    final partnerLat = widget.partner?.currentLat != 0 ? widget.partner!.currentLat : 11.0080;
    final partnerLng = widget.partner?.currentLng != 0 ? widget.partner!.currentLng : 76.9480;

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
          LanguageService.tr('pickup_location', defaultText: 'Go to Pickup Location'),
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Farm Banner with Navigate Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: yellow, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${order.farmerName}'s Farm",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.farmerLocation.isNotEmpty ? order.farmerLocation : 'Farm Location',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _launchExternalMap(farmLat, farmLng),
                      icon: const Icon(Icons.navigation_rounded, color: Colors.black, size: 14),
                      label: Text(
                        LanguageService.tr('track', defaultText: 'Navigate'),
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: yellow,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Live Interactive Map View
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: LiveMapWidget(
                  partnerLocation: LatLng(partnerLat, partnerLng),
                  farmerLocation: LatLng(farmLat, farmLng),
                  farmerName: "${order.farmerName}'s Farm",
                  height: double.infinity,
                  initialZoom: 14.5,
                  showPolyline: true,
                ),
              ),
            ),

            // Order Card at Bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F241F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.eco_rounded, color: Colors.greenAccent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#$shortId',
                            style: const TextStyle(color: yellow, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${order.firstProductName} • ${order.firstProductQuantity.toInt()} ${order.firstProductUnit}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            "${order.farmerName}'s Farm",
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Start Pickup Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _startPickup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black),
                            const SizedBox(width: 8),
                            Text(
                              LanguageService.tr('start_pickup', defaultText: 'Start Pickup'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

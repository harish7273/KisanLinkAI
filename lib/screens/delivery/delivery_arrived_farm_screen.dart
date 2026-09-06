import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/delivery_partner_model.dart';
import '../../models/order_model.dart';
import '../../services/delivery_service.dart';
import 'delivery_picked_up_screen.dart';

class DeliveryArrivedFarmScreen extends StatefulWidget {
  final OrderModel order;
  final DeliveryPartnerModel? partner;

  const DeliveryArrivedFarmScreen({
    super.key,
    required this.order,
    this.partner,
  });

  @override
  State<DeliveryArrivedFarmScreen> createState() => _DeliveryArrivedFarmScreenState();
}

class _DeliveryArrivedFarmScreenState extends State<DeliveryArrivedFarmScreen> {
  static const Color yellow = Color(0xFFFFC107);
  static const Color background = Color(0xFF080A08);
  static const Color card = Color(0xFF151515);

  bool loading = false;

  Future<void> _callPhone(String phone) async {
    final Uri uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _confirmPickup() async {
    setState(() => loading = true);
    await DeliveryService.instance.confirmPickup(widget.order.orderId);
    setState(() => loading = false);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryPickedUpScreen(
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
          'Arrived at Farm',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // Farm Location Graphic / Pin
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B221B),
                          shape: BoxShape.circle,
                          border: Border.all(color: yellow.withOpacity(0.3), width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.location_on_rounded, color: yellow, size: 48),
                            SizedBox(height: 4),
                            Icon(Icons.house_siding_rounded, color: Colors.greenAccent, size: 42),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'You have reached\nthe pickup location!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Confirm with the farmer and collect the order items.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 28),

                      // Order items summary card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F241F),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.eco_rounded, color: Colors.greenAccent, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '#$shortId',
                                    style: const TextStyle(color: yellow, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    order.firstProductName,
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${order.firstProductQuantity.toInt()} ${order.firstProductUnit}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${order.totalAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Farmer contact card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.greenAccent.withOpacity(0.2),
                              child: const Icon(Icons.agriculture_rounded, color: Colors.greenAccent, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.farmerName,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    order.farmerPhone.isNotEmpty ? order.farmerPhone : '+91 98765 43210',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _callPhone(order.farmerPhone.isNotEmpty ? order.farmerPhone : '9876543210'),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: yellow,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.phone_rounded, color: Colors.black, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Confirm Pickup Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _confirmPickup,
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
                          children: const [
                            Icon(Icons.check_rounded, color: Colors.black, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Confirm Pickup',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

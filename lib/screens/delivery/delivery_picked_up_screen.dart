import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/delivery_partner_model.dart';
import '../../models/order_model.dart';
import '../../services/delivery_service.dart';
import 'delivery_out_for_delivery_screen.dart';

class DeliveryPickedUpScreen extends StatefulWidget {
  final OrderModel order;
  final DeliveryPartnerModel? partner;

  const DeliveryPickedUpScreen({
    super.key,
    required this.order,
    this.partner,
  });

  @override
  State<DeliveryPickedUpScreen> createState() => _DeliveryPickedUpScreenState();
}

class _DeliveryPickedUpScreenState extends State<DeliveryPickedUpScreen> {
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

  Future<void> _startDelivery() async {
    setState(() => loading = true);
    await DeliveryService.instance.startDelivery(widget.order.orderId);
    setState(() => loading = false);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryOutForDeliveryScreen(
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
          'Order Picked Up!',
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
                      const SizedBox(height: 14),

                      // Order Picked Up Celebration Box Graphic
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: yellow.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: yellow, width: 2),
                        ),
                        child: const Icon(Icons.inventory_2_rounded, color: yellow, size: 64),
                      ),
                      const SizedBox(height: 22),

                      Text(
                        'Order Picked Up!',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The fresh produce is now with you.\nProceed to deliver to the customer.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 26),

                      // Order Items Summary
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
                      const SizedBox(height: 18),

                      // Deliver to Customer Card
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Deliver to',
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                                    order.buyerPhone.isNotEmpty ? order.buyerPhone : '+91 98765 12345',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.deliveryAddress,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _callPhone(order.buyerPhone.isNotEmpty ? order.buyerPhone : '9876512345'),
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
                    ],
                  ),
                ),
              ),

              // Start Delivery Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _startDelivery,
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
                            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black),
                            SizedBox(width: 8),
                            Text(
                              'Start Delivery',
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

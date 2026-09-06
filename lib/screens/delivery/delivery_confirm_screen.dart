import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/delivery_partner_model.dart';
import '../../models/order_model.dart';
import '../../services/delivery_service.dart';
import 'delivery_success_screen.dart';

class DeliveryConfirmScreen extends StatefulWidget {
  final OrderModel order;
  final DeliveryPartnerModel? partner;

  const DeliveryConfirmScreen({
    super.key,
    required this.order,
    this.partner,
  });

  @override
  State<DeliveryConfirmScreen> createState() => _DeliveryConfirmScreenState();
}

class _DeliveryConfirmScreenState extends State<DeliveryConfirmScreen> {
  static const Color yellow = Color(0xFFFFC107);
  static const Color background = Color(0xFF080A08);
  static const Color card = Color(0xFF151515);

  bool loading = false;

  Future<void> _callPhone(String phone) async {
    if (phone.isEmpty) return;
    final Uri uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _completeDelivery() async {
    if (widget.partner == null) return;

    setState(() => loading = true);

    await DeliveryService.instance.completeDelivery(
      orderId: widget.order.orderId,
      partnerId: widget.partner!.uid,
    );

    setState(() => loading = false);

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => DeliverySuccessScreen(
          order: widget.order,
          partner: widget.partner,
        ),
      ),
      (route) => false,
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
          'Confirm Delivery',
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

                      // Delivery Handover Graphic
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F241F),
                          shape: BoxShape.circle,
                          border: Border.all(color: yellow.withOpacity(0.3), width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.volunteer_activism_rounded, color: yellow, size: 52),
                            SizedBox(height: 4),
                            Icon(Icons.inventory_2_rounded, color: Colors.greenAccent, size: 36),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      Text(
                        'Confirm Delivery',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Make sure the customer has received the order.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 28),

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

                      // Customer Info Card
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Customer',
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

              // Final Mark as Delivered Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _completeDelivery,
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
                            Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Mark as Delivered',
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

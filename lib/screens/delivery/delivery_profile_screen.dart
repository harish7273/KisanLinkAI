import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/delivery_partner_model.dart';
import '../role_screen.dart';

class DeliveryProfileScreen extends StatelessWidget {
  final DeliveryPartnerModel partner;
  final VoidCallback onBack;

  const DeliveryProfileScreen({
    super.key,
    required this.partner,
    required this.onBack,
  });

  static const Color yellow = Color(0xFFFFC107);
  static const Color background = Color(0xFF080A08);
  static const Color card = Color(0xFF151515);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: onBack,
        ),
        title: Text(
          'Delivery Profile',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Avatar & Name
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: yellow.withOpacity(0.2),
                          child: const Icon(Icons.person_rounded, color: yellow, size: 52),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                            child: const Icon(Icons.verified_rounded, color: Colors.black, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      partner.name,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      partner.phone.isNotEmpty ? partner.phone : 'Delivery Partner',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded, color: yellow, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${partner.rating.toStringAsFixed(1)} Rating',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        const Text('•', style: TextStyle(color: Colors.white30)),
                        const SizedBox(width: 12),
                        Text(
                          '${partner.totalDeliveries} Deliveries',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Vehicle Information Card
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Vehicle & Logistics',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    // Dynamic Vehicle Image Banner
                    Container(
                      height: 130,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                        image: (partner.vehicleType.toLowerCase().contains('truck') ||
                                partner.vehicleType.toLowerCase().contains('reefer') ||
                                partner.vehicleType.toLowerCase().contains('ace') ||
                                partner.vehicleType.toLowerCase().contains('bolero') ||
                                !partner.vehicleType.toLowerCase().contains('bike'))
                            ? const DecorationImage(
                                image: AssetImage('assets/images/delivery_partner_truck.jpg'),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: const Color(0xFF1B241C),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Colors.black87, Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        padding: const EdgeInsets.all(10),
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              partner.vehicleType,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: yellow.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                partner.vehicleType.toLowerCase().contains('reefer')
                                    ? '❄️ Active Cold-Chain 4°C'
                                    : 'Heavy Agri Transit',
                                style: const TextStyle(color: yellow, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _infoRow(
                      (partner.vehicleType.toLowerCase().contains('truck') || partner.vehicleType.toLowerCase().contains('reefer'))
                          ? Icons.local_shipping_rounded
                          : (partner.vehicleType.toLowerCase().contains('electric') || partner.vehicleType.toLowerCase().contains('ev'))
                              ? Icons.electric_bolt_rounded
                              : Icons.two_wheeler_rounded,
                      'Vehicle Type',
                      partner.vehicleType,
                    ),
                    const Divider(color: Colors.white10, height: 20),
                    _infoRow(Icons.confirmation_number_rounded, 'Vehicle Number', partner.vehicleNumber),
                    const Divider(color: Colors.white10, height: 20),
                    _infoRow(Icons.badge_rounded, 'Verification', partner.verificationStatus.toUpperCase(), isSuccess: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const RoleScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                  label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isSuccess = false}) {
    return Row(
      children: [
        Icon(icon, color: yellow, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: isSuccess ? Colors.greenAccent : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

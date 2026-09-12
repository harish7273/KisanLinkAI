import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/language_service.dart';

class VehicleAssignmentSheet extends StatefulWidget {
  final String orderId;
  final String? currentVehicle;
  final String? currentPlate;
  final String? currentDriverName;
  final Function(Map<String, dynamic> assignedDriver)? onAssigned;

  const VehicleAssignmentSheet({
    super.key,
    required this.orderId,
    this.currentVehicle,
    this.currentPlate,
    this.currentDriverName,
    this.onAssigned,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String orderId,
    String? currentVehicle,
    String? currentPlate,
    String? currentDriverName,
    Function(Map<String, dynamic>)? onAssigned,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VehicleAssignmentSheet(
        orderId: orderId,
        currentVehicle: currentVehicle,
        currentPlate: currentPlate,
        currentDriverName: currentDriverName,
        onAssigned: onAssigned,
      ),
    );
  }

  @override
  State<VehicleAssignmentSheet> createState() => _VehicleAssignmentSheetState();
}

class _VehicleAssignmentSheetState extends State<VehicleAssignmentSheet> {
  static const Color green = Color(0xFF00E676);
  static const Color cardBg = Color(0xFF131814);
  static const Color surfaceBg = Color(0xFF0A0D0B);
  static const Color borderColor = Color(0xFF233226);

  int _selectedIndex = 0;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _availableDrivers = [
    {
      'id': 'drv_selvam_4412',
      'name': 'P. Selvam',
      'phone': '+91 94432 17890',
      'rating': 4.9,
      'trips': 318,
      'deliveryTime': '25 - 40 Mins Express',
      'safetyScore': '99.8% Zero-Damage • Correct Location Pin Guarantee',
      'vehicle': 'Tata Ace Cold-Chain Reefer (2.2T)',
      'plate': 'TN-38-BZ-4412',
      'reeferTemp': '❄️ 4°C Active Cold Chain',
      'icon': Icons.ac_unit_rounded,
      'tag': 'Fastest Reefer',
    },
    {
      'id': 'drv_manikandan_8921',
      'name': 'M. Manikandan',
      'phone': '+91 98433 45210',
      'rating': 4.8,
      'trips': 245,
      'deliveryTime': '35 - 50 Mins Direct',
      'safetyScore': '99.5% Safe Delivery • Direct Farm Route',
      'vehicle': 'Mahindra Bolero Maxi Truck Plus (2.5T)',
      'plate': 'TN-37-CE-8921',
      'reeferTemp': 'Ventilated Agro Carrier',
      'icon': Icons.local_shipping_rounded,
      'tag': 'Heavy Capacity',
    },
    {
      'id': 'drv_saravanan_1044',
      'name': 'V. Saravanan',
      'phone': '+91 97892 65431',
      'rating': 5.0,
      'trips': 142,
      'deliveryTime': '20 - 30 Mins Local Express',
      'safetyScore': '100% Damage-Free • Zero Carbon City Delivery',
      'vehicle': 'Piaggio Ape E-Xtra EV Cargo (1.2T)',
      'plate': 'TN-38-ED-1044',
      'reeferTemp': 'Insulated Fresh Produce Box',
      'icon': Icons.electric_bolt_rounded,
      'tag': 'Eco Electric',
    },
    {
      'id': 'drv_anand_6502',
      'name': 'K. Anand Kumar',
      'phone': '+91 94861 22890',
      'rating': 4.9,
      'trips': 410,
      'deliveryTime': '40 - 55 Mins Bulk Dispatch',
      'safetyScore': '99.9% Safe Arrival • GPS Geofenced Pin Verification',
      'vehicle': 'Ashok Leyland Dost Reefer (2.8T)',
      'plate': 'TN-39-AA-6502',
      'reeferTemp': '❄️ 2°C Deep Chill Reefer',
      'icon': Icons.verified_user_rounded,
      'tag': 'Top Rated',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Pre-select if already matching
    if (widget.currentPlate != null && widget.currentPlate!.isNotEmpty) {
      final found = _availableDrivers.indexWhere(
        (d) => d['plate'] == widget.currentPlate,
      );
      if (found != -1) {
        _selectedIndex = found;
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error calling driver: ');
    }
  }

  Future<void> _confirmAssignment() async {
    setState(() => _isSaving = true);
    final chosen = _availableDrivers[_selectedIndex];

    try {
      if (widget.orderId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
          'deliveryPartnerId': chosen['id'],
          'deliveryPartnerName': chosen['name'],
          'deliveryPartnerPhone': chosen['phone'],
          'deliveryPartnerVehicle': chosen['vehicle'],
          'deliveryPartnerPlate': chosen['plate'],
          'reeferTemperature': chosen['reeferTemp'],
          'driverRating': chosen['rating'],
          'deliveryEstimate': chosen['deliveryTime'],
          'safetyScore': chosen['safetyScore'],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Firestore update fallback: ');
    }

    if (widget.onAssigned != null) {
      widget.onAssigned!(chosen);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, chosen);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ' ( - )',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF142718),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLocaleNotifier,
      builder: (context, locale, _) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border(
              top: BorderSide(color: borderColor, width: 1.5),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: green.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.local_shipping_rounded, color: green, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('assign_transport_title'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tr('assign_transport_subtitle'),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(color: borderColor, height: 1),

              // Mutual coordination notice banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF132216),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: green.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.handshake_rounded, color: green, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Either Farmer or Buyer can select or change this vehicle upon mutual communication.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Driver cards list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  itemCount: _availableDrivers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final driver = _availableDrivers[index];
                    final isSelected = _selectedIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedIndex = index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF122416) : cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? green : borderColor,
                            width: isSelected ? 1.8 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: green.withOpacity(0.15),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row: name, rating, call button
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? green.withOpacity(0.2) : Colors.white10,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    driver['icon'] as IconData,
                                    color: isSelected ? green : Colors.white70,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            driver['name'] as String,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isSelected ? green.withOpacity(0.2) : Colors.white10,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              driver['tag'] as String,
                                              style: TextStyle(
                                                color: isSelected ? green : Colors.white70,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                          const SizedBox(width: 2),
                                          Text(
                                            ' ( trips)',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Call button
                                IconButton(
                                  onPressed: () => _makePhoneCall(driver['phone'] as String),
                                  icon: const Icon(Icons.phone_rounded, color: green, size: 20),
                                  tooltip: 'Call Driver',
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D2513),
                                    shape: const CircleBorder(),
                                  ),
                                ),

                                // Select checkmark
                                Icon(
                                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                                  color: isSelected ? green : Colors.white30,
                                  size: 24,
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            const Divider(color: borderColor, height: 1),
                            const SizedBox(height: 10),

                            // Vehicle & Plate
                            Row(
                              children: [
                                const Icon(Icons.directions_car_rounded, color: Colors.white54, size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    ' []',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F2618),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    driver['reeferTemp'] as String,
                                    style: const TextStyle(color: green, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Delivery Speed & Safe Guarantee
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Est. Arrival: ',
                                        style: const TextStyle(
                                          color: Colors.amberAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.shield_rounded, color: green, size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          driver['safetyScore'] as String,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Confirmation Button
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                decoration: const BoxDecoration(
                  color: surfaceBg,
                  border: Border(top: BorderSide(color: borderColor, width: 1)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _confirmAssignment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                tr('confirm_assign_vehicle'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

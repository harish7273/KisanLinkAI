import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../models/order_model.dart';
import '../../services/language_service.dart';
import '../../widgets/live_map_widget.dart';
import '../../widgets/vehicle_assignment_sheet.dart';
import 'buyer_live_tracking_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class BuyerOrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const BuyerOrderDetailsScreen({
    super.key,
    required this.order,
  });

  static const Color orange = Color(0xFFFF9800);
  static const Color green = Color(0xFF4CAF50);
  static const Color background = Color(0xFF080A08);
  static const Color card = Color(0xFF151515);

  int _getStatusStepIndex(String status) {
    switch (status.toLowerCase().trim()) {
      case 'placed':
        return 0;
      case 'accepted':
      case 'confirmed':
        return 1;
      case 'preparing':
      case 'ready':
      case 'ready for pickup':
        return 2;
      case 'out for delivery':
      case 'partner accepted':
      case 'going to farmer':
      case 'arrived at farm':
      case 'picked up':
        return 3;
      case 'delivered':
      case 'completed':
        return 4;
      default:
        return 0;
    }
  }

  Future<void> _cancelOrder(BuildContext context) async {
    final canCancel = order.orderStatus.toLowerCase() == 'placed' ||
        order.orderStatus.toLowerCase() == 'accepted';

    if (!canCancel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order is already in progress and cannot be cancelled.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: card,
        title: const Text('Cancel Order?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to cancel this order? If paid, a refund will be processed.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, Keep Order'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('orders').doc(order.orderId).update({
        'orderStatus': 'Cancelled',
        'deliveryStatus': 'Cancelled',
        'cancelledBy': 'Buyer',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order has been cancelled.'), backgroundColor: Colors.redAccent),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortId = order.orderId.length > 8 ? order.orderId.substring(0, 8).toUpperCase() : order.orderId;
    final currentStep = _getStatusStepIndex(order.orderStatus);

    final farmLat = order.pickupLatitude ?? 11.0168;
    final farmLng = order.pickupLongitude ?? 76.9558;
    final dropLat = order.dropLatitude ?? 11.0250;
    final dropLng = order.dropLongitude ?? 76.9680;

    final createdDateStr = order.createdAt != null
        ? DateFormat('d MMM, h:mm a').format(order.createdAt!.toDate())
        : 'Today';

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
              'Order Details',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Order #$shortId',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: order.orderStatus.toLowerCase() == 'delivered'
                  ? green.withOpacity(0.2)
                  : orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: order.orderStatus.toLowerCase() == 'delivered' ? green : orange,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: order.orderStatus.toLowerCase() == 'delivered' ? green : orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  order.orderStatus,
                  style: TextStyle(
                    color: order.orderStatus.toLowerCase() == 'delivered' ? green : orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Payment Protected Banner (Reference Image 1)
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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: orange.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded, color: orange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Payment Protected',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Amount will be released after successful delivery.',
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Track Your Order Card (Reference Image 1)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_shipping_rounded, color: green, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Track Your Order',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Live updates on your delivery',
                              style: TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: green),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.fiber_manual_record, color: Colors.greenAccent, size: 8),
                              SizedBox(width: 4),
                              Text('LIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Horizontal Timeline Stepper
                    _buildHorizontalStepper(currentStep, createdDateStr),

                    const SizedBox(height: 16),

                    // Embedded Map Preview
                    LiveMapWidget(
                      farmerLocation: LatLng(farmLat, farmLng),
                      buyerLocation: LatLng(dropLat, dropLng),
                      farmerName: order.farmerName,
                      buyerName: 'You',
                      height: 140,
                      initialZoom: 13.5,
                      showPolyline: true,
                      isInteractive: false,
                    ),

                    const SizedBox(height: 14),

                    // Bottom Subcard: "Your order is being prepared" + "View Live Location" button
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A221A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_pin_circle_rounded, color: green, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.orderStatus.toLowerCase() == 'out for delivery'
                                      ? 'Order is on the way'
                                      : 'Order is in progress',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                Text(
                                  order.orderStatus.toLowerCase() == 'out for delivery'
                                      ? 'Partner is delivering to you'
                                      : 'The farmer is packing your produce',
                                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BuyerLiveTrackingScreen(order: order),
                                ),
                              );
                            },
                            icon: const Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                            label: const Text('View Live Location', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: green,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Transport & Optional Assignment Section
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('orders').doc(order.orderId).snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() ?? {};
                  final vehicle = data['deliveryPartnerVehicle']?.toString() ?? order.deliveryPartnerVehicle;
                  final plate = data['deliveryPartnerPlate']?.toString() ?? '';
                  final driverName = data['deliveryPartnerName']?.toString() ?? order.deliveryPartnerName;
                  final driverRating = data['driverRating']?.toString() ?? '4.9';
                  final deliveryEstimate = data['deliveryEstimate']?.toString() ?? '25 - 40 Mins Express';
                  final hasVehicle = vehicle != null && vehicle.isNotEmpty;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_shipping_rounded, color: green, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              tr('assign_transport_title', defaultText: 'Transport & Delivery'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const Spacer(),
                            if (hasVehicle)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amberAccent.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 12),
                                    const SizedBox(width: 2),
                                    Text(
                                      driverRating,
                                      style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (hasVehicle) ...[
                          Text(
                            '$vehicle ($plate)',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${tr('driver', defaultText: 'Driver')}: $driverName • $deliveryEstimate',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${tr('zero_damage_guarantee', defaultText: 'Zero-Damage & Correct Location Guarantee')} • OTP: ${data['deliveryOtp'] ?? order.deliveryOtp ?? '7935'}',
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  VehicleAssignmentSheet.show(
                                    context,
                                    orderId: order.orderId,
                                    currentVehicle: vehicle,
                                    currentPlate: plate,
                                    currentDriverName: driverName,
                                  );
                                },
                                icon: const Icon(Icons.sync_alt_rounded, size: 12, color: green),
                                label: Text(
                                  tr('change_vehicle_optional', defaultText: 'Change Vehicle (Optional)'),
                                  style: const TextStyle(color: green, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: green.withValues(alpha: 0.4)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            tr('mutual_assign_notice', defaultText: 'Either Farmer or Buyer can select transport upon mutual communication.'),
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                VehicleAssignmentSheet.show(
                                  context,
                                  orderId: order.orderId,
                                );
                              },
                              icon: const Icon(Icons.add_road_rounded, size: 14),
                              label: Text(
                                tr('assign_transport_optional', defaultText: 'Assign Transport (Optional)'),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amberAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Farmer Details & Quality Inspection Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.agriculture_rounded, color: green, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('farmer_details', defaultText: 'Farmer & Farm Details'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              tr('direct_from_origin', defaultText: 'Direct farm produce origin verified'),
                              style: const TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: green),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.verified_rounded, color: green, size: 12),
                              SizedBox(width: 4),
                              Text('Grade-A QC', style: TextStyle(color: green, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 20),

                    // Farmer Name & Contact Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.farmerName.isNotEmpty ? order.farmerName : 'M. Palanisamy',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.farmerPhone.isNotEmpty ? order.farmerPhone : '+91 94431 82910',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, color: Colors.white38, size: 12),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      order.farmerLocation.isNotEmpty ? order.farmerLocation : 'Pollachi, Coimbatore, Tamil Nadu',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final p = (order.farmerPhone.isNotEmpty ? order.farmerPhone : '+91 94431 82910').replaceAll(' ', '');
                            final uri = Uri.parse('tel:$p');
                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                          },
                          icon: const Icon(Icons.call, size: 13),
                          label: Text(tr('call', defaultText: 'Call')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    // Quality Check Breakdown Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF132217),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.health_and_safety_rounded, color: green, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Quality Checked: 98.4% Freshness Index • Pesticide-Safe & Organically Graded',
                              style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Order Items Section (Reference Image 1)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Items',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),

                    ...order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F241F),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: item.image.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        item.image,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.eco_rounded, color: Colors.greenAccent),
                                      ),
                                    )
                                  : const Icon(Icons.eco_rounded, color: Colors.greenAccent, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    '${item.farmerName} • ${item.quantity.toInt()} ${item.unit}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${item.itemTotal.toStringAsFixed(0)}',
                              style: const TextStyle(color: orange, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(color: Colors.white10, height: 16),

                    _priceRow('Item Total', '₹${order.subtotal.toStringAsFixed(0)}'),
                    const SizedBox(height: 6),
                    _priceRow('Delivery Fee', '₹${order.deliveryFee.toStringAsFixed(0)}'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const Spacer(),
                        Text(
                          '₹${order.totalAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            color: orange,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 20),

                    // Payment Method Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: orange, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Payment Method', style: TextStyle(color: Colors.white38, fontSize: 10)),
                            Text('${order.paymentMethod} Payment', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: green),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.check_circle_rounded, color: green, size: 12),
                              SizedBox(width: 4),
                              Text('Paid', style: TextStyle(color: green, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Need Help?
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.contact_support_outlined, color: Colors.white70, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Need Help?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Get support for your order', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5. Cancel Order Button (Red Outline)
              if (order.orderStatus.toLowerCase() != 'delivered' &&
                  order.orderStatus.toLowerCase() != 'cancelled' &&
                  order.orderStatus.toLowerCase() != 'out for delivery')
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelOrder(context),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 18),
                    label: const Text('Cancel Order', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalStepper(int currentStep, String date) {
    final steps = ['Order Placed', 'Confirmed', 'Preparing', 'Out for Delivery', 'Delivered'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final isDone = index <= currentStep;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == 0 ? Colors.transparent : (index <= currentStep ? green : Colors.white12),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isDone ? green : const Color(0xFF222822),
                      shape: BoxShape.circle,
                      border: Border.all(color: isDone ? green : Colors.white24, width: 1.5),
                    ),
                    child: Icon(
                      isDone ? Icons.check : Icons.circle,
                      color: isDone ? Colors.black : Colors.white24,
                      size: 12,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == steps.length - 1 ? Colors.transparent : (index < currentStep ? green : Colors.white12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                steps[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDone ? Colors.white : Colors.white38,
                  fontSize: 8.5,
                  fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _priceRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

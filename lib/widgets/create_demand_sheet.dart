import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:latlong2/latlong.dart';

import '../services/location_directory_service.dart';

class CreateDemandSheet extends StatefulWidget {
  const CreateDemandSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateDemandSheet(),
    );
  }

  @override
  State<CreateDemandSheet> createState() => _CreateDemandSheetState();
}

class _CreateDemandSheetState extends State<CreateDemandSheet> {
  static const Color green = Color(0xFF22C55E);
  static const Color orange = Color(0xFFFF9800);
  static const Color card = Color(0xFF131914);
  static const Color border = Color(0xFF223425);

  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController(text: '500');
  final _priceController = TextEditingController(text: '28');
  final _addressController = TextEditingController(
    text: 'Ukkadam Central Agro Market, Coimbatore, TN - 641001',
  );

  String _selectedCrop = 'Organic Tomato (Fresh Harvest)';
  String _selectedDestination = 'Ukkadam (Coimbatore)';
  bool _isBranchA = false; // false = Branch B (Delivery Partner), true = Branch A (Direct Farm Pickup)
  bool _coldChainRequired = true;
  bool _isPosting = false;

  final List<Map<String, dynamic>> _cropOptions = [
    {'name': 'Organic Tomato (Fresh Harvest)', 'category': 'Vegetable', 'defaultPrice': 28.0, 'unit': 'kg'},
    {'name': 'Fresh Farm Bananas (Nendran)', 'category': 'Fruit', 'defaultPrice': 40.0, 'unit': 'kg'},
    {'name': 'Sweet Golden Corn', 'category': 'Grain', 'defaultPrice': 24.0, 'unit': 'kg'},
    {'name': 'Sona Masoori Paddy (Grade A)', 'category': 'Grain', 'defaultPrice': 32.0, 'unit': 'kg'},
    {'name': 'Banganapalli Mango (Grade A)', 'category': 'Fruit', 'defaultPrice': 65.0, 'unit': 'kg'},
  ];

  final Map<String, LatLng> _destinationHubs = {
    'Ukkadam (Coimbatore)': LocationDirectoryService.ukkadam,
    'Gandhipuram (Coimbatore)': LocationDirectoryService.gandhipuram,
    'RS Puram (Coimbatore)': LocationDirectoryService.rsPuram,
    'Tiruppur City Market': LocationDirectoryService.resolveLocation('Tiruppur'),
    'Erode Agricultural Depot': LocationDirectoryService.erode,
  };

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  double get _totalProduceAmount {
    final q = double.tryParse(_qtyController.text) ?? 0.0;
    final p = double.tryParse(_priceController.text) ?? 0.0;
    return q * p;
  }

  double get _deliveryFee => _isBranchA ? 0.0 : 550.0;

  double get _totalBudget => _totalProduceAmount + _deliveryFee;

  Future<void> _postDemand() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPosting = true);

    final user = FirebaseAuth.instance.currentUser;
    final buyerId = user?.uid ?? 'buyer_demo_user';
    final buyerName = user?.displayName ?? 'Fresh Farms Hypermarket';
    final buyerPhone = user?.phoneNumber ?? '+91 98421 55670';

    final double qty = double.tryParse(_qtyController.text) ?? 500.0;
    final double price = double.tryParse(_priceController.text) ?? 28.0;

    final destCoords = _destinationHubs[_selectedDestination] ?? LocationDirectoryService.ukkadam;
    final String deliveryAddress = _addressController.text.trim();

    final orderId = 'ORD-DEM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final String deliveryOtp = (1000 + Random().nextInt(9000)).toString();

    try {
      // 1. Post to shared orders collection (Single source of truth)
      await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'buyerId': buyerId,
        'buyerName': buyerName,
        'buyerPhone': buyerPhone,
        'farmerId': '', // Open demand available to all qualified farmers
        'farmerName': 'Awaiting Farmer Acceptance',
        'farmerPhone': '',
        'farmerLocation': 'Tamil Nadu Regional Farms',
        'pickupAddress': 'Udumalpet Organic Farm, Tiruppur Dist, TN',
        'pickupLatitude': 10.5855,
        'pickupLongitude': 77.2492,
        'deliveryAddress': deliveryAddress,
        'dropLatitude': destCoords.latitude,
        'dropLongitude': destCoords.longitude,
        'distanceKm': 71.5,
        'orderStatus': 'Demand Posted',
        'deliveryStatus': _isBranchA ? 'Buyer Self Pickup' : 'Pending Farmer Acceptance',
        'paymentStatus': 'Escrow Reserved',
        'paymentMethod': 'KisanAI Direct Escrow',
        'isDirectPickup': _isBranchA,
        'coldChainRequired': _coldChainRequired,
        'deliveryOtp': deliveryOtp,
        'pickupOtp': (1000 + Random().nextInt(9000)).toString(),
        'totalAmount': _totalBudget,
        'deliveryFee': _deliveryFee,
        'subtotal': _totalProduceAmount,
        'isDemandBroadcast': true,
        'notes': 'Buyer posted demand for $qty kg of $_selectedCrop. ${_isBranchA ? "Branch A: Direct Farm Pickup" : "Branch B: KisanAI Delivery Partner required"}',
        'items': [
          {
            'productId': 'demand_${DateTime.now().millisecondsSinceEpoch}',
            'name': _selectedCrop,
            'quantity': qty,
            'price': price,
            'unit': 'kg',
            'itemTotal': qty * price,
          }
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Broadcast real-time notification to all farmers
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': 'all_farmers',
        'title': '📢 New Buyer Demand: ${qty.toStringAsFixed(0)} kg $_selectedCrop',
        'message': 'Buyer posted ₹${price.toStringAsFixed(0)}/kg at $_selectedDestination. Tap to evaluate & accept!',
        'type': 'buyer_demand',
        'orderId': orderId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF142416),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: green, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Demand #$orderId broadcast live to all regional farmers!',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPosting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent.shade700,
          content: Text('Failed to post demand: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFF0C120D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: border, width: 1.5)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Step 1 Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Post Crop Demand',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Step 1 • Direct Farm-to-Buyer Workflow',
                        style: TextStyle(color: green, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: green.withValues(alpha: 0.4)),
                    ),
                    child: const Text('Live Broadcast', style: TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Crop Variety Selector
              const Text('Select Crop Variety', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCrop,
                    dropdownColor: const Color(0xFF141C15),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: green),
                    items: _cropOptions.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['name'] as String,
                        child: Text(
                          c['name'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCrop = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Quantity and Price Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Required Weight (kg)', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            suffixText: 'kg',
                            suffixStyle: const TextStyle(color: green, fontWeight: FontWeight.bold),
                            filled: true,
                            fillColor: card,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter quantity' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Target Price (₹ / kg)', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            prefixText: '₹ ',
                            prefixStyle: const TextStyle(color: green, fontWeight: FontWeight.bold),
                            filled: true,
                            fillColor: card,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter price' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Destination Hub Selector
              const Text('Destination Hub', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDestination,
                    dropdownColor: const Color(0xFF141C15),
                    isExpanded: true,
                    icon: const Icon(Icons.location_on_rounded, color: orange),
                    items: _destinationHubs.keys.map((h) {
                      return DropdownMenuItem<String>(
                        value: h,
                        child: Text(h, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedDestination = val;
                          _addressController.text = '$val, Tamil Nadu, India';
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Delivery Address Details
              const Text('Exact Drop Address', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                maxLines: 2,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
                ),
              ),
              const SizedBox(height: 18),

              // STEP 3 DECISION FORK: Branch A vs Branch B
              Text(
                'Step 3 Decision Fork • Delivery Method',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isBranchA = false),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: !_isBranchA ? green.withValues(alpha: 0.15) : card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: !_isBranchA ? green : border, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.local_shipping_rounded, color: !_isBranchA ? green : Colors.white38, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  'Branch B',
                                  style: TextStyle(color: !_isBranchA ? green : Colors.white60, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text('KisanAI Delivery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 2),
                            const Text('Auto-assigned Truck / Reefer', style: TextStyle(color: Colors.white54, fontSize: 10)),
                            const SizedBox(height: 4),
                            Text('Fee: ₹550', style: TextStyle(color: !_isBranchA ? green : Colors.white60, fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isBranchA = true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isBranchA ? green.withValues(alpha: 0.15) : card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _isBranchA ? green : border, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.storefront_rounded, color: _isBranchA ? green : Colors.white38, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  'Branch A',
                                  style: TextStyle(color: _isBranchA ? green : Colors.white60, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text('Direct Farm Pickup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 2),
                            const Text('Collect produce at farm gate', style: TextStyle(color: Colors.white54, fontSize: 10)),
                            const SizedBox(height: 4),
                            const Text('Fee: ₹0 (Free)', style: TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Cold Chain Toggle
              if (!_isBranchA)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101913),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.ac_unit_rounded, color: Colors.lightBlueAccent, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Tata Ace Reefer Cold-Chain', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('Active 4°C refrigeration for perishables', style: TextStyle(color: Colors.white54, fontSize: 10)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _coldChainRequired,
                        onChanged: (v) => setState(() => _coldChainRequired = v),
                        activeColor: green,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),

              // Total Budget Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF142017),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estimated Total Budget', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          '₹${_totalBudget.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(color: green, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      _isBranchA ? 'Produce Only (₹0 Delivery)' : 'Includes Reefer Delivery Fee',
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Broadcast Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isPosting ? null : _postDemand,
                  icon: _isPosting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Icon(Icons.podcasts_rounded, size: 22),
                  label: Text(
                    _isPosting ? 'Broadcasting...' : 'Broadcast Demand to Farmers',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
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

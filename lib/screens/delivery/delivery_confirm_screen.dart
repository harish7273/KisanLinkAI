import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/delivery_partner_model.dart';
import '../../models/order_model.dart';
import '../../services/delivery_service.dart';
import '../../services/firestore_service.dart';
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
  static const Color border = Color(0xFF243426);
  static const Color green = Color(0xFF00E676);

  bool loading = false;
  final TextEditingController _otpController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _capturedPhotoPath;
  final List<Offset?> _signaturePoints = [];
  bool _freshnessChecked = true;
  bool _quantityChecked = true;
  bool _zeroDamageChecked = true;
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _takePodPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
      );
      if (photo != null) {
        setState(() {
          _capturedPhotoPath = photo.path;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Error capturing POD photo: $e');
    }
  }

  Future<void> _completeDelivery() async {
    if (widget.partner == null) return;

    final expectedOtp = widget.order.deliveryOtp ?? widget.order.pickupOtp ?? '';
    final enteredOtp = _otpController.text.trim();

    // 1. Validate OTP
    if (enteredOtp.isEmpty || enteredOtp.length != 4) {
      setState(() => _errorMessage = 'Please enter the 4-digit handover OTP from the buyer');
      return;
    }
    if (expectedOtp.isNotEmpty && enteredOtp != expectedOtp) {
      setState(() => _errorMessage = 'Incorrect OTP entered. Please ask buyer for the OTP.');
      return;
    }

    // 2. Validate POD Photo
    if (_capturedPhotoPath == null) {
      setState(() => _errorMessage = 'Please capture a photo of the unloaded produce as Proof of Delivery.');
      return;
    }

    // 3. Validate Digital Signature
    if (_signaturePoints.length < 5) {
      setState(() => _errorMessage = 'Recipient digital signature is required on the signature pad.');
      return;
    }

    // 4. Validate Quality Checkpoints
    if (!_freshnessChecked || !_quantityChecked || !_zeroDamageChecked) {
      setState(() => _errorMessage = 'Please confirm all zero-damage inspection checkpoints.');
      return;
    }

    setState(() {
      loading = true;
      _errorMessage = null;
    });

    try {
      // Record complete Proof of Delivery in Firestore
      await FirestoreService().recordProofOfDelivery(
        orderId: widget.order.orderId,
        deliveryPartnerId: widget.partner!.uid,
        deliveryPartnerName: widget.partner!.name,
        deliveryOtp: enteredOtp,
        photoUrl: _capturedPhotoPath,
        signatureBase64: 'signed_${_signaturePoints.length}_points',
      );

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
    } catch (e) {
      setState(() {
        loading = false;
        _errorMessage = 'Failed to record delivery: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Confirm Delivery & POD',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: yellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: yellow, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.order.firstProductName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          '#${widget.order.orderId} • ${widget.order.firstProductQuantity.toInt()} ${widget.order.firstProductUnit}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${widget.order.totalAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(color: green, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 1. STEP 1: Handover OTP
            Text(
              '1. Customer Handover OTP',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ask the buyer for the 4-digit OTP shown in their KisanAI app.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: yellow, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '• • • •',
                hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 8),
                counterText: '',
                filled: true,
                fillColor: card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)),
              ),
            ),

            const SizedBox(height: 20),

            // 2. STEP 2: Delivery Photo Capture
            Text(
              '2. Proof of Delivery (Photo)',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Take a clear photo of the delivered produce at the buyer destination.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 8),

            InkWell(
              onTap: _takePodPhoto,
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _capturedPhotoPath != null ? green : border, width: 1.5),
                ),
                child: _capturedPhotoPath != null && File(_capturedPhotoPath!).existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(File(_capturedPhotoPath!), fit: BoxFit.cover, width: double.infinity),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.camera_alt_rounded, color: yellow, size: 36),
                          SizedBox(height: 8),
                          Text('Tap to Capture POD Photo', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('Shows crates/produce at delivery gate', style: TextStyle(color: Colors.white38, fontSize: 10)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. STEP 3: Digital Signature Pad
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '3. Receiver Digital Signature',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                if (_signaturePoints.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _signaturePoints.clear()),
                    child: const Text('Clear', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF101411),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _signaturePoints.isNotEmpty ? green : border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _signaturePoints.add(details.localPosition);
                    });
                  },
                  onPanEnd: (_) => setState(() => _signaturePoints.add(null)),
                  child: CustomPaint(
                    painter: _SignaturePainter(_signaturePoints),
                    child: _signaturePoints.isEmpty
                        ? Center(
                            child: Text(
                              'Sign inside this box (Touch or Stylus)',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 4. Inspection Checkpoints
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  _checkpointRow(
                    'Produce Freshness Verified',
                    'AGMARK certified condition intact upon unloading',
                    _freshnessChecked,
                    (v) => setState(() => _freshnessChecked = v ?? true),
                  ),
                  const Divider(color: Colors.white10, height: 12),
                  _checkpointRow(
                    'Weight & Crates Verified',
                    'Full lot weight accounted for at receiver scale',
                    _quantityChecked,
                    (v) => setState(() => _quantityChecked = v ?? true),
                  ),
                  const Divider(color: Colors.white10, height: 12),
                  _checkpointRow(
                    'Zero Spoilage Handover',
                    'No transit bruising or cold-chain break reported',
                    _zeroDamageChecked,
                    (v) => setState(() => _zeroDamageChecked = v ?? true),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: loading ? null : _completeDelivery,
                icon: loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Icon(Icons.verified_rounded, size: 22),
                label: Text(
                  loading ? 'Recording POD & Releasing Escrow...' : 'Confirm Delivery & Release Escrow',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
    );
  }

  Widget _checkpointRow(String title, String subtitle, bool val, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Checkbox(
          value: val,
          onChanged: onChanged,
          activeColor: green,
          checkColor: Colors.black,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E676)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/quality_scanner_service.dart';
import 'add_product_screen.dart';

class QualityScannerScreen extends StatefulWidget {
  final String? initialCrop;

  const QualityScannerScreen({super.key, this.initialCrop});

  @override
  State<QualityScannerScreen> createState() => _QualityScannerScreenState();
}

class _QualityScannerScreenState extends State<QualityScannerScreen>
    with SingleTickerProviderStateMixin {
  static const Color background = Color(0xFF080A09);
  static const Color cardColor = Color(0xFF141715);
  static const Color primaryGreen = Color(0xFF00E676);
  static const Color darkGreen = Color(0xFF102819);
  static const Color borderColor = Color(0xFF223326);

  final ImagePicker _picker = ImagePicker();
  String _selectedCrop = 'Tomato';
  String? _selectedImagePath;
  bool _isScanning = false;
  QualityCertificate? _certificate;

  late AnimationController _beamController;

  final List<String> _crops = [
    'Tomato',
    'Onion',
    'Capsicum',
    'Potato',
    'Green Chilli',
    'Carrot',
    'Alphonso Mango',
    'Sweet Corn',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCrop != null && _crops.contains(widget.initialCrop)) {
      _selectedCrop = widget.initialCrop!;
    }
    _beamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _beamController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _selectedImagePath = photo.path;
          _certificate = null;
        });
        _runScanner(photo.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _testSampleCrop(String crop, String assetPath) {
    setState(() {
      _selectedCrop = crop;
      _selectedImagePath = assetPath;
      _certificate = null;
    });
    _runScanner(assetPath);
  }

  Future<void> _runScanner(String imgPath) async {
    setState(() => _isScanning = true);
    final cert = await QualityScannerService.analyzeProduce(
      cropName: _selectedCrop,
      imagePath: imgPath,
    );
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      _certificate = cert;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A150D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/kisan_logo.png',
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.camera_enhance_rounded,
                color: primaryGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Quality Check Scanner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Farmgate AGMARK Computer Vision Grading',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crop selector dropdown
            _buildCropSelector(),

            const SizedBox(height: 18),

            // Scanner viewfinder / preview
            _buildScannerViewfinder(),

            const SizedBox(height: 20),

            // Action Buttons (Camera / Gallery / Samples)
            _buildActionButtons(),

            const SizedBox(height: 16),

            // Quick Samples Chips
            _buildSampleProduceChips(),

            // Certificate Output
            if (_certificate != null) ...[
              const SizedBox(height: 24),
              _buildCertificateCard(_certificate!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCropSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco_rounded, color: primaryGreen, size: 20),
          const SizedBox(width: 12),
          const Text(
            'Target Crop:',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCrop,
                dropdownColor: const Color(0xFF161C18),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primaryGreen),
                items: _crops.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCrop = val);
                    if (_selectedImagePath != null) {
                      _runScanner(_selectedImagePath!);
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerViewfinder() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1411),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isScanning ? primaryGreen : borderColor,
          width: _isScanning ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Image or placeholder
          if (_selectedImagePath != null)
            _selectedImagePath!.startsWith('assets/')
                ? Image.asset(
                    _selectedImagePath!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF142217),
                      child: const Center(
                        child: Icon(Icons.eco_rounded, color: primaryGreen, size: 48),
                      ),
                    ),
                  )
                : Image.file(
                    File(_selectedImagePath!),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF142217),
                      child: const Center(
                        child: Icon(Icons.eco_rounded, color: primaryGreen, size: 48),
                      ),
                    ),
                  )
          else
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: darkGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryGreen.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    color: primaryGreen,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Align Produce Crate in Frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Detects ripeness, defect area & AGMARK grade',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),

          // Scanner Laser Beam Animation
          if (_isScanning)
            AnimatedBuilder(
              animation: _beamController,
              builder: (context, child) {
                return Positioned(
                  top: _beamController.value * 220,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          primaryGreen,
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withOpacity(0.8),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Scanning indicator banner
          if (_isScanning)
            Positioned(
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryGreen),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryGreen,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Analyzing Ripeness & Blemishes...',
                      style: TextStyle(
                        color: primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Capture Photo', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _pickImage(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF2E4434)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.photo_library_rounded, color: primaryGreen),
            label: const Text('Choose File'),
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Widget _buildSampleProduceChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Or test instant sample harvest photos:',
          style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _sampleChip('Tomato (Grade A)', 'assets/crops/tomato.png', 'Tomato'),
            _sampleChip('Onion (Cured)', 'assets/crops/onion.png', 'Onion'),
            _sampleChip('Carrot (Fresh)', 'assets/crops/carrot.png', 'Carrot'),
          ],
        ),
      ],
    );
  }

  Widget _sampleChip(String label, String asset, String crop) {
    return ActionChip(
      avatar: const Icon(Icons.verified_outlined, size: 16, color: primaryGreen),
      backgroundColor: const Color(0xFF142217),
      side: const BorderSide(color: Color(0xFF223F2B)),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
      ),
      onPressed: () => _testSampleCrop(crop, asset),
    );
  }

  Widget _buildCertificateCard(QualityCertificate cert) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1C12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primaryGreen.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${cert.grade} CERTIFIED',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                cert.certificateId,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            '${cert.cropName} AGMARK Quality Pass',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cert.gradeDescription,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),

          const SizedBox(height: 16),

          // 3 Metric Boxes
          Row(
            children: [
              _metricBox('Ripeness Index', '${cert.ripenessPercentage}%', const Color(0xFF00E676)),
              const SizedBox(width: 8),
              _metricBox('Blemish / Defects', '${cert.defectPercentage}%', const Color(0xFF00E5FF)),
              const SizedBox(width: 8),
              _metricBox('Uniformity', '${cert.uniformityPercentage}%', const Color(0xFFFFD600)),
            ],
          ),

          const SizedBox(height: 16),

          // Routing Recommendation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E3523)),
            ),
            child: Row(
              children: [
                const Icon(Icons.store_rounded, color: primaryGreen, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recommended Buyer Channel:',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      Text(
                        cert.targetBuyer,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Attach to Listing Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.attach_file_rounded),
              label: const Text(
                'Attach Certificate to Produce Listing',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddProductScreen(
                      initialCrop: cert.cropName,
                      initialQuality: cert.grade,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBox(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            const SizedBox(height: 6),
            Text(
              val,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

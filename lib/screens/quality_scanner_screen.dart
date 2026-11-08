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
  final List<String> _lotImagePaths = [];
  bool _isLotMode = false;
  bool _isScanning = false;
  QualityCertificate? _certificate;

  late AnimationController _beamController;

  final List<String> _crops = [
    'Tomato',
    'Onion',
    'Potato',
    'Brinjal',
    'Ladies Finger',
    'Carrot',
    'Green Chilli',
    'Capsicum',
    'Cabbage',
    'Cauliflower',
    'Beans',
    'Beetroot',
    'Cucumber',
    'Bottle Gourd',
    'Bitter Gourd',
    'Radish',
    'Ginger',
    'Garlic',
    'Drumstick',
    'Spinach',
    'Coriander',
    'Banana',
    'Mango',
    'Apple',
    'Lemon',
    'Orange',
    'Pomegranate',
    'Papaya',
    'Guava',
    'Grapes',
    'Watermelon',
    'Sweet Corn',
    'Coconut',
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
        if (_isLotMode) {
          setState(() {
            _lotImagePaths.add(photo.path);
            _selectedImagePath = photo.path;
            _certificate = null;
          });
          _runLotScanner();
        } else {
          setState(() {
            _lotImagePaths.clear();
            _selectedImagePath = photo.path;
            _certificate = null;
          });
          _runScanner(photo.path);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _testSampleCrop(String crop, String assetPath) {
    setState(() {
      _selectedCrop = crop;
      _selectedImagePath = assetPath;
      _lotImagePaths.clear();
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

  Future<void> _runLotScanner() async {
    if (_lotImagePaths.isEmpty) return;
    setState(() => _isScanning = true);
    final cert = await QualityScannerService.analyzeLotProduce(
      cropName: _selectedCrop,
      imagePaths: _lotImagePaths,
    );
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      _certificate = cert;
    });
  }

  void _showReportCorrectionDialog() {
    if (_certificate == null) return;
    final cert = _certificate!;
    final correctionController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141916),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF283A2E)),
        ),
        title: const Row(
          children: [
            Icon(Icons.report_problem_rounded, color: Colors.orangeAccent),
            SizedBox(width: 10),
            Text(
              'Report Incorrect Result',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help retrain the KisanAI inspection model. System reported: "${cert.grade}" (${cert.detectedCrop}).',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: correctionController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Correct Crop / Grade',
                  labelStyle: const TextStyle(color: primaryGreen, fontSize: 12),
                  hintText: 'e.g. Fresh Tomato Grade A, or Rotten Reject',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0D140F),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Observation / Reason',
                  labelStyle: const TextStyle(color: primaryGreen, fontSize: 12),
                  hintText: 'e.g. Skin had sunburn, not fungal rot',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0D140F),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final corr = correctionController.text.trim();
              final rsn = reasonController.text.trim();
              if (corr.isNotEmpty) {
                Navigator.pop(ctx);
                final ok = await QualityScannerService.reportIncorrectResult(
                  cert: cert,
                  userCorrection: corr,
                  reason: rsn,
                );
                if (mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Feedback saved to quality_corrections queue for review.'),
                      backgroundColor: primaryGreen,
                    ),
                  );
                }
              }
            },
            child: const Text('Submit Correction'),
          ),
        ],
      ),
    );
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
            // Mode Selector: Single Photo vs Multi-Photo Lot
            _buildModeSelector(),

            const SizedBox(height: 14),

            // Crop selector dropdown
            _buildCropSelector(),

            const SizedBox(height: 18),

            // Scanner viewfinder / preview
            _buildScannerViewfinder(),

            // Multi-photo thumb rail if lot mode active
            if (_isLotMode && _lotImagePaths.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildLotThumbnailRail(),
            ],

            const SizedBox(height: 20),

            // Action Buttons (Camera / Gallery)
            _buildActionButtons(),

            const SizedBox(height: 16),

            // Quick Samples Chips (Real test cases: fresh, rotten, mismatch, shoe)
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

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isLotMode = false;
                  _lotImagePaths.clear();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_isLotMode ? primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Single Sample Scan',
                  style: TextStyle(
                    color: !_isLotMode ? Colors.black : Colors.white70,
                    fontSize: 12,
                    fontWeight: !_isLotMode ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isLotMode = true;
                  _lotImagePaths.clear();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _isLotMode ? primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Multi-Photo Lot (3-5 Photos)',
                  style: TextStyle(
                    color: _isLotMode ? Colors.black : Colors.white70,
                    fontSize: 12,
                    fontWeight: _isLotMode ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
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
                      if (_isLotMode && _lotImagePaths.isNotEmpty) {
                        _runLotScanner();
                      } else {
                        _runScanner(_selectedImagePath!);
                      }
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
            _selectedImagePath!.startsWith('assets/') || _selectedImagePath!.startsWith('test/')
                ? Image.file(
                    File(_selectedImagePath!),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
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
                Text(
                  _isLotMode
                      ? 'Capture Batch Samples (3-5 Photos)'
                      : 'Align Produce Crate in Frame',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Identifies crop, verifies selection, detects defects honestly',
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
                      'Identifying Crop & Surface Lesions...',
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

  Widget _buildLotThumbnailRail() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _lotImagePaths.length,
        itemBuilder: (ctx, idx) {
          final p = _lotImagePaths[idx];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            width: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryGreen, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.file(File(p), fit: BoxFit.cover),
          );
        },
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
            label: Text(
              _isLotMode ? 'Add Lot Photo (${_lotImagePaths.length}/5)' : 'Capture Photo',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
          'Run real acceptance tests (evaluates honest grading):',
          style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _sampleChip('Fresh Tomato (Grade A)', 'test/test_images/fresh_tomato.png', 'Tomato', Colors.greenAccent),
            _sampleChip('Rotten Tomato (Reject / Blight)', 'test/test_images/rotten_tomato.png', 'Tomato', Colors.redAccent),
            _sampleChip('Onion with "Tomato" Target (Mismatch)', 'test/test_images/fresh_onion.png', 'Tomato', Colors.orangeAccent),
            _sampleChip('Shoe / Leather (Non-Produce)', 'test/test_images/shoe_non_produce.png', 'Tomato', Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _sampleChip(String label, String asset, String crop, Color tint) {
    return ActionChip(
      avatar: Icon(Icons.science_outlined, size: 16, color: tint),
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
    final bool isReject = cert.grade.contains('Reject') || !cert.isProduce || cert.grade.contains('Mismatch');
    final Color badgeColor = !cert.isProduce
        ? Colors.grey
        : (!cert.selectedCropMatches
            ? Colors.orangeAccent
            : (cert.grade.contains('Reject')
                ? Colors.redAccent
                : (cert.grade.contains('Grade C')
                    ? Colors.amber
                    : (cert.grade.contains('Grade B')
                        ? const Color(0xFF00E5FF)
                        : primaryGreen))));

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1C12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.12),
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
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  !cert.isProduce
                      ? 'NON-PRODUCE REJECTED'
                      : (!cert.selectedCropMatches
                          ? 'CROP MISMATCH BLOCKED'
                          : (!cert.isReliable
                              ? 'AMBIGUOUS / RETAKE'
                              : (cert.grade.contains('Reject')
                                  ? 'SUBSTANDARD / REJECT'
                                  : '${cert.grade.toUpperCase()} CERTIFIED'))),
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

          // Crop Identification Result Row
          Row(
            children: [
              const Icon(Icons.find_in_page_outlined, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                'Detected: ${cert.detectedCrop} (${cert.cropConfidence.toInt()}%)',
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (cert.isOfflineEstimate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Offline estimate', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            !cert.isProduce
                ? 'No Harvest Produce Detected'
                : (!cert.selectedCropMatches
                    ? 'Crop Mismatch Detected'
                    : '${cert.cropName} AGMARK Inspection Pass'),
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

          // Crop Mismatch Alert Banner
          if (!cert.selectedCropMatches && cert.isProduce) ...[
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Incorrect: this looks like ${cert.detectedCrop} (confidence ${cert.cropConfidence.toInt()}%), not ${cert.cropName}.',
                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orangeAccent,
                        side: const BorderSide(color: Colors.orangeAccent),
                      ),
                      onPressed: () {
                        if (_crops.contains(cert.detectedCrop)) {
                          setState(() {
                            _selectedCrop = cert.detectedCrop;
                          });
                          if (_selectedImagePath != null) {
                            _runScanner(_selectedImagePath!);
                          }
                        }
                      },
                      child: Text('Switch Target Crop to "${cert.detectedCrop}" & Re-Grade'),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Rejection / Warning banner
          if (cert.rejectionReason != null && cert.selectedCropMatches) ...[
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cert.rejectionReason!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 3 Metric Boxes
          Row(
            children: [
              _metricBox('Ripeness Index', '${cert.ripenessPercentage}%', const Color(0xFF00E5FF)),
              const SizedBox(width: 8),
              _metricBox(
                'Defect Area',
                '${cert.defectPercentage}%',
                cert.defectPercentage >= 15.0 ? Colors.redAccent : (cert.defectPercentage > 6.0 ? Colors.amber : primaryGreen),
              ),
              const SizedBox(width: 8),
              _metricBox('Condition', cert.condition, const Color(0xFFFFD700)),
            ],
          ),

          // Trilingual Explanation Section
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1A3322)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grade Explanation (Trilingual AGMARK Inspection):',
                  style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text('EN: ${cert.explanationEn}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                const SizedBox(height: 4),
                Text('TA: ${cert.explanationTa}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text('HI: ${cert.explanationHi}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),

          const SizedBox(height: 14),

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
                Icon(
                  isReject ? Icons.delete_outline_rounded : Icons.store_rounded,
                  color: isReject ? Colors.orangeAccent : primaryGreen,
                  size: 22,
                ),
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

          // Attach to Listing Button (Only if valid produce and crop matches)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: !isReject ? primaryGreen : Colors.grey[800],
                foregroundColor: !isReject ? Colors.black : Colors.white60,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(!isReject ? Icons.attach_file_rounded : Icons.refresh_rounded),
              label: Text(
                !isReject
                    ? 'Attach Certificate to Produce Listing'
                    : 'Re-scan with Clear Harvest Photo',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: !isReject
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddProductScreen(
                            initialCrop: cert.cropName,
                            initialQuality: cert.grade,
                          ),
                        ),
                      );
                    }
                  : () => _pickImage(ImageSource.camera),
            ),
          ),

          const SizedBox(height: 10),

          // Feedback Loop: Report Incorrect Result Button
          Center(
            child: TextButton.icon(
              onPressed: _showReportCorrectionDialog,
              icon: const Icon(Icons.flag_outlined, size: 16, color: Colors.white54),
              label: const Text(
                'Report Incorrect Result (Feedback Loop)',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
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
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

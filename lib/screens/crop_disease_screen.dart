import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/disease_detection_service.dart';
import '../services/language_service.dart';

class CropDiseaseScreen extends StatefulWidget {
  final String? initialCrop;

  const CropDiseaseScreen({super.key, this.initialCrop});

  @override
  State<CropDiseaseScreen> createState() => _CropDiseaseScreenState();
}

class _CropDiseaseScreenState extends State<CropDiseaseScreen>
    with SingleTickerProviderStateMixin {
  static const Color background = Color(0xFF080D09);
  static const Color cardColor = Color(0xFF131A14);
  static const Color primaryGreen = Color(0xFF00E676);
  static const Color border = Color(0xFF243426);
  static const Color orange = Color(0xFFFF9800);
  static const Color red = Color(0xFFEF4444);

  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _selectedCrop = 'Tomato';
  String? _selectedImagePath;
  bool _isAnalyzing = false;
  DiseaseDiagnosisResult? _result;
  int _selectedTreatmentTab = 0; // 0 = Organic, 1 = Chemical

  late AnimationController _beamController;

  final List<String> _crops = [
    'Tomato',
    'Potato',
    'Chilli',
    'Cotton',
    'Rice',
    'Banana',
    'Mango',
    'Brinjal',
    'Onion',
    'Cabbage',
    'Groundnut',
    'Maize',
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
          _result = null;
        });
        _runDiagnosis(photo.path);
      }
    } catch (e) {
      debugPrint('Error picking leaf image: $e');
    }
  }

  Future<void> _runDiagnosis(String imgPath) async {
    setState(() => _isAnalyzing = true);
    final user = _auth.currentUser;
    final res = await DiseaseDetectionService.diagnoseLeaf(
      crop: _selectedCrop,
      imagePath: imgPath,
      userId: user?.uid,
    );
    if (!mounted) return;
    setState(() {
      _isAnalyzing = false;
      _result = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLocaleNotifier,
      builder: (context, locale, _) {
        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D150E),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LanguageService.tr('crop_doctor', defaultText: 'AI Leaf Doctor & Disease Scanner'),
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  LanguageService.tr('icar_certified', defaultText: 'ICAR & CIBRC Treatment Protocol'),
                  style: GoogleFonts.poppins(color: primaryGreen, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Colors.white70),
                onPressed: () => _showHistoryModal(),
                tooltip: 'Scan History',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Crop Selector Strip
                _buildCropSelector(),

                const SizedBox(height: 16),

                // Image Scanner Viewport
                _buildScanViewport(),

                const SizedBox(height: 16),

                // Action Buttons (Camera / Gallery / Presets)
                _buildCaptureButtons(),

                const SizedBox(height: 20),

                // Results Card
                if (_result != null) _buildDiagnosisCard(_result!),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCropSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco_rounded, color: primaryGreen, size: 20),
          const SizedBox(width: 10),
          Text(
            LanguageService.tr('target_crop', defaultText: 'Target Crop:'),
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCrop,
                dropdownColor: const Color(0xFF162018),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primaryGreen),
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                isExpanded: true,
                items: _crops.map((crop) {
                  return DropdownMenuItem<String>(
                    value: crop,
                    child: Text(LanguageService.tr(crop.toLowerCase(), defaultText: crop)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCrop = val;
                      _result = null;
                    });
                    if (_selectedImagePath != null) {
                      _runDiagnosis(_selectedImagePath!);
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

  Widget _buildScanViewport() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF0E1410),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_selectedImagePath != null && File(_selectedImagePath!).existsSync())
              Image.file(
                File(_selectedImagePath!),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.document_scanner_rounded, color: primaryGreen, size: 48),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    LanguageService.tr('capture_leaf_instruction', defaultText: 'Point camera at an infected or discolored leaf'),
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    LanguageService.tr('hold_steady', defaultText: 'Natural light • 15 cm distance • Steady focus'),
                    style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),

            // Scanning Beam Overlay
            if (_isAnalyzing)
              AnimatedBuilder(
                animation: _beamController,
                builder: (context, _) {
                  return Positioned(
                    top: _beamController.value * 220,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: primaryGreen,
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withValues(alpha: 0.8),
                            blurRadius: 16,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            if (_isAnalyzing)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: primaryGreen, strokeWidth: 3),
                      const SizedBox(height: 14),
                      Text(
                        LanguageService.tr('analyzing_leaf_pathology', defaultText: 'Analyzing foliar lesions with Deep Vision AI...'),
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded, size: 20),
                label: Text(
                  LanguageService.tr('take_leaf_photo', defaultText: 'Take Photo'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded, size: 20, color: Colors.white70),
                label: Text(
                  LanguageService.tr('gallery', defaultText: 'Gallery'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: cardColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiagnosisCard(DiseaseDiagnosisResult res) {
    Color severityColor = primaryGreen;
    if (res.severity == 'Severe') severityColor = red;
    if (res.severity == 'Moderate') severityColor = orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: severityColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${res.severity.toUpperCase()} SEVERITY',
                  style: TextStyle(color: severityColor, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  res.pathogenType,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Disease Titles
          Text(
            res.diseaseName,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (res.diseaseNameLocal.isNotEmpty && res.diseaseNameLocal != res.diseaseName)
            Text(
              res.diseaseNameLocal,
              style: GoogleFonts.outfit(color: primaryGreen, fontSize: 14, fontWeight: FontWeight.w600),
            ),

          const SizedBox(height: 14),

          // Affected Surface Area Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Foliar Defect Surface Area',
                style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11),
              ),
              Text(
                '${res.affectedAreaPercentage.toStringAsFixed(1)}%',
                style: GoogleFonts.outfit(color: severityColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (res.affectedAreaPercentage / 100.0).clamp(0.0, 1.0),
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(severityColor),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 18),

          // Symptoms Checklist
          Text(
            'Observed Symptoms',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...res.symptoms.map((symptom) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: primaryGreen, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        symptom,
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 16),
          const Divider(color: border),
          const SizedBox(height: 10),

          // Treatment Protocol Switcher
          Text(
            'Recommended Treatment Protocol',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0A100B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTreatmentTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTreatmentTab == 0 ? primaryGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Organic / Bio-Control',
                        style: TextStyle(
                          color: _selectedTreatmentTab == 0 ? Colors.black : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTreatmentTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTreatmentTab == 1 ? primaryGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Chemical Control',
                        style: TextStyle(
                          color: _selectedTreatmentTab == 1 ? Colors.black : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Treatment Detail Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1711),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _selectedTreatmentTab == 0 ? Icons.eco_rounded : Icons.science_rounded,
                      color: primaryGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedTreatmentTab == 0 ? 'Biological & Organic Prescription' : 'ICAR / CIBRC Chemical Dosage',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedTreatmentTab == 0 ? res.organicTreatment : res.chemicalTreatment,
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, height: 1.45),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Preventive Cultural Practices
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, color: Colors.white60, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preventive & Cultural Practices',
                        style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        res.preventiveMeasures,
                        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHistoryModal() {
    final user = _auth.currentUser;
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        if (user == null) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Sign in to access your farm leaf disease history.',
              style: GoogleFonts.outfit(color: Colors.white70),
            ),
          );
        }
        return StreamBuilder(
          stream: DiseaseDetectionService.diagnoseLeaf(crop: _selectedCrop) as dynamic,
          builder: (context, snapshot) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leaf Health Log',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'All diagnoses are securely backed up in your farm record.',
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

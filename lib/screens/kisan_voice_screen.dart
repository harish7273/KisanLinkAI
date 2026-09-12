import 'dart:async';
import 'package:flutter/material.dart';
import '../services/kisan_voice_service.dart';
import 'add_product_screen.dart';

class KisanVoiceScreen extends StatefulWidget {
  final String? initialPrompt;

  const KisanVoiceScreen({super.key, this.initialPrompt});

  @override
  State<KisanVoiceScreen> createState() => _KisanVoiceScreenState();
}

class _KisanVoiceScreenState extends State<KisanVoiceScreen>
    with SingleTickerProviderStateMixin {
  static const Color background = Color(0xFF080A09);
  static const Color cardColor = Color(0xFF141715);
  static const Color primaryGreen = Color(0xFF00E676);
  static const Color darkGreen = Color(0xFF102819);
  static const Color borderColor = Color(0xFF223326);

  String _selectedLang = 'ta'; // 'ta', 'en', 'hi'
  bool _isListening = false;
  String _recognizedText = '';
  VoiceListingResult? _parsedResult;
  String? _assistantAnswer;
  final TextEditingController _manualTextController = TextEditingController();

  late AnimationController _pulseController;

  final List<String> _tamilChips = [
    '500 கிலோ தக்காளி பொள்ளாச்சி',
    '1200 கிலோ வெங்காயம் நாசிக்',
    '400 கிலோ குடைமிளகாய் ஊட்டி',
    'இன்றைய தக்காளி விலை என்ன?',
    'தர சான்றிதழ் பெறுவது எப்படி?',
  ];

  final List<String> _englishChips = [
    '500 kg Tomato Pollachi Coimbatore',
    '1200 kg Onion Nashik Garwa',
    '400 kg Capsicum Ooty Nilgiris',
    'What is today\'s mandi rate?',
    'How does KisanPool logistics work?',
  ];

  final List<String> _hindiChips = [
    '500 किलो टमाटर पोलाची कोयंबटूर',
    '1200 किलो प्याज नासिक',
    '1500 किलो आलू आगरा',
    'आज का टमाटर का भाव क्या है?',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _processVoiceInput(widget.initialPrompt!);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _manualTextController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });

    if (_isListening) {
      // Simulate speech listening with countdown
      Timer(const Duration(seconds: 2), () {
        if (!mounted || !_isListening) return;
        final sample = _selectedLang == 'ta'
            ? '500 கிலோ தக்காளி பொள்ளாச்சி கோவை'
            : (_selectedLang == 'hi'
                ? '500 किलो टमाटर पोलाची'
                : '500 kg Tomato Pollachi Coimbatore');
        _processVoiceInput(sample);
      });
    }
  }

  void _processVoiceInput(String text) {
    setState(() {
      _isListening = false;
      _recognizedText = text;
      _parsedResult = KisanVoiceService.parseVoiceListing(text);
      _assistantAnswer = KisanVoiceService.answerFarmerQuery(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chips = _selectedLang == 'ta'
        ? _tamilChips
        : (_selectedLang == 'hi' ? _hindiChips : _englishChips);

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
                Icons.mic_rounded,
                color: primaryGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KisanAI Voice Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Zero-Typing Voice Listing & AI Support',
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
            // Language Selection Pills
            _buildLanguageSelector(),

            const SizedBox(height: 24),

            // Microphone Visualizer Card
            _buildMicVisualizer(),

            const SizedBox(height: 20),

            // Quick Voice Chips
            Text(
              _selectedLang == 'ta'
                  ? 'விரைவு குரல் உதாரணங்கள் (Tap to test):'
                  : (_selectedLang == 'hi'
                      ? 'त्वरित आवाज़ नमूने:'
                      : 'Quick Voice Prompts (Tap to test):'),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips.map((chip) {
                return ActionChip(
                  avatar: const Icon(
                    Icons.record_voice_over_rounded,
                    size: 16,
                    color: primaryGreen,
                  ),
                  backgroundColor: const Color(0xFF16251A),
                  side: const BorderSide(color: Color(0xFF22422C)),
                  label: Text(
                    chip,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () => _processVoiceInput(chip),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Manual Text Input Fallback
            _buildManualInput(),

            // Result Display
            if (_parsedResult != null) ...[
              const SizedBox(height: 24),
              _buildListingResultCard(_parsedResult!),
            ],

            if (_assistantAnswer != null) ...[
              const SizedBox(height: 20),
              _buildAssistantAnswerCard(_assistantAnswer!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          _langTab('ta', 'தமிழ் (Tamil)'),
          _langTab('en', 'English'),
          _langTab('hi', 'हिंदी (Hindi)'),
        ],
      ),
    );
  }

  Widget _langTab(String code, String label) {
    final active = _selectedLang == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedLang = code),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.black : Colors.white70,
              fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicVisualizer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isListening
              ? primaryGreen.withOpacity(0.6)
              : borderColor,
          width: _isListening ? 2 : 1,
        ),
        boxShadow: [
          if (_isListening)
            BoxShadow(
              color: primaryGreen.withOpacity(0.25),
              blurRadius: 25,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = _isListening
                    ? 1.0 + (_pulseController.value * 0.15)
                    : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isListening
                            ? [const Color(0xFF00E676), const Color(0xFF00B0FF)]
                            : [const Color(0xFF1E3A28), const Color(0xFF122519)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isListening
                              ? primaryGreen.withOpacity(0.5)
                              : Colors.black45,
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening ? Colors.black : primaryGreen,
                      size: 44,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _isListening
                ? (_selectedLang == 'ta'
                    ? 'பேசவும்... கவனித்துக் கொண்டிருக்கிறோம் 🎙️'
                    : 'Listening... Speak your crop harvest')
                : (_selectedLang == 'ta'
                    ? 'மைக் ஐ அழுத்தி தமிழில் பேசவும்'
                    : 'Tap microphone to speak'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isListening ? primaryGreen : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedLang == 'ta'
                ? 'எ.கா: "500 கிலோ தக்காளி பொள்ளாச்சி கோவை"'
                : 'e.g. "500 kg Fresh Tomato Pollachi Coimbatore"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.keyboard_rounded, color: Colors.white38),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _manualTextController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Or type harvest here (e.g. 800 kg Tomato)...',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                border: InputBorder.none,
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  _processVoiceInput(val);
                  _manualTextController.clear();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: primaryGreen),
            onPressed: () {
              final val = _manualTextController.text.trim();
              if (val.isNotEmpty) {
                _processVoiceInput(val);
                _manualTextController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListingResultCard(VoiceListingResult res) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1A11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryGreen.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: primaryGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Voice Harvest Extracted',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'AI Verified',
                  style: TextStyle(
                    color: primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _detailRow('Crop', res.crop, Icons.eco_rounded),
          _detailRow('Quantity', '${res.quantityKg.toInt()} kg', Icons.inventory_2_outlined),
          _detailRow('Farm Location', res.location, Icons.location_on_outlined),
          _detailRow('Mandi Benchmark', '₹${res.estimatedMandiPrice.toStringAsFixed(0)} / kg', Icons.storefront_outlined),
          _detailRow('KisanAI Direct Rate', '₹${res.estimatedDirectPrice.toStringAsFixed(0)} / kg (+55%)', Icons.trending_up_rounded, valueColor: primaryGreen),
          const Divider(color: Color(0xFF223528), height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text(
                'Auto-Fill Produce Listing Form',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddProductScreen(
                      initialCrop: res.crop,
                      initialQuantity: res.quantityKg.toInt(),
                      initialLocation: res.location,
                      initialPrice: res.estimatedDirectPrice,
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

  Widget _buildAssistantAnswerCard(String answer) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: darkGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_rounded, color: primaryGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KisanAI Advisory',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  answer,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String val, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white38),
          const SizedBox(width: 8),
          Text('$label:', style: const TextStyle(color: Colors.white60, fontSize: 13)),
          const Spacer(),
          Text(
            val,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/kisan_voice_service.dart';
import 'add_product_screen.dart';
import 'buyer_market_screen.dart';
import 'farmer_orders_screen.dart';
import 'quality_scanner_screen.dart';

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
  bool _isSpeechAvailable = false;
  String _statusMessage = '';
  String _recognizedText = '';
  VoiceListingResult? _parsedResult;
  String? _assistantAnswer;
  bool _isLoadingAdvisory = false;

  final TextEditingController _manualTextController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  late AnimationController _pulseController;

  final List<String> _tamilChips = [
    '500 கிலோ தக்காளி பொள்ளாச்சி 30 ரூபாய்',
    '1200 கிலோ வெங்காயம் நாசிக் 25 ரூபாய்',
    '400 கிலோ குடைமிளகாய் ஊட்டி',
    'இன்றைய தக்காளி மண்டி விலை என்ன?',
    'ஆர்டர்களை திற',
  ];

  final List<String> _englishChips = [
    '500 kg Tomato Pollachi at 30 rupees per kg',
    '1200 kg Onion Nashik at 24 rupees',
    '400 kg Capsicum Ooty',
    'What is today\'s mandi rate?',
    'Open orders',
  ];

  final List<String> _hindiChips = [
    '500 किलो टमाटर पोलाची तीस रुपये प्रति किलो',
    '1200 किलो प्याज नासिक 24 रुपये',
    '1500 किलो आलू आगरा',
    'आज का टमाटर का भाव क्या है?',
    'ऑर्डर खोलो',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _initSpeech();

    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _processVoiceInput(widget.initialPrompt!);
    }
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('[SpeechToText] status: $status');
          if (mounted) {
            if (status == 'notListening' || status == 'done') {
              setState(() => _isListening = false);
            }
          }
        },
        onError: (errorNotification) {
          debugPrint('[SpeechToText] error: ${errorNotification.errorMsg}');
          if (mounted) {
            setState(() {
              _isListening = false;
              _statusMessage = 'Speech error: ${errorNotification.errorMsg}';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isSpeechAvailable = available;
          if (!available) {
            _statusMessage = 'Microphone or speech services initializing...';
          }
        });
      }
    } catch (e) {
      debugPrint('[SpeechToText] init exception: $e');
      if (mounted) {
        setState(() {
          _isSpeechAvailable = false;
          _statusMessage = 'Speech engine initialization pending.';
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _manualTextController.dispose();
    _speech.stop();
    super.dispose();
  }

  String _getLocaleForSelectedLang() {
    switch (_selectedLang) {
      case 'ta':
        return 'ta_IN';
      case 'hi':
        return 'hi_IN';
      default:
        return 'en_IN';
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    // Request runtime microphone permission
    final micStatus = await Permission.microphone.request();
    if (micStatus.isDenied || micStatus.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedLang == 'ta'
                  ? 'மைக் அனுமதி மறுக்கப்பட்டது. அமைப்புகளில் அனுமதிக்கவும்.'
                  : (_selectedLang == 'hi'
                      ? 'माइक अनुमति अस्वीकृत। सेटिंग्स में सक्षम करें।'
                      : 'Microphone permission required to listen.'),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (!_isSpeechAvailable) {
      await _initSpeech();
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _statusMessage = _selectedLang == 'ta'
          ? 'பேசவும்... கவனித்துக் கொண்டிருக்கிறோம் 🎙️'
          : (_selectedLang == 'hi'
              ? 'सुन रहे हैं... बोलिए 🎙️'
              : 'Listening... speak clearly into mic 🎙️');
    });

    final targetLocale = _getLocaleForSelectedLang();

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _recognizedText = result.recognizedWords;
          });

          if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
            _processVoiceInput(result.recognizedWords);
          }
        },
        localeId: targetLocale,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      debugPrint('[SpeechToText] listen error: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusMessage = 'Could not start speech listening: $e';
        });
      }
    }
  }

  Future<void> _processVoiceInput(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) {
      setState(() {
        _statusMessage = _selectedLang == 'ta'
            ? 'குரல் கேட்கவில்லை. மீண்டும் பேசவும்.'
            : (_selectedLang == 'hi'
                ? 'कोई आवाज़ नहीं सुनी गई। कृपया पुनः बोलें।'
                : 'No speech detected. Please speak again.');
      });
      return;
    }

    setState(() {
      _isListening = false;
      _recognizedText = clean;
      _parsedResult = KisanVoiceService.parseVoiceListing(clean);
      _statusMessage = '';
    });

    // Check if voice command triggers navigation
    if (_parsedResult?.command != null) {
      _handleVoiceCommand(_parsedResult!.command!);
      return;
    }

    // Speak follow-up question if missing details
    if (_parsedResult!.followUpQuestion != null) {
      KisanVoiceService.speakResponse(_parsedResult!.followUpQuestion!, language: _selectedLang);
    }

    // If query is an advisory / information question, fetch AI response
    if (!_parsedResult!.isListingIntent || clean.contains('?') || clean.contains('எப்படி') || clean.contains('விலை') || clean.contains('rate') || clean.contains('भाव')) {
      setState(() => _isLoadingAdvisory = true);
      final ans = await KisanVoiceService.answerFarmerQuery(clean, language: _selectedLang);
      if (mounted) {
        setState(() {
          _assistantAnswer = ans;
          _isLoadingAdvisory = false;
        });
        KisanVoiceService.speakResponse(ans, language: _selectedLang);
      }
    } else {
      setState(() => _assistantAnswer = null);
    }
  }

  void _handleVoiceCommand(String command) {
    String msg = '';
    Widget? destination;

    switch (command) {
      case 'open_orders':
        msg = _selectedLang == 'ta' ? 'ஆர்டர்கள் பக்கத்திற்கு செல்கிறது...' : 'Navigating to Orders...';
        destination = const FarmerOrdersScreen();
        break;
      case 'open_market':
        msg = _selectedLang == 'ta' ? 'விளைபொருள் சந்தைக்கு செல்கிறது...' : 'Navigating to Produce Market...';
        destination = const BuyerMarketScreen();
        break;
      case 'open_quality':
        msg = _selectedLang == 'ta' ? 'தர பரிசோதனை ஸ்கேனரை திறக்கிறது...' : 'Opening AI Quality Scanner...';
        destination = const QualityScannerScreen();
        break;
      case 'check_price':
        msg = _selectedLang == 'ta' ? 'மண்டி விலை நிலவரம் காட்டப்படுகிறது.' : 'Displaying Mandi benchmarks.';
        break;
      case 'change_lang_ta':
        setState(() => _selectedLang = 'ta');
        msg = 'மொழியை தமிழுக்கு மாற்றப்பட்டது.';
        break;
      case 'change_lang_en':
        setState(() => _selectedLang = 'en');
        msg = 'Language switched to English.';
        break;
      case 'change_lang_hi':
        setState(() => _selectedLang = 'hi');
        msg = 'भाषा हिंदी में बदल दी गई है।';
        break;
      case 'filter_orders':
        msg = _selectedLang == 'ta' ? 'நிலுவையில் உள்ள ஆர்டர்கள் வடிகட்டப்படுகிறது...' : 'Filtering pending orders...';
        destination = const FarmerOrdersScreen();
        break;
    }

    KisanVoiceService.speakResponse(msg, language: _selectedLang);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );

    if (destination != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => destination!));
    }
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
                  'Real-Time Speech & Input-Driven AI',
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

            if (_statusMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isListening ? primaryGreen : Colors.orangeAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Quick Voice Chips (Tap to test input parsing)
            Text(
              _selectedLang == 'ta'
                  ? 'மாதிரி குரல் உள்ளீடுகள் (Tap to test input):'
                  : (_selectedLang == 'hi'
                      ? 'नमूना आवाज़ इनपुट:'
                      : 'Sample Voice Inputs (Tap to test input):'),
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

            // Result Display: Confirmation Card
            if (_parsedResult != null) ...[
              const SizedBox(height: 24),
              _buildListingResultCard(_parsedResult!),
            ],

            if (_isLoadingAdvisory) ...[
              const SizedBox(height: 20),
              const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              ),
            ] else if (_assistantAnswer != null) ...[
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
        onTap: () {
          setState(() {
            _selectedLang = code;
          });
        },
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
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isListening ? primaryGreen.withOpacity(0.6) : borderColor,
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
                    : (_selectedLang == 'hi'
                        ? 'सुन रहे हैं... बोलिए 🎙️'
                        : 'Listening... Speak your crop harvest'))
                : (_selectedLang == 'ta'
                    ? 'மைக் ஐ அழுத்தி பேசவும்'
                    : (_selectedLang == 'hi'
                        ? 'माइक दबाकर बोलें'
                        : 'Tap microphone to speak')),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isListening ? primaryGreen : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Live Transcript Display
          if (_recognizedText.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1F13),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E4B2B)),
              ),
              child: Text(
                '“$_recognizedText”',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ] else ...[
            Text(
              _selectedLang == 'ta'
                  ? 'எ.கா: "500 கிலோ தக்காளி பொள்ளாச்சி 30 ரூபாய்"'
                  : (_selectedLang == 'hi'
                      ? 'उदा: "500 किलो टमाटर पोलाची 30 रुपये"'
                      : 'e.g. "500 kg Tomato Pollachi at 30 rupees"'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
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
              decoration: InputDecoration(
                hintText: _selectedLang == 'ta'
                    ? 'அல்லது உரையை இங்கே தட்டச்சு செய்யவும்...'
                    : (_selectedLang == 'hi'
                        ? 'या यहाँ टाइप करें...'
                        : 'Or type harvest here (e.g. 50 kg Tomato)...'),
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
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
              Row(
                children: [
                  Icon(
                    res.isComplete
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    color: res.isComplete ? primaryGreen : Colors.orangeAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    res.isComplete
                        ? 'Confirmation Card'
                        : 'Extracted Details',
                    style: const TextStyle(
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
                  color: (res.isComplete ? primaryGreen : Colors.orangeAccent)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  res.isComplete ? 'Ready to List' : 'Missing Info',
                  style: TextStyle(
                    color: res.isComplete ? primaryGreen : Colors.orangeAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Follow up notice if missing fields
          if (res.followUpQuestion != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.help_outline_rounded, color: Colors.orangeAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      res.followUpQuestion!,
                      style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          _detailRow(
            'Crop',
            res.crop ?? 'Not mentioned',
            Icons.eco_rounded,
            isMissing: res.crop == null,
          ),
          _detailRow(
            'Quantity',
            res.quantityKg != null ? '${res.quantityKg!.toInt()} kg' : 'Not mentioned',
            Icons.inventory_2_outlined,
            isMissing: res.quantityKg == null,
          ),
          _detailRow(
            'Selling Price',
            res.price != null ? '₹${res.price!.toStringAsFixed(0)} / kg' : 'Not mentioned (Never invented)',
            Icons.payments_outlined,
            isMissing: res.price == null,
            valueColor: res.price != null ? primaryGreen : Colors.orangeAccent,
          ),
          _detailRow(
            'Farm Location',
            res.location ?? 'Not mentioned',
            Icons.location_on_outlined,
            isMissing: res.location == null,
          ),

          if (res.estimatedMandiPrice != null) ...[
            _detailRow(
              'Market Price Today (Hint only)',
              '₹${res.estimatedMandiPrice!.toStringAsFixed(0)} / kg',
              Icons.storefront_outlined,
              valueColor: const Color(0xFF00E5FF),
            ),
          ],

          const Divider(color: Color(0xFF223528), height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: res.crop != null ? primaryGreen : Colors.grey[800],
                foregroundColor: res.crop != null ? Colors.black : Colors.white60,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                res.crop != null
                    ? 'Auto-Fill Produce Listing Form'
                    : 'Specify Crop First',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: res.crop != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddProductScreen(
                            initialCrop: res.crop,
                            initialQuantity: res.quantityKg?.toInt(),
                            initialLocation: res.location,
                            initialPrice: res.price,
                          ),
                        ),
                      );
                    }
                  : null,
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

  Widget _detailRow(
    String label,
    String val,
    IconData icon, {
    Color? valueColor,
    bool isMissing = false,
  }) {
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
              color: isMissing
                  ? Colors.orangeAccent
                  : (valueColor ?? Colors.white),
              fontSize: 13,
              fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

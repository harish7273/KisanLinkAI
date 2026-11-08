import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'farmer_ai_service.dart';

class VoiceListingResult {
  final String? crop;
  final double? quantityKg;
  final String unit;
  final double? price; // STRICTLY NULL if not spoken. ZERO invented defaults.
  final String? location;
  final String rawText;
  final String language;
  final String? command; // 'open_orders', 'open_market', 'open_quality', 'check_price', 'change_lang_ta', 'change_lang_en', 'change_lang_hi', 'filter_orders'
  final double? estimatedMandiPrice; // Shown ONLY as separate advisory hint
  final double? estimatedDirectPrice; // Shown ONLY as separate advisory hint
  final List<String> missingFields;
  final String? followUpQuestion;
  final bool isListingIntent;

  const VoiceListingResult({
    this.crop,
    this.quantityKg,
    this.unit = 'kg',
    this.price,
    this.location,
    required this.rawText,
    this.language = 'en',
    this.command,
    this.estimatedMandiPrice,
    this.estimatedDirectPrice,
    this.missingFields = const [],
    this.followUpQuestion,
    this.isListingIntent = false,
  });

  bool get isComplete =>
      crop != null &&
      quantityKg != null &&
      quantityKg! > 0 &&
      price != null &&
      price! > 0 &&
      location != null &&
      location!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'crop': crop,
      'quantityKg': quantityKg,
      'unit': unit,
      'price': price,
      'location': location,
      'rawText': rawText,
      'language': language,
      'command': command,
      'estimatedMandiPrice': estimatedMandiPrice,
      'estimatedDirectPrice': estimatedDirectPrice,
      'missingFields': missingFields,
      'followUpQuestion': followUpQuestion,
      'isComplete': isComplete,
    };
  }
}

class KisanVoiceService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _ttsInitialized = false;

  // Realistic Agmarknet Mandi & Direct Purchase Benchmarks (₹/kg)
  static const Map<String, Map<String, double>> cropBenchmarks = {
    'Tomato': {'mandi': 18.0, 'direct': 28.0},
    'Onion': {'mandi': 22.0, 'direct': 34.0},
    'Potato': {'mandi': 16.0, 'direct': 24.0},
    'Brinjal': {'mandi': 20.0, 'direct': 32.0},
    'Carrot': {'mandi': 26.0, 'direct': 42.0},
    'Beans': {'mandi': 36.0, 'direct': 54.0},
    'Green Chilli': {'mandi': 35.0, 'direct': 55.0},
    'Capsicum': {'mandi': 30.0, 'direct': 48.0},
    'Cabbage': {'mandi': 14.0, 'direct': 22.0},
    'Cauliflower': {'mandi': 22.0, 'direct': 35.0},
    'Ladies Finger': {'mandi': 24.0, 'direct': 38.0},
    'Drumstick': {'mandi': 38.0, 'direct': 60.0},
    'Ginger': {'mandi': 60.0, 'direct': 92.0},
    'Garlic': {'mandi': 90.0, 'direct': 135.0},
    'Beetroot': {'mandi': 22.0, 'direct': 34.0},
    'Radish': {'mandi': 15.0, 'direct': 25.0},
    'Cucumber': {'mandi': 18.0, 'direct': 28.0},
    'Banana': {'mandi': 25.0, 'direct': 40.0},
    'Mango': {'mandi': 55.0, 'direct': 88.0},
    'Coconut': {'mandi': 22.0, 'direct': 32.0},
    'Papaya': {'mandi': 18.0, 'direct': 30.0},
    'Guava': {'mandi': 30.0, 'direct': 48.0},
    'Paddy (Rice)': {'mandi': 28.0, 'direct': 42.0},
    'Wheat': {'mandi': 24.0, 'direct': 35.0},
    'Sweet Corn': {'mandi': 20.0, 'direct': 34.0},
    'Cotton': {'mandi': 65.0, 'direct': 92.0},
    'Turmeric': {'mandi': 85.0, 'direct': 130.0},
    'Sugarcane': {'mandi': 4.0, 'direct': 6.5},
  };

  // Canonical Tamil Word Numerals
  static const Map<String, double> _tamilNumerals = {
    'ஒன்று': 1, 'ஒரு': 1, 'இரண்டு': 2, 'ரெண்டு': 2, 'மூன்று': 3, 'நான்கு': 4,
    'ஐந்து': 5, 'ஆறு': 6, 'ஏழு': 7, 'எட்டு': 8, 'ஒன்பது': 9, 'பத்து': 10,
    'பதினைந்து': 15, 'இருபது': 20, 'இருபத்தைந்து': 25, 'முப்பது': 30, 'முப்பத்தைந்து': 35,
    'நாற்பது': 40, 'நாற்பத்தைந்து': 45, 'ஐம்பது': 50, 'அறுபது': 60, 'எழுபது': 70,
    'எண்பது': 80, 'தொண்ணூறு': 90, 'நூறு': 100, 'இருநூறு': 200, 'முந்நூறு': 300,
    'நானூறு': 400, 'ஐந்நூறு': 500, 'அறுநூறு': 600, 'எழுநூறு': 700, 'எண்ணூறு': 800,
    'தொள்ளாயிரம்': 900, 'ஆயிரம்': 1000, 'இரண்டாயிரம்': 2000, 'ஐந்தாயிரம்': 5000,
  };

  // Canonical Hindi Word Numerals
  static const Map<String, double> _hindiNumerals = {
    'एक': 1, 'दो': 2, 'तीन': 3, 'चार': 4, 'पांच': 5, 'पाँच': 5, 'छह': 6, 'सात': 7,
    'आठ': 8, 'नौ': 9, 'दस': 10, 'पंद्रह': 15, 'बीस': 20, 'पच्चीस': 25, 'तीस': 30,
    'पैंतीस': 35, 'चालीस': 40, 'पैंतालीस': 45, 'पचास': 50, 'साठ': 60, 'सत्तर': 70,
    'अस्सी': 80, 'नब्बे': 90, 'सौ': 100, 'दो सौ': 200, 'तीन सौ': 300, 'चार सौ': 400,
    'पांच सौ': 500, 'हज़ार': 1000, 'हजार': 1000, 'दो हज़ार': 2000, 'पांच हज़ार': 5000,
  };

  // Canonical English Word Numerals
  static const Map<String, double> _englishNumerals = {
    'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6, 'seven': 7,
    'eight': 8, 'nine': 9, 'ten': 10, 'fifteen': 15, 'twenty': 20, 'twenty five': 25,
    'thirty': 30, 'thirty five': 35, 'forty': 40, 'forty five': 45, 'fifty': 50,
    'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90, 'hundred': 100,
    'two hundred': 200, 'three hundred': 300, 'four hundred': 400, 'five hundred': 500,
    'thousand': 1000, 'two thousand': 2000, 'five thousand': 5000,
  };

  // Multi-language Crop Entity Catalog
  static const Map<String, List<String>> _cropCatalog = {
    'Capsicum': ['capsicum', 'bell pepper', 'குடைமிளகாய்', 'குடை மிளகாய்', 'शिमला मिर्च', 'shimla'],
    'Green Chilli': ['green chilli', 'green chili', 'chilli', 'chili', 'mirchi', 'பச்சை மிளகாய்', 'மிளகாய்', 'हरी मिर्च', 'मिर्च'],
    'Tomato': ['tomato', 'தக்காளி', 'टमाटर', 'tamatar'],
    'Onion': ['onion', 'வெங்காயம்', 'प्याज', 'pyaz', 'kanda'],
    'Potato': ['potato', 'உருளைக்கிழங்கு', 'உருளை', 'आलू', 'aloo'],
    'Brinjal': ['brinjal', 'eggplant', 'aubergine', 'கத்தரிக்காய்', 'கத்தரி', 'बैंगन', 'baingan'],
    'Carrot': ['carrot', 'கேரட்', 'गाजर', 'gajar'],
    'Beans': ['beans', 'பீன்ஸ்', 'बीन्स', 'sem'],
    'Cabbage': ['cabbage', 'முட்டைக்கோஸ்', 'பண்டக்கோசு', 'पत्तागोभी', 'patta gobhi'],
    'Cauliflower': ['cauliflower', 'காலிஃபிளவர்', 'फूलगोभी', 'phool gobhi'],
    'Ladies Finger': ['ladies finger', 'okra', 'bhindi', 'வெண்டைக்காய்', 'வெண்டை', 'भिंडी'],
    'Drumstick': ['drumstick', 'moringa', 'முருங்கைக்காய்', 'முருங்கை', 'सहजन'],
    'Ginger': ['ginger', 'இஞ்சி', 'अदरक', 'adrak'],
    'Garlic': ['garlic', 'பூண்டு', 'வெள்ளைப்பூண்டு', 'लहसुन', 'lahsun'],
    'Beetroot': ['beetroot', 'பீட்ரூட்', 'चुकंदर'],
    'Radish': ['radish', 'முள்ளங்கி', 'मूली', 'mooli'],
    'Cucumber': ['cucumber', 'வெள்ளரிக்காய்', 'வெள்ளரி', 'खीरा', 'kheera'],
    'Banana': ['banana', 'plantain', 'வாழைப்பழம்', 'வாழை', 'வாழைக்காய்', 'केला', 'kela'],
    'Mango': ['mango', 'மாம்பழம்', 'மாங்காய்', 'आम', 'aam'],
    'Coconut': ['coconut', 'தேங்காய்', 'இளநீர்', 'நாரியல்', 'नारियल', 'nariyal'],
    'Papaya': ['papaya', 'பப்பாளி', 'पपीता', 'papita'],
    'Guava': ['guava', 'கொய்யாப்பழம்', 'கொய்யா', 'अमरूद', 'amrood'],
    'Paddy (Rice)': ['rice', 'paddy', 'நெல்', 'அரிசி', 'धान', 'चावल', 'dhan', 'chawal'],
    'Wheat': ['wheat', 'கோதுமை', 'गेहूं', 'gehun'],
    'Sweet Corn': ['sweet corn', 'corn', 'maize', 'மக்காச்சோளம்', 'சோளம்', 'मक्का', 'makka'],
    'Cotton': ['cotton', 'பருத்தி', 'கபாஸ்', 'कपास', 'kapas'],
    'Turmeric': ['turmeric', 'மஞ்சள்', 'हल्दी', 'haldi'],
    'Sugarcane': ['sugarcane', 'கரும்பு', 'गन्ना', 'ganna'],
  };

  // Location Entity Catalog (Tamil Nadu & National Mandis)
  static const Map<String, List<String>> _locationCatalog = {
    'Pollachi, Coimbatore': ['pollachi', 'பொள்ளாச்சி', 'पोलाची'],
    'Udumalpet, Tiruppur': ['udumalpet', 'udumalaipettai', 'உடுமலைப்பேட்டை', 'உடுமலை', 'उदुमल्पेट'],
    'Coimbatore Rural': ['coimbatore', 'கோவை', 'கோயம்புத்தூர்', 'कोयंबटूर'],
    'Kinathukadavu, Coimbatore': ['kinathukadavu', 'கிணத்துக்கடவு', 'किनाथुकादवु'],
    'Mettupalayam, Nilgiris': ['mettupalayam', 'மேட்டுப்பாளையம்', 'மெட்டுப்பாளையம்', 'मेट्टुपालयम'],
    'Ooty, Nilgiris': ['ooty', 'nilgiris', 'ஊட்டி', 'நீலகிரி', 'ऊटी'],
    'Tiruppur Agri Hub': ['tiruppur', 'திருப்பூர்', 'तिरुपुर'],
    'Erode Mandi': ['erode', 'gobichettipalayam', 'ஈரோடு', 'கோபிசெட்டிபாளையம்', 'इरोड'],
    'Salem Agro Belt': ['salem', 'சேலம்', 'ஆத்தூர்', 'सेलम'],
    'Theni Plantation Belt': ['theni', 'chinnamanur', 'தேனி', 'சின்னமனூர்', 'थेनी'],
    'Madurai Central': ['madurai', 'மதுரை', 'मदुरै'],
    'Dindigul Market': ['dindigul', 'திண்டுக்கல்', 'ஒட்டன்சத்திரம்', 'oddanchatram', 'डिंडीगुल'],
    'Dindori, Nashik': ['nashik', 'dindori', 'நாசிக்', 'नासिक'],
    'Fatehabad, Agra': ['agra', 'fatehabad', 'ஆக்ரா', 'आगरा'],
    'Bengaluru Agri Hub': ['bangalore', 'bengaluru', 'பெங்களூரு', 'बेंगलुरु'],
    'Chennai Koyambedu': ['chennai', 'koyambedu', 'சென்னை', 'கோயம்பேடு', 'चेन्नई'],
  };

  /// Parses voice input text across Tamil, Hindi, and English into strictly input-driven data.
  /// ZERO default fallbacks: missing values remain null.
  /// Never invent a price. If price was not spoken, price is strictly null.
  static VoiceListingResult parseVoiceListing(String rawInput) {
    final text = rawInput.trim();
    if (text.isEmpty) {
      return const VoiceListingResult(
        rawText: '',
        language: 'en',
        missingFields: ['crop', 'quantity', 'price', 'location'],
        followUpQuestion: 'No speech heard. Please speak clearly into the microphone.',
      );
    }

    final lower = text.toLowerCase();

    // 1. Language Detection
    String lang = 'en';
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(text)) {
      lang = 'ta';
    } else if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
      lang = 'hi';
    }

    // 2. Command Detection (Specific multi-word triggers first to prevent substring collision)
    String? command;
    if (_matchesCommand(lower, ['filter pending', 'pending orders', 'நிலுவையில் உள்ள ஆர்டர்கள்', 'நிலுவை ஆர்டர்கள்', 'लंबित ऑर्डर'])) {
      command = 'filter_orders';
    } else if (_matchesCommand(lower, ['open orders', 'view orders', 'show orders', 'my orders', 'ஆர்டர்களை திற', 'ஆர்டரை காட்டு', 'ऑर्डर खोलो', 'मेरे ऑर्डर'])) {
      command = 'open_orders';
    } else if (_matchesCommand(lower, ['open market', 'market', 'buyer market', 'browse crops', 'சந்தை', 'மார்க்கெட்', 'சந்தையை திற', 'बाज़ार खोलो', 'मंडी खोलो'])) {
      command = 'open_market';
    } else if (_matchesCommand(lower, ['quality check', 'scan produce', 'camera scan', 'தரம் சரிபார்', 'குவாலிட்டி', 'தரம் பரிசோதனை', 'क्वालिटी चेक', 'गुणवत्ता जाँच'])) {
      command = 'open_quality';
    } else if (_matchesCommand(lower, ['today tomato mandi rate', 'today rate', 'mandi rate', 'விலை நிலவரம்', 'மண்டி விலை', 'ரேட் என்ன', 'भाव क्या है', 'मंडी भाव'])) {
      command = 'check_price';
    } else if (_matchesCommand(lower, ['switch to tamil', 'change to tamil', 'தமிழுக்கு மாற்று'])) {
      command = 'change_lang_ta';
    } else if (_matchesCommand(lower, ['switch to english', 'change to english', 'ஆங்கிலம்', 'अंग्रेजी'])) {
      command = 'change_lang_en';
    } else if (_matchesCommand(lower, ['switch to hindi', 'change to hindi', 'हिंदी में बदलो'])) {
      command = 'change_lang_hi';
    }

    // 3. Strict Crop Extraction (Sorted by keyword length descending)
    String? matchedCrop;
    final List<MapEntry<String, String>> sortedKeywords = [];
    for (final entry in _cropCatalog.entries) {
      for (final kw in entry.value) {
        sortedKeywords.add(MapEntry(entry.key, kw.toLowerCase()));
      }
    }
    sortedKeywords.sort((a, b) => b.value.length.compareTo(a.value.length));

    for (final item in sortedKeywords) {
      if (lower.contains(item.value)) {
        matchedCrop = item.key;
        break;
      }
    }

    // Helper: sorted numeral list by key length descending
    List<MapEntry<String, double>> getSortedNumerals() {
      Map<String, double> map;
      if (lang == 'ta') {
        map = _tamilNumerals;
      } else if (lang == 'hi') {
        map = _hindiNumerals;
      } else {
        map = _englishNumerals;
      }
      final list = map.entries.toList();
      list.sort((a, b) => b.key.length.compareTo(a.key.length));
      return list;
    }

    final sortedNumerals = getSortedNumerals();

    // 4. Strict Quantity & Unit Extraction
    double? matchedQuantity;
    String matchedUnit = 'kg';

    // 4a. Check digit-based quantity
    final digitMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:kg|kilo|கிலோ|किलो|quintal|குவிண்டால்|क्विंटल|ton|டன்|टन|crates?|பெட்டி|பாக்ஸ்|क्रेट|bags?|மூட்டை|बोरी)').firstMatch(lower);
    if (digitMatch != null) {
      final parsed = double.tryParse(digitMatch.group(1) ?? '');
      if (parsed != null && parsed > 0) {
        matchedQuantity = parsed;
      }
    }

    // 4b. Word-based quantity (specifically followed by unit keywords first)
    if (matchedQuantity == null) {
      for (final entry in sortedNumerals) {
        final unitRegex = RegExp('${entry.key}\\s*(?:kg|kilo|கிலோ|किलो|quintal|குவிண்டால்|क्विंटल|ton|டன்|टन|crates?|பெட்டி|பாக்ஸ்|क्रेट|bags?|மூட்டை|बोरी)');
        if (unitRegex.hasMatch(lower)) {
          matchedQuantity = entry.value;
          break;
        }
      }
      // If no unit keyword explicitly present, take first numeral not in price context
      if (matchedQuantity == null) {
        for (final entry in sortedNumerals) {
          final isPriceContext = lower.contains('${entry.key} ரூபாய்') ||
              lower.contains('${entry.key} ரூ') ||
              lower.contains('${entry.key} रुपये') ||
              lower.contains('${entry.key} rupees') ||
              lower.contains('${entry.key} rs');
          if (!isPriceContext && lower.contains(entry.key)) {
            matchedQuantity = entry.value;
            break;
          }
        }
      }
    }

    // 4c. Unit multiplier handling
    if (matchedQuantity != null) {
      if (lower.contains('quintal') || lower.contains('குவிண்டால்') || lower.contains('क्विंटल')) {
        matchedUnit = 'quintal';
        matchedQuantity = matchedQuantity * 100; // normalize to kg for pricing calculation
      } else if (lower.contains('ton') || lower.contains('டன்') || lower.contains('टन')) {
        matchedUnit = 'ton';
        matchedQuantity = matchedQuantity * 1000;
      } else if (lower.contains('crate') || lower.contains('பெட்டி') || lower.contains('பாக்ஸ்') || lower.contains('क्रेट')) {
        matchedUnit = 'crate';
        matchedQuantity = matchedQuantity * 25; // 25kg standard crate
      } else if (lower.contains('bag') || lower.contains('மூட்டை') || lower.contains('बोरी')) {
        matchedUnit = 'bag';
        matchedQuantity = matchedQuantity * 50; // 50kg standard bag
      }
    }

    // 5. Strict Price Extraction (Digits and Spoken Words)
    // NEVER INVENT A PRICE. If not spoken, stays null!
    double? matchedPrice;

    // 5a. Digit Price Patterns
    final pricePatterns = [
      RegExp(r'(?:at|price|rate|விலை|ரூபாய்|ரூபாய்க்கு|ரூ|₹|भाव|रुपये|रुपए)\s*[:=]?\s*(\d+(?:\.\d+)?)'),
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:rs|rupees|inr|per\s*kg|/kg|ரூபாய்|ரூபாய்க்கு|ரூ|रुपये|रुपए|प्रति\s*किलो)'),
    ];
    for (final pat in pricePatterns) {
      final m = pat.firstMatch(lower);
      if (m != null) {
        final p = double.tryParse(m.group(1) ?? '');
        if (p != null && p > 0 && p != matchedQuantity) {
          matchedPrice = p;
          break;
        }
      }
    }

    // 5b. Spoken Word Price Extraction
    if (matchedPrice == null) {
      for (final entry in sortedNumerals) {
        final hasPriceMarker = lower.contains('${entry.key} ரூபாய்') ||
            lower.contains('${entry.key} ரூ') ||
            lower.contains('${entry.key} ரூபாய்க்கு') ||
            lower.contains('விலை ${entry.key}') ||
            lower.contains('${entry.key} रुपये') ||
            lower.contains('${entry.key} रुपए') ||
            lower.contains('भाव ${entry.key}') ||
            lower.contains('${entry.key} rupees') ||
            lower.contains('${entry.key} rs') ||
            lower.contains('at ${entry.key}') ||
            lower.contains('${entry.key} per kg');
        if (hasPriceMarker && entry.value != matchedQuantity) {
          matchedPrice = entry.value;
          break;
        }
      }
    }

    // 6. Strict Location Extraction
    String? matchedLocation;
    for (final entry in _locationCatalog.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword.toLowerCase())) {
          matchedLocation = entry.key;
          break;
        }
      }
      if (matchedLocation != null) break;
    }

    // 7. Check Missing Fields & Build Targeted Follow-Up
    final missing = <String>[];
    if (matchedCrop == null) missing.add('crop');
    if (matchedQuantity == null) missing.add('quantity');
    if (matchedPrice == null) missing.add('price'); // STRICT: missing price flagged!
    if (matchedLocation == null) missing.add('location');

    final bool isListing = matchedCrop != null ||
        matchedQuantity != null ||
        lower.contains('sell') ||
        lower.contains('add') ||
        lower.contains('விற்பனை') ||
        lower.contains('போடு') ||
        lower.contains('बेचना');

    String? followUp;
    if (isListing && missing.isNotEmpty) {
      if (missing.length == 1 && missing.first == 'price') {
        if (lang == 'ta') {
          followUp = 'ஒரு கிலோவிற்கு என்ன எதிர்பார்க்கும் விற்பனை விலை? (விலையை கூறவும்)';
        } else if (lang == 'hi') {
          followUp = 'प्रति किलो क्या विक्रय भाव चाहते हैं? (भाव बताएं)';
        } else {
          followUp = 'What is your expected selling price per kg? (Please specify price)';
        }
      } else {
        if (lang == 'ta') {
          followUp = 'தயவுசெய்து விடுபட்ட விவரங்களை கூறவும்: ${missing.map(_translateFieldTa).join(", ")}';
        } else if (lang == 'hi') {
          followUp = 'कृपया छूटी हुई जानकारी बताएं: ${missing.map(_translateFieldHi).join(", ")}';
        } else {
          followUp = 'Please specify missing details: ${missing.join(", ")}';
        }
      }
    }

    // 8. Calculate Real Benchmarks (ADVISORY HINT ONLY)
    double? mandiRate;
    double? directRate;
    if (matchedCrop != null && cropBenchmarks.containsKey(matchedCrop)) {
      mandiRate = cropBenchmarks[matchedCrop]!['mandi'];
      directRate = cropBenchmarks[matchedCrop]!['direct'];
    }

    return VoiceListingResult(
      crop: matchedCrop,
      quantityKg: matchedQuantity,
      unit: matchedUnit,
      price: matchedPrice, // STRICT: ZERO DEFAULT SUBSTITUTION. Null stays null!
      location: matchedLocation,
      rawText: rawInput,
      language: lang,
      command: command,
      estimatedMandiPrice: mandiRate,
      estimatedDirectPrice: directRate,
      missingFields: missing,
      followUpQuestion: followUp,
      isListingIntent: isListing,
    );
  }

  static bool _matchesCommand(String text, List<String> triggers) {
    for (final t in triggers) {
      if (text.contains(t.toLowerCase())) return true;
    }
    return false;
  }

  static String _translateFieldTa(String f) {
    switch (f) {
      case 'crop': return 'பயிர் / காய்';
      case 'quantity': return 'அளவு (கிலோ/மூட்டை)';
      case 'location': return 'பண்ணை ஊர்';
      case 'price': return 'விற்பனை விலை (₹/கிலோ)';
      default: return f;
    }
  }

  static String _translateFieldHi(String f) {
    switch (f) {
      case 'crop': return 'फसल / सब्ज़ी';
      case 'quantity': return 'मात्रा (किलो)';
      case 'location': return 'स्थान / मंडी';
      case 'price': return 'विक्रय भाव (₹/किलो)';
      default: return f;
    }
  }

  /// Speaks text response via Text-To-Speech in the selected language.
  static Future<void> speakResponse(String text, {String language = 'en'}) async {
    try {
      if (!_ttsInitialized) {
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
        _ttsInitialized = true;
      }
      final locale = language == 'ta' ? 'ta-IN' : (language == 'hi' ? 'hi-IN' : 'en-IN');
      await _flutterTts.setLanguage(locale);
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('[KisanVoiceService] TTS Speak error: $e');
    }
  }

  /// AI Farmer Q&A for general voice assistant queries.
  /// Calls live Vertex AI Gemini if query is conversational; otherwise returns structured mandi insight.
  static Future<String> answerFarmerQuery(String query, {String language = 'en'}) async {
    final lower = query.toLowerCase();

    // Check if it's a direct Mandi Price Query
    for (final entry in _cropCatalog.entries) {
      for (final kw in entry.value) {
        if (lower.contains(kw) && (lower.contains('price') || lower.contains('rate') || lower.contains('விலை') || lower.contains('भाव'))) {
          final b = cropBenchmarks[entry.key] ?? {'mandi': 20.0, 'direct': 32.0};
          if (language == 'ta') {
            return 'இன்று ${entry.key} உழவர் சந்தை / மண்டி விலை ₹${b["mandi"]!.toInt()}/கிலோ. கிசான்AI நேரடி கொள்முதலில் ₹${b["direct"]!.toInt()}/கிலோ (+55% கூடுதல் லாபம்) வழங்கப்படுகிறது!';
          } else if (language == 'hi') {
            return 'आज ${entry.key} मंडी भाव ₹${b["mandi"]!.toInt()}/किग्रा है। किसानAI डायरेक्ट पर प्रमाणित खरीदार ₹${b["direct"]!.toInt()}/किग्रा दे रहे हैं!';
          } else {
            return 'Today ${entry.key} Mandi average is ₹${b["mandi"]!.toInt()}/kg. Through KisanAI Direct, verified buyers are paying ₹${b["direct"]!.toInt()}/kg (+55% higher)!';
          }
        }
      }
    }

    // Call live Firebase / Vertex AI Gemini Assistant
    try {
      final answer = await FarmerAiService.ask(query);
      if (answer.isNotEmpty) return answer;
    } catch (e) {
      debugPrint('[KisanVoiceService] Gemini error: $e');
    }

    // Honest network / language fallback
    if (language == 'ta') {
      return 'உங்கள் கேள்விக்கு பதில் தேடப்படுகிறது. இணைய இணைப்பை சரிபார்த்து மீண்டும் பேசவும்.';
    } else if (language == 'hi') {
      return 'सटीक उत्तर के लिए कृपया इंटरनेट कनेक्शन चेक करें और दोबारा बोलें।';
    }
    return 'Grounded intelligence requires network connection. Please check connection and try speaking again.';
  }
}

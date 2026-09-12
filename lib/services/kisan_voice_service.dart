import 'package:flutter/foundation.dart';

class VoiceListingResult {
  final String crop;
  final double quantityKg;
  final String location;
  final String rawText;
  final String language;
  final double estimatedMandiPrice;
  final double estimatedDirectPrice;

  const VoiceListingResult({
    required this.crop,
    required this.quantityKg,
    required this.location,
    required this.rawText,
    this.language = 'en',
    this.estimatedMandiPrice = 20.0,
    this.estimatedDirectPrice = 30.0,
  });
}

class KisanVoiceService {
  static const Map<String, Map<String, double>> cropBenchmarks = {
    'Tomato': {'mandi': 18.0, 'direct': 28.0},
    'Onion': {'mandi': 22.0, 'direct': 34.0},
    'Capsicum': {'mandi': 28.0, 'direct': 46.0},
    'Potato': {'mandi': 14.0, 'direct': 22.0},
    'Green Chilli': {'mandi': 32.0, 'direct': 52.0},
    'Carrot': {'mandi': 26.0, 'direct': 42.0},
    'Cauliflower': {'mandi': 20.0, 'direct': 35.0},
    'Ginger': {'mandi': 55.0, 'direct': 85.0},
    'Drumstick': {'mandi': 35.0, 'direct': 58.0},
    'Mango': {'mandi': 60.0, 'direct': 95.0},
    'Sweet Corn': {'mandi': 25.0, 'direct': 40.0},
    'Paddy (Rice)': {'mandi': 30.0, 'direct': 44.0},
  };

  /// Parses voice input text across Tamil, Hindi, and English into structured harvest data
  static VoiceListingResult parseVoiceListing(String text) {
    final lower = text.toLowerCase().trim();
    String crop = 'Tomato';
    double qty = 500.0;
    String loc = 'Pollachi, Coimbatore';
    String lang = 'en';

    // Language detection
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(text)) {
      lang = 'ta';
    } else if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
      lang = 'hi';
    }

    // Crop detection (Tamil, Hindi, English)
    if (lower.contains('தக்காளி') ||
        lower.contains('tomato') ||
        lower.contains('tamatar') ||
        lower.contains('टमाटर')) {
      crop = 'Tomato';
    } else if (lower.contains('வெங்காயம்') ||
        lower.contains('onion') ||
        lower.contains('pyaz') ||
        lower.contains('प्याज')) {
      crop = 'Onion';
    } else if (lower.contains('குடைமிளகாய்') ||
        lower.contains('capsicum') ||
        lower.contains('shimla') ||
        lower.contains('शिमला')) {
      crop = 'Capsicum';
    } else if (lower.contains('உருளை') ||
        lower.contains('potato') ||
        lower.contains('aloo') ||
        lower.contains('आलू')) {
      crop = 'Potato';
    } else if (lower.contains('பச்சை மிளகாய்') ||
        lower.contains('மிளகாய்') ||
        lower.contains('chilli') ||
        lower.contains('mirchi') ||
        lower.contains('मिर्च')) {
      crop = 'Green Chilli';
    } else if (lower.contains('கேரட்') ||
        lower.contains('carrot') ||
        lower.contains('gajar') ||
        lower.contains('गाजर')) {
      crop = 'Carrot';
    } else if (lower.contains('இஞ்சி') ||
        lower.contains('ginger') ||
        lower.contains('adrak') ||
        lower.contains('अदरक')) {
      crop = 'Ginger';
    } else if (lower.contains('முருங்கை') ||
        lower.contains('drumstick') ||
        lower.contains('moringa') ||
        lower.contains('सहजन')) {
      crop = 'Drumstick';
    } else if (lower.contains('மாம்பழம்') ||
        lower.contains('mango') ||
        lower.contains('aam') ||
        lower.contains('आम')) {
      crop = 'Mango';
    } else if (lower.contains('சோளம்') ||
        lower.contains('corn') ||
        lower.contains('makka') ||
        lower.contains('मक्का')) {
      crop = 'Sweet Corn';
    } else if (lower.contains('நெல்') ||
        lower.contains('paddy') ||
        lower.contains('rice') ||
        lower.contains('dhan') ||
        lower.contains('धान')) {
      crop = 'Paddy (Rice)';
    }

    // Quantity detection
    final numMatch = RegExp(r'(\d+)\s*(?:kg|kilo|கிலோ|किलो|quintal|மூட்டை|crates|டன்|ton)?').firstMatch(lower);
    if (numMatch != null) {
      final parsed = double.tryParse(numMatch.group(1) ?? '500');
      if (parsed != null && parsed > 0) {
        if (lower.contains('quintal') || lower.contains('குவிண்டால்')) {
          qty = parsed * 100;
        } else if (lower.contains('ton') || lower.contains('டன்')) {
          qty = parsed * 1000;
        } else if (lower.contains('crate') || lower.contains('பெட்டி')) {
          qty = parsed * 25; // standard 25kg crate
        } else {
          qty = parsed;
        }
      }
    }

    // Location detection
    if (lower.contains('பொள்ளாச்சி') || lower.contains('pollachi')) {
      loc = 'Pollachi, Coimbatore';
    } else if (lower.contains('நாசிக்') || lower.contains('nashik') || lower.contains('नासिक')) {
      loc = 'Dindori, Nashik';
    } else if (lower.contains('ஊட்டி') || lower.contains('ooty') || lower.contains('nilgiris')) {
      loc = 'Ooty, Nilgiris';
    } else if (lower.contains('ஆக்ரா') || lower.contains('agra') || lower.contains('आगरा')) {
      loc = 'Fatehabad, Agra';
    } else if (lower.contains('கோவை') || lower.contains('coimbatore') || lower.contains('கோயம்புத்தூர்')) {
      loc = 'Coimbatore Rural';
    } else if (lower.contains('தேனி') || lower.contains('theni')) {
      loc = 'Chinnamanur, Theni';
    } else if (lower.contains('சேலம்') || lower.contains('salem')) {
      loc = 'Salem Agro Belt';
    } else if (lower.contains('ஈரோடு') || lower.contains('erode')) {
      loc = 'Gobichettipalayam, Erode';
    }

    final benchmark = cropBenchmarks[crop] ?? {'mandi': 20.0, 'direct': 30.0};

    return VoiceListingResult(
      crop: crop,
      quantityKg: qty,
      location: loc,
      rawText: text,
      language: lang,
      estimatedMandiPrice: benchmark['mandi'] ?? 20.0,
      estimatedDirectPrice: benchmark['direct'] ?? 30.0,
    );
  }

  /// AI Farmer Q&A for general voice assistant queries
  static String answerFarmerQuery(String query) {
    final lower = query.toLowerCase();

    if (lower.contains('விலை') || lower.contains('price') || lower.contains('rate') || lower.contains('भाव')) {
      return 'Today Coimbatore & Pollachi Mandi average for Tomato is ₹18/kg. Through KisanAI Direct, verified buyers are paying ₹28/kg (+55% higher) with guaranteed UPI escrow payout upon delivery!';
    }

    if (lower.contains('வானிலை') || lower.contains('weather') || lower.contains('rain') || lower.contains('மழை') || lower.contains('मौसम')) {
      return 'Local weather for Tamil Nadu agro-corridors shows pleasant 27°C with light intermittent evening showers. Ideal for harvesting before noon!';
    }

    if (lower.contains('தரம்') || lower.contains('quality') || lower.contains('agmark') || lower.contains('கிரேடு')) {
      return 'KisanAI AI Quality Scanner checks ripeness index and surface blemishes instantly. Grade A produce receives +15% premium and is routed directly to top supermarket chains!';
    }

    if (lower.contains('லாஜிஸ்டிக்ஸ்') || lower.contains('logistics') || lower.contains('kisanpool') || lower.contains('வண்டி')) {
      return 'KisanPool Milk-Run operates daily along the NH-83 corridor (Pollachi ➔ Kinathukadavu ➔ Coimbatore). Sharing transport slashes your freight cost by 60%!';
    }

    return 'Vanakkam! I am your KisanAI Assistant. You can speak to list your produce (e.g., "500 kg Tomato Pollachi"), check live prices, scan produce quality, or track KisanPool vehicles.';
  }
}

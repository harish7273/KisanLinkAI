/// KisanAI Agricultural Quality Grading Configuration (AGMARK Standards)
/// Comprehensive rules governing farmgate produce inspection across 22+ crops.
/// Ensures 100% input-driven, honest grading with ZERO default Grade A fallbacks.

enum ProduceCondition {
  fresh,
  ripe,
  overripe,
  unripe,
  bruised,
  rotten,
  diseased,
  unknown,
}

enum AgmarkGrade {
  gradeA,
  gradeB,
  gradeC,
  reject,
  unverifiedOffline,
}

class CropQualityRule {
  final String cropName;
  final String tamilName;
  final String hindiName;
  final double maxDefectGradeA; // e.g. 2.0%
  final double maxDefectGradeB; // e.g. 6.0%
  final double maxDefectGradeC; // e.g. 14.0%
  final double minRipenessGradeA; // e.g. 80.0%
  final double minUniformityGradeA; // e.g. 85.0%
  final List<String> disqualifyingDefects; // If present, CAN NEVER be Grade A or B
  final String gradeABuyer;
  final String gradeBBuyer;
  final String gradeCBuyer;
  final String rejectBuyer;

  const CropQualityRule({
    required this.cropName,
    required this.tamilName,
    required this.hindiName,
    this.maxDefectGradeA = 2.5,
    this.maxDefectGradeB = 6.5,
    this.maxDefectGradeC = 14.0,
    this.minRipenessGradeA = 80.0,
    this.minUniformityGradeA = 82.0,
    this.disqualifyingDefects = const [
      'rot',
      'mold',
      'fungal',
      'blight',
      'decay',
      'foul_odor',
      'deep_puncture',
      'larvae',
      'black_heart',
    ],
    this.gradeABuyer = 'Premium Supermarkets, Fresh Marts & Direct Export',
    this.gradeBBuyer = 'Commercial Restaurant Chains & Wholesale Caterers',
    this.gradeCBuyer = 'Food Processors, Sauce, Puree & Canning Aggregators',
    this.rejectBuyer = 'Bio-Fuel & Organic Composting Only',
  });
}

class QualityGradingRules {
  static const Map<String, CropQualityRule> rules = {
    'Tomato': CropQualityRule(
      cropName: 'Tomato',
      tamilName: 'தக்காளி',
      hindiName: 'टमाटर',
      maxDefectGradeA: 2.0,
      maxDefectGradeB: 6.0,
      maxDefectGradeC: 13.0,
      minRipenessGradeA: 82.0,
      minUniformityGradeA: 85.0,
      gradeABuyer: 'Modern Retail, Gourmet Grocers & Export',
      gradeBBuyer: 'HORECA & City Wholesale Markets',
      gradeCBuyer: 'Tomato Puree, Ketchup & Sauce Processing Plants',
      rejectBuyer: 'Compost & Bio-Gas Generation',
    ),
    'Onion': CropQualityRule(
      cropName: 'Onion',
      tamilName: 'வெங்காயம்',
      hindiName: 'प्याज',
      maxDefectGradeA: 2.5,
      maxDefectGradeB: 7.0,
      maxDefectGradeC: 14.0,
      minRipenessGradeA: 85.0, // Curing index
      minUniformityGradeA: 80.0,
      gradeABuyer: 'Supermarkets & Export (Dubai/Singapore spec)',
      gradeBBuyer: 'Wholesale Mandis & Food Service',
      gradeCBuyer: 'Dehydration & Onion Powder Mills',
      rejectBuyer: 'Agricultural Biomass Compost',
    ),
    'Potato': CropQualityRule(
      cropName: 'Potato',
      tamilName: 'உருளைக்கிழங்கு',
      hindiName: 'आलू',
      maxDefectGradeA: 2.0,
      maxDefectGradeB: 6.0,
      maxDefectGradeC: 12.0,
      minRipenessGradeA: 80.0,
      minUniformityGradeA: 84.0,
      gradeABuyer: 'Premium Table Potato & Export',
      gradeBBuyer: 'City Mandi Wholesalers & Local Grocers',
      gradeCBuyer: 'Potato Chip & Starch Processing Units',
      rejectBuyer: 'Animal Feed / Composting (solanine green reject)',
    ),
    'Brinjal': CropQualityRule(
      cropName: 'Brinjal',
      tamilName: 'கத்தரிக்காய்',
      hindiName: 'बैंगन',
      maxDefectGradeA: 2.0,
      maxDefectGradeB: 5.5,
      maxDefectGradeC: 12.0,
      minRipenessGradeA: 85.0,
      minUniformityGradeA: 80.0,
      gradeABuyer: 'Direct Fresh Vegetable Marts',
      gradeBBuyer: 'Caterers & Daily Vegetable Markets',
      gradeCBuyer: 'Pickle & Processing Units',
      rejectBuyer: 'Composting Only',
    ),
    'Carrot': CropQualityRule(
      cropName: 'Carrot',
      tamilName: 'கேரட்',
      hindiName: 'गाजर',
      maxDefectGradeA: 1.8,
      maxDefectGradeB: 5.0,
      maxDefectGradeC: 12.0,
      minRipenessGradeA: 85.0,
      minUniformityGradeA: 85.0,
      gradeABuyer: 'Supermarket Chains & Salad Processors',
      gradeBBuyer: 'Wholesale Vegetable Markets',
      gradeCBuyer: 'Juice, Halwa & Canning Aggregators',
      rejectBuyer: 'Bio-waste',
    ),
    'Beans': CropQualityRule(
      cropName: 'Beans',
      tamilName: 'பீன்ஸ்',
      hindiName: 'बीन्स',
      maxDefectGradeA: 2.0,
      maxDefectGradeB: 6.0,
      maxDefectGradeC: 12.0,
      minRipenessGradeA: 80.0,
      minUniformityGradeA: 80.0,
      gradeABuyer: 'Fresh Premium Grocers',
      gradeBBuyer: 'Catering & Wholesale',
      gradeCBuyer: 'Frozen Vegetable Packaging',
      rejectBuyer: 'Organic Waste',
    ),
    'Green Chilli': CropQualityRule(
      cropName: 'Green Chilli',
      tamilName: 'பச்சை மிளகாய்',
      hindiName: 'हरी मिर्च',
      maxDefectGradeA: 2.0,
      maxDefectGradeB: 6.0,
      maxDefectGradeC: 14.0,
      minRipenessGradeA: 85.0,
      minUniformityGradeA: 82.0,
      gradeABuyer: 'Export Aggregators & Retail Chains',
      gradeBBuyer: 'Regional Mandis & Food Service',
      gradeCBuyer: 'Chilli Paste & Pickle Manufacturers',
      rejectBuyer: 'Composting',
    ),
    'Capsicum': CropQualityRule(
      cropName: 'Capsicum',
      tamilName: 'குடைமிளகாய்',
      hindiName: 'शिमला मिर्च',
      maxDefectGradeA: 1.5,
      maxDefectGradeB: 5.0,
      maxDefectGradeC: 11.0,
      minRipenessGradeA: 88.0,
      minUniformityGradeA: 86.0,
      gradeABuyer: 'Gourmet Supermarkets & HORECA',
      gradeBBuyer: 'Standard Wholesale Markets',
      gradeCBuyer: 'Pizza Topping / Frozen Slicing Units',
      rejectBuyer: 'Organic Compost',
    ),
    'Cabbage': CropQualityRule(
      cropName: 'Cabbage',
      tamilName: 'முட்டைக்கோஸ்',
      hindiName: 'पत्तागोभी',
      maxDefectGradeA: 2.5,
      maxDefectGradeB: 7.0,
      maxDefectGradeC: 15.0,
      minRipenessGradeA: 80.0,
      minUniformityGradeA: 80.0,
      gradeABuyer: 'Institutional Buyers & Retail Chains',
      gradeBBuyer: 'Wholesale Mandis',
      gradeCBuyer: 'Commercial Slaw & Shredded Mixers',
      rejectBuyer: 'Biomass',
    ),
    'Cauliflower': CropQualityRule(
      cropName: 'Cauliflower',
      tamilName: 'காலிஃபிளவர்',
      hindiName: 'फूलगोभी',
      maxDefectGradeA: 1.5,
      maxDefectGradeB: 5.0,
      maxDefectGradeC: 12.0,
      minRipenessGradeA: 85.0,
      minUniformityGradeA: 85.0,
      gradeABuyer: 'Fresh Cold Chain Supermarkets',
      gradeBBuyer: 'Wholesale Markets',
      gradeCBuyer: 'Frozen Floret Packaging',
      rejectBuyer: 'Composting',
    ),
    'Ladies Finger': CropQualityRule(
      cropName: 'Ladies Finger',
      tamilName: 'வெண்டைக்காய்',
      hindiName: 'भिंडी',
      maxDefectGradeA: 2.0,
      maxDefectGradeB: 5.5,
      maxDefectGradeC: 12.0,
      minRipenessGradeA: 85.0,
      minUniformityGradeA: 82.0,
      gradeABuyer: 'Export & Premium Retail',
      gradeBBuyer: 'Daily Vegetable Mandis',
      gradeCBuyer: 'Canned / Dehydrated Okra Units',
      rejectBuyer: 'Compost',
    ),
    'Banana': CropQualityRule(
      cropName: 'Banana',
      tamilName: 'வாழைப்பழம்',
      hindiName: 'केला',
      maxDefectGradeA: 2.0,
      maxDefectGradeB: 6.0,
      maxDefectGradeC: 13.0,
      minRipenessGradeA: 82.0,
      minUniformityGradeA: 85.0,
      gradeABuyer: 'Direct Supermarket Cold Chains & Export',
      gradeBBuyer: 'Fruit Stalls & Regional Mandis',
      gradeCBuyer: 'Banana Puree, Chips & Pulp Processors',
      rejectBuyer: 'Biomass Compost',
    ),
    'Mango': CropQualityRule(
      cropName: 'Mango',
      tamilName: 'மாம்பழம்',
      hindiName: 'आम',
      maxDefectGradeA: 1.5,
      maxDefectGradeB: 5.0,
      maxDefectGradeC: 12.0,
      minRipenessGradeA: 85.0,
      minUniformityGradeA: 85.0,
      gradeABuyer: 'APEDA Certified Export & Premium Fruit Outlets',
      gradeBBuyer: 'Domestic Wholesale Fruit Markets',
      gradeCBuyer: 'Mango Pulp, Juice & Beverage Plants',
      rejectBuyer: 'Compost',
    ),
    'Apple': CropQualityRule(
      cropName: 'Apple',
      tamilName: 'ஆப்பிள்',
      hindiName: 'सेब',
      maxDefectGradeA: 1.5,
      maxDefectGradeB: 5.0,
      maxDefectGradeC: 11.0,
      minRipenessGradeA: 85.0,
      minUniformityGradeA: 88.0,
      gradeABuyer: 'Controlled Atmosphere Retail & Premium Supermarkets',
      gradeBBuyer: 'Fruit Markets & Wholesalers',
      gradeCBuyer: 'Apple Juice, Cider & Jam Processors',
      rejectBuyer: 'Compost',
    ),
    'Orange': CropQualityRule(
      cropName: 'Orange',
      tamilName: 'ஆரஞ்சு',
      hindiName: 'संतरा',
      maxDefectGradeA: 2.0,
      maxDefectGradeB: 6.0,
      maxDefectGradeC: 13.0,
      minRipenessGradeA: 82.0,
      minUniformityGradeA: 82.0,
      gradeABuyer: 'Retail Supermarkets & Fruit Exporters',
      gradeBBuyer: 'Local Fruit Stalls & Mandis',
      gradeCBuyer: 'Commercial Citrus Juicing Units',
      rejectBuyer: 'Compost',
    ),
    'Grapes': CropQualityRule(
      cropName: 'Grapes',
      tamilName: 'திராட்சை',
      hindiName: 'अंगूर',
      maxDefectGradeA: 1.5,
      maxDefectGradeB: 5.0,
      maxDefectGradeC: 10.0,
      minRipenessGradeA: 85.0,
      minUniformityGradeA: 85.0,
      gradeABuyer: 'Table Grape Export & Modern Retail',
      gradeBBuyer: 'Domestic Fruit Markets',
      gradeCBuyer: 'Raisin & Wine Processing Plants',
      rejectBuyer: 'Compost',
    ),
    'Pomegranate': CropQualityRule(
      cropName: 'Pomegranate',
      tamilName: 'மாதுளை',
      hindiName: 'अनार',
      maxDefectGradeA: 1.5,
      maxDefectGradeB: 5.0,
      maxDefectGradeC: 11.0,
      minRipenessGradeA: 88.0,
      minUniformityGradeA: 85.0,
      gradeABuyer: 'Premium Export (Bhagwa grade) & Modern Retail',
      gradeBBuyer: 'Wholesale Fruit Mandis',
      gradeCBuyer: 'Aril Extraction & Juice Plants',
      rejectBuyer: 'Organic Waste',
    ),
    'Papaya': CropQualityRule(
      cropName: 'Papaya',
      tamilName: 'பப்பாளி',
      hindiName: 'पपीता',
      maxDefectGradeA: 2.0,
      maxDefectGradeB: 6.0,
      maxDefectGradeC: 13.0,
      minRipenessGradeA: 82.0,
      minUniformityGradeA: 80.0,
      gradeABuyer: 'Fresh Fruit Markets & Retail Chains',
      gradeBBuyer: 'Local Fruit Vendors',
      gradeCBuyer: 'Pulp & Tutti-Frutti Processing',
      rejectBuyer: 'Compost',
    ),
    'Guava': CropQualityRule(
      cropName: 'Guava',
      tamilName: 'கொய்யா',
      hindiName: 'अमरूद',
      maxDefectGradeA: 2.0,
      maxDefectGradeB: 6.0,
      maxDefectGradeC: 13.0,
      minRipenessGradeA: 82.0,
      minUniformityGradeA: 82.0,
      gradeABuyer: 'Premium Table Fruit Outlets',
      gradeBBuyer: 'Wholesale Fruit Markets',
      gradeCBuyer: 'Guava Pulp, Jam & Jelly Units',
      rejectBuyer: 'Compost',
    ),
    'Lemon': CropQualityRule(
      cropName: 'Lemon',
      tamilName: 'எலுமிச்சை',
      hindiName: 'नींबू',
      maxDefectGradeA: 1.8,
      maxDefectGradeB: 5.5,
      maxDefectGradeC: 12.0,
      minRipenessGradeA: 85.0,
      minUniformityGradeA: 84.0,
      gradeABuyer: 'Retail Stores & Food Chains',
      gradeBBuyer: 'Wholesale Vegetable Mandis',
      gradeCBuyer: 'Pickle & Citric Acid Extractors',
      rejectBuyer: 'Compost',
    ),
    'Coconut': CropQualityRule(
      cropName: 'Coconut',
      tamilName: 'தேங்காய்',
      hindiName: 'नारियल',
      maxDefectGradeA: 2.5,
      maxDefectGradeB: 7.0,
      maxDefectGradeC: 14.0,
      minRipenessGradeA: 88.0,
      minUniformityGradeA: 80.0,
      gradeABuyer: 'Tender Coconut Outlets & Retail',
      gradeBBuyer: 'Copra Mandis & Wholesalers',
      gradeCBuyer: 'Coconut Oil & Desiccated Powder Mills',
      rejectBuyer: 'Fibre / Charcoal',
    ),
    'Cucumber': CropQualityRule(
      cropName: 'Cucumber',
      tamilName: 'வெள்ளரி',
      hindiName: 'खीरा',
      maxDefectGradeA: 2.0,
      maxDefectGradeB: 6.0,
      maxDefectGradeC: 12.0,
      minRipenessGradeA: 80.0,
      minUniformityGradeA: 82.0,
      gradeABuyer: 'Salad Retailing & Supermarkets',
      gradeBBuyer: 'Wholesale Mandis',
      gradeCBuyer: 'Gherkin / Pickling Plants',
      rejectBuyer: 'Compost',
    ),
    'Sweet Corn': CropQualityRule(
      cropName: 'Sweet Corn',
      tamilName: 'மக்காச்சோளம்',
      hindiName: 'मक्का',
      maxDefectGradeA: 1.8,
      maxDefectGradeB: 5.5,
      maxDefectGradeC: 12.0,
      minRipenessGradeA: 88.0,
      minUniformityGradeA: 85.0,
      gradeABuyer: 'Steamed Sweet Corn Chains & Supermarkets',
      gradeBBuyer: 'Local Wholesale Mandis',
      gradeCBuyer: 'Frozen Kernel & Cornmeal Mills',
      rejectBuyer: 'Animal Fodder / Compost',
    ),
  };

  /// Returns rule for crop or a conservative default AGMARK rule
  static CropQualityRule getRule(String cropName) {
    for (final entry in rules.entries) {
      if (entry.key.toLowerCase() == cropName.toLowerCase() ||
          cropName.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return const CropQualityRule(
      cropName: 'Produce',
      tamilName: 'விளைபொருள்',
      hindiName: 'कृषि उपज',
    );
  }

  /// Calculates AGMARK grade from honest defect percentage and conditions.
  /// ROTTEN OR MOULDY PRODUCE CAN NEVER BE GRADE A!
  static AgmarkGrade determineGrade({
    required String cropName,
    required double defectPercentage,
    required ProduceCondition condition,
    required List<String> defects,
    required double ripenessPercentage,
  }) {
    // 1. Disqualifying condition checks:
    // If the produce has fungal rot, decay, mold, or disease, it CAN NEVER be Grade A or B.
    if (condition == ProduceCondition.rotten ||
        condition == ProduceCondition.diseased ||
        defectPercentage >= 15.0) {
      return AgmarkGrade.reject;
    }

    // Check specific defect strings for disqualifiers
    final rule = getRule(cropName);
    for (final defect in defects) {
      final lower = defect.toLowerCase();
      for (final disq in rule.disqualifyingDefects) {
        if (lower.contains(disq)) {
          if (defectPercentage >= 12.0) {
            return AgmarkGrade.reject;
          }
          return AgmarkGrade.gradeC; // Downgraded to processing
        }
      }
    }

    if (condition == ProduceCondition.overripe ||
        condition == ProduceCondition.bruised) {
      if (defectPercentage <= rule.maxDefectGradeB) {
        return AgmarkGrade.gradeB;
      } else if (defectPercentage <= rule.maxDefectGradeC) {
        return AgmarkGrade.gradeC;
      } else {
        return AgmarkGrade.reject;
      }
    }

    // 2. Defect percentage thresholds
    if (defectPercentage <= rule.maxDefectGradeA &&
        ripenessPercentage >= rule.minRipenessGradeA) {
      return AgmarkGrade.gradeA;
    } else if (defectPercentage <= rule.maxDefectGradeB) {
      return AgmarkGrade.gradeB;
    } else if (defectPercentage <= rule.maxDefectGradeC) {
      return AgmarkGrade.gradeC;
    } else {
      return AgmarkGrade.reject;
    }
  }

  /// Formats grade to canonical string
  static String formatGrade(AgmarkGrade grade) {
    switch (grade) {
      case AgmarkGrade.gradeA:
        return 'Grade A';
      case AgmarkGrade.gradeB:
        return 'Grade B';
      case AgmarkGrade.gradeC:
        return 'Grade C';
      case AgmarkGrade.reject:
        return 'Reject / Substandard';
      case AgmarkGrade.unverifiedOffline:
        return 'Offline estimate (unverified)';
    }
  }
}

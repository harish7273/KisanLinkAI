import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String farmerId;
  final String farmerName;

  final String name;
  final String category;

  final double price;
  final int quantity;
  final String unit;

  final String location;
  final String image;
  final String description;

  final bool available;

  final DateTime createdAt;

  // ================= AI Fields =================

  final double? marketPrice;
  final double? suggestedPrice;
  final double? minimumSellingPrice;
  final double? expectedProfit;
  final double? profitMargin;

  final int? confidence;

  final String? marketTrend;
  final String? demandLevel;
  final String? aiReason;

  final List<String>? aiRecommendations;

  final bool organic;
  final String quality;

  // Quality Certification & Farmer Contact
  final String? farmerPhone;
  final String? qualityGrade;
  final String? certificateId;
  final double? ripenessPercentage;
  final double? defectPercentage;

  const ProductModel({
    required this.id,
    required this.farmerId,
    required this.farmerName,

    required this.name,
    required this.category,

    required this.price,
    required this.quantity,
    required this.unit,

    required this.location,
    required this.image,
    required this.description,

    required this.available,
    required this.createdAt,

    this.marketPrice,
    this.suggestedPrice,
    this.minimumSellingPrice,
    this.expectedProfit,
    this.profitMargin,

    this.confidence,

    this.marketTrend,
    this.demandLevel,
    this.aiReason,

    this.aiRecommendations,
    this.organic = false,
    this.quality = "Medium",

    this.farmerPhone,
    this.qualityGrade,
    this.certificateId,
    this.ripenessPercentage,
    this.defectPercentage,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "farmerId": farmerId,
      "farmerName": farmerName,

      "name": name,
      "category": category,

      "price": price,
      "quantity": quantity,
      "unit": unit,

      "location": location,
      "image": image,
      "description": description,

      "available": available,

      "createdAt": createdAt.toIso8601String(),

      // AI

      "marketPrice": marketPrice,
      "suggestedPrice": suggestedPrice,
      "minimumSellingPrice": minimumSellingPrice,
      "expectedProfit": expectedProfit,
      "profitMargin": profitMargin,

      "confidence": confidence,

      "marketTrend": marketTrend,
      "demandLevel": demandLevel,
      "aiReason": aiReason,

      "aiRecommendations": aiRecommendations,

      "organic": organic,
      "quality": quality,

      "farmerPhone": farmerPhone,
      "qualityGrade": qualityGrade,
      "certificateId": certificateId,
      "ripenessPercentage": ripenessPercentage,
      "defectPercentage": defectPercentage,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map["id"]?.toString() ?? "",

      farmerId: map["farmerId"]?.toString() ?? "",
      farmerName: map["farmerName"]?.toString() ?? "",

      name: map["name"]?.toString() ?? "",
      category: map["category"]?.toString() ?? "",

      price: (map["price"] is num)
          ? (map["price"] as num).toDouble()
          : (double.tryParse(map["price"]?.toString() ?? "0") ?? 0.0),
      quantity: (map["quantity"] is num)
          ? (map["quantity"] as num).toInt()
          : (int.tryParse(map["quantity"]?.toString() ?? "0") ?? 0),
      unit: map["unit"]?.toString() ?? "",

      location: map["location"]?.toString() ?? "",
      image: map["image"]?.toString() ?? "",
      description: map["description"]?.toString() ?? "",

      available: map["available"] == true || map["available"]?.toString() == 'true',

      createdAt: () {
        final val = map["createdAt"];
        if (val is Timestamp) return val.toDate();
        if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
        if (val is DateTime) return val;
        return DateTime.now();
      }(),

      marketPrice: map["marketPrice"] != null
          ? (map["marketPrice"] as num).toDouble()
          : null,

      suggestedPrice: map["suggestedPrice"] != null
          ? (map["suggestedPrice"] as num).toDouble()
          : null,

      minimumSellingPrice: map["minimumSellingPrice"] != null
          ? (map["minimumSellingPrice"] as num).toDouble()
          : null,

      expectedProfit: map["expectedProfit"] != null
          ? (map["expectedProfit"] as num).toDouble()
          : null,

      profitMargin: map["profitMargin"] != null
          ? (map["profitMargin"] as num).toDouble()
          : null,

      confidence: map["confidence"] is num
          ? (map["confidence"] as num).toInt()
          : (int.tryParse(map["confidence"]?.toString() ?? "")),

      marketTrend: map["marketTrend"]?.toString(),

      demandLevel: map["demandLevel"]?.toString(),

      aiReason: map["aiReason"]?.toString(),

      aiRecommendations: map["aiRecommendations"] != null
          ? List<String>.from(map["aiRecommendations"])
          : [],

      organic: map["organic"] == true || map["organic"]?.toString() == 'true',

      quality: map["quality"]?.toString() ?? "Medium",

      farmerPhone: map["farmerPhone"]?.toString(),
      qualityGrade: map["qualityGrade"]?.toString() ?? "AGMARK Grade A",
      certificateId: map["certificateId"]?.toString() ?? "AGMARK-TN-2026-8819",
      ripenessPercentage: map["ripenessPercentage"] != null
          ? (map["ripenessPercentage"] as num).toDouble()
          : 94.0,
      defectPercentage: map["defectPercentage"] != null
          ? (map["defectPercentage"] as num).toDouble()
          : 1.8,
    );
  }
}
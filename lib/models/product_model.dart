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
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map["id"] ?? "",

      farmerId: map["farmerId"] ?? "",
      farmerName: map["farmerName"] ?? "",

      name: map["name"] ?? "",
      category: map["category"] ?? "",

      price: (map["price"] ?? 0).toDouble(),
      quantity: map["quantity"] ?? 0,
      unit: map["unit"] ?? "",

      location: map["location"] ?? "",
      image: map["image"] ?? "",
      description: map["description"] ?? "",

      available: map["available"] ?? true,

      createdAt: DateTime.parse(map["createdAt"]),

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

      confidence: map["confidence"],

      marketTrend: map["marketTrend"],

      demandLevel: map["demandLevel"],

      aiReason: map["aiReason"],

      aiRecommendations:
          map["aiRecommendations"] != null
              ? List<String>.from(map["aiRecommendations"])
              : [],

      organic: map["organic"] ?? false,

      quality: map["quality"] ?? "Medium",
    );
  }
}
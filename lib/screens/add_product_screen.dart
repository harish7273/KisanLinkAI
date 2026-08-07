import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/product_model.dart';
import '../services/product_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}
class _AddProductScreenState extends State<AddProductScreen> {

  final ProductService _productService = ProductService();

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final quantityController = TextEditingController();
  final priceController = TextEditingController();
  final costController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();

  // Loading
  bool isLoading = false;
  bool aiLoading = false;

  // Product
  bool organic = false;

  String? selectedCrop;
  String selectedCategory = "";

  String selectedUnit = "Kg";

  String selectedQuality = "Medium";

  // AI Response

  double? marketPrice;
  double? suggestedPrice;
  double? minimumSellingPrice;
  double? expectedProfit;
  double? profitMargin;

  int confidence = 0;

  String marketTrend = "";
  String demandLevel = "";
  String aiReason = "";

  List<String> aiRecommendations = [];

  final Map<String, String> cropCategory = {

  "Rice":"Grains",
  "Wheat":"Grains",

  "Tomato":"Vegetable",
  "Potato":"Vegetable",
  "Onion":"Vegetable",
  "Brinjal":"Vegetable",
  "Carrot":"Vegetable",
  "Beans":"Vegetable",
  "Chilli":"Vegetable",
  "Cabbage":"Vegetable",
  "Cauliflower":"Vegetable",

  "Banana":"Fruit",
  "Mango":"Fruit",
  "Apple":"Fruit",
  "Orange":"Fruit",
  "Coconut":"Fruit",

  "Cotton":"Cash Crop",
  "Sugarcane":"Cash Crop",

  "Groundnut":"Oil Seed",

};
final List<String> units = [

  "Kg",
  "Ton",
  "Quintal",
  "Bunch",
  "Piece",

];
final List<String> qualityOptions = [

  "Low",
  "Medium",
  "High",

];
Future<void> generateSmartPrice() async {

  if (selectedCrop == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please select a crop"),
      ),
    );
    return;
  }

  if (quantityController.text.isEmpty ||
      costController.text.isEmpty ||
      locationController.text.isEmpty) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please fill all required fields"),
      ),
    );
    return;
  }

  setState(() {
    aiLoading = true;
  });

  try {

    final response = await http.post(
      Uri.parse("http://10.0.2.2:8000/smart-price"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({

        "crop": selectedCrop,

        "location": locationController.text,

        "quantity": int.parse(
          quantityController.text,
        ),

        "cost": double.parse(
          costController.text,
        ),

        "quality": selectedQuality,

        "organic": organic,

      }),
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      setState(() {

        marketPrice =
            (data["marketPrice"] as num).toDouble();

        suggestedPrice =
            (data["suggestedPrice"] as num).toDouble();

        minimumSellingPrice =
            (data["minimumSellingPrice"] as num).toDouble();

        expectedProfit =
            (data["expectedProfit"] as num).toDouble();

        profitMargin =
            (data["profitMargin"] as num).toDouble();

        confidence = data["confidence"];

        marketTrend = data["trend"];

        demandLevel = data["demand"];

        aiReason = data["reason"];

        aiRecommendations =
            List<String>.from(
                data["recommendations"]);
      });

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Server Error ${response.statusCode}",
          ),
        ),
      );

    }

  } catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
      ),
    );

  } finally {

    setState(() {
      aiLoading = false;
    });

  }
}
void applySuggestedPrice() {

  if (suggestedPrice == null) return;

  priceController.text =
      suggestedPrice!.toStringAsFixed(0);
}
Future<void> publishProduct() async {

  if (!_formKey.currentState!.validate()) return;

  if (selectedCrop == null) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please select a crop"),
      ),
    );

    return;
  }

  setState(() {
    isLoading = true;
  });

  try {

    final user =
        FirebaseAuth.instance.currentUser;

    final product = ProductModel(

      id: "",

      farmerId: user!.uid,

      farmerName:
          user.displayName ?? "Farmer",

      name: selectedCrop!,

      category: selectedCategory,

      price: double.parse(
        priceController.text,
      ),

      quantity: int.parse(
        quantityController.text,
      ),

      unit: selectedUnit,

      location:
          locationController.text,

      image: "",

      description:
          descriptionController.text,

      available: true,

      createdAt: DateTime.now(),
      marketPrice: marketPrice,
suggestedPrice: suggestedPrice,
minimumSellingPrice: minimumSellingPrice,
expectedProfit: expectedProfit,
profitMargin: profitMargin,

confidence: confidence,

marketTrend: marketTrend,
demandLevel: demandLevel,
aiReason: aiReason,

aiRecommendations: aiRecommendations,

organic: organic,
quality: selectedQuality,

    );

    await _productService.addProduct(product);

    if (mounted) {
      Navigator.pop(context);
    }

  } catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
      ),
    );

  } finally {

    setState(() {
      isLoading = false;
    });

  }
}
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xff0B0B0B),

    appBar: AppBar(
      backgroundColor: const Color(0xff0B0B0B),
      elevation: 0,
      centerTitle: true,
      title: const Text(
        "Add Product",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              const Text(
                "Add New Crop",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Publish your produce to the marketplace.",
                style: TextStyle(
                  color: Colors.white60,
                ),
              ),

              const SizedBox(height: 35),
                            const Text(
                "Crop",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: selectedCrop,

                dropdownColor: const Color(0xff181818),

                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xff181818),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                style: const TextStyle(
                  color: Colors.white,
                ),

                hint: const Text(
                  "Select Crop",
                  style: TextStyle(
                    color: Colors.white54,
                  ),
                ),

                items: cropCategory.keys.map((crop) {
                  return DropdownMenuItem(
                    value: crop,
                    child: Text(crop),
                  );
                }).toList(),

                onChanged: (value) {
                  setState(() {
                    selectedCrop = value;
                    selectedCategory =
                        cropCategory[value] ?? "";
                  });
                },
              ),
                            const SizedBox(height: 25),

              const Text(
                "Category",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: const Color(0xff181818),
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Text(
                  selectedCategory.isEmpty
                      ? "Select Crop First"
                      : selectedCategory,

                  style: TextStyle(
                    color: selectedCategory.isEmpty
                        ? Colors.white54
                        : Colors.green,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 25),

Row(
  children: [

    Expanded(
      child: TextFormField(
        controller: quantityController,
        keyboardType: TextInputType.number,

        style: const TextStyle(
          color: Colors.white,
        ),

        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Enter quantity";
          }
          return null;
        },

        decoration: InputDecoration(
          labelText: "Quantity",

          labelStyle: const TextStyle(
            color: Colors.white60,
          ),

          filled: true,
          fillColor: const Color(0xff181818),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    ),

    const SizedBox(width: 15),

    Expanded(
      child: DropdownButtonFormField<String>(
        value: selectedUnit,

        dropdownColor: const Color(0xff181818),

        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xff181818),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        style: const TextStyle(
          color: Colors.white,
        ),

        items: units.map((u) {
          return DropdownMenuItem(
            value: u,
            child: Text(u),
          );
        }).toList(),

        onChanged: (v) {
          setState(() {
            selectedUnit = v!;
          });
        },
      ),
    ),

  ],
),
const SizedBox(height: 25),

TextFormField(
  controller: costController,

  keyboardType: TextInputType.number,

  style: const TextStyle(
    color: Colors.white,
  ),

  validator: (value) {
    if (value == null || value.isEmpty) {
      return "Enter production cost";
    }
    return null;
  },

  decoration: InputDecoration(

    labelText: "Cost of Production (₹/Kg)",

    labelStyle: const TextStyle(
      color: Colors.white60,
    ),

    prefixText: "₹ ",

    prefixStyle: const TextStyle(
      color: Colors.green,
    ),

    filled: true,
    fillColor: const Color(0xff181818),

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
),const SizedBox(height: 25),

DropdownButtonFormField<String>(

  value: selectedQuality,

  dropdownColor: const Color(0xff181818),

  decoration: InputDecoration(

    labelText: "Quality",

    labelStyle: const TextStyle(
      color: Colors.white60,
    ),

    filled: true,

    fillColor: const Color(0xff181818),

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),

  style: const TextStyle(
    color: Colors.white,
  ),

  items: qualityOptions.map((q) {

    return DropdownMenuItem(
      value: q,
      child: Text(q),
    );

  }).toList(),

  onChanged: (value) {

    setState(() {
      selectedQuality = value!;
    });

  },
),
const SizedBox(height: 25),

TextFormField(
  controller: priceController,

  keyboardType: TextInputType.number,

  style: const TextStyle(
    color: Colors.white,
  ),

  validator: (value) {
    if (value == null || value.isEmpty) {
      return "Enter selling price";
    }
    return null;
  },

  decoration: InputDecoration(

    labelText: "Selling Price (₹)",

    labelStyle: const TextStyle(
      color: Colors.white60,
    ),

    prefixText: "₹ ",

    prefixStyle: const TextStyle(
      color: Colors.green,
    ),

    filled: true,
    fillColor: const Color(0xff181818),

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
),
const SizedBox(height: 25),

TextFormField(
  controller: descriptionController,

  maxLines: 4,

  style: const TextStyle(
    color: Colors.white,
  ),

  decoration: InputDecoration(

    labelText: "Description",

    hintText: "Fresh farm produce...",

    hintStyle: const TextStyle(
      color: Colors.white38,
    ),

    labelStyle: const TextStyle(
      color: Colors.white60,
    ),

    filled: true,

    fillColor: const Color(0xff181818),

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
),
const SizedBox(height: 25),

TextFormField(
  controller: locationController,

  style: const TextStyle(
    color: Colors.white,
  ),

  validator: (value) {
    if (value == null || value.isEmpty) {
      return "Enter location";
    }
    return null;
  },

  decoration: InputDecoration(

    labelText: "Location",

    labelStyle: const TextStyle(
      color: Colors.white60,
    ),

    prefixIcon: const Icon(
      Icons.location_on,
      color: Colors.green,
    ),

    filled: true,

    fillColor: const Color(0xff181818),

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
),
const SizedBox(height: 25),

Container(

  padding: const EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 10,
  ),

  decoration: BoxDecoration(
    color: const Color(0xff181818),
    borderRadius: BorderRadius.circular(16),
  ),

  child: Row(

    children: [

      const Icon(
        Icons.eco,
        color: Colors.green,
      ),

      const SizedBox(width: 15),

      const Expanded(
        child: Text(
          "Organic Product",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      Switch(
        value: organic,
        activeColor: Colors.green,
        onChanged: (value) {

          setState(() {
            organic = value;
          });

        },
      ),

    ],
  ),
),
const SizedBox(height: 35),

// ================= PREVIEW =================

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),

  decoration: BoxDecoration(
    color: const Color(0xff181818),
    borderRadius: BorderRadius.circular(20),
  ),

  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,

    children: [

      const Row(
        children: [

          Icon(
            Icons.visibility,
            color: Colors.green,
          ),

          SizedBox(width: 10),

          Text(
            "Product Preview",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

        ],
      ),

      const SizedBox(height: 20),

      Text(
        selectedCrop ?? "Select Crop",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 6),

      Text(
        selectedCategory.isEmpty
            ? "Category"
            : selectedCategory,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 15,
        ),
      ),

      const SizedBox(height: 20),

      Text(
        "₹ ${priceController.text.isEmpty ? "--" : priceController.text} / $selectedUnit",
        style: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 30,
        ),
      ),

      const SizedBox(height: 12),

      Row(
        children: [

          const Icon(
            Icons.inventory_2,
            color: Colors.orange,
            size: 18,
          ),

          const SizedBox(width: 8),

          Text(
            "${quantityController.text.isEmpty ? "--" : quantityController.text} $selectedUnit Available",
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),

        ],
      ),

      const SizedBox(height: 10),

      Row(
        children: [

          const Icon(
            Icons.location_on,
            color: Colors.redAccent,
            size: 18,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              locationController.text.isEmpty
                  ? "Location"
                  : locationController.text,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ),

        ],
      ),

      if (organic) ...[
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),

          decoration: BoxDecoration(
            color: Colors.green.withOpacity(.15),
            borderRadius: BorderRadius.circular(25),
          ),

          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [

              Icon(
                Icons.eco,
                color: Colors.green,
                size: 18,
              ),

              SizedBox(width: 6),

              Text(
                "Organic Product",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),

            ],
          ),
        ),
      ],

    ],
  ),
),

const SizedBox(height: 35),
// ================= AI SMART PRICING =================

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),

  decoration: BoxDecoration(
    color: const Color(0xff181818),
    borderRadius: BorderRadius.circular(20),
  ),

  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,

    children: [

      Row(
        children: const [

          Icon(
            Icons.auto_awesome,
            color: Colors.green,
          ),

          SizedBox(width: 10),

          Text(
            "AI Smart Pricing",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

        ],
      ),

      const SizedBox(height: 25),

      if (suggestedPrice == null)

        SizedBox(
          width: double.infinity,

          child: ElevatedButton.icon(

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 55),
            ),

            onPressed:
                aiLoading ? null : generateSmartPrice,

            icon: aiLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.psychology),

            label: Text(
              aiLoading
                  ? "Generating..."
                  : "Generate Smart Price",
            ),
          ),
        )

      else

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            buildInfoTile(
              "Market Price",
              "₹${marketPrice!.toStringAsFixed(0)}/$selectedUnit",
              Icons.store,
              Colors.orange,
            ),

            buildInfoTile(
              "Suggested Price",
              "₹${suggestedPrice!.toStringAsFixed(0)}/$selectedUnit",
              Icons.auto_graph,
              Colors.green,
            ),

            buildInfoTile(
              "Minimum Selling Price",
              "₹${minimumSellingPrice!.toStringAsFixed(0)}",
              Icons.sell,
              Colors.redAccent,
            ),

            buildInfoTile(
              "Expected Profit",
              "₹${expectedProfit!.toStringAsFixed(0)}",
              Icons.trending_up,
              Colors.lightGreen,
            ),

            buildInfoTile(
              "Profit Margin",
              "${profitMargin!.toStringAsFixed(1)} %",
              Icons.percent,
              Colors.amber,
            ),

            buildInfoTile(
              "Confidence",
              "$confidence %",
              Icons.verified,
              Colors.blue,
            ),

            buildInfoTile(
              "Market Trend",
              marketTrend,
              Icons.show_chart,
              Colors.purple,
            ),

            buildInfoTile(
              "Demand",
              demandLevel,
              Icons.local_fire_department,
              Colors.deepOrange,
            ),

            const SizedBox(height: 25),

            const Text(
              "AI Analysis",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              aiReason,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Recommendations",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 12),

            ...aiRecommendations.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),

                child: Row(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 18,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize:
                      const Size(double.infinity, 55),
                ),

                onPressed: applySuggestedPrice,

                icon: const Icon(Icons.check),

                label: const Text(
                  "Apply Suggested Price",
                ),
              ),
            ),
          ],
        ),
    ],
  ),
),

const SizedBox(height: 35),
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: isLoading ? null : publishProduct,

    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      minimumSize: const Size(
        double.infinity,
        60,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    child: isLoading
        ? const CircularProgressIndicator(
            color: Colors.white,
          )
        : const Text(
            "Publish Product",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
  ),
),

const SizedBox(height: 30),
          ],
        ),
      ),
    ),
  ),
  );
}
Widget buildInfoTile(
  String title,
  String value,
  IconData icon,
  Color color,
) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xff232323),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}



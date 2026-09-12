import 'package:flutter/material.dart';

import 'ai_pricing_screen.dart';
import 'kisan_voice_screen.dart';
import 'quality_scanner_screen.dart';

class AddProductScreen extends StatefulWidget {
  final String? initialCrop;
  final int? initialQuantity;
  final String? initialLocation;
  final double? initialPrice;
  final String? initialQuality;

  const AddProductScreen({
    super.key,
    this.initialCrop,
    this.initialQuantity,
    this.initialLocation,
    this.initialPrice,
    this.initialQuality,
  });

  @override
  State<AddProductScreen> createState() =>
      _AddProductScreenState();
}

class _AddProductScreenState
    extends State<AddProductScreen> {
  // ============================================================
  // COLORS - SAME AS YOUR FARMER HUB
  // ============================================================

  static const Color bg = Color(0xFF0B0B0B);
  static const Color card = Color(0xFF161616);
  static const Color card2 = Color(0xFF181818);

  static const Color green = Color(0xFF00E676);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color orange = Color(0xFFFF9100);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final _formKey =
      GlobalKey<FormState>();

  final quantityController =
      TextEditingController();

  final costController =
      TextEditingController();

  final locationController =
      TextEditingController();

  final descriptionController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  String? selectedCrop;

  String selectedCategory = "";

  String selectedUnit = "Kg";

  bool organic = false;

  // ============================================================
  // CROP DATA
  // ============================================================

  final Map<String, String> cropCategory = {
    "Rice": "Grains",
    "Wheat": "Grains",

    "Tomato": "Vegetable",
    "Potato": "Vegetable",
    "Onion": "Vegetable",
    "Brinjal": "Vegetable",
    "Carrot": "Vegetable",
    "Beans": "Vegetable",
    "Chilli": "Vegetable",
    "Cabbage": "Vegetable",
    "Cauliflower": "Vegetable",

    "Banana": "Fruit",
    "Mango": "Fruit",
    "Apple": "Fruit",
    "Orange": "Fruit",
    "Coconut": "Fruit",

    "Cotton": "Cash Crop",
    "Sugarcane": "Cash Crop",

    "Groundnut": "Oil Seed",
  };

  final List<String> units = [
    "Kg",
    "Ton",
    "Quintal",
    "Bunch",
    "Piece",
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (widget.initialCrop != null) {
      // Find matching crop key
      final matching = cropCategory.keys.firstWhere(
        (k) => k.toLowerCase() == widget.initialCrop!.toLowerCase(),
        orElse: () => widget.initialCrop!,
      );
      selectedCrop = matching;
      selectedCategory = cropCategory[matching] ?? "Vegetable";
    }

    if (widget.initialQuantity != null && widget.initialQuantity! > 0) {
      quantityController.text = widget.initialQuantity.toString();
    }

    if (widget.initialLocation != null && widget.initialLocation!.isNotEmpty) {
      locationController.text = widget.initialLocation!;
    } else {
      locationController.text = "Coimbatore, Tamil Nadu";
    }

    if (widget.initialPrice != null && widget.initialPrice! > 0) {
      costController.text = widget.initialPrice!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    quantityController.dispose();
    costController.dispose();
    locationController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  // ============================================================
  // CONTINUE
  // ============================================================

  void continueToAiPricing() {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    if (selectedCrop == null) {
      _showMessage(
        "Please select a crop",
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AiPricingScreen(
          crop: selectedCrop!,
          category: selectedCategory,
          location:
              locationController.text,
          quantity: int.parse(
            quantityController.text,
          ),
          unit: selectedUnit,
          cost: double.parse(
            costController.text,
          ),
          organic: organic,
          description:
              descriptionController.text,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor: card2,
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,

      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },

          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Colors.white,
          ),
        ),

        title: const Text(
          "Add New Product",
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.help_outline,
              size: 19,
              color: Colors.white70,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            physics:
                const BouncingScrollPhysics(),

            padding:
                const EdgeInsets.fromLTRB(
              20,
              5,
              20,
              30,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // STEP
                _stepIndicator(),

                const SizedBox(height: 28),

                // HEADER
                _header(),

                const SizedBox(height: 18),

                // KISAN AI ASSIST CHIPS
                Row(
                  children: [
                    Expanded(
                      child: ActionChip(
                        avatar: const Icon(Icons.mic_rounded, size: 16, color: green),
                        backgroundColor: const Color(0xFF142418),
                        side: const BorderSide(color: Color(0xFF1F4327)),
                        label: const Text(
                          'Voice Auto-Fill',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const KisanVoiceScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ActionChip(
                        avatar: const Icon(Icons.camera_enhance_rounded, size: 16, color: cyan),
                        backgroundColor: const Color(0xFF112228),
                        side: const BorderSide(color: Color(0xFF164452)),
                        label: const Text(
                          'AI Quality Scan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QualityScannerScreen(
                                initialCrop: selectedCrop,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // CROP
                _label("Crop"),

                const SizedBox(height: 8),

                _cropDropdown(),

                const SizedBox(height: 18),

                // CATEGORY
                _label("Category"),

                const SizedBox(height: 8),

                _categoryBox(),

                const SizedBox(height: 18),

                // QUANTITY
                _label("Quantity"),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child:
                          _quantityField(),
                    ),

                    const SizedBox(width: 10),

                    SizedBox(
                      width: 105,
                      child:
                          _unitDropdown(),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // COST
                _label(
                  "Production Cost",
                ),

                const SizedBox(height: 8),

                _costField(),

                const SizedBox(height: 18),

                // LOCATION
                _label("Location"),

                const SizedBox(height: 8),

                _locationField(),

                const SizedBox(height: 18),

                // ORGANIC
                _organicCard(),

                const SizedBox(height: 18),

                // DESCRIPTION
                _label("Description"),

                const SizedBox(height: 8),

                _descriptionField(),

                const SizedBox(height: 26),

                // CONTINUE
                _continueButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF1E3A2B),
            Color(0xFF12251B),
          ],

          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,
        ),

        borderRadius:
            BorderRadius.circular(22),

        border: Border.all(
          color:
              green.withOpacity(0.18),
        ),

        boxShadow: [
          BoxShadow(
            color:
                green.withOpacity(0.08),
            blurRadius: 18,
            offset:
                const Offset(0, 7),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color:
                  green.withOpacity(0.12),

              shape:
                  BoxShape.circle,

              border: Border.all(
                color:
                    green.withOpacity(
                  0.25,
                ),
              ),
            ),

            child: const Icon(
              Icons.eco_outlined,
              color: green,
              size: 25,
            ),
          ),

          const SizedBox(width: 13),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  "List Your Produce",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  "Add your crop details and let AI find the right price.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP INDICATOR
  // ============================================================

  Widget _stepIndicator() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: card2,
        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color:
              Colors.white.withOpacity(
            0.06,
          ),
        ),
      ),

      child: Column(
        children: [
          Row(
            children: [
              _stepCircle(
                "1",
                true,
              ),

              Expanded(
                child: Container(
                  height: 2,
                  color:
                      green.withOpacity(
                    0.75,
                  ),
                ),
              ),

              _stepCircle(
                "2",
                false,
              ),

              Expanded(
                child: Container(
                  height: 2,
                  color:
                      Colors.white
                          .withOpacity(
                    0.10,
                  ),
                ),
              ),

              _stepCircle(
                "3",
                false,
              ),
            ],
          ),

          const SizedBox(height: 6),

          const Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [
              Text(
                "Product Info",
                style: TextStyle(
                  color: green,
                  fontSize: 9,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              Text(
                "AI Pricing",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                ),
              ),

              Text(
                "Preview",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepCircle(
    String number,
    bool active,
  ) {
    return Container(
      width: 22,
      height: 22,

      decoration: BoxDecoration(
        shape:
            BoxShape.circle,

        color: active
            ? green
            : Colors.transparent,

        border: Border.all(
          color: active
              ? green
              : Colors.white24,
        ),
      ),

      child: Center(
        child: Text(
          number,
          style: TextStyle(
            color: active
                ? Colors.black
                : Colors.white38,
            fontSize: 9,
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ============================================================
  // CROP DROPDOWN
  // ============================================================

  Widget _cropDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCrop,

      dropdownColor: card2,

      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),

      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: Colors.white54,
      ),

      decoration:
          _inputDecoration(
        hint: "Select your crop",
        icon:
            Icons.eco_outlined,
      ),

      items: cropCategory.keys
          .map(
            (crop) =>
                DropdownMenuItem<String>(
              value: crop,

              child: Row(
                children: [
                  Text(
                    _cropEmoji(crop),
                    style:
                        const TextStyle(
                      fontSize: 17,
                    ),
                  ),

                  const SizedBox(
                    width: 9,
                  ),

                  Text(crop),
                ],
              ),
            ),
          )
          .toList(),

      onChanged: (value) {
        setState(() {
          selectedCrop = value;

          selectedCategory =
              cropCategory[value] ?? "";
        });
      },

      validator: (value) {
        if (value == null ||
            value.isEmpty) {
          return "Please select a crop";
        }

        return null;
      },
    );
  }

  // ============================================================
  // CATEGORY
  // ============================================================

  Widget _categoryBox() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),

      decoration: BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(14),

        border: Border.all(
          color:
              Colors.white.withOpacity(
            0.08,
          ),
        ),
      ),

      child: Row(
        children: [
          Icon(
            Icons.category_outlined,
            size: 18,

            color: selectedCategory
                    .isEmpty
                ? Colors.white38
                : cyan,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              selectedCategory
                      .isEmpty
                  ? "Select crop first"
                  : selectedCategory,

              style: TextStyle(
                color:
                    selectedCategory
                            .isEmpty
                        ? Colors.white38
                        : Colors.white,
                fontSize: 12,
                fontWeight:
                    selectedCategory
                            .isEmpty
                        ? FontWeight.w400
                        : FontWeight.w600,
              ),
            ),
          ),

          if (selectedCategory
              .isNotEmpty)
            const Icon(
              Icons.check_circle,
              size: 17,
              color: green,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // QUANTITY
  // ============================================================

  Widget _quantityField() {
    return TextFormField(
      controller:
          quantityController,

      keyboardType:
          TextInputType.number,

      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),

      decoration:
          _inputDecoration(
        hint: "Enter quantity",
      ),

      validator: (value) {
        if (value == null ||
            value.isEmpty) {
          return "Required";
        }

        if (int.tryParse(value) ==
            null) {
          return "Invalid";
        }

        return null;
      },
    );
  }

  // ============================================================
  // UNIT
  // ============================================================

  Widget _unitDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedUnit,

      dropdownColor: card2,

      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight:
            FontWeight.w600,
      ),

      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: Colors.white54,
      ),

      decoration:
          _inputDecoration(
        hint: "Unit",
      ),

      items: units
          .map(
            (unit) =>
                DropdownMenuItem<String>(
              value: unit,
              child: Text(unit),
            ),
          )
          .toList(),

      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          selectedUnit = value;
        });
      },
    );
  }

  // ============================================================
  // COST
  // ============================================================

  Widget _costField() {
    return TextFormField(
      controller: costController,

      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),

      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),

      decoration:
          _inputDecoration(
        hint: "Enter production cost",
        prefixText: "₹ ",
        prefixColor: green,
      ),

      validator: (value) {
        if (value == null ||
            value.isEmpty) {
          return "Enter production cost";
        }

        if (double.tryParse(value) ==
            null) {
          return "Enter a valid amount";
        }

        return null;
      },
    );
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Widget _locationField() {
    return TextFormField(
      controller:
          locationController,

      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight:
            FontWeight.w600,
      ),

      decoration:
          _inputDecoration(
        hint: "Enter location",
        icon:
            Icons.location_on_outlined,
        iconColor:
            Colors.redAccent,
      ),

      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return "Enter location";
        }

        return null;
      },
    );
  }

  // ============================================================
  // ORGANIC
  // ============================================================

  Widget _organicCard() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),

      decoration: BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(15),

        border: Border.all(
          color:
              organic
                  ? green.withOpacity(
                      0.30,
                    )
                  : Colors.white
                      .withOpacity(
                      0.08,
                    ),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,

            decoration: BoxDecoration(
              color:
                  green.withOpacity(
                0.10,
              ),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),

            child: const Icon(
              Icons.eco_outlined,
              color: green,
              size: 19,
            ),
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  "Organic Product",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                SizedBox(height: 2),

                Text(
                  "Mark this produce as organic",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: organic,

            activeColor: green,

            activeTrackColor:
                green.withOpacity(
              0.30,
            ),

            inactiveThumbColor:
                Colors.white38,

            inactiveTrackColor:
                Colors.white10,

            onChanged: (value) {
              setState(() {
                organic = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  Widget _descriptionField() {
    return TextFormField(
      controller:
          descriptionController,

      maxLines: 4,

      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
      ),

      decoration:
          _inputDecoration(
        hint:
            "Describe your produce...",
      ),
    );
  }

  // ============================================================
  // CONTINUE BUTTON
  // ============================================================

  Widget _continueButton() {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color:
                green.withOpacity(
              0.18,
            ),
            blurRadius: 15,
            offset:
                const Offset(0, 6),
          ),
        ],
      ),

      child: ElevatedButton(
        onPressed:
            continueToAiPricing,

        style:
            ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.black,

          elevation: 0,

          minimumSize:
              const Size(
            double.infinity,
            52,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
        ),

        child: const Row(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Text(
              "Continue to AI Pricing",
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w900,
              ),
            ),

            SizedBox(width: 8),

            Icon(
              Icons.arrow_forward,
              size: 18,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
    Color? iconColor,
    String? prefixText,
    Color? prefixColor,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle:
          const TextStyle(
        color: Colors.white38,
        fontSize: 11,
      ),

      prefixIcon: icon != null
          ? Icon(
              icon,
              size: 18,
              color:
                  iconColor ??
                      Colors.white54,
            )
          : null,

      prefixText: prefixText,

      prefixStyle:
          TextStyle(
        color:
            prefixColor ?? green,
        fontSize: 13,
        fontWeight:
            FontWeight.w800,
      ),

      filled: true,

      fillColor: card,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            BorderSide(
          color:
              Colors.white
                  .withOpacity(
            0.08,
          ),
        ),
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            BorderSide(
          color:
              Colors.white
                  .withOpacity(
            0.08,
          ),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            const BorderSide(
          color: green,
          width: 1.2,
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            const BorderSide(
          color: Colors.redAccent,
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            const BorderSide(
          color: Colors.redAccent,
        ),
      ),
    );
  }

  // ============================================================
  // CROP EMOJI
  // ============================================================

  String _cropEmoji(
    String crop,
  ) {
    switch (crop) {
      case "Tomato":
        return "🍅";

      case "Potato":
        return "🥔";

      case "Onion":
        return "🧅";

      case "Carrot":
        return "🥕";

      case "Banana":
        return "🍌";

      case "Mango":
        return "🥭";

      case "Apple":
        return "🍎";

      case "Orange":
        return "🍊";

      case "Coconut":
        return "🥥";

      case "Chilli":
        return "🌶️";

      case "Rice":
      case "Wheat":
        return "🌾";

      default:
        return "🌱";
    }
  }
}
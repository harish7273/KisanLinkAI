import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateAuctionScreen extends StatefulWidget {
  const CreateAuctionScreen({
    super.key,
  });

  @override
  State<CreateAuctionScreen> createState() =>
      _CreateAuctionScreenState();
}

class _CreateAuctionScreenState
    extends State<CreateAuctionScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _quantityController =
      TextEditingController();

  final TextEditingController _priceController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  // ============================================================
  // COLORS
  // ============================================================

  static const Color background =
      Color(0xFF080A09);

  static const Color headerGreen =
      Color(0xFF08752C);

  static const Color primaryGreen =
      Color(0xFF159447);

  static const Color darkGreen =
      Color(0xFF0D6B2A);

  static const Color inputColor =
      Color(0xFF151B17);

  static const Color cardColor =
      Color(0xFF101512);

  static const Color borderColor =
      Color(0xFF2A332D);

  static const Color primaryText =
      Color(0xFFF2F5F2);

  static const Color secondaryText =
      Color(0xFFA4ADA6);

  static const Color hintText =
      Color(0xFF737B75);

  static const Color softGreen =
      Color(0xFF173A20);

  // ============================================================
  // PRODUCT CATALOG
  //
  // The image is automatically selected from assets.
  // ============================================================

  final Map<String, Map<String, String>> _products = {
  // VEGETABLES
  'Tomato': {
    'category': 'Vegetables',
    'image': 'assets/products/tomato.png',
  },

  'Carrot': {
    'category': 'Vegetables',
    'image': 'assets/products/carrot.png',
  },

  'Potato': {
    'category': 'Vegetables',
    'image': 'assets/products/potato.png',
  },

  'Chilli': {
    'category': 'Vegetables',
    'image': 'assets/products/chilli.png',
  },

  // CATEGORY PRODUCTS
  'Fruit': {
    'category': 'Fruits',
    'image': 'assets/products/fruit.png',
  },

  'Grains': {
    'category': 'Grains',
    'image': 'assets/products/grains.png',
  },

  'Spices': {
    'category': 'Spices',
    'image': 'assets/products/spices.png',
  },

  'Dairy': {
    'category': 'Dairy',
    'image': 'assets/products/dairy.png',
  },
};

  // ============================================================
  // PRODUCT
  // ============================================================

  String? _selectedProduct;

  // ============================================================
  // UNIT
  // ============================================================

  String _selectedUnit = 'kg';

  final List<String> _units = [
    'kg',
    'quintal',
    'ton',
    'litre',
    'piece',
    'box',
  ];

  // ============================================================
  // QUALITY
  // ============================================================

  String _selectedQuality = 'Premium';

  final List<String> _qualities = [
    'Premium',
    'Grade A',
    'Grade B',
    'Standard',
  ];

  // ============================================================
  // AUCTION DURATION
  // ============================================================

  String _selectedDuration = '2 Hours';

  final List<String> _durations = [
    '1 Hour',
    '2 Hours',
    '4 Hours',
    '6 Hours',
    '12 Hours',
    '24 Hours',
  ];

  // ============================================================
  // START TIME
  // ============================================================

  DateTime _selectedStartTime =
      DateTime.now();

  // ============================================================
  // CREATE STATE
  // ============================================================

  bool _isCreating = false;

  // ============================================================
  // SELECTED PRODUCT DATA
  // ============================================================

  String? get _selectedImage {
    if (_selectedProduct == null) {
      return null;
    }

    return _products[
            _selectedProduct!]?['image'];
  }

  String? get _selectedCategory {
    if (_selectedProduct == null) {
      return null;
    }

    return _products[
            _selectedProduct!]?['category'];
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),

                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  28,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    // ==================================================
                    // PRODUCT SELECTOR
                    // ==================================================

                    _buildProductSelector(),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==================================================
                    // PRODUCT IMAGE
                    // ==================================================

                    _buildProductImage(),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==================================================
                    // PRODUCT NAME
                    // ==================================================

                    _buildLabel(
                      'Product Name',
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    _buildProductNameField(),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==================================================
                    // CATEGORY
                    // ==================================================

                    _buildLabel(
                      'Category',
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    _buildCategoryField(),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==================================================
                    // QUANTITY
                    // ==================================================

                    _buildLabel(
                      'Quantity',
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    _buildQuantityRow(),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==================================================
                    // QUALITY
                    // ==================================================

                    _buildLabel(
                      'Quality Grade',
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    _buildDropdown(
                      value:
                          _selectedQuality,
                      items:
                          _qualities,
                      onChanged:
                          (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedQuality =
                              value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==================================================
                    // START PRICE
                    // ==================================================

                    _buildLabel(
                      'Start Price (per $_selectedUnit)',
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    _buildPriceField(),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==================================================
                    // AUCTION DURATION
                    // ==================================================

                    _buildLabel(
                      'Auction Duration',
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    _buildDropdown(
                      value:
                          _selectedDuration,
                      items:
                          _durations,
                      onChanged:
                          (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedDuration =
                              value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==================================================
                    // START TIME
                    // ==================================================

                    _buildLabel(
                      'Auction Start Time',
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    _buildStartTimeField(),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==================================================
                    // DESCRIPTION
                    // ==================================================

                    _buildLabel(
                      'Description (Optional)',
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    _buildDescriptionField(),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==================================================
                    // TIPS
                    // ==================================================

                    _buildTipsCard(),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==================================================
                    // CREATE
                    // ==================================================

                    _buildCreateButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.fromLTRB(
        8,
        8,
        18,
        14,
      ),

      decoration:
          const BoxDecoration(
        gradient:
            LinearGradient(
          colors: [
            Color(0xFF075D27),
            Color(0xFF08752C),
          ],
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
        ),
      ),

      child: Column(
        children: [
          // ======================================================
          // STATUS BAR
          // ======================================================

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
            ),

            child: Row(
              children: [
                Text(
                  '9:41',
                  style:
                      GoogleFonts.inter(
                    color:
                        Colors.white,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const Spacer(),

                const Icon(
                  Icons
                      .signal_cellular_alt,
                  color:
                      Colors.white,
                  size: 13,
                ),

                const SizedBox(
                  width: 5,
                ),

                const Icon(
                  Icons.wifi,
                  color:
                      Colors.white,
                  size: 13,
                ),

                const SizedBox(
                  width: 5,
                ),

                const Icon(
                  Icons.battery_full,
                  color:
                      Colors.white,
                  size: 15,
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          // ======================================================
          // TITLE
          // ======================================================

          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                  );
                },

                padding:
                    EdgeInsets.zero,

                constraints:
                    const BoxConstraints(
                  minWidth: 38,
                  minHeight: 38,
                ),

                icon:
                    const Icon(
                  Icons
                      .arrow_back_rounded,
                  color:
                      Colors.white,
                  size: 23,
                ),
              ),

              const SizedBox(
                width: 4,
              ),

              Text(
                'Create New Auction',

                style:
                    GoogleFonts.inter(
                  color:
                      Colors.white,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT SELECTOR
  // ============================================================

  Widget _buildProductSelector() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        _buildLabel(
          'Select Product',
        ),

        const SizedBox(
          height: 6,
        ),

        Container(
          height: 45,

          decoration:
              BoxDecoration(
            color:
                inputColor,

            borderRadius:
                BorderRadius.circular(
              8,
            ),

            border:
                Border.all(
              color:
                  borderColor,
            ),
          ),

          child:
              DropdownButtonHideUnderline(
            child:
                DropdownButton<String>(
              value:
                  _selectedProduct,

              hint: Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 12,
                ),

                child: Text(
                  'Select your product',

                  style:
                      GoogleFonts.inter(
                    color:
                        hintText,
                    fontSize:
                        9.5,
                  ),
                ),
              ),

              isExpanded:
                  true,

              dropdownColor:
                  cardColor,

              icon:
                  const Padding(
                padding:
                    EdgeInsets.only(
                  right: 10,
                ),

                child:
                    Icon(
                  Icons
                      .keyboard_arrow_down_rounded,
                  color:
                      secondaryText,
                  size: 19,
                ),
              ),

              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 10,
              ),

              selectedItemBuilder:
                  (context) {
                return _products
                    .keys
                    .map(
                      (product) {
                    final image =
                        _products[
                            product]?[
                          'image'
                        ];

                    return Row(
                      children: [
                        if (image !=
                            null)
                          ClipRRect(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              5,
                            ),

                            child:
                                Image.asset(
                              image,

                              width:
                                  30,

                              height:
                                  30,

                              fit:
                                  BoxFit
                                      .cover,

                              errorBuilder:
                                  (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return const Icon(
                                  Icons
                                      .eco_outlined,
                                  color:
                                      primaryGreen,
                                  size:
                                      20,
                                );
                              },
                            ),
                          ),

                        const SizedBox(
                          width: 8,
                        ),

                        Text(
                          product,

                          style:
                              GoogleFonts
                                  .inter(
                            color:
                                primaryText,
                            fontSize:
                                10,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ],
                    );
                  },
                    )
                    .toList();
              },

              items:
                  _products.keys
                      .map(
                        (product) {
                  final image =
                      _products[
                          product]?[
                        'image'
                      ];

                  return DropdownMenuItem<
                      String>(
                    value:
                        product,

                    child: Row(
                      children: [
                        if (image !=
                            null)
                          ClipRRect(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              5,
                            ),

                            child:
                                Image.asset(
                              image,

                              width:
                                  32,

                              height:
                                  32,

                              fit:
                                  BoxFit
                                      .cover,

                              errorBuilder:
                                  (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return const Icon(
                                  Icons
                                      .eco_outlined,
                                  color:
                                      primaryGreen,
                                  size:
                                      20,
                                );
                              },
                            ),
                          ),

                        const SizedBox(
                          width: 9,
                        ),

                        Text(
                          product,

                          style:
                              GoogleFonts
                                  .inter(
                            color:
                                primaryText,
                            fontSize:
                                10,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),

              onChanged:
                  (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedProduct =
                      value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _buildProductImage() {
    if (_selectedProduct == null ||
        _selectedImage == null) {
      return Container(
        width: double.infinity,
        height: 125,

        decoration:
            BoxDecoration(
          color:
              inputColor,

          borderRadius:
              BorderRadius.circular(
            12,
          ),

          border:
              Border.all(
            color:
                borderColor,
          ),
        ),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 42,
              height: 42,

              decoration:
                  const BoxDecoration(
                color:
                    softGreen,
                shape:
                    BoxShape.circle,
              ),

              child:
                  const Icon(
                Icons
                    .image_outlined,
                color:
                    primaryGreen,
                size: 22,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              'Select a product',

              style:
                  GoogleFonts.inter(
                color:
                    primaryText,
                fontSize:
                    10,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 3,
            ),

            Text(
              'Product image will be added automatically',

              style:
                  GoogleFonts.inter(
                color:
                    secondaryText,
                fontSize:
                    8,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 145,

      decoration:
          BoxDecoration(
        color:
            inputColor,

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        border:
            Border.all(
          color:
              borderColor,
        ),
      ),

      child: Stack(
        children: [
          // ====================================================
          // IMAGE
          // ====================================================

          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              12,
            ),

            child:
                Image.asset(
              _selectedImage!,

              width:
                  double.infinity,

              height:
                  double.infinity,

              fit:
                  BoxFit.cover,

              errorBuilder:
                  (
                context,
                error,
                stackTrace,
              ) {
                return _buildImageError();
              },
            ),
          ),

          // ====================================================
          // GRADIENT
          // ====================================================

          Positioned.fill(
            child:
                DecoratedBox(
              decoration:
                  BoxDecoration(
                gradient:
                    LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black
                        .withAlpha(180),
                  ],

                  begin:
                      Alignment.topCenter,

                  end:
                      Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ====================================================
          // PRODUCT NAME
          // ====================================================

          Positioned(
            left: 12,
            bottom: 10,

            child: Row(
              children: [
                const Icon(
                  Icons
                      .check_circle,
                  color:
                      Color(0xFF7BE68D),
                  size: 16,
                ),

                const SizedBox(
                  width: 5,
                ),

                Text(
                  _selectedProduct!,
                  style:
                      GoogleFonts.inter(
                    color:
                        Colors.white,
                    fontSize:
                        12,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // ====================================================
          // CHANGE PRODUCT
          // ====================================================

          Positioned(
            right: 9,
            top: 9,

            child: Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 8,
                vertical: 5,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Colors.black
                        .withAlpha(150),

                borderRadius:
                    BorderRadius.circular(
                  6,
                ),
              ),

              child: Text(
                'Change Product',

                style:
                    GoogleFonts.inter(
                  color:
                      Colors.white,
                  fontSize:
                      7.5,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IMAGE ERROR
  // ============================================================

  Widget _buildImageError() {
    return Container(
      color:
          const Color(0xFF1A241D),

      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          const Icon(
            Icons
                .broken_image_outlined,
            color:
                secondaryText,
            size: 30,
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            'Product image not found',

            style:
                GoogleFonts.inter(
              color:
                  secondaryText,
              fontSize:
                  8,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT NAME FIELD
  // ============================================================

  Widget _buildProductNameField() {
    return Container(
      height: 42,

      decoration:
          BoxDecoration(
        color:
            inputColor,

        borderRadius:
            BorderRadius.circular(
          8,
        ),

        border:
            Border.all(
          color:
              borderColor,
        ),
      ),

      child:
          Row(
        children: [
          const SizedBox(
            width: 12,
          ),

          Expanded(
            child:
                Text(
              _selectedProduct ??
                  'Select a product above',

              style:
                  GoogleFonts.inter(
                color:
                    _selectedProduct ==
                            null
                        ? hintText
                        : primaryText,

                fontSize:
                    9.5,

                fontWeight:
                    _selectedProduct ==
                            null
                        ? FontWeight.w400
                        : FontWeight.w500,
              ),
            ),
          ),

          if (_selectedProduct !=
              null)
            const Padding(
              padding:
                  EdgeInsets.only(
                right: 11,
              ),

              child:
                  Icon(
                Icons
                    .check_circle_outline,
                color:
                    primaryGreen,
                size:
                    17,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORY
  // ============================================================

  Widget _buildCategoryField() {
    return Container(
      height: 42,

      decoration:
          BoxDecoration(
        color:
            inputColor,

        borderRadius:
            BorderRadius.circular(
          8,
        ),

        border:
            Border.all(
          color:
              borderColor,
        ),
      ),

      child:
          Row(
        children: [
          const SizedBox(
            width: 12,
          ),

          const Icon(
            Icons
                .category_outlined,
            color:
                primaryGreen,
            size:
                16,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child:
                Text(
              _selectedCategory ??
                  'Category will be selected automatically',

              style:
                  GoogleFonts.inter(
                color:
                    _selectedCategory ==
                            null
                        ? hintText
                        : primaryText,

                fontSize:
                    9.5,
              ),
            ),
          ),

          const Padding(
            padding:
                EdgeInsets.only(
              right: 11,
            ),

            child:
                Icon(
              Icons
                  .lock_outline_rounded,
              color:
                  hintText,
              size:
                  14,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUANTITY ROW
  // ============================================================

  Widget _buildQuantityRow() {
    return Row(
      children: [
        Expanded(
          child:
              Container(
            height: 42,

            decoration:
                BoxDecoration(
              color:
                  inputColor,

              borderRadius:
                  BorderRadius.circular(
                8,
              ),

              border:
                  Border.all(
                color:
                    borderColor,
              ),
            ),

            child:
                TextField(
              controller:
                  _quantityController,

              keyboardType:
                  const TextInputType
                      .numberWithOptions(
                decimal:
                    true,
              ),

              style:
                  GoogleFonts.inter(
                color:
                    primaryText,
                fontSize:
                    10,
              ),

              decoration:
                  InputDecoration(
                hintText:
                    'e.g., 20',

                hintStyle:
                    GoogleFonts.inter(
                  color:
                      hintText,
                  fontSize:
                      9,
                ),

                border:
                    InputBorder.none,

                contentPadding:
                    const EdgeInsets
                        .symmetric(
                  horizontal:
                      12,
                  vertical:
                      11,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        SizedBox(
          width: 105,

          child:
              _buildDropdown(
            value:
                _selectedUnit,

            items:
                _units,

            onChanged:
                (value) {
              if (value ==
                  null) {
                return;
              }

              setState(() {
                _selectedUnit =
                    value;
              });
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?>
        onChanged,
  }) {
    return Container(
      height: 42,

      decoration:
          BoxDecoration(
        color:
            inputColor,

        borderRadius:
            BorderRadius.circular(
          8,
        ),

        border:
            Border.all(
          color:
              borderColor,
        ),
      ),

      child:
          DropdownButtonHideUnderline(
        child:
            DropdownButton<String>(
          value:
              value,

          isExpanded:
              true,

          dropdownColor:
              cardColor,

          icon:
              const Padding(
            padding:
                EdgeInsets.only(
              right: 9,
            ),

            child:
                Icon(
              Icons
                  .keyboard_arrow_down_rounded,
              color:
                  secondaryText,
              size:
                  18,
            ),
          ),

          padding:
              const EdgeInsets
                  .symmetric(
            horizontal:
                11,
          ),

          style:
              GoogleFonts.inter(
            color:
                primaryText,
            fontSize:
                9.5,
          ),

          items:
              items.map(
            (item) {
              return DropdownMenuItem<
                  String>(
                value:
                    item,

                child:
                    Text(
                  item,
                  style:
                      GoogleFonts
                          .inter(
                    color:
                        primaryText,
                    fontSize:
                        9.5,
                  ),
                ),
              );
            },
          ).toList(),

          onChanged:
              onChanged,
        ),
      ),
    );
  }

  // ============================================================
  // PRICE FIELD
  // ============================================================

  Widget _buildPriceField() {
    return Container(
      height: 42,

      decoration:
          BoxDecoration(
        color:
            inputColor,

        borderRadius:
            BorderRadius.circular(
          8,
        ),

        border:
            Border.all(
          color:
              borderColor,
        ),
      ),

      child:
          Row(
        children: [
          Container(
            width:
                40,

            alignment:
                Alignment.center,

            decoration:
                const BoxDecoration(
              border:
                  Border(
                right:
                    BorderSide(
                  color:
                      borderColor,
                ),
              ),
            ),

            child:
                Text(
              '₹',

              style:
                  GoogleFonts.inter(
                color:
                    primaryText,
                fontSize:
                    13,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child:
                TextField(
              controller:
                  _priceController,

              keyboardType:
                  const TextInputType
                      .numberWithOptions(
                decimal:
                    true,
              ),

              style:
                  GoogleFonts.inter(
                color:
                    primaryText,
                fontSize:
                    10,
              ),

              decoration:
                  InputDecoration(
                hintText:
                    'e.g., 28',

                hintStyle:
                    GoogleFonts.inter(
                  color:
                      hintText,
                  fontSize:
                      9,
                ),

                border:
                    InputBorder.none,

                contentPadding:
                    const EdgeInsets
                        .symmetric(
                  horizontal:
                      10,
                  vertical:
                      11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // START TIME
  // ============================================================

  Widget _buildStartTimeField() {
    return GestureDetector(
      onTap:
          _selectStartDateTime,

      child:
          Container(
        height:
            42,

        padding:
            const EdgeInsets
                .symmetric(
          horizontal:
              11,
        ),

        decoration:
            BoxDecoration(
          color:
              inputColor,

          borderRadius:
              BorderRadius.circular(
            8,
          ),

          border:
              Border.all(
            color:
                borderColor,
          ),
        ),

        child:
            Row(
          children: [
            const Icon(
              Icons
                  .calendar_today_outlined,
              color:
                  primaryGreen,
              size:
                  16,
            ),

            const SizedBox(
              width:
                  8,
            ),

            Expanded(
              child:
                  Text(
                _formatDateTime(
                  _selectedStartTime,
                ),

                style:
                    GoogleFonts.inter(
                  color:
                      primaryText,
                  fontSize:
                      9.5,
                ),
              ),
            ),

            const Icon(
              Icons
                  .keyboard_arrow_down_rounded,
              color:
                  secondaryText,
              size:
                  18,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE TIME PICKER
  // ============================================================

  Future<void>
      _selectStartDateTime() async {
    final DateTime now =
        DateTime.now();

    final DateTime? date =
        await showDatePicker(
      context:
          context,

      initialDate:
          _selectedStartTime
                  .isBefore(now)
              ? now
              : _selectedStartTime,

      firstDate:
          now,

      lastDate:
          now.add(
        const Duration(
          days:
              30,
        ),
      ),

      builder:
          (
        context,
        child,
      ) {
        return Theme(
          data:
              ThemeData.dark().copyWith(
            colorScheme:
                const ColorScheme.dark(
              primary:
                  primaryGreen,
              surface:
                  cardColor,
            ),
          ),

          child:
              child!,
        );
      },
    );

    if (date ==
            null ||
        !mounted) {
      return;
    }

    final TimeOfDay?
        time =
        await showTimePicker(
      context:
          context,

      initialTime:
          TimeOfDay.fromDateTime(
        _selectedStartTime,
      ),

      builder:
          (
        context,
        child,
      ) {
        return Theme(
          data:
              ThemeData.dark().copyWith(
            colorScheme:
                const ColorScheme.dark(
              primary:
                  primaryGreen,
              surface:
                  cardColor,
            ),
          ),

          child:
              child!,
        );
      },
    );

    if (time ==
        null) {
      return;
    }

    setState(() {
      _selectedStartTime =
          DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  Widget _buildDescriptionField() {
    return Container(
      height:
          78,

      decoration:
          BoxDecoration(
        color:
            inputColor,

        borderRadius:
            BorderRadius.circular(
          8,
        ),

        border:
            Border.all(
          color:
              borderColor,
        ),
      ),

      child:
          TextField(
        controller:
            _descriptionController,

        maxLines:
            3,

        style:
            GoogleFonts.inter(
          color:
              primaryText,
          fontSize:
              9,
        ),

        decoration:
            InputDecoration(
          hintText:
              'Describe your product quality, farm, etc.',

          hintStyle:
              GoogleFonts.inter(
            color:
                hintText,
            fontSize:
                8.5,
          ),

          border:
              InputBorder.none,

          contentPadding:
              const EdgeInsets
                  .all(
            11,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TIPS CARD
  // ============================================================

  Widget _buildTipsCard() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets
              .all(
        11,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFF122417,
        ),

        borderRadius:
            BorderRadius.circular(
          9,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFF24462D,
          ),
        ),
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width:
                27,

            height:
                27,

            decoration:
                const BoxDecoration(
              color:
                  Color(
                0xFF183A20,
              ),

              shape:
                  BoxShape.circle,
            ),

            child:
                const Icon(
              Icons
                  .lightbulb_outline_rounded,
              color:
                  primaryGreen,
              size:
                  17,
            ),
          ),

          const SizedBox(
            width:
                9,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'Tips for better results',

                  style:
                      GoogleFonts.inter(
                    color:
                        primaryGreen,
                    fontSize:
                        9,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height:
                      3,
                ),

                Text(
                  'Your product image is automatically added from the Vidhai catalog. Set a competitive starting price and provide accurate details.',

                  style:
                      GoogleFonts.inter(
                    color:
                        secondaryText,
                    fontSize:
                        7.5,
                    height:
                        1.35,
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
  // CREATE BUTTON
  // ============================================================

  Widget _buildCreateButton() {
    return SizedBox(
      width:
          double.infinity,

      height:
          44,

      child:
          ElevatedButton(
        onPressed:
            _isCreating
                ? null
                : _createAuction,

        style:
            ElevatedButton
                .styleFrom(
          backgroundColor:
              primaryGreen,

          disabledBackgroundColor:
              primaryGreen
                  .withAlpha(
            80,
          ),

          foregroundColor:
              Colors.white,

          elevation:
              0,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              8,
            ),
          ),
        ),

        child:
            _isCreating
                ? const SizedBox(
                    width:
                        19,
                    height:
                        19,
                    child:
                        CircularProgressIndicator(
                      color:
                          Colors.white,
                      strokeWidth:
                          2,
                    ),
                  )
                : Text(
                    'Create Auction',

                    style:
                        GoogleFonts.inter(
                      color:
                          Colors.white,
                      fontSize:
                          11,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
      ),
    );
  }

  // ============================================================
  // CREATE AUCTION
  // ============================================================

  Future<void> _createAuction() async {
    // ==========================================================
    // PRODUCT
    // ==========================================================

    if (_selectedProduct ==
        null) {
      _showMessage(
        'Please select a product',
      );

      return;
    }

    // ==========================================================
    // QUANTITY
    // ==========================================================

    final double? quantity =
        double.tryParse(
      _quantityController.text
          .trim(),
    );

    if (quantity ==
            null ||
        quantity <=
            0) {
      _showMessage(
        'Please enter a valid quantity',
      );

      return;
    }

    // ==========================================================
    // PRICE
    // ==========================================================

    final double? price =
        double.tryParse(
      _priceController.text
          .trim(),
    );

    if (price ==
            null ||
        price <=
            0) {
      _showMessage(
        'Please enter a valid starting price',
      );

      return;
    }

    // ==========================================================
    // USER
    // ==========================================================

    final User? user =
        FirebaseAuth.instance
            .currentUser;

    if (user ==
        null) {
      _showMessage(
        'Please login again',
      );

      return;
    }

    // ==========================================================
    // START
    // ==========================================================

    setState(() {
      _isCreating =
          true;
    });

    try {
      // ========================================================
      // DURATION
      // ========================================================

      final Duration duration =
          _getDuration();

      final DateTime endTime =
          _selectedStartTime
              .add(
        duration,
      );

      // ========================================================
      // STATUS
      // ========================================================

      final DateTime now =
          DateTime.now();

      final String status =
          _selectedStartTime
                  .isAfter(
                    now,
                  )
              ? 'upcoming'
              : 'active';

      // ========================================================
      // FIRESTORE
      // ========================================================

      await FirebaseFirestore
          .instance
          .collection(
            'auctions',
          )
          .add({
        // ======================================================
        // FARMER
        // ======================================================

        'farmerId':
            user.uid,

        // ======================================================
        // PRODUCT
        // ======================================================

        'productId':
            _selectedProduct!
                .toLowerCase()
                .replaceAll(
                  ' ',
                  '_',
                ),

        'productName':
            _selectedProduct,

        'category':
            _selectedCategory,

        'imageAsset':
            _selectedImage,

        // ======================================================
        // AUCTION DETAILS
        // ======================================================

        'quantity':
            quantity,

        'unit':
            _selectedUnit,

        'quality':
            _selectedQuality,

        'startPrice':
            price,

        'highestBid':
            price,

        'bidCount':
            0,

        // ======================================================
        // TIME
        // ======================================================

        'duration':
            _selectedDuration,

        'startTime':
            Timestamp.fromDate(
          _selectedStartTime,
        ),

        'endTime':
            Timestamp.fromDate(
          endTime,
        ),

        // ======================================================
        // DESCRIPTION
        // ======================================================

        'description':
            _descriptionController
                .text
                .trim(),

        // ======================================================
        // STATUS
        // ======================================================

        'status':
            status,

        // ======================================================
        // CREATED
        // ======================================================

        'createdAt':
            FieldValue
                .serverTimestamp(),
      });

      // ========================================================
      // SUCCESS
      // ========================================================

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content:
              Text(
            'Auction created successfully',
          ),

          backgroundColor:
              primaryGreen,
        ),
      );

      Navigator.pop(
        context,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to create auction. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating =
              false;
        });
      }
    }
  }

  // ============================================================
  // DURATION
  // ============================================================

  Duration _getDuration() {
    switch (_selectedDuration) {
      case '1 Hour':
        return const Duration(
          hours:
              1,
        );

      case '2 Hours':
        return const Duration(
          hours:
              2,
        );

      case '4 Hours':
        return const Duration(
          hours:
              4,
        );

      case '6 Hours':
        return const Duration(
          hours:
              6,
        );

      case '12 Hours':
        return const Duration(
          hours:
              12,
        );

      case '24 Hours':
        return const Duration(
          hours:
              24,
        );

      default:
        return const Duration(
          hours:
              2,
        );
    }
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDateTime(
    DateTime date,
  ) {
    final DateTime now =
        DateTime.now();

    final bool today =
        date.year ==
                now.year &&
            date.month ==
                now.month &&
            date.day ==
                now.day;

    final DateTime tomorrow =
        now.add(
      const Duration(
        days:
            1,
      ),
    );

    final bool tomorrowDate =
        date.year ==
                tomorrow.year &&
            date.month ==
                tomorrow.month &&
            date.day ==
                tomorrow.day;

    final int hour =
        date.hour %
                    12 ==
                0
            ? 12
            : date.hour %
                12;

    final String minute =
        date.minute
            .toString()
            .padLeft(
          2,
          '0',
        );

    final String period =
        date.hour >=
                12
            ? 'PM'
            : 'AM';

    if (today) {
      return 'Today, '
          '$hour:$minute $period';
    }

    if (tomorrowDate) {
      return 'Tomorrow, '
          '$hour:$minute $period';
    }

    return '${date.day}/${date.month}/${date.year}, '
        '$hour:$minute $period';
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(
    String text,
  ) {
    return Text(
      text,

      style:
          GoogleFonts.inter(
        color:
            primaryText,
        fontSize:
            9.5,
        fontWeight:
            FontWeight.w600,
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(
          message,
        ),

        backgroundColor:
            const Color(
          0xFF202522,
        ),
      ),
    );
  }
}
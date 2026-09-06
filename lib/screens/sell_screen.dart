import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_product_screen.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';
import '../widgets/product_card.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() =>
      _SellScreenState();
}

class _SellScreenState
    extends State<SellScreen> {
  final ProductService _productService =
      ProductService();

  String _selectedFilter = "All";

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    final currentUserId =
        user?.uid ?? '';

    return Scaffold(
      backgroundColor:
          const Color(0xFF0B0B0B),

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0B0B0B),

        elevation: 0,

        centerTitle: true,

        // BACK TO FARMER HOME
        leading: IconButton(
          onPressed: () {
            Navigator.of(context)
                .pushNamedAndRemoveUntil(
              '/farmer-home',
              (route) => false,
            );
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 25,
          ),
          tooltip: "Farmer Home",
        ),

        title: const Text(
          "My Farmer Hub",

          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color:
                  Colors.greenAccent,
            ),

            tooltip:
                "Refresh Listings",

            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(),

          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // ==================================================
              // HEADER
              // ==================================================

              const Text(
                "My Products",

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.all(
                      4,
                    ),

                    decoration:
                        BoxDecoration(
                      color: Colors.red
                          .withOpacity(
                        0.15,
                      ),

                      shape:
                          BoxShape.circle,
                    ),

                    child:
                        const Icon(
                      Icons.location_on,
                      color:
                          Colors.redAccent,
                      size: 16,
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  const Text(
                    "Coimbatore, Tamil Nadu",

                    style: TextStyle(
                      color:
                          Colors.white60,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // STATISTICS
              // ==================================================

              StreamBuilder<
                  List<ProductModel>>(
                stream: currentUserId
                        .isNotEmpty
                    ? _productService
                        .getFarmerProducts(
                        currentUserId,
                      )
                    : Stream.value(
                        <ProductModel>[],
                      ),

                builder:
                    (context, snapshot) {
                  if (snapshot
                          .connectionState ==
                      ConnectionState
                          .waiting) {
                    return Container(
                      height: 110,

                      alignment:
                          Alignment.center,

                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFF181818,
                        ),

                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                      ),

                      child:
                          const CircularProgressIndicator(
                        color:
                            Colors.greenAccent,
                      ),
                    );
                  }

                  final products =
                      snapshot.data ??
                          <ProductModel>[];

                  final total =
                      products.length;

                  final active =
                      products
                          .where(
                            (p) =>
                                p.available,
                          )
                          .length;

                  final sold =
                      products
                          .where(
                            (p) =>
                                !p.available,
                          )
                          .length;

                  return Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 20,
                      horizontal: 14,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFF161616,
                      ),

                      borderRadius:
                          BorderRadius
                              .circular(
                        22,
                      ),

                      border:
                          Border.all(
                        color: Colors
                            .white
                            .withOpacity(
                          0.08,
                        ),
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors
                              .black
                              .withOpacity(
                            0.4,
                          ),

                          blurRadius: 20,

                          offset:
                              const Offset(
                            0,
                            10,
                          ),
                        ),
                      ],
                    ),

                    child: Row(
                      children: [

                        Expanded(
                          child:
                              _buildStatItem(
                            title:
                                "Total",

                            value:
                                total
                                    .toString(),

                            color:
                                const Color(
                              0xFF00E676,
                            ),

                            icon: Icons
                                .inventory_2_outlined,
                          ),
                        ),

                        _divider(),

                        Expanded(
                          child:
                              _buildStatItem(
                            title:
                                "Active",

                            value:
                                active
                                    .toString(),

                            color:
                                const Color(
                              0xFF00E5FF,
                            ),

                            icon: Icons
                                .check_circle_outline,
                          ),
                        ),

                        _divider(),

                        Expanded(
                          child:
                              _buildStatItem(
                            title:
                                "Sold Out",

                            value:
                                sold
                                    .toString(),

                            color:
                                const Color(
                              0xFFFF9100,
                            ),

                            icon: Icons
                                .shopping_bag_outlined,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // ADD PRODUCT BANNER
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.all(
                  22,
                ),

                decoration:
                    BoxDecoration(
                  gradient:
                      const LinearGradient(
                    colors: [
                      Color(
                        0xFF1E3A2B,
                      ),
                      Color(
                        0xFF12251B,
                      ),
                    ],

                    begin:
                        Alignment.topLeft,

                    end:
                        Alignment
                            .bottomRight,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    24,
                  ),

                  border:
                      Border.all(
                    color: Colors
                        .greenAccent
                        .withOpacity(
                      0.2,
                    ),
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.green
                          .withOpacity(
                        0.15,
                      ),

                      blurRadius: 15,

                      offset:
                          const Offset(
                        0,
                        6,
                      ),
                    ),
                  ],
                ),

                child: Row(
                  children: [

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [

                          const Text(
                            "List Your Produce",

                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontSize: 22,
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          const Text(
                            "Reach buyers directly using AI pricing assistant.",

                            style:
                                TextStyle(
                              color:
                                  Colors.white70,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          const AddProductScreen(),
                                ),
                              );
                            },

                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFF00E676,
                              ),

                              foregroundColor:
                                  Colors.black,

                              elevation: 4,

                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    20,
                                vertical:
                                    12,
                              ),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  16,
                                ),
                              ),
                            ),

                            icon:
                                const Icon(
                              Icons.add,
                              size: 20,
                              color:
                                  Colors.black,
                            ),

                            label:
                                const Text(
                              "Add New",

                              style:
                                  TextStyle(
                                fontSize:
                                    15,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Container(
                      width: 80,
                      height: 80,

                      decoration:
                          BoxDecoration(
                        color: Colors
                            .greenAccent
                            .withOpacity(
                          0.12,
                        ),

                        shape:
                            BoxShape.circle,

                        border:
                            Border.all(
                          color: Colors
                              .greenAccent
                              .withOpacity(
                            0.25,
                          ),
                        ),
                      ),

                      child:
                          const Icon(
                        Icons
                            .storefront_rounded,
                        color:
                            Colors.greenAccent,
                        size: 42,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 32,
              ),

              // ==================================================
              // MY LISTINGS + FILTERS
              // ==================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [

                  const Text(
                    "My Listings",

                    style:
                        TextStyle(
                      color:
                          Colors.white,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 22,
                      letterSpacing:
                          -0.3,
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets.all(
                      4,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFF181818,
                      ),

                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),

                    child: Row(
                      children: [
                        _filterChip("All"),
                        _filterChip(
                            "Active"),
                        _filterChip("Sold"),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // PRODUCT LIST
              // ==================================================

              StreamBuilder<
                  List<ProductModel>>(
                stream: currentUserId
                        .isNotEmpty
                    ? _productService
                        .getFarmerProducts(
                        currentUserId,
                      )
                    : Stream.value(
                        <ProductModel>[],
                      ),

                builder:
                    (context, snapshot) {

                  if (snapshot
                          .connectionState ==
                      ConnectionState
                          .waiting) {
                    return const Padding(
                      padding:
                          EdgeInsets
                              .symmetric(
                        vertical: 40,
                      ),

                      child:
                          Center(
                        child:
                            CircularProgressIndicator(
                          color:
                              Colors.greenAccent,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!
                          .isEmpty) {
                    return _emptyProducts();
                  }

                  List<ProductModel>
                      products =
                      snapshot.data!;

                  // FILTER
                  if (_selectedFilter ==
                      "Active") {
                    products = products
                        .where(
                          (p) =>
                              p.available,
                        )
                        .toList();
                  }

                  if (_selectedFilter ==
                      "Sold") {
                    products = products
                        .where(
                          (p) =>
                              !p.available,
                        )
                        .toList();
                  }

                  if (products.isEmpty) {
                    return Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 35,
                      ),

                      alignment:
                          Alignment.center,

                      child: Text(
                        "No $_selectedFilter products found.",

                        style:
                            const TextStyle(
                          color:
                              Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,

                    physics:
                        const NeverScrollableScrollPhysics(),

                    itemCount:
                        products.length,

                    itemBuilder:
                        (context, index) {

                      final product =
                          products[index];

                      return Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          bottom: 12,
                        ),

                        child:
                            ProductCard(
                          product:
                              product,
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(
                height: 90,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STAT DIVIDER
  // ============================================================

  Widget _divider() {
    return Container(
      width: 1,
      height: 55,
      color:
          Colors.white.withOpacity(
        0.1,
      ),
    );
  }

  // ============================================================
  // STAT ITEM
  // ============================================================

  Widget _buildStatItem({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize:
          MainAxisSize.min,

      children: [

        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              icon,
              color: color,
              size: 16,
            ),

            const SizedBox(
              width: 6,
            ),

            Text(
              title,

              style:
                  const TextStyle(
                color:
                    Colors.white70,
                fontWeight:
                    FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 8,
        ),

        Text(
          value,

          style:
              TextStyle(
            color: color,
            fontSize: 28,
            fontWeight:
                FontWeight.w800,
            letterSpacing:
                -0.5,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTER CHIP
  // ============================================================

  Widget _filterChip(
    String filter,
  ) {
    final bool selected =
        _selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },

      child:
          AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 200,
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),

        decoration:
            BoxDecoration(
          color: selected
              ? const Color(
                  0xFF00E676,
                )
              : Colors.transparent,

          borderRadius:
              BorderRadius.circular(
            10,
          ),
        ),

        child: Text(
          filter,

          style:
              TextStyle(
            color: selected
                ? Colors.black
                : Colors.white60,

            fontWeight: selected
                ? FontWeight.bold
                : FontWeight.w500,

            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY PRODUCTS
  // ============================================================

  Widget _emptyProducts() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.symmetric(
        vertical: 45,
        horizontal: 20,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFF141414),

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border:
            Border.all(
          color: Colors.white
              .withOpacity(
            0.05,
          ),
        ),
      ),

      child: const Column(
        children: [

          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Colors.white30,
          ),

          SizedBox(
            height: 12,
          ),

          Text(
            "No products listed yet",

            style:
                TextStyle(
              color:
                  Colors.white70,
              fontWeight:
                  FontWeight.bold,
              fontSize: 16,
            ),
          ),

          SizedBox(
            height: 4,
          ),

          Text(
            "Tap 'Add New' above to list your produce.",

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  Colors.white38,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
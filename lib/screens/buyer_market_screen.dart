import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/product_model.dart';
import 'cart_screen.dart';
import 'chat_screen.dart';

class BuyerMarketScreen extends StatefulWidget {
  const BuyerMarketScreen({super.key});

  @override
  State<BuyerMarketScreen> createState() =>
      _BuyerMarketScreenState();
}

class _BuyerMarketScreenState extends State<BuyerMarketScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange = Color(0xFFFF9800);
  static const Color background = Color(0xFF080A08);
  static const Color card = Color(0xFF141817);
  static const Color cardLight = Color(0xFF1B1F1D);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _searchController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  String _selectedCategory = 'All';
  String _searchText = '';
  String _sortBy = 'Recommended';

  final Set<String> _favorites = {};

  // ============================================================
  // CATEGORY IMAGES
  // ============================================================

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'All',
      'image': 'assets/products/all.png',
    },
    {
      'name': 'Vegetables',
      'image': 'assets/products/vegetables.png',
    },
    {
      'name': 'Fruits',
      'image': 'assets/products/fruits.png',
    },
    {
      'name': 'Grains & Pulses',
      'image': 'assets/products/grains.png',
    },
    {
      'name': 'Spices',
      'image': 'assets/products/spices.png',
    },
    {
      'name': 'Dairy',
      'image': 'assets/products/dairy.png',
    },
    {
      'name': 'Others',
      'image': 'assets/products/others.png',
    },
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        _searchText =
            _searchController.text.trim().toLowerCase();
      });
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),

            SliverToBoxAdapter(
              child: _buildSearchBar(),
            ),

            SliverToBoxAdapter(
              child: _buildCategories(),
            ),

            SliverToBoxAdapter(
              child: _buildSectionHeader(),
            ),

            _buildProducts(),

            SliverToBoxAdapter(
              child: _buildBottomBenefits(),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 25),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        14,
        10,
        14,
        10,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: card,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: _showMarketMenu,
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 23,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.eco_rounded,
                  color: orange,
                  size: 27,
                ),
                const SizedBox(width: 3),
                const Text(
                  'Vidhai',
                  style: TextStyle(
                    color: orange,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 72,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Coimbatore, TN',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                Text(
                  '641001',
                  style: TextStyle(
                    color: orange,
                    fontSize: 7,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 2),

          SizedBox(
            width: 35,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          SizedBox(
            width: 35,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: _openCart,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 24,
                  ),

                  StreamBuilder<
                      QuerySnapshot<
                          Map<String, dynamic>>>(
                    stream: _cartItemsStream(),
                    builder:
                        (context, snapshot) {
                      final count =
                          snapshot.data?.docs.length ??
                              0;

                      return Positioned(
                        right: -5,
                        top: -5,
                        child: Container(
                          width: 17,
                          height: 17,
                          alignment:
                              Alignment.center,
                          decoration:
                              const BoxDecoration(
                            color: orange,
                            shape:
                                BoxShape.circle,
                          ),
                          child: Text(
                            count > 9
                                ? '9+'
                                : '$count',
                            style:
                                const TextStyle(
                              color: Colors.black,
                              fontSize: 7,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CART STREAM
  // ============================================================

  Stream<
      QuerySnapshot<Map<String, dynamic>>>
      _cartItemsStream() {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .snapshots();
  }

  // ============================================================
  // CART
  // ============================================================

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CartScreen(),
      ),
    );
  }

  // ============================================================
  // MENU
  // ============================================================

  void _showMarketMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return Container(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            12,
            18,
            25,
          ),
          decoration:
              const BoxDecoration(
            color: card,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 4,
                margin:
                    const EdgeInsets.only(
                  bottom: 20,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white24,
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),

              const Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              _menuItem(
                Icons.chat_bubble_outline_rounded,
                'Chat with Farmers',
                () {
                  Navigator.pop(context);
                  _showSnackBar(
                    'Open Chat from the Chat tab.',
                  );
                },
              ),

              _menuItem(
                Icons.favorite_border_rounded,
                'Favorites',
                () {
                  Navigator.pop(context);
                  _showSnackBar(
                    '${_favorites.length} favorite product(s)',
                  );
                },
              ),

              _menuItem(
                Icons.local_offer_outlined,
                "Today's Deals",
                () {
                  Navigator.pop(context);
                  _showSnackBar(
                    'Deals section coming soon.',
                  );
                },
              ),

              _menuItem(
                Icons.location_on_outlined,
                'Change Location',
                () {
                  Navigator.pop(context);
                  _showSnackBar(
                    'Location selection coming soon.',
                  );
                },
              ),

              _menuItem(
                Icons.help_outline_rounded,
                'Help & Support',
                () {
                  Navigator.pop(context);
                  _showSnackBar(
                    'Help & Support coming soon.',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color:
              orange.withValues(alpha: 0.12),
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: orange,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight:
              FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.white38,
      ),
      onTap: onTap,
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchBar() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 55,
              decoration:
                  BoxDecoration(
                color: card,
                borderRadius:
                    BorderRadius.circular(17),
                border: Border.all(
                  color: Colors.white
                      .withValues(
                    alpha: 0.10,
                  ),
                ),
              ),
              child: TextField(
                controller:
                    _searchController,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
                decoration:
                    const InputDecoration(
                  border:
                      InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color:
                        Colors.white54,
                    size: 27,
                  ),
                  hintText:
                      'Search for vegetables, fruits, grains...',
                  hintStyle:
                      TextStyle(
                    color:
                        Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Container(
            height: 55,
            width: 55,
            decoration:
                BoxDecoration(
              color: orange.withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(17),
              border: Border.all(
                color: orange.withValues(
                  alpha: 0.35,
                ),
              ),
            ),
            child: IconButton(
              onPressed:
                  _showFilterSheet,
              icon: const Icon(
                Icons.tune_rounded,
                color: orange,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORY IMAGES
  // ============================================================

  Widget _buildCategories() {
    return SizedBox(
      height: 145,
      child: ListView.separated(
        padding:
            const EdgeInsets.fromLTRB(
          18,
          10,
          18,
          5,
        ),
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        itemCount:
            _categories.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(width: 14),
        itemBuilder:
            (context, index) {
          final category =
              _categories[index];

          return _categoryItem(
            name:
                category['name']
                    as String,
            image:
                category['image']
                    as String,
          );
        },
      ),
    );
  }

  Widget _categoryItem({
    required String name,
    required String image,
  }) {
    final selected =
        _selectedCategory == name;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory =
              name;
        });
      },
      child: SizedBox(
        width: 88,
        child: Column(
          children: [
            AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 180,
              ),
              width: 98,
              height: 98,
              padding:
                  const EdgeInsets.all(8),
              decoration:
                  BoxDecoration(
                color: selected
                    ? orange.withValues(
                        alpha: 0.14,
                      )
                    : card,
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
                border: Border.all(
                  color: selected
                      ? orange
                      : Colors.white
                          .withValues(
                          alpha: 0.12,
                        ),
                  width: selected
                      ? 1.4
                      : 1,
                ),
              ),
              child: Image.asset(
                image,
                fit: BoxFit.contain,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const Icon(
                    Icons.eco_rounded,
                    color: orange,
                    size: 30,
                  );
                },
              ),
            ),

            const SizedBox(height: 7),

            Text(
              name,
              maxLines: 2,
              textAlign:
                  TextAlign.center,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? orange
                    : Colors.white70,
                fontSize: 9,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        3,
        18,
        12,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Fresh from Farmers near you 🌱',
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 8),

          GestureDetector(
            onTap:
                _showSortSheet,
            child: Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Text(
                  'Sort ',
                  style: TextStyle(
                    color:
                        Colors.white54,
                    fontSize: 9,
                  ),
                ),
                Text(
                  _sortBy,
                  style:
                      const TextStyle(
                    color: orange,
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const Icon(
                  Icons
                      .keyboard_arrow_down_rounded,
                  color:
                      Colors.white54,
                  size: 17,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCTS
  // ============================================================

  Widget _buildProducts() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore
          .instance
          .collection('products')
          .snapshots(),
      builder:
          (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child:
                _buildErrorState(
              snapshot.error
                  .toString(),
            ),
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(
                vertical: 80,
              ),
              child: Center(
                child:
                    CircularProgressIndicator(
                  color: orange,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        final documents =
            snapshot.data?.docs ??
                [];

        List<ProductModel>
            products = [];

        for (final doc
            in documents) {
          try {
            final data =
                Map<String, dynamic>.from(
              doc.data(),
            );

            data['id'] =
                data['id'] ?? doc.id;

            products.add(
              _productFromFirestore(
                data,
              ),
            );
          } catch (e) {
            debugPrint(
              'Product parse error: $e',
            );
          }
        }

        products =
            products.where(
          (product) {
            return product.available &&
                product.quantity > 0;
          },
        ).toList();

        if (_selectedCategory !=
            'All') {
          products =
              products.where(
            (product) {
              return _categoryMatches(
                product.category,
                _selectedCategory,
              );
            },
          ).toList();
        }

        if (_searchText.isNotEmpty) {
          products =
              products.where(
            (product) {
              final name = product
                  .name
                  .toLowerCase();

              final category =
                  product.category
                      .toLowerCase();

              final farmer =
                  product.farmerName
                      .toLowerCase();

              final location =
                  product.location
                      .toLowerCase();

              return name.contains(
                    _searchText,
                  ) ||
                  category.contains(
                    _searchText,
                  ) ||
                  farmer.contains(
                    _searchText,
                  ) ||
                  location.contains(
                    _searchText,
                  );
            },
          ).toList();
        }

        _sortProducts(products);

        if (products.isEmpty) {
          return SliverToBoxAdapter(
            child:
                _buildEmptyProducts(),
          );
        }

        return SliverPadding(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            15,
          ),
          sliver: SliverGrid(
            delegate:
                SliverChildBuilderDelegate(
              (context, index) {
                return _productCard(
                  products[index],
                );
              },
              childCount:
                  products.length,
            ),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,

              // Slightly taller card to
              // avoid bottom overflow.
              childAspectRatio: 0.63,
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // FIRESTORE PRODUCT
  // ============================================================

  ProductModel _productFromFirestore(
    Map<String, dynamic> data,
  ) {
    dynamic createdAt =
        data['createdAt'];

    if (createdAt is Timestamp) {
      createdAt =
          createdAt.toDate()
              .toIso8601String();
    }

    if (createdAt == null ||
        createdAt
            .toString()
            .isEmpty) {
      createdAt =
          DateTime.now()
              .toIso8601String();
    }

    dynamic price =
        data['price'];

    dynamic quantity =
        data['quantity'];

    return ProductModel.fromMap({
      ...data,
      'createdAt':
          createdAt.toString(),
      'price': price is num
          ? price.toDouble()
          : double.tryParse(
                price?.toString() ??
                    '0',
              ) ??
              0.0,
      'quantity': quantity is num
          ? quantity.toInt()
          : int.tryParse(
                quantity?.toString() ??
                    '0',
              ) ??
              0,
    });
  }

  // ============================================================
  // CATEGORY MATCH
  // ============================================================

  bool _categoryMatches(
    String productCategory,
    String selected,
  ) {
    final category =
        productCategory
            .toLowerCase()
            .trim();

    final target =
        selected
            .toLowerCase()
            .trim();

    if (target ==
        'grains & pulses') {
      return category.contains(
            'grain',
          ) ||
          category.contains(
            'pulse',
          );
    }

    if (target == 'dairy') {
      return category.contains(
            'dairy',
          ) ||
          category.contains(
            'milk',
          );
    }

    if (target == 'others') {
      return !category.contains(
            'vegetable',
          ) &&
          !category.contains(
            'fruit',
          ) &&
          !category.contains(
            'grain',
          ) &&
          !category.contains(
            'pulse',
          ) &&
          !category.contains(
            'spice',
          ) &&
          !category.contains(
            'dairy',
          );
    }

    if (target ==
        'vegetables') {
      return category.contains(
        'vegetable',
      );
    }

    if (target == 'fruits') {
      return category.contains(
        'fruit',
      );
    }

    if (target == 'spices') {
      return category.contains(
        'spice',
      );
    }

    return true;
  }

  // ============================================================
  // SORT
  // ============================================================

  void _sortProducts(
    List<ProductModel>
        products,
  ) {
    if (_sortBy ==
        'Price Low') {
      products.sort(
        (a, b) => a.price
            .compareTo(b.price),
      );
    } else if (_sortBy ==
        'Price High') {
      products.sort(
        (a, b) => b.price
            .compareTo(a.price),
      );
    } else if (_sortBy ==
        'Newest') {
      products.sort(
        (a, b) =>
            b.createdAt
                .compareTo(
          a.createdAt,
        ),
      );
    }
  }

  // ============================================================
  // PRODUCT CARD
  // ============================================================

  Widget _productCard(
    ProductModel product,
  ) {
    final favorite =
        _favorites.contains(
      product.id,
    );

    return GestureDetector(
      onTap: () {
        _showProductDetails(
          product,
        );
      },
      child: Container(
        decoration:
            BoxDecoration(
          color: card,
          borderRadius:
              BorderRadius.circular(
            17,
          ),
          border: Border.all(
            color: Colors.white
                .withValues(
              alpha: 0.10,
            ),
          ),
        ),
        clipBehavior:
            Clip.antiAlias,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // PRODUCT IMAGE
            // ==================================================

            SizedBox(
              height: 125,
              width:
                  double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child:
                        _buildProductImage(
                      product,
                    ),
                  ),

                  Positioned(
                    left: 9,
                    top: 9,
                    child: Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration:
                          BoxDecoration(
                        color: product
                                .organic
                            ? Colors.green
                            : orange,
                        borderRadius:
                            BorderRadius
                                .circular(
                          5,
                        ),
                      ),
                      child: Text(
                        product.organic
                            ? 'ORGANIC'
                            : 'FRESH',
                        style:
                            const TextStyle(
                          color:
                              Colors.black,
                          fontSize: 6.5,
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    right: 8,
                    top: 8,
                    child:
                        GestureDetector(
                      onTap: () {
                        setState(() {
                          if (favorite) {
                            _favorites
                                .remove(
                              product.id,
                            );
                          } else {
                            _favorites
                                .add(
                              product.id,
                            );
                          }
                        });
                      },
                      child:
                          Container(
                        width: 30,
                        height: 30,
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .black
                              .withValues(
                            alpha:
                                0.55,
                          ),
                          shape:
                              BoxShape
                                  .circle,
                        ),
                        child: Icon(
                          favorite
                              ? Icons
                                  .favorite_rounded
                              : Icons
                                  .favorite_border_rounded,
                          color: favorite
                              ? Colors
                                  .redAccent
                              : Colors
                                  .white,
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // PRODUCT INFORMATION
            // ==================================================

            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets
                        .fromLTRB(
                  9,
                  6,
                  9,
                  6,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize: 14,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Row(
                      children: [
                        Container(
                          width: 19,
                          height: 19,
                          decoration:
                              BoxDecoration(
                            color: orange
                                .withValues(
                              alpha:
                                  0.12,
                            ),
                            shape:
                                BoxShape
                                    .circle,
                          ),
                          child:
                              const Icon(
                            Icons
                                .person_rounded,
                            color:
                                orange,
                            size: 11,
                          ),
                        ),

                        const SizedBox(
                          width: 4,
                        ),

                        Expanded(
                          child:
                              Text(
                            product
                                    .farmerName
                                    .isEmpty
                                ? 'Farmer'
                                : product
                                    .farmerName,
                            maxLines:
                                1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  Colors
                                      .white70,
                              fontSize:
                                  8,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Row(
                      children: [
                        const Icon(
                          Icons
                              .location_on_rounded,
                          color: Colors
                              .white38,
                          size: 10,
                        ),
                        const SizedBox(
                          width: 2,
                        ),
                        Expanded(
                          child:
                              Text(
                            product
                                    .location
                                    .isEmpty
                                ? 'Coimbatore'
                                : product
                                    .location,
                            maxLines:
                                1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  Colors
                                      .white38,
                              fontSize:
                                  7,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      '₹${product.price.toStringAsFixed(0)} / ${product.unit}',
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color: orange,
                        fontSize: 15,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors
                            .green
                            .withValues(
                          alpha: 0.12,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          5,
                        ),
                      ),
                      child: Text(
                        '${product.quantity} ${product.unit} available',
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color: Colors
                              .greenAccent,
                          fontSize: 6.5,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                    ),

                    const Spacer(),

                    SizedBox(
                      width:
                          double.infinity,
                      height: 28,
                      child:
                          OutlinedButton(
                        onPressed: () {
                          _showProductDetails(
                            product,
                          );
                        },
                        style:
                            OutlinedButton
                                .styleFrom(
                          foregroundColor:
                              orange,
                          side:
                              const BorderSide(
                            color:
                                orange,
                          ),
                          padding:
                              EdgeInsets
                                  .zero,
                          minimumSize:
                              Size.zero,
                          tapTargetSize:
                              MaterialTapTargetSize
                                  .shrinkWrap,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              7,
                            ),
                          ),
                        ),
                        child:
                            const Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [
                            Text(
                              'Details',
                              style:
                                  TextStyle(
                                fontSize:
                                    8,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                            SizedBox(
                              width: 3,
                            ),
                            Icon(
                              Icons
                                  .arrow_forward_rounded,
                              size: 11,
                            ),
                          ],
                        ),
                      ),
                    ),
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
  // PRODUCT IMAGE
  // ============================================================

  Widget _buildProductImage(
    ProductModel product,
  ) {
    String image =
        product.image.trim();

    // ==========================================================
    // AUTOMATIC LOCAL PRODUCT IMAGES
    // ==========================================================

    if (image.isEmpty) {
      image =
          _resolveProductImage(
        product,
      );
    }

    if (image.isEmpty) {
      return _imagePlaceholder(
        product.name,
      );
    }

    // ==========================================================
    // NETWORK IMAGE
    // ==========================================================

    if (image.startsWith(
          'http://',
        ) ||
        image.startsWith(
          'https://',
        )) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder:
            (
          context,
          error,
          stackTrace,
        ) {
          return _imagePlaceholder(
            product.name,
          );
        },
        loadingBuilder:
            (
          context,
          child,
          progress,
        ) {
          if (progress == null) {
            return child;
          }

          return Container(
            color: cardLight,
            alignment:
                Alignment.center,
            child:
                const CircularProgressIndicator(
              color: orange,
              strokeWidth: 2,
            ),
          );
        },
      );
    }

    // ==========================================================
    // LOCAL ASSET
    // ==========================================================

    return Container(
      color: cardLight,
      alignment:
          Alignment.center,
      padding:
          const EdgeInsets.all(
        12,
      ),
      child: Image.asset(
        image,
        fit: BoxFit.contain,
        errorBuilder:
            (
          context,
          error,
          stackTrace,
        ) {
          debugPrint(
            'Product image failed: $image',
          );

          return _imagePlaceholder(
            product.name,
          );
        },
      ),
    );
  }

  // ============================================================
  // RESOLVE PRODUCT IMAGE
  // ============================================================

  String _resolveProductImage(
    ProductModel product,
  ) {
    final existing =
        product.image.trim();

    if (existing.isNotEmpty) {
      return existing;
    }

    final name =
        product.name
            .toLowerCase()
            .trim();

    if (name.contains('tomato')) {
      return 'assets/products/tomato.png';
    }

    if (name.contains('carrot')) {
      return 'assets/products/carrot.png';
    }

    if (name.contains('potato')) {
      return 'assets/products/potato.png';
    }

    if (name.contains('onion')) {
      return 'assets/products/onion.png';
    }

    if (name.contains('spinach')) {
      return 'assets/products/spinach.png';
    }

    if (name.contains('apple')) {
      return 'assets/products/apple.png';
    }

    if (name.contains('banana')) {
      return 'assets/products/banana.png';
    }

    if (name.contains('chilli') ||
        name.contains('chili')) {
      return 'assets/products/chilli.png';
    }

    if (name.contains('brinjal') ||
        name.contains('eggplant')) {
      return 'assets/products/brinjal.png';
    }

    if (name.contains('cabbage')) {
      return 'assets/products/cabbage.png';
    }

    if (name.contains('cauliflower')) {
      return 'assets/products/cauliflower.png';
    }

    return '';
  }

  // ============================================================
  // PLACEHOLDER
  // ============================================================

  Widget _imagePlaceholder(
    String name,
  ) {
    IconData icon =
        Icons.eco_rounded;

    final lower =
        name.toLowerCase();

    if (lower.contains(
          'tomato',
        ) ||
        lower.contains(
          'apple',
        )) {
      icon =
          Icons.local_florist_rounded;
    } else if (lower.contains(
        'carrot')) {
      icon =
          Icons.eco_rounded;
    } else if (lower.contains(
        'milk')) {
      icon =
          Icons.local_drink_rounded;
    } else if (lower.contains(
        'grain')) {
      icon =
          Icons.grass_rounded;
    }

    return Container(
      decoration:
          const BoxDecoration(
        gradient:
            LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            Color(0xFF3A2400),
            Color(0xFF181818),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: orange,
          size: 48,
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT DETAILS
  // ============================================================

  void _showProductDetails(
    ProductModel product,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true,
      backgroundColor:
          Colors.transparent,
      builder: (context) {
        return _productDetailsSheet(
          product,
        );
      },
    );
  }

  Widget _productDetailsSheet(
    ProductModel product,
  ) {
    return SafeArea(
      child: Container(
        height:
            MediaQuery.of(context)
                    .size
                    .height *
                0.78,
        decoration:
            const BoxDecoration(
          color: card,
          borderRadius:
              BorderRadius.vertical(
            top: Radius.circular(
              28,
            ),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin:
                  const EdgeInsets.only(
                top: 10,
                bottom: 10,
              ),
              width: 45,
              height: 4,
              decoration:
                  BoxDecoration(
                color:
                    Colors.white24,
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
            ),

            Expanded(
              child:
                  SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  5,
                  18,
                  20,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    // ==================================================
                    // IMAGE
                    // ==================================================

                    Container(
                      height: 210,
                      width:
                          double.infinity,
                      clipBehavior:
                          Clip.antiAlias,
                      decoration:
                          BoxDecoration(
                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                        color:
                            cardLight,
                      ),
                      child:
                          _buildProductImage(
                        product,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==================================================
                    // NAME + PRICE
                    // ==================================================

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize:
                                  22,
                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Flexible(
                          child:
                              Text(
                            '₹${product.price.toStringAsFixed(0)} / ${product.unit}',
                            textAlign:
                                TextAlign
                                    .right,
                            style:
                                const TextStyle(
                              color:
                                  orange,
                              fontSize:
                                  16,
                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    Text(
                      product.description
                              .isEmpty
                          ? 'Fresh farm produce directly from the farmer.'
                          : product
                              .description,
                      style:
                          const TextStyle(
                        color:
                            Colors.white54,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    _detailRow(
                      Icons
                          .person_outline_rounded,
                      'Farmer',
                      product
                              .farmerName
                              .isEmpty
                          ? 'Farmer'
                          : product
                              .farmerName,
                    ),

                    _detailRow(
                      Icons
                          .location_on_outlined,
                      'Location',
                      product
                              .location
                              .isEmpty
                          ? 'Coimbatore, Tamil Nadu'
                          : product
                              .location,
                    ),

                    _detailRow(
                      Icons
                          .inventory_2_outlined,
                      'Available',
                      '${product.quantity} ${product.unit}',
                    ),

                    _detailRow(
                      Icons
                          .verified_outlined,
                      'Quality',
                      product.quality,
                    ),

                    _detailRow(
                      product.organic
                          ? Icons.eco_outlined
                          : Icons
                              .agriculture_outlined,
                      'Type',
                      product.organic
                          ? 'Organic Farm Produce'
                          : 'Fresh Farm Produce',
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==================================================
                    // CHAT
                    // ==================================================

                    SizedBox(
                      width:
                          double.infinity,
                      height: 48,
                      child:
                          OutlinedButton
                              .icon(
                        onPressed:
                            () {
                          Navigator.pop(
                            context,
                          );
                          _openFarmerChat(
                            product,
                          );
                        },
                        icon:
                            const Icon(
                          Icons
                              .chat_bubble_outline_rounded,
                          color:
                              orange,
                          size: 19,
                        ),
                        label:
                            const Text(
                          'Chat with Farmer',
                          style:
                              TextStyle(
                            color:
                                orange,
                            fontSize:
                                12,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                        style:
                            OutlinedButton
                                .styleFrom(
                          side:
                              BorderSide(
                            color: orange
                                .withValues(
                              alpha:
                                  0.7,
                            ),
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 9,
                    ),

                    // ==================================================
                    // ADD TO CART
                    // ==================================================

                    SizedBox(
                      width:
                          double.infinity,
                      height: 48,
                      child:
                          ElevatedButton
                              .icon(
                        onPressed:
                            () {
                          _addToCart(
                            product,
                          );
                        },
                        icon:
                            const Icon(
                          Icons
                              .shopping_cart_outlined,
                          color:
                              Colors.black,
                          size: 19,
                        ),
                        label:
                            const Text(
                          'Add to Cart',
                          style:
                              TextStyle(
                            color:
                                Colors.black,
                            fontSize:
                                12,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              orange,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                          ),
                        ),
                      ),
                    ),
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
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: orange,
            size: 18,
          ),

          const SizedBox(
            width: 10,
          ),

          Text(
            '$title:',
            style:
                const TextStyle(
              color:
                  Colors.white38,
              fontSize: 10,
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow:
                  TextOverflow
                      .ellipsis,
              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize: 10,
                fontWeight:
                    FontWeight
                        .w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHAT
  // ============================================================

  void _openFarmerChat(
    ProductModel product,
  ) {
    if (product.farmerId
        .trim()
        .isEmpty) {
      _showSnackBar(
        'This product is not linked to a farmer account yet.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatScreen(
          product: product,
        ),
      ),
    );
  }

  // ============================================================
  // ADD TO CART
  // ============================================================

  Future<void> _addToCart(
    ProductModel product,
  ) async {
    try {
      final user =
          FirebaseAuth
              .instance
              .currentUser;

      if (user == null) {
        _showSnackBar(
          'Please login to add items to your cart.',
        );
        return;
      }

      final productId =
          product.id.trim();

      if (productId.isEmpty) {
        _showSnackBar(
          'Unable to add this product. Product ID is missing.',
        );
        return;
      }

      final cartItemRef =
          FirebaseFirestore
              .instance
              .collection(
                'carts',
              )
              .doc(user.uid)
              .collection(
                'items',
              )
              .doc(productId);

      final existing =
          await cartItemRef.get();

      if (existing.exists) {
        final existingData =
            existing.data() ??
                {};

        final currentQuantity =
            (existingData[
                        'quantity']
                    as num?)
                ?.toDouble() ??
            1.0;

        await cartItemRef.update({
          'quantity':
              currentQuantity + 1,
          'updatedAt':
              FieldValue
                  .serverTimestamp(),
        });
      } else {
        final resolvedImage =
            _resolveProductImage(
          product,
        );

        await cartItemRef.set({
          'productId':
              productId,
          'name':
              product.name,
          'farmerId':
              product.farmerId,
          'farmerName':
              product.farmerName,
          'location':
              product.location,
          'image':
              resolvedImage,
          'unit':
              product.unit,
          'quality':
              product.quality,
          'price':
              product.price,
          'quantity':
              1.0,
          'originalPrice':
              product.price,
          'fromNegotiation':
              false,
          'dealAccepted':
              false,
          'addedAt':
              FieldValue
                  .serverTimestamp(),
          'updatedAt':
              FieldValue
                  .serverTimestamp(),
        });
      }

      if (!mounted) return;

      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const CartScreen(),
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'ADD TO CART FIREBASE ERROR: '
        '${e.code} - ${e.message}',
      );

      if (!mounted) return;

      _showSnackBar(
        'Could not add to cart: '
        '${e.message ?? e.code}',
      );
    } catch (e) {
      debugPrint(
        'ADD TO CART ERROR: $e',
      );

      if (!mounted) return;

      _showSnackBar(
        'Something went wrong while adding to cart.',
      );
    }
  }

  // ============================================================
  // SORT SHEET
  // ============================================================

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: card,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(
              20,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  'Sort Products',
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

                _sortOption(
                  'Recommended',
                ),
                _sortOption(
                  'Newest',
                ),
                _sortOption(
                  'Price Low',
                ),
                _sortOption(
                  'Price High',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sortOption(
    String value,
  ) {
    final selected =
        _sortBy == value;

    return ListTile(
      contentPadding:
          EdgeInsets.zero,
      leading: Icon(
        selected
            ? Icons
                .radio_button_checked_rounded
            : Icons
                .radio_button_off_rounded,
        color: selected
            ? orange
            : Colors.white38,
      ),
      title: Text(
        value,
        style: TextStyle(
          color: selected
              ? orange
              : Colors.white70,
          fontSize: 13,
          fontWeight: selected
              ? FontWeight.w700
              : FontWeight.w400,
        ),
      ),
      onTap: () {
        setState(() {
          _sortBy = value;
        });

        Navigator.pop(context);
      },
    );
  }

  // ============================================================
  // FILTER SHEET
  // ============================================================

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: card,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(
              20,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  'Filter by Category',
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _categories.map(
                    (category) {
                      final name =
                          category[
                              'name'] as String;

                      final selected =
                          _selectedCategory ==
                              name;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory =
                                name;
                          });

                          Navigator.pop(
                            context,
                          );
                        },
                        child:
                            AnimatedContainer(
                          duration:
                              const Duration(
                            milliseconds:
                                150,
                          ),
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                13,
                            vertical: 9,
                          ),
                          decoration:
                              BoxDecoration(
                            color: selected
                                ? orange
                                    .withValues(
                                    alpha:
                                        0.15,
                                  )
                                : cardLight,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                            border:
                                Border.all(
                              color: selected
                                  ? orange
                                  : Colors
                                      .white
                                      .withValues(
                                      alpha:
                                          0.08,
                                    ),
                            ),
                          ),
                          child: Text(
                            name,
                            style:
                                TextStyle(
                              color: selected
                                  ? orange
                                  : Colors
                                      .white70,
                              fontSize:
                                  10,
                              fontWeight: selected
                                  ? FontWeight
                                      .w700
                                  : FontWeight
                                      .w400,
                            ),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),

                const SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyProducts() {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        20,
      ),
      padding:
          const EdgeInsets.symmetric(
        vertical: 55,
        horizontal: 25,
      ),
      decoration:
          BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: Colors.white
              .withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons
                .inventory_2_outlined,
            color:
                Colors.white24,
            size: 50,
          ),

          const SizedBox(
            height: 14,
          ),

          const Text(
            'No products found',
            style:
                TextStyle(
              color:
                  Colors.white70,
              fontSize: 16,
              fontWeight:
                  FontWeight
                      .w700,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            _searchText.isNotEmpty
                ? 'Try a different search.'
                : 'Farmers have not listed products in this category yet.',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Colors.white38,
              fontSize: 10,
              height: 1.4,
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory =
                    'All';
                _searchController
                    .clear();
              });
            },
            child:
                const Text(
              'Clear Filters',
              style:
                  TextStyle(
                color: orange,
                fontWeight:
                    FontWeight
                        .w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState(
    String error,
  ) {
    return Container(
      margin:
          const EdgeInsets.all(
        18,
      ),
      padding:
          const EdgeInsets.all(
        25,
      ),
      decoration:
          BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: orange,
            size: 40,
          ),

          const SizedBox(
            height: 10,
          ),

          const Text(
            'Unable to load products',
            style:
                TextStyle(
              color:
                  Colors.white,
              fontWeight:
                  FontWeight
                      .w700,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            error,
            maxLines: 3,
            overflow:
                TextOverflow.ellipsis,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Colors.white38,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BENEFITS
  // ============================================================

  Widget _buildBottomBenefits() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        5,
        18,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _benefitCard(
              Icons.eco_outlined,
              '100% Fresh',
              'Quality checked',
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: _benefitCard(
              Icons
                  .local_shipping_outlined,
              'Fast Delivery',
              'Above ₹499',
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: _benefitCard(
              Icons
                  .support_agent_rounded,
              'Chat',
              'With farmers',
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitCard(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      height: 90,
      padding:
          const EdgeInsets.all(
        10,
      ),
      decoration:
          BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: Colors.white
              .withValues(
            alpha: 0.07,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment
                .center,
        children: [
          Icon(
            icon,
            color: orange,
            size: 23,
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            title,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize: 8,
              fontWeight:
                  FontWeight
                      .w700,
            ),
          ),

          const SizedBox(
            height: 2,
          ),

          Text(
            subtitle,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              color:
                  Colors.white38,
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style:
              const TextStyle(
            fontSize: 11,
          ),
        ),
        backgroundColor:
            cardLight,
        behavior:
            SnackBarBehavior
                .floating,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),
      ),
    );
  }
}
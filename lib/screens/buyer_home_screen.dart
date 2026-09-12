import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/language_service.dart';
import '../widgets/language_switch_button.dart';
import 'role_screen.dart';
import 'buyer_auction_screen.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() =>
      _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange = Color(0xFFFF9800);
  static const Color background = Color(0xFF080A08);
  static const Color card = Color(0xFF151817);

  // ============================================================
  // PRODUCT SERVICE
  // ============================================================

  final ProductService _productService =
      ProductService();

  // ============================================================
  // CATEGORY
  // ============================================================

  String selectedCategory = "All";

  final List<Map<String, dynamic>> categories = [
    {
      "name": "Vegetables",
      "icon": "🥬",
      "value": "Vegetable",
    },
    {
      "name": "Fruits",
      "icon": "🍎",
      "value": "Fruit",
    },
    {
      "name": "Grains",
      "icon": "🌾",
      "value": "Grains",
    },
    {
      "name": "Spices",
      "icon": "🌶️",
      "value": "Spice",
    },
    {
      "name": "Oil Seeds",
      "icon": "🥜",
      "value": "Oil Seed",
    },
  ];

  @override
  void initState() {
    super.initState();
    LanguageService.currentLocaleNotifier.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LanguageService.currentLocaleNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // BuyerBottomNav handles:
      // Home | Market | Cart | Orders | Profile
      body: SafeArea(
        child: _buildHome(),
      ),
    );
  }

  // ============================================================
  // HOME
  // ============================================================

  Widget _buildHome() {
    return StreamBuilder<List<ProductModel>>(
      stream: _productService.getProducts(),
      builder: (context, snapshot) {
        // --------------------------------------------------------
        // LOADING
        // --------------------------------------------------------

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: orange,
            ),
          );
        }

        // --------------------------------------------------------
        // ERROR
        // --------------------------------------------------------

        if (snapshot.hasError) {
          return _buildErrorState(
            snapshot.error.toString(),
          );
        }

        // --------------------------------------------------------
        // PRODUCTS
        // --------------------------------------------------------

        List<ProductModel> products =
            snapshot.data ?? [];

        products = products
            .where(
              (product) => product.available,
            )
            .toList();

        // --------------------------------------------------------
        // CATEGORY FILTER
        // --------------------------------------------------------

        if (selectedCategory != "All") {
          products = products
              .where(
                (product) => _categoryMatches(
                  product.category,
                  selectedCategory,
                ),
              )
              .toList();
        }

        return RefreshIndicator(
          color: orange,
          backgroundColor: card,

          onRefresh: () async {
            setState(() {});

            await Future.delayed(
              const Duration(
                milliseconds: 400,
              ),
            );
          },

          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),

            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                12,
                18,
                30,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  // ==================================================
                  // HEADER
                  // ==================================================

                  _buildHeader(),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // SEARCH
                  // ==================================================

                  _buildSearchBar(),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // HERO
                  // ==================================================

                  _buildHeroBanner(),

                  const SizedBox(
                    height: 28,
                  ),

                  // ==================================================
                  // CATEGORY
                  // ==================================================

                  _buildSectionTitle(
                    "Shop by Category",
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  _buildCategories(),

                  const SizedBox(
                    height: 28,
                  ),

                  // ==================================================
                  // PRODUCTS
                  // ==================================================

                  _buildSectionTitle(
                    "Fresh Picks for You",
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  if (products.isEmpty)
                    _buildEmptyProducts()
                  else
                    _buildProductList(
                      products,
                    ),

                  const SizedBox(
                    height: 25,
                  ),

                  // ==================================================
                  // DELIVERY
                  // ==================================================

                  _buildDeliveryBanner(),

                  const SizedBox(
                    height: 15,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return SizedBox(
      height: 58,

      child: Row(
        children: [
          // --------------------------------------------------------
          // HAMBURGER
          // --------------------------------------------------------

          GestureDetector(
            onTap: _showMenu,

            child: Container(
              width: 48,
              height: 48,

              decoration: BoxDecoration(
                color: card,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: 0.08,
                  ),
                ),
              ),

              child: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
          ),

          const SizedBox(
            width: 9,
          ),

          // --------------------------------------------------------
          // KISANAI LOGO
          // --------------------------------------------------------

          Expanded(
            child: Row(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/kisan_logo.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.eco_rounded,
                      color: orange,
                      size: 31,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 6,
                ),

                Flexible(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [
                      const Text(
                        "KisanAI",
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,

                        style: TextStyle(
                          color: orange,
                          fontSize: 22,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),

                      Text(
                        tr("fresh_from_farms", defaultText: "Fresh from Farms"),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,

                        style: TextStyle(
                          color:
                              Colors.white
                                  .withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 4,
          ),

          // --------------------------------------------------------
          // LOCATION
          // --------------------------------------------------------

          Row(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              const Icon(
                Icons.location_on_rounded,
                color: orange,
                size: 19,
              ),

              const SizedBox(
                width: 2,
              ),

              Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: const [
                  Text(
                    "Coimbatore",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  Text(
                    "Tamil Nadu",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(
            width: 7,
          ),

          const LanguageSwitchButton(compact: true),

          const SizedBox(
            width: 7,
          ),

          // --------------------------------------------------------
          // NOTIFICATION
          // --------------------------------------------------------

          Stack(
            children: [
              const Icon(
                Icons
                    .notifications_none_rounded,
                color: Colors.white,
                size: 27,
              ),

              Positioned(
                right: 1,
                top: 0,

                child: Container(
                  width: 7,
                  height: 7,

                  decoration:
                      const BoxDecoration(
                    color: orange,
                    shape:
                        BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            width: 8,
          ),

          // --------------------------------------------------------
          // PROFILE
          // --------------------------------------------------------

          Container(
            width: 40,
            height: 40,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              border: Border.all(
                color: orange,
                width: 1.5,
              ),
            ),

            child: const CircleAvatar(
              backgroundColor:
                  Color(0xFF30352F),

              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 23,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HAMBURGER MENU
  // ============================================================

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: card,
      isScrollControlled: true,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),

      builder: (menuContext) {
        final screenHeight =
            MediaQuery.of(
          menuContext,
        ).size.height;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  screenHeight * 0.82,
            ),

            child: SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),

              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  20,
                ),

                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    // ==================================================
                    // HANDLE
                    // ==================================================

                    Container(
                      width: 45,
                      height: 4,

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white24,

                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // TITLE
                    // ==================================================

                    Align(
                      alignment:
                          Alignment.centerLeft,

                      child: Text(
                        tr("menu", defaultText: "Menu"),

                        style: const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 21,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==================================================
                    // AUCTIONS
                    // ==================================================

                    ListTile(
                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 4,
                      ),

                      leading: Container(
                        width: 42,
                        height: 42,

                        decoration:
                            BoxDecoration(
                          color:
                              orange.withValues(
                            alpha: 0.12,
                          ),

                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                        ),

                        child: const Icon(
                          Icons.gavel_rounded,
                          color: orange,
                          size: 22,
                        ),
                      ),

                      title: Text(
                        tr("auctions", defaultText: "Auctions"),

                        style: const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      subtitle:
                          Text(
                        tr("bid_fresh_products", defaultText: "Bid on fresh products"),

                        style: const TextStyle(
                          color:
                              Colors.white38,
                          fontSize: 10,
                        ),
                      ),

                      trailing:
                          const Icon(
                        Icons
                            .arrow_forward_ios_rounded,
                        color:
                            Colors.white30,
                        size: 15,
                      ),

                      onTap: () {
                        Navigator.pop(
                          menuContext,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const BuyerAuctionScreen(),
                          ),
                        );
                      },
                    ),

                    // ==================================================
                    // CHAT
                    // ==================================================

                    _menuItem(
                      Icons
                          .chat_bubble_outline_rounded,
                      "Chat with Farmers",
                    ),

                    // ==================================================
                    // FAVORITES
                    // ==================================================

                    _menuItem(
                      Icons
                          .favorite_border_rounded,
                      "Favorites",
                    ),

                    // ==================================================
                    // TODAY'S DEALS
                    // ==================================================

                    _menuItem(
                      Icons
                          .local_offer_outlined,
                      "Today's Deals",
                    ),

                    // ==================================================
                    // LOCATION
                    // ==================================================

                    _menuItem(
                      Icons
                          .location_on_outlined,
                      "Change Location",
                    ),

                    // ==================================================
                    // HELP
                    // ==================================================

                    _menuItem(
                      Icons
                          .help_outline_rounded,
                      "Help & Support",
                    ),

                    // ==================================================
                    // SETTINGS
                    // ==================================================

                    _menuItem(
                      Icons.settings_outlined,
                      "Settings",
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    const Divider(
                      color:
                          Colors.white12,
                      height: 20,
                    ),

                    // ==================================================
                    // LOGOUT
                    // ==================================================

                    ListTile(
                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 4,
                      ),

                      leading: Container(
                        width: 42,
                        height: 42,

                        decoration:
                            BoxDecoration(
                          color:
                              Colors.redAccent
                                  .withValues(
                            alpha: 0.10,
                          ),

                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                        ),

                        child: const Icon(
                          Icons
                              .logout_rounded,
                          color:
                              Colors.redAccent,
                          size: 22,
                        ),
                      ),

                      title: Text(
                        tr("logout", defaultText: "Logout"),

                        style: const TextStyle(
                          color:
                              Colors.redAccent,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      subtitle:
                          Text(
                        tr("logout_subtitle", defaultText: "Sign out of your account"),

                        style: const TextStyle(
                          color:
                              Colors.white30,
                          fontSize: 10,
                        ),
                      ),

                      trailing:
                          const Icon(
                        Icons
                            .arrow_forward_ios_rounded,
                        color:
                            Colors.white30,
                        size: 15,
                      ),

                      onTap: () {
                        Navigator.pop(
                          menuContext,
                        );

                        _showLogoutDialog();
                      },
                    ),

                    const SizedBox(
                      height: 5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MENU ITEM
  // ============================================================

  Widget _menuItem(
    IconData icon,
    String title,
  ) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 4,
      ),

      leading: Container(
        width: 42,
        height: 42,

        decoration: BoxDecoration(
          color: orange.withValues(
            alpha: 0.12,
          ),

          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),

        child: Icon(
          icon,
          color: orange,
          size: 22,
        ),
      ),

      title: Text(
        tr(title),

        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight:
              FontWeight.w600,
        ),
      ),

      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.white30,
        size: 15,
      ),

      onTap: () {
        Navigator.pop(context);
      },
    );
  }

  // ============================================================
  // LOGOUT DIALOG
  // ============================================================

  void _showLogoutDialog() {
    showDialog(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: card,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),

          title: Text(
            tr("logout_dialog_title", defaultText: "Logout?"),

            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          content: Text(
            tr("logout_dialog_msg", defaultText: "Are you sure you want to logout from KisanAI?"),

            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              height: 1.4,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },

              child: Text(
                tr("cancel", defaultText: "Cancel"),

                style: const TextStyle(
                  color:
                      Colors.white54,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                _logout();
              },

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.redAccent,
                foregroundColor:
                    Colors.white,
                elevation: 0,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),

              child:
                  Text(
                tr("logout", defaultText: "Logout"),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance
          .signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,

        MaterialPageRoute(
          builder: (_) =>
              const RoleScreen(),
        ),

        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: const Text(
            "Unable to logout. Please try again.",
          ),

          backgroundColor: card,

          behavior:
              SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Container(
      height: 58,

      decoration:
          BoxDecoration(
        color: card,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border: Border.all(
          color: orange.withValues(
            alpha: 0.18,
          ),
        ),
      ),

      child: Row(
        children: [
          const SizedBox(
            width: 16,
          ),

          const Icon(
            Icons.search_rounded,
            color: Colors.white54,
            size: 29,
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: TextField(
              style: const TextStyle(
                color: Colors.white,
              ),

              decoration:
                  InputDecoration(
                border:
                    InputBorder.none,

                hintText:
                    tr("search_placeholder", defaultText: "Search fruits, vegetables..."),

                hintStyle:
                    const TextStyle(
                  color:
                      Colors.white54,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          Container(
            width: 46,
            height: 46,

            margin:
                const EdgeInsets.only(
              right: 5,
            ),

            decoration:
                BoxDecoration(
              color:
                  orange.withValues(
                alpha: 0.12,
              ),

              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),

            child: const Icon(
              Icons.tune_rounded,
              color: orange,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO BANNER
  // ============================================================

  Widget _buildHeroBanner() {
    return Container(
      height: 220,
      width: double.infinity,

      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          25,
        ),

        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF321600),
            Color(0xFF6A3000),
          ],

          begin:
              Alignment.centerLeft,

          end:
              Alignment.centerRight,
        ),

        border: Border.all(
          color: orange.withValues(
            alpha: 0.25,
          ),
        ),
      ),

      child: Stack(
        children: [
          // ------------------------------------------------------
          // VEGETABLE CIRCLE
          // ------------------------------------------------------

          Positioned(
            right: -30,
            top: 12,

            child: Container(
              width: 185,
              height: 185,

              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,

                color:
                    orange.withValues(
                  alpha: 0.12,
                ),
              ),

              child:
                  const Center(
                child: Text(
                  "🥕🍅🥦",
                  style:
                      TextStyle(
                    fontSize: 50,
                  ),
                ),
              ),
            ),
          ),

          // ------------------------------------------------------
          // CONTENT
          // ------------------------------------------------------

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              16,
            ),

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  tr("eat_fresh", defaultText: "Eat Fresh,"),

                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 26,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                Text(
                  tr("stay_healthy", defaultText: "Stay Healthy"),

                  style:
                      const TextStyle(
                    color: orange,
                    fontSize: 26,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  tr("hero_subtitle", defaultText: "Handpicked produce\ndirectly from farmers 🌱"),

                  style:
                      const TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 14,
                    height: 1.25,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                SizedBox(
                  height: 38,

                  child:
                      ElevatedButton(
                    onPressed: () {},

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          orange,

                      foregroundColor:
                          Colors.white,

                      elevation: 0,

                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 16,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          11,
                        ),
                      ),
                    ),

                    child:
                        Row(
                      mainAxisSize:
                          MainAxisSize.min,

                      children: [
                        Text(
                          tr("shop_now", defaultText: "Shop Now"),

                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(
                          width: 6,
                        ),

                        const Icon(
                          Icons
                              .arrow_forward_rounded,
                          size: 17,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------
          // SLIDER DOTS
          // ------------------------------------------------------

          Positioned(
            right: 18,
            top: 15,

            child: Row(
              children: [
                _dot(true),
                _dot(false),
                _dot(false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(
    bool active,
  ) {
    return Container(
      width:
          active ? 23 : 8,
      height: 8,

      margin:
          const EdgeInsets.only(
        left: 6,
      ),

      decoration:
          BoxDecoration(
        color: active
            ? Colors.white
            : Colors.white38,

        borderRadius:
            BorderRadius.circular(
          10,
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title, {
    bool showSeeAll = true,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            tr(title),

            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),

        if (showSeeAll)
          Row(
            children: [
              Text(
                tr("see_all", defaultText: "See All"),

                style:
                    const TextStyle(
                  color: orange,
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                width: 4,
              ),

              const Icon(
                Icons
                    .arrow_forward_ios_rounded,
                color: orange,
                size: 13,
              ),
            ],
          ),
      ],
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Widget _buildCategories() {
    return SizedBox(
      height: 130,

      child:
          ListView.separated(
        scrollDirection:
            Axis.horizontal,

        itemCount:
            categories.length,

        separatorBuilder:
            (_, __) =>
                const SizedBox(
          width: 15,
        ),

        itemBuilder:
            (context, index) {
          final category =
              categories[index];

          final bool selected =
              selectedCategory ==
                  category["value"];

          return GestureDetector(
            onTap: () {
              setState(() {
                if (selected) {
                  selectedCategory =
                      "All";
                } else {
                  selectedCategory =
                      category[
                          "value"];
                }
              });
            },

            child: SizedBox(
              width: 90,

              child: Column(
                children: [
                  Container(
                    width: 78,
                    height: 78,

                    decoration:
                        BoxDecoration(
                      shape:
                          BoxShape.circle,

                      color: selected
                          ? orange.withValues(
                              alpha:
                                  0.18,
                            )
                          : card,

                      border:
                          Border.all(
                        color: selected
                            ? orange
                            : orange
                                .withValues(
                                alpha:
                                    0.20,
                              ),

                        width: selected
                            ? 2
                            : 1,
                      ),
                    ),

                    child:
                        Center(
                      child: Text(
                        category[
                                "icon"]
                            as String,

                        style:
                            const TextStyle(
                          fontSize:
                              38,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    tr(category["name"] as String),

                    textAlign:
                        TextAlign.center,

                    maxLines: 2,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        TextStyle(
                      color: selected
                          ? orange
                          : Colors
                              .white,

                      fontSize: 11,

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // PRODUCT LIST
  // ============================================================

  Widget _buildProductList(
    List<ProductModel> products,
  ) {
    return SizedBox(
      height: 320,

      child:
          ListView.separated(
        scrollDirection:
            Axis.horizontal,

        itemCount:
            products.length,

        separatorBuilder:
            (_, __) =>
                const SizedBox(
          width: 14,
        ),

        itemBuilder:
            (context, index) {
          return _buildProductCard(
            products[index],
          );
        },
      ),
    );
  }

  // ============================================================
  // PRODUCT CARD
  // ============================================================

  Widget _buildProductCard(
    ProductModel product,
  ) {
    return Container(
      width: 225,

      decoration:
          BoxDecoration(
        color: card,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border: Border.all(
          color:
              Colors.white.withValues(
            alpha: 0.08,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ------------------------------------------------------
          // IMAGE
          // ------------------------------------------------------

          Stack(
            children: [
              Container(
                height: 140,
                width:
                    double.infinity,

                decoration:
                    BoxDecoration(
                  borderRadius:
                      const BorderRadius
                          .vertical(
                    top:
                        Radius.circular(
                      20,
                    ),
                  ),

                  gradient:
                      LinearGradient(
                    colors: [
                      orange.withValues(
                        alpha:
                            0.20,
                      ),

                      const Color(
                        0xFF242424,
                      ),
                    ],
                  ),
                ),

                child:
                    _buildProductImage(
                  product,
                ),
              ),

              // TAG

              Positioned(
                left: 10,
                top: 10,

                child: Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),

                  decoration:
                      BoxDecoration(
                    color: orange,

                    borderRadius:
                        BorderRadius
                            .circular(
                      7,
                    ),
                  ),

                  child:
                      Text(
                    _getProductTag(
                      product,
                    ),

                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 9,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ),
              ),

              // FAVORITE

              Positioned(
                right: 10,
                top: 10,

                child: Container(
                  width: 35,
                  height: 35,

                  decoration:
                      BoxDecoration(
                    color: Colors.black
                        .withValues(
                      alpha: 0.45,
                    ),

                    shape:
                        BoxShape.circle,
                  ),

                  child:
                      const Icon(
                    Icons
                        .favorite_border_rounded,
                    color:
                        Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          // ------------------------------------------------------
          // DETAILS
          // ------------------------------------------------------

          Padding(
            padding:
                const EdgeInsets
                    .fromLTRB(
              12,
              10,
              10,
              10,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Text(
                  tr(product.name),

                  maxLines: 1,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  _formatPrice(
                    product.price,
                    product.unit,
                  ),

                  style:
                      const TextStyle(
                    color: orange,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Row(
                  children: [
                    const Icon(
                      Icons
                          .location_on_rounded,
                      color:
                          Colors.white54,
                      size: 14,
                    ),

                    const SizedBox(
                      width: 3,
                    ),

                    Expanded(
                      child: Text(
                        product.location
                                .isEmpty
                            ? "Coimbatore"
                            : product
                                .location,

                        maxLines: 1,

                        overflow:
                            TextOverflow
                                .ellipsis,

                        style:
                            const TextStyle(
                          color:
                              Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 4,
                ),

                Row(
                  children: [
                    const Icon(
                      Icons
                          .person_outline,
                      color:
                          Colors.white54,
                      size: 14,
                    ),

                    const SizedBox(
                      width: 3,
                    ),

                    Expanded(
                      child:
                          Text(
                        product
                            .farmerName,

                        maxLines: 1,

                        overflow:
                            TextOverflow
                                .ellipsis,

                        style:
                            const TextStyle(
                          color:
                              Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 5,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          Text(
                        "${tr('available_label', defaultText: 'Available: ')}"
                        "${product.quantity} "
                        "${product.unit}",

                        maxLines: 1,

                        overflow:
                            TextOverflow
                                .ellipsis,

                        style:
                            const TextStyle(
                          color:
                              Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ),

                    Container(
                      width: 38,
                      height: 38,

                      decoration:
                          const BoxDecoration(
                        color: orange,
                        shape:
                            BoxShape.circle,
                      ),

                      child:
                          const Icon(
                        Icons
                            .add_rounded,
                        color:
                            Colors.white,
                        size: 25,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _buildProductImage(
    ProductModel product,
  ) {
    if (product.image.isNotEmpty) {
      return ClipRRect(
        borderRadius:
            const BorderRadius
                .vertical(
          top:
              Radius.circular(
            20,
          ),
        ),

        child:
            Image.network(
          product.image,

          width:
              double.infinity,

          height: 140,

          fit: BoxFit.cover,

          errorBuilder:
              (
            context,
            error,
            stackTrace,
          ) {
            return _emojiImage(
              product.name,
            );
          },
        ),
      );
    }

    return _emojiImage(
      product.name,
    );
  }

  // ============================================================
  // EMOJI FALLBACK
  // ============================================================

  Widget _emojiImage(
    String name,
  ) {
    return Center(
      child: Text(
        _getEmoji(name),

        style:
            const TextStyle(
          fontSize: 70,
        ),
      ),
    );
  }

  String _getEmoji(
    String name,
  ) {
    final value =
        name.toLowerCase();

    if (value.contains("tomato")) {
      return "🍅";
    }

    if (value.contains("potato")) {
      return "🥔";
    }

    if (value.contains("onion")) {
      return "🧅";
    }

    if (value.contains("carrot")) {
      return "🥕";
    }

    if (value.contains("bean")) {
      return "🫛";
    }

    if (value.contains("chilli") ||
        value.contains("chili")) {
      return "🌶️";
    }

    if (value.contains("cabbage")) {
      return "🥬";
    }

    if (value.contains("cauliflower")) {
      return "🥦";
    }

    if (value.contains("brinjal") ||
        value.contains("eggplant")) {
      return "🍆";
    }

    if (value.contains("banana")) {
      return "🍌";
    }

    if (value.contains("mango")) {
      return "🥭";
    }

    if (value.contains("apple")) {
      return "🍎";
    }

    if (value.contains("orange")) {
      return "🍊";
    }

    if (value.contains("coconut")) {
      return "🥥";
    }

    if (value.contains("rice") ||
        value.contains("wheat")) {
      return "🌾";
    }

    if (value.contains("groundnut")) {
      return "🥜";
    }

    if (value.contains("cotton")) {
      return "🌱";
    }

    if (value.contains("sugarcane")) {
      return "🌿";
    }

    return "🌱";
  }

  // ============================================================
  // PRICE
  // ============================================================

  String _formatPrice(
    double price,
    String unit,
  ) {
    final String formatted =
        price % 1 == 0
            ? price.toStringAsFixed(0)
            : price.toStringAsFixed(2);

    return "₹$formatted / $unit";
  }

  // ============================================================
  // PRODUCT TAG
  // ============================================================

  String _getProductTag(
    ProductModel product,
  ) {
    if (product.organic) {
      return "ORGANIC";
    }

    return "FRESH";
  }

  // ============================================================
  // CATEGORY MATCH
  // ============================================================

  bool _categoryMatches(
    String productCategory,
    String selected,
  ) {
    final product =
        productCategory.toLowerCase();

    final target =
        selected.toLowerCase();

    if (product == target) {
      return true;
    }

    if (target == "grains" &&
        (product.contains("grain") ||
            product.contains("pulse"))) {
      return true;
    }

    if (target == "vegetable" &&
        product.contains("vegetable")) {
      return true;
    }

    if (target == "fruit" &&
        product.contains("fruit")) {
      return true;
    }

    if (target == "spice" &&
        product.contains("spice")) {
      return true;
    }

    if (target == "oil seed" &&
        (product.contains("oil") ||
            product.contains("seed"))) {
      return true;
    }

    return false;
  }

  // ============================================================
  // EMPTY PRODUCTS
  // ============================================================

  Widget _buildEmptyProducts() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.symmetric(
        vertical: 40,
        horizontal: 20,
      ),

      decoration:
          BoxDecoration(
        color: card,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border: Border.all(
          color:
              Colors.white.withValues(
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
                Colors.white30,
            size: 48,
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            selectedCategory == "All"
                ? tr("no_fresh_products", defaultText: "No fresh products available")
                : tr("no_products_category", defaultText: "No products in this category"),

            style:
                const TextStyle(
              color:
                  Colors.white70,
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            selectedCategory == "All"
                ? tr("farmers_not_listed", defaultText: "Farmers haven't listed any available products yet.")
                : tr("try_another_category", defaultText: "Try selecting another category."),

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              color:
                  Colors.white38,
              fontSize: 12,
            ),
          ),

          if (selectedCategory !=
              "All") ...[
            const SizedBox(
              height: 12,
            ),

            TextButton(
              onPressed: () {
                setState(() {
                  selectedCategory =
                      "All";
                });
              },

              child:
                  Text(
                tr("view_all_products", defaultText: "View All Products"),

                style:
                    const TextStyle(
                  color: orange,
                ),
              ),
            ),
          ],
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
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          25,
        ),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.error_outline,
              color: orange,
              size: 50,
            ),

            const SizedBox(
              height: 15,
            ),

            Text(
              tr("unable_to_load", defaultText: "Unable to load products"),

              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              error,

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                color:
                    Colors.white54,
                fontSize: 12,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {});
              },

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    orange,

                foregroundColor:
                    Colors.white,
              ),

              child:
                  Text(
                tr("retry", defaultText: "Retry"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DELIVERY BANNER
  // ============================================================

  Widget _buildDeliveryBanner() {
    return Container(
      height: 88,
      width: double.infinity,

      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          20,
        ),

        gradient:
            LinearGradient(
          colors: [
            const Color(
              0xFF3A1D00,
            ),

            orange.withValues(
              alpha: 0.22,
            ),
          ],
        ),

        border: Border.all(
          color:
              orange.withValues(
            alpha: 0.20,
          ),
        ),
      ),

      child: Row(
        children: [
          const SizedBox(
            width: 14,
          ),

          Container(
            width: 57,
            height: 57,

            decoration:
                const BoxDecoration(
              color: orange,
              shape:
                  BoxShape.circle,
            ),

            child: ClipOval(
              child: Image.asset(
                'assets/images/kisan_logo.png',
                width: 57,
                height: 57,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.eco_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,

              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Text(
                  tr("free_delivery_banner", defaultText: "Free Delivery above ₹499"),

                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  tr("free_delivery_desc", defaultText: "Support farmers. Eat fresh."),

                  style:
                      const TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const Text(
            "🛵",

            style:
                TextStyle(
              fontSize: 38,
            ),
          ),

          const SizedBox(
            width: 12,
          ),
        ],
      ),
    );
  }
}
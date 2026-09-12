import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/colors.dart';

// ============================================================
// FARMER SCREENS
// ============================================================

import '../screens/home_screen.dart';
import '../screens/sell_screen.dart';
import '../screens/farmer_orders_screen.dart';
import '../screens/farmer_chats_screen.dart';
import '../screens/auction_screen.dart';
import '../services/language_service.dart';

// ============================================================
// FARMER BOTTOM NAVIGATION
// ============================================================

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({
    super.key,
  });

  @override
  State<BottomNavScreen> createState() =>
      _BottomNavScreenState();
}

class _BottomNavScreenState
    extends State<BottomNavScreen> {

  // ============================================================
  // SELECTED TAB
  // ============================================================

  int _selectedIndex = 0;

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
  // COLORS
  // ============================================================

  static const Color background =
      Color(0xFF080A09);

  static const Color navBackground =
      Color(0xFF101211);

  static const Color inactive =
      Color(0xFF8A908B);

  static const Color borderColor =
      Color(0xFF292E2A);

  // ============================================================
  // PAGES
  // ============================================================

  // 0 → Home
  // 1 → Products
  // 2 → Orders
  // 3 → Auction
  // 4 → Messages
  //
  // IMPORTANT:
  // Profile is NOT included here.
  //
  // Products uses a separate SellScreen navigation.
  // ============================================================

  final List<Widget> _pages = const [
    // INDEX 0
    HomeScreen(),

    // INDEX 1
    // Products opens SellScreen separately.
    SizedBox(),

    // INDEX 2
    FarmerOrdersScreen(),

    // INDEX 3
    AuctionScreen(),

    // INDEX 4
    FarmerChatsScreen(),
  ];

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // ========================================================
      // PAGE CONTENT
      // ========================================================

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBar:
          _buildBottomNavigation(),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: navBackground,

        border: const Border(
          top: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),

      child: SafeArea(
        top: false,

        child: SizedBox(
          height: 72,

          child: Row(
            children: [

              // =================================================
              // HOME
              // =================================================

              Expanded(
                child: _buildNavItem(
                  icon: Icons.home_rounded,
                  label: tr('nav_home'),
                  index: 0,
                ),
              ),

              // =================================================
              // PRODUCTS
              // =================================================

              Expanded(
                child: _buildNavItem(
                  icon: Icons.agriculture_rounded,
                  label: tr('nav_products'),
                  index: 1,
                ),
              ),

              // =================================================
              // ORDERS
              // =================================================

              Expanded(
                child: _buildOrdersNavItem(),
              ),

              // =================================================
              // AUCTION
              // =================================================

              Expanded(
                child: _buildNavItem(
                  icon: Icons.gavel_rounded,
                  label: tr('nav_auction'),
                  index: 3,
                ),
              ),

              // =================================================
              // MESSAGES
              // =================================================

              Expanded(
                child: _buildMessagesNavItem(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ORDERS NAV ITEM
  // ============================================================

  Widget _buildOrdersNavItem() {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    // ==========================================================
    // USER NOT LOGGED IN
    // ==========================================================

    if (currentUser == null) {
      return _buildNavItem(
        icon: Icons.assignment_rounded,
        label: tr('nav_orders'),
        index: 2,
        badge: 0,
      );
    }

    // ==========================================================
    // LIVE FIRESTORE ORDER COUNT
    // ==========================================================

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where(
            'farmerId',
            isEqualTo: currentUser.uid,
          )
          .where(
            'orderStatus',
            isEqualTo: 'Placed',
          )
          .snapshots(),

      builder: (
        context,
        snapshot,
      ) {
        int orderCount = 0;

        // ======================================================
        // COUNT ORDERS
        // ======================================================

        if (snapshot.hasData) {
          orderCount =
              snapshot.data!.docs.length;
        }

        // ======================================================
        // ORDERS NAV ITEM
        // ======================================================

        return _buildNavItem(
          icon: Icons.assignment_rounded,
          label: tr('nav_orders'),
          index: 2,
          badge: orderCount,
        );
      },
    );
  }

  // ============================================================
  // MESSAGES NAV ITEM
  // ============================================================

  Widget _buildMessagesNavItem() {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    // ==========================================================
    // USER NOT LOGGED IN
    // ==========================================================

    if (currentUser == null) {
      return _buildNavItem(
        icon: Icons.chat_bubble_outline_rounded,
        label: tr('nav_messages'),
        index: 4,
        badge: 0,
      );
    }

    // ==========================================================
    // MESSAGES
    //
    // Currently no hardcoded notification count.
    //
    // Later we can connect this badge to Firestore unread
    // messages.
    // ==========================================================

    return _buildNavItem(
      icon: Icons.chat_bubble_outline_rounded,
      label: tr('nav_messages'),
      index: 4,
      badge: 0,
    );
  }

  // ============================================================
  // NAVIGATION ITEM
  // ============================================================

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    int badge = 0,
  }) {
    final bool selected =
        _selectedIndex == index;

    return InkWell(
      borderRadius:
          BorderRadius.circular(20),

      // ========================================================
      // TAP
      // ========================================================

      onTap: () {

        // ======================================================
        // PRODUCTS → SELL SCREEN
        // ======================================================

        if (index == 1) {
          Navigator.push(
            context,

            MaterialPageRoute(
              builder: (_) =>
                  const SellScreen(),
            ),
          );

          return;
        }

        // ======================================================
        // NORMAL NAVIGATION
        // ======================================================

        setState(() {
          _selectedIndex = index;
        });
      },

      splashColor:
          AppColors.primary.withAlpha(20),

      highlightColor:
          AppColors.primary.withAlpha(10),

      child: SizedBox(
        height: 72,

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            // ==================================================
            // ICON + BADGE
            // ==================================================

            Stack(
              clipBehavior:
                  Clip.none,

              children: [

                // =================================================
                // ICON
                // =================================================

                Icon(
                  icon,
                  size: 27,
                  color: selected
                      ? AppColors.primary
                      : inactive,
                ),

                // =================================================
                // RED BADGE
                // =================================================

                if (badge > 0)
                  Positioned(
                    right: -9,
                    top: -8,

                    child: Container(
                      constraints:
                          const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),

                      alignment:
                          Alignment.center,

                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),

                      decoration:
                          const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),

                      child: Text(
                        badge > 99
                            ? '99+'
                            : '$badge',

                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(
              height: 5,
            ),

            // ==================================================
            // LABEL
            // ==================================================

            Text(
              label,

              maxLines: 1,

              overflow:
                  TextOverflow.ellipsis,

              style:
                  TextStyle(
                fontSize: 11,

                fontWeight:
                    selected
                        ? FontWeight.w600
                        : FontWeight.w400,

                color:
                    selected
                        ? AppColors.primary
                        : inactive,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            // ==================================================
            // ACTIVE GREEN LINE
            // ==================================================

            AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 180,
              ),

              curve:
                  Curves.easeOut,

              width:
                  selected
                      ? 34
                      : 0,

              height: 3,

              decoration:
                  BoxDecoration(
                color:
                    AppColors.primary,

                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
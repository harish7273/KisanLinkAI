import 'package:flutter/material.dart';

// ============================================================
// SCREENS
// ============================================================

import '../screens/home_screen.dart';
import '../screens/sell_screen.dart';
import '../screens/farmer_orders_screen.dart';
import '../screens/farmer_chats_screen.dart';
import '../screens/farmer_profile_screen.dart';

// ============================================================
// FARMER BOTTOM NAVIGATION
// ============================================================

class FarmerBottomNav extends StatefulWidget {
  const FarmerBottomNav({
    super.key,
  });

  @override
  State<FarmerBottomNav> createState() =>
      _FarmerBottomNavState();
}

class _FarmerBottomNavState
    extends State<FarmerBottomNav> {

  // ============================================================
  // COLORS
  // ============================================================

  static const Color background =
      Color(0xFF080A09);

  static const Color navBackground =
      Color(0xFF0D120E);

  static const Color green =
      Color(0xFF65D83F);

  static const Color inactive =
      Color(0xFF777D78);

  // ============================================================
  // SELECTED TAB
  // ============================================================

  int selectedIndex = 0;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // ========================================================
      // CURRENT SCREEN
      // ========================================================

      body: IndexedStack(
        index: selectedIndex,

        children: const [

          // ----------------------------------------------------
          // 0 - HOME
          // ----------------------------------------------------

          HomeScreen(),

          // ----------------------------------------------------
          // 1 - PRODUCTS
          // ----------------------------------------------------
          // Products tab now opens SellScreen
          // ----------------------------------------------------

          SellScreen(),

          // ----------------------------------------------------
          // 2 - ORDERS
          // ----------------------------------------------------

          FarmerOrdersScreen(),

          // ----------------------------------------------------
          // 3 - MESSAGES
          // ----------------------------------------------------

          FarmerChatsScreen(),

          // ----------------------------------------------------
          // 4 - PROFILE
          // ----------------------------------------------------

          FarmerProfileScreen(),
        ],
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBar: SafeArea(
        top: false,

        child: Container(
          height: 76,

          decoration: const BoxDecoration(
            color: navBackground,

            border: Border(
              top: BorderSide(
                color: Color(0xFF202720),
                width: 1,
              ),
            ),
          ),

          child: Row(
            children: [

              // ==================================================
              // HOME
              // ==================================================

              _navItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
              ),

              // ==================================================
              // PRODUCTS
              // ==================================================

              _navItem(
                index: 1,
                icon: Icons.inventory_2_rounded,
                label: 'Products',
              ),

              // ==================================================
              // ORDERS
              // ==================================================

              _navItem(
                index: 2,
                icon: Icons.shopping_bag_rounded,
                label: 'Orders',
              ),

              // ==================================================
              // MESSAGES
              // ==================================================

              _navItem(
                index: 3,
                icon: Icons.chat_bubble_rounded,
                label: 'Messages',
              ),

              // ==================================================
              // PROFILE
              // ==================================================

              _navItem(
                index: 4,
                icon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NAVIGATION ITEM
  // ============================================================

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected =
        selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        onTap: () {
          if (selectedIndex == index) {
            return;
          }

          setState(() {
            selectedIndex = index;
          });
        },

        child: SizedBox(
          height: 70,

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              // ==================================================
              // ICON
              // ==================================================

              AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 180,
                ),

                curve:
                    Curves.easeOut,

                width:
                    isSelected ? 42 : 38,

                height:
                    isSelected ? 32 : 30,

                decoration:
                    BoxDecoration(
                  color: isSelected
                      ? green.withOpacity(.12)
                      : Colors.transparent,

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                child: Icon(
                  icon,

                  color: isSelected
                      ? green
                      : inactive,

                  size:
                      isSelected ? 22 : 21,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              // ==================================================
              // LABEL
              // ==================================================

              Text(
                label,

                maxLines: 1,

                overflow:
                    TextOverflow.ellipsis,

                style: TextStyle(
                  color: isSelected
                      ? green
                      : inactive,

                  fontSize: 9,

                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
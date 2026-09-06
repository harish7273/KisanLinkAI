import 'package:flutter/material.dart';

import '../screens/farmer_orders_screen.dart';
import '../screens/farmer_products_screen.dart';
import '../screens/farmer_profile_screen.dart';
import '../screens/home_screen.dart';

class FarmerBottomNav extends StatefulWidget {
  const FarmerBottomNav({super.key});

  @override
  State<FarmerBottomNav> createState() =>
      _FarmerBottomNavState();
}

class _FarmerBottomNavState
    extends State<FarmerBottomNav> {

  // ============================================================
  // CURRENT SCREEN
  // ============================================================

  int selectedIndex = 0;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color background =
      Color(0xFF080A09);

  static const Color navBackground =
      Color(0xFF101211);

  static const Color green =
      Color(0xFF65D83F);

  static const Color inactive =
      Color(0xFF8A908B);

  static const Color borderColor =
      Color(0xFF292E2A);

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // ========================================================
      // PAGE
      // ========================================================

      body: _buildCurrentPage(),

      // ========================================================
      // NAVIGATION
      // ========================================================

      bottomNavigationBar:
          _buildBottomNavigation(),
    );
  }

  // ============================================================
  // CURRENT PAGE
  // ============================================================

  Widget _buildCurrentPage() {

    switch (selectedIndex) {

      // --------------------------------------------------------
      // HOME
      // --------------------------------------------------------

      case 0:
        return const HomeScreen();

      // --------------------------------------------------------
      // PRODUCTS
      // --------------------------------------------------------

      case 1:
        return const FarmerProductsScreen();

      // --------------------------------------------------------
      // ORDERS
      // --------------------------------------------------------

      case 2:
        return const FarmerOrdersScreen();

      // --------------------------------------------------------
      // MESSAGES
      // --------------------------------------------------------

      case 3:
        return const FarmerMessagesScreen();

      // --------------------------------------------------------
      // PROFILE
      // --------------------------------------------------------

      case 4:
        return const FarmerProfileScreen();

      // --------------------------------------------------------
      // DEFAULT
      // --------------------------------------------------------

      default:
        return const HomeScreen();
    }
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
            color:
                Colors.black.withAlpha(110),
            blurRadius: 18,
            offset:
                const Offset(0, -5),
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

              _navItem(
                icon:
                    Icons.home_rounded,

                label:
                    'Home',

                index: 0,
              ),

              // =================================================
              // PRODUCTS
              // =================================================

              _navItem(
                icon:
                    Icons.shopping_basket_outlined,

                label:
                    'Products',

                index: 1,
              ),

              // =================================================
              // ORDERS
              // =================================================

              _navItem(
                icon:
                    Icons.assignment_rounded,

                label:
                    'Orders',

                index: 2,

                badge: 0,
              ),

              // =================================================
              // MESSAGES
              // =================================================

              _navItem(
                icon:
                    Icons.chat_bubble_outline_rounded,

                label:
                    'Messages',

                index: 3,

                badge: 0,
              ),

              // =================================================
              // PROFILE
              // =================================================

              _navItem(
                icon:
                    Icons.person_outline_rounded,

                label:
                    'Profile',

                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NAV ITEM
  // ============================================================

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
    int badge = 0,
  }) {

    final bool selected =
        selectedIndex == index;

    return Expanded(
      child: InkWell(

        onTap: () {

          // IMPORTANT:
          // Directly change selectedIndex.

          setState(() {
            selectedIndex = index;
          });

          debugPrint(
            'FARMER NAV -> $label -> INDEX $index',
          );
        },

        splashColor:
            green.withAlpha(20),

        highlightColor:
            green.withAlpha(10),

        child: SizedBox(
          height: 72,

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              // =================================================
              // ICON
              // =================================================

              Stack(
                clipBehavior:
                    Clip.none,

                children: [

                  Icon(
                    icon,

                    size: 28,

                    color: selected
                        ? green
                        : inactive,
                  ),

                  // =================================================
                  // BADGE
                  // =================================================

                  if (badge > 0)
                    Positioned(
                      right: -10,
                      top: -8,

                      child:
                          Container(
                        constraints:
                            const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),

                        alignment:
                            Alignment.center,

                        decoration:
                            const BoxDecoration(
                          color:
                              Colors.red,

                          shape:
                              BoxShape.circle,
                        ),

                        child:
                            Text(
                          badge > 99
                              ? '99+'
                              : '$badge',

                          style:
                              const TextStyle(
                            color:
                                Colors.white,

                            fontSize:
                                10,

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

              // =================================================
              // LABEL
              // =================================================

              Text(
                label,

                style:
                    TextStyle(
                  color: selected
                      ? green
                      : inactive,

                  fontSize: 11,

                  fontWeight:
                      selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              // =================================================
              // ACTIVE LINE
              // =================================================

              AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 180,
                ),

                width:
                    selected ? 34 : 0,

                height: 3,

                decoration:
                    BoxDecoration(
                  color: green,

                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// MESSAGES SCREEN
// ================================================================

class FarmerMessagesScreen
    extends StatelessWidget {

  const FarmerMessagesScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF080A09),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF06150C),

        elevation: 0,

        title:
            const Text(
          'Messages',

          style: TextStyle(
            color:
                Colors.white,

            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Container(
              width: 80,
              height: 80,

              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFF65D83F,
                ).withAlpha(20),

                shape:
                    BoxShape.circle,
              ),

              child:
                  const Icon(
                Icons
                    .chat_bubble_outline_rounded,

                color:
                    Color(
                  0xFF65D83F,
                ),

                size: 40,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'Messages',

              style:
                  TextStyle(
                color:
                    Colors.white,

                fontSize:
                    22,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Your buyer conversations will appear here.',

              style:
                  TextStyle(
                color:
                    Color(
                  0xFFA8ADA8,
                ),

                fontSize:
                    13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
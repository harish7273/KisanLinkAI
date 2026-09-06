import 'package:flutter/material.dart';

import 'buyer_home_screen.dart';
import 'buyer_market_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'buyer_profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
  });

  @override
  State<MainScreen> createState() =>
      _MainScreenState();
}

class _MainScreenState
    extends State<MainScreen> {
  int currentIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = const [
      BuyerHomeScreen(),
      BuyerMarketScreen(),
      CartScreen(),
      OrdersScreen(),

      // FIXED
      BuyerProfileScreen(),
    ];
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF080A08),

      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),

      bottomNavigationBar:
          _buildBottomNavigationBar(),
    );
  }

  // ============================================================
  // BUYER BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigationBar() {
    const orange =
        Color(0xFFFF9800);

    return SafeArea(
      top: false,

      child: Container(
        margin:
            const EdgeInsets.fromLTRB(
          10,
          0,
          10,
          10,
        ),

        decoration:
            BoxDecoration(
          color:
              const Color(0xFF151515),

          borderRadius:
              BorderRadius.circular(
            24,
          ),

          border:
              Border.all(
            color:
                Colors.white.withValues(
              alpha: 0.08,
            ),
          ),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: 0.35,
              ),

              blurRadius: 20,

              offset:
                  const Offset(0, -5),
            ),
          ],
        ),

        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),

          child: Row(
            children: [
              // ==================================================
              // HOME
              // ==================================================

              _navItem(
                index: 0,
                icon:
                    Icons.home_rounded,
                label: 'Home',
              ),

              // ==================================================
              // MARKET
              // ==================================================

              _navItem(
                index: 1,
                icon:
                    Icons.storefront_rounded,
                label: 'Market',
              ),

              // ==================================================
              // CART
              // ==================================================

              _navItem(
                index: 2,
                icon:
                    Icons.shopping_cart_rounded,
                label: 'Cart',
              ),

              // ==================================================
              // ORDERS
              // ==================================================

              _navItem(
                index: 3,
                icon:
                    Icons.receipt_long_rounded,
                label: 'Orders',
              ),

              // ==================================================
              // PROFILE
              // ==================================================

              _navItem(
                index: 4,
                icon:
                    Icons.person_rounded,
                label: 'Profile',
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
    required int index,
    required IconData icon,
    required String label,
  }) {
    const orange =
        Color(0xFFFF9800);

    final bool selected =
        currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            currentIndex = index;
          });
        },

        behavior:
            HitTestBehavior.opaque,

        child:
            AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 180,
          ),

          padding:
              const EdgeInsets.symmetric(
            vertical: 7,
          ),

          margin:
              const EdgeInsets.symmetric(
            horizontal: 2,
          ),

          decoration:
              BoxDecoration(
            color: selected
                ? orange.withValues(
                    alpha: 0.16,
                  )
                : Colors.transparent,

            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              Icon(
                icon,

                size: 23,

                color: selected
                    ? orange
                    : Colors.white54,
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                label,

                maxLines: 1,

                overflow:
                    TextOverflow.ellipsis,

                style: TextStyle(
                  color: selected
                      ? orange
                      : Colors.white54,

                  fontSize: 10,

                  fontWeight: selected
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
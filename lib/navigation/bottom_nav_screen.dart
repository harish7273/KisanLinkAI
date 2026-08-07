import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../screens/auction_screen.dart';
import '../screens/home_screen.dart';
import '../screens/market_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sell_screen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    MarketScreen(),
    SellScreen(),
    AuctionScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      floatingActionButton: FloatingActionButton(
        heroTag: "sell",
        elevation: 10,
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        onPressed: () {
          setState(() {
            _selectedIndex = 2;
          });
        },
        child: const Icon(
          Icons.agriculture_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BottomAppBar(
          color: AppColors.card,
          elevation: 15,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,

          child: SizedBox(
            height: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [

                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: "Home",
                  index: 0,
                ),

                _buildNavItem(
                  icon: Icons.storefront_rounded,
                  label: "Market",
                  index: 1,
                ),

                const SizedBox(width: 48),

                _buildNavItem(
                  icon: Icons.gavel_rounded,
                  label: "Auction",
                  index: 3,
                ),

                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: "Profile",
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool selected = _selectedIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: selected
                  ? AppColors.primary
                  : Colors.white54,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? AppColors.primary
                    : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
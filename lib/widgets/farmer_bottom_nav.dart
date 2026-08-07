import 'package:flutter/material.dart';

import '../screens/farmer_analytics_screen.dart';
import '../screens/farmer_orders_screen.dart';
import '../screens/farmer_products_screen.dart';
import '../screens/farmer_profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/sell_screen.dart';

class FarmerBottomNav extends StatefulWidget {
  const FarmerBottomNav({super.key});

  @override
  State<FarmerBottomNav> createState() => _FarmerBottomNavState();
}

class _FarmerBottomNavState extends State<FarmerBottomNav> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    HomeScreen(),
    FarmerProductsScreen(),
    SellScreen(), // Center FAB
    FarmerOrdersScreen(),
    FarmerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF22C55E),
        elevation: 8,
        shape: const CircleBorder(),
        onPressed: () {
          setState(() {
            selectedIndex = 2;
          });
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
        ),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF181818),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [

              _navItem(
                icon: Icons.home_rounded,
                label: "Home",
                index: 0,
              ),

              _navItem(
                icon: Icons.agriculture_rounded,
                label: "My Crops",
                index: 1,
              ),

              const SizedBox(width: 50),

              _navItem(
                icon: Icons.shopping_bag_rounded,
                label: "Orders",
                index: 3,
              ),

              _navItem(
                icon: Icons.person_rounded,
                label: "Profile",
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final selected = selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFF22C55E)
                  : Colors.white60,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: selected
                    ? const Color(0xFF22C55E)
                    : Colors.white60,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
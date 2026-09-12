import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomHeader extends StatelessWidget {
  final String farmerName;

  const CustomHeader({
    super.key,
    required this.farmerName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 0, 0, 0),
      padding: const EdgeInsets.only(
        top: 10,
        left: 20,
        right: 20,
        bottom: 10,
      ),
      child: Row(
        children: [

          /// Menu
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF1D1D1D),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
              ),
            ),
          ),

          const Spacer(),

          ClipOval(
            child: Image.asset(
              'assets/images/kisan_logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.spa_rounded,
                color: Color(0xFF017422),
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Text(
            "KisanAI",
            style: GoogleFonts.outfit(
              color: const Color(0xFF00E676),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF1D1D1D),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
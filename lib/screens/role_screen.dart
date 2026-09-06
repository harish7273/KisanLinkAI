import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'buyer_login_screen.dart';

class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  int selectedRole = -1;

  static const Color farmerGreen = Color(0xFF14652C);
  static const Color farmerLight = Color(0xFFE9F6CE);

  static const Color buyerOrange = Color(0xFFE87500);
  static const Color buyerLight = Color(0xFFFFE6B9);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF001D08),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/farm_background.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF003A16),
                        Color(0xFF002B0E),
                        Color(0xFF001805),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Dark overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    const Color(0xFF002E0E)
                        .withValues(alpha: 0.65),
                    const Color(0xFF001806)
                        .withValues(alpha: 0.96),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 6,
              ),
              child: Column(
                children: [
                  // Language
                  SizedBox(
                    height: 48,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: _languageButton(),
                    ),
                  ),

                  // Logo
                  _logoSection(),

                  const SizedBox(height: 12),

                  const Text(
                    'Welcome!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Choose your role to get started',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: 90,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF72D13C),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Role cards
                  SizedBox(
                    height: size.height < 800 ? 215 : 230,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildFarmerCard(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildBuyerCard(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  _buildTrustSection(),

                  const SizedBox(height: 15),

                  _buildBottomMessage(),

                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LANGUAGE
  // ============================================================

  Widget _languageButton() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.language_rounded,
            color: Colors.white,
            size: 21,
          ),
          const SizedBox(width: 7),
          Text(
            'English',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 5),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
            size: 19,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGO
  // ============================================================

  Widget _logoSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 48,
          width: 70,
          child: Image.asset(
            'assets/images/vidhai_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.spa_rounded,
                color: Color(0xFF78D641),
                size: 45,
              );
            },
          ),
        ),

        const SizedBox(height: 1),

        Text(
          'Vidhai',
          style: GoogleFonts.lora(
            fontSize: 43,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF72D13C),
            height: 0.9,
          ),
        ),

        const SizedBox(height: 4),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.eco_rounded,
              color: Color(0xFF70CE42),
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              'Fresh from Farms',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.80),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.eco_rounded,
              color: Color(0xFF70CE42),
              size: 14,
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // FARMER
  // ============================================================

  Widget _buildFarmerCard() {
    return RoleCard(
      title: 'I am a Farmer',
      description:
          'Sell your produce,\nconnect with buyers.',
      image: 'assets/images/farmer.png',
      icon: Icons.agriculture_rounded,
      accentColor: farmerGreen,
      lightColor: farmerLight,
      buttonText: 'Continue as Farmer',
      selected: selectedRole == 0,
      onTap: () {
        setState(() {
          selectedRole = 0;
        });

        Navigator.pushNamed(
          context,
          '/login',
        );
      },
    );
  }

  // ============================================================
  // BUYER
  // ============================================================

  Widget _buildBuyerCard() {
    return RoleCard(
      title: 'I am a Buyer',
      description:
          'Buy fresh produce\ndirect from farmers.',
      image: 'assets/images/buyer.png',
      icon: Icons.shopping_basket_rounded,
      accentColor: buyerOrange,
      lightColor: buyerLight,
      buttonText: 'Continue as Buyer',
      selected: selectedRole == 1,

      onTap: () {
        setState(() {
          selectedRole = 1;
        });

        // IMPORTANT:
        // Direct navigation to BuyerLoginScreen.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return BuyerLoginScreen();
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // TRUST
  // ============================================================

  Widget _buildTrustSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF00270D)
            .withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF4D9C3C)
              .withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _featureItem(
              Icons.verified_user_rounded,
              'Trusted',
              'Safe & secure',
            ),
          ),

          _divider(),

          Expanded(
            child: _featureItem(
              Icons.eco_rounded,
              'Fresh',
              'Farm quality',
            ),
          ),

          _divider(),

          Expanded(
            child: _featureItem(
              Icons.local_shipping_rounded,
              'Fast',
              'Quick delivery',
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureItem(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: const Color(0xFF7ED84A),
          size: 30,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.60),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 52,
      width: 1,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }

  // ============================================================
  // BOTTOM MESSAGE
  // ============================================================

  Widget _buildBottomMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF063418),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFF4D9C3C)
              .withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF073B18),
              border: Border.all(
                color: const Color(0xFF67C943)
                    .withValues(alpha: 0.45),
              ),
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              color: Color(0xFF7BD64B),
              size: 25,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Together, let’s grow a better tomorrow 💚',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  'Support farmers. Eat fresh. Live healthy.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// ROLE CARD
// ==================================================================

class RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final String image;
  final String buttonText;

  final IconData icon;

  final Color accentColor;
  final Color lightColor;

  final bool selected;

  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.title,
    required this.description,
    required this.image,
    required this.buttonText,
    required this.icon,
    required this.accentColor,
    required this.lightColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 200,
        ),
        padding: const EdgeInsets.fromLTRB(
          9,
          8,
          9,
          8,
        ),
        decoration: BoxDecoration(
          color: lightColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selected
                ? accentColor
                : Colors.white.withValues(alpha: 0.30),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(
                alpha: selected ? 0.28 : 0.08,
              ),
              blurRadius: selected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // IMAGE
            SizedBox(
              height: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 82,
                      height: 70,
                      child: Image.asset(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return Container(
                            color: Colors.white
                                .withValues(alpha: 0.55),
                            child: Icon(
                              icon,
                              color: accentColor,
                              size: 38,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  if (selected)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // TITLE
            SizedBox(
              height: 24,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: accentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            // DIVIDER
            SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: accentColor.withValues(
                        alpha: 0.20,
                      ),
                    ),
                  ),

                  Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),
                    child: Icon(
                      Icons.eco_rounded,
                      color: accentColor,
                      size: 11,
                    ),
                  ),

                  Expanded(
                    child: Container(
                      height: 1,
                      color: accentColor.withValues(
                        alpha: 0.20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // DESCRIPTION
            SizedBox(
              height: 29,
              child: Text(
                description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF315138),
                  fontSize: 9,
                  height: 1.15,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // BUTTON
            SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(11),
                  ),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                    ),

                    const SizedBox(width: 4),

                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          buttonText,
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 3),

                    const Icon(
                      Icons
                          .arrow_forward_ios_rounded,
                      size: 8,
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
}
import 'package:flutter/material.dart';
import '../screens/buyer_market_screen.dart';
import '../screens/crop_disease_screen.dart';
import '../screens/kisan_voice_screen.dart';
import '../screens/quality_scanner_screen.dart';
import '../screens/kisan_pool_screen.dart';
import '../screens/offline_sync_screen.dart';
import '../screens/wishlist_screen.dart';
import '../services/language_service.dart';

class QuickActions extends StatelessWidget {
  final String role;

  const QuickActions({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final actions =
        role == "farmer" ? _farmerActions(context) : _buyerActions(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LanguageService.tr('quick_actions', defaultText: "Quick Actions"),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final item = actions[index];

            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: item.onTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141A15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: .22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        color: const Color(0xFF00E676),
                        size: 24,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      LanguageService.tr(item.title, defaultText: item.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      LanguageService.tr(item.subtitle, defaultText: item.subtitle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ===================== FARMER ======================

  static List<_ActionItem> _farmerActions(BuildContext context) => [
        _ActionItem(
          icon: Icons.health_and_safety_rounded,
          title: "Crop Doctor",
          subtitle: "Leaf disease diagnosis",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CropDiseaseScreen(),
              ),
            );
          },
        ),
        _ActionItem(
          icon: Icons.camera_enhance_rounded,
          title: "Quality Scanner",
          subtitle: "AGMARK AI grading",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const QualityScannerScreen(),
              ),
            );
          },
        ),
        _ActionItem(
          icon: Icons.record_voice_over_rounded,
          title: "Voice Assistant",
          subtitle: "Zero-typing listing",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const KisanVoiceScreen(),
              ),
            );
          },
        ),
        _ActionItem(
          icon: Icons.local_shipping_rounded,
          title: "KisanPool",
          subtitle: "Shared transport",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const KisanPoolScreen(),
              ),
            );
          },
        ),
        _ActionItem(
          icon: Icons.cloud_sync_rounded,
          title: "Offline Sync",
          subtitle: "Local queue & cache",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OfflineSyncScreen(),
              ),
            );
          },
        ),
      ];

  // ===================== BUYER ======================

  static List<_ActionItem> _buyerActions(BuildContext context) => [
        _ActionItem(
          icon: Icons.shopping_basket_rounded,
          title: "Market Feed",
          subtitle: "Fresh verified lots",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BuyerMarketScreen(),
              ),
            );
          },
        ),
        _ActionItem(
          icon: Icons.qr_code_scanner_rounded,
          title: "Quality Verify",
          subtitle: "Scan lot certificate",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const QualityScannerScreen(),
              ),
            );
          },
        ),
        _ActionItem(
          icon: Icons.favorite_rounded,
          title: "Wishlist",
          subtitle: "Saved farmer lots",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const WishlistScreen(),
              ),
            );
          },
        ),
        _ActionItem(
          icon: Icons.cloud_sync_rounded,
          title: "Offline Sync",
          subtitle: "Order cache",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OfflineSyncScreen(),
              ),
            );
          },
        ),
      ];
}

class _ActionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

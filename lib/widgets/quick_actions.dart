import 'package:flutter/material.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/kisan_voice_screen.dart';
import '../screens/quality_scanner_screen.dart';
import '../screens/kisan_pool_screen.dart';
import '../screens/offline_sync_screen.dart';

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
        const Text(
          "Quick Actions",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.12,
          ),
          itemBuilder: (context, index) {
            final item = actions[index];

            return InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: item.onTap,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF181818),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFF00E676).withOpacity(.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Color(0x2200E676),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        color: const Color(0xFF00E676),
                        size: 30,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
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
          icon: Icons.record_voice_over_rounded,
          title: "Voice Assistant",
          subtitle: "Zero-typing list",
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
          icon: Icons.local_shipping_rounded,
          title: "KisanPool",
          subtitle: "Shared milk-run",
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
          icon: Icons.shopping_cart_rounded,
          title: "Buy Crops",
          subtitle: "Fresh produce",
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Coming Soon 🚀"),
              ),
            );
          },
        ),
        _ActionItem(
          icon: Icons.favorite_rounded,
          title: "Wishlist",
          subtitle: "Saved items",
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Coming Soon 🚀"),
              ),
            );
          },
        ),
        _ActionItem(
          icon: Icons.local_shipping_rounded,
          title: "Orders",
          subtitle: "Track orders",
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Coming Soon 🚀"),
              ),
            );
          },
        ),
        _ActionItem(
          icon: Icons.bar_chart_rounded,
          title: "Price Trends",
          subtitle: "Market data",
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Coming Soon 🚀"),
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

  const _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
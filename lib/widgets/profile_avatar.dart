import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String avatarId;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.avatarId,
    this.size = 70,
  });

  static const Color orange =
      Color(0xFFFF9800);

  @override
  Widget build(BuildContext context) {
    final index =
        _getIndex(avatarId);

    final icons = [
      Icons.storefront_rounded,
      Icons.person_rounded,
      Icons.business_center_rounded,
      Icons.shopping_bag_rounded,
      Icons.store_rounded,
    ];

    final colors = [
      const Color(0xFFFF9800),
      const Color(0xFFFF7043),
      const Color(0xFFFFB300),
      const Color(0xFFFF8A65),
      const Color(0xFFF57C00),
    ];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors[index]
            .withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(
          color: colors[index]
              .withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Icon(
        icons[index],
        color: colors[index],
        size: size * 0.48,
      ),
    );
  }

  int _getIndex(String id) {
    final number =
        int.tryParse(
              id.replaceAll(
                'buyer_',
                '',
              ),
            ) ??
            1;

    final index = number - 1;

    if (index < 0 ||
        index >= 5) {
      return 0;
    }

    return index;
  }
}
import 'package:flutter/material.dart';

class ProfileAvatar extends StatefulWidget {
  final String avatarId;
  final double size;
  final bool animated;

  const ProfileAvatar({
    super.key,
    required this.avatarId,
    this.size = 80,
    this.animated = true,
  });

  @override
  State<ProfileAvatar> createState() =>
      _ProfileAvatarState();
}

class _ProfileAvatarState
    extends State<ProfileAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 2),
    );

    _floatAnimation = Tween<double>(
      begin: -2.5,
      end: 2.5,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.animated) {
      _controller.repeat(
        reverse: true,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final isFarmer =
        widget.avatarId.startsWith(
      'farmer_',
    );

    final accent = isFarmer
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF9800);

    Widget avatar = Container(
      width: widget.size,
      height: widget.size,

      decoration: BoxDecoration(
        shape: BoxShape.circle,

        border: Border.all(
          color: accent,
          width: 2.5,
        ),

        boxShadow: [
          BoxShadow(
            color: accent.withValues(
              alpha: .28,
            ),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),

      child: ClipOval(
        child: Image.asset(
          'assets/avatars/${widget.avatarId}.png',

          width: widget.size,
          height: widget.size,

          fit: BoxFit.cover,

          errorBuilder:
              (
            context,
            error,
            stackTrace,
          ) {
            return Container(
              color:
                  const Color(0xFF1A1A1A),

              child: Icon(
                Icons.person_rounded,
                color: accent,
                size:
                    widget.size * .45,
              ),
            );
          },
        ),
      ),
    );

    if (!widget.animated) {
      return avatar;
    }

    return AnimatedBuilder(
      animation: _floatAnimation,

      builder:
          (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            _floatAnimation.value,
          ),
          child: child,
        );
      },

      child: avatar,
    );
  }
}
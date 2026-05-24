import 'package:flutter/material.dart';

import '../../config/theme.dart';

class LoadingDots extends StatefulWidget {
  final Color color;
  final double size;
  const LoadingDots({super.key, this.color = AppColors.accent, this.size = 8});

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_c.value - i * 0.2) % 1.0;
            final opacity = (phase < 0.5 ? phase * 2 : (1 - phase) * 2).clamp(0.2, 1.0);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.size * 0.4),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  height: widget.size,
                  width: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

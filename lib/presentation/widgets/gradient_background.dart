import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';

class GradientBackground extends StatefulWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.showOrbs = true,
  });

  final Widget child;
  final bool showOrbs;

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base background
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
        ),
        if (widget.showOrbs) ...[
          // Top-left violet orb
          Positioned(
            top: -80,
            left: -60,
            child: _Orb(
              size: 280,
              color: AppColors.primary.withAlpha(30),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.1, 1.1),
                  duration: 6.seconds,
                  curve: Curves.easeInOut,
                ),
          ),
          // Bottom-right cyan orb
          Positioned(
            bottom: -100,
            right: -80,
            child: _Orb(
              size: 320,
              color: AppColors.secondary.withAlpha(20),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(0.85, 0.85),
                  duration: 8.seconds,
                  curve: Curves.easeInOut,
                ),
          ),
        ],
        // Content
        widget.child,
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Fades + slides in a child widget on mount
class AnimatedFadeSlide extends StatelessWidget {
  const AnimatedFadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration,
    this.offsetY = 24.0,
    this.curve = Curves.easeOut,
  });

  final Widget child;
  final Duration delay;
  final Duration? duration;
  final double offsetY;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(
          duration: duration ?? const Duration(milliseconds: 400),
          curve: curve,
        )
        .slideY(
          begin: offsetY / 100,
          end: 0,
          duration: duration ?? const Duration(milliseconds: 400),
          curve: curve,
        );
  }
}

/// Staggered list animation helper
class StaggeredList extends StatelessWidget {
  const StaggeredList({
    super.key,
    required this.children,
    this.staggerMs = 80,
    this.baseDelay = Duration.zero,
  });

  final List<Widget> children;
  final int staggerMs;
  final Duration baseDelay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i++)
          AnimatedFadeSlide(
            delay: baseDelay + Duration(milliseconds: staggerMs * i),
            child: children[i],
          ),
      ],
    );
  }
}

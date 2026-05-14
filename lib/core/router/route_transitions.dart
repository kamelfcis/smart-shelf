import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RouteTransitions {
  RouteTransitions._();

  static Page<void> slide({
    required Widget child,
    required LocalKey key,
    Offset begin = const Offset(1.0, 0.0),
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
        final tween = Tween(begin: begin, end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        final fade = Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(opacity: animation.drive(fade), child: child),
        );
      },
    );
  }

  static Page<void> fade({
    required Widget child,
    required LocalKey key,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        return FadeTransition(opacity: fade, child: child);
      },
    );
  }

  static Page<void> bottomSheet({
    required Widget child,
    required LocalKey key,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      // Material is required so that TextField / AppTextField have an ancestor.
      // CustomTransitionPage with opaque:false does NOT inject one automatically.
      child: Material(color: Colors.transparent, child: child),
      opaque: false,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(0, 1), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}

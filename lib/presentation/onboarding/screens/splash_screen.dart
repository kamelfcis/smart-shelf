import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../widgets/geometric_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _navigate();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    // If the user is already signed in, skip onboarding and go straight home.
    final session = ref.read(authStateProvider).valueOrNull;
    if (session != null) {
      context.go(AppRoutes.dashboard);
    } else {
      // New / signed-out user → show onboarding every time.
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GeometricBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated glow logo
              AnimatedBuilder(
                animation: _glowCtrl,
                builder: (context, child) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusXl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(
                            (50 + (_glowCtrl.value * 100)).round(),
                          ),
                          blurRadius: 28 + (_glowCtrl.value * 20),
                          spreadRadius: 2 + (_glowCtrl.value * 4),
                        ),
                        BoxShadow(
                          color: AppColors.secondary.withAlpha(
                            (20 + (_glowCtrl.value * 50)).round(),
                          ),
                          blurRadius: 48 + (_glowCtrl.value * 24),
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.white,
                  size: 50,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1.0, 1.0),
                    duration: 900.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 400.ms)
                  .shimmer(
                    delay: 1000.ms,
                    duration: 800.ms,
                    color: Colors.white.withAlpha(80),
                  ),

              const SizedBox(height: AppDimensions.lg),

              // App name
              Text(
                'Smart Shelf',
                style: AppTypography.displayMedium.copyWith(
                  foreground: Paint()
                    ..shader = AppColors.primaryGradient.createShader(
                      const Rect.fromLTWH(0, 0, 220, 50),
                    ),
                ),
              )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic)
                  .blur(
                    begin: const Offset(4, 4),
                    end: Offset.zero,
                    duration: 600.ms,
                  ),

              const SizedBox(height: AppDimensions.sm),

              Text(
                'IoT Shelf Intelligence',
                style: AppTypography.bodyMedium,
              )
                  .animate(delay: 650.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: AppDimensions.xxxl),

              // Loading dots
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withAlpha(180),
                    ),
                  )
                      .animate(
                        delay: Duration(milliseconds: 900 + (i * 160)),
                        onPlay: (c) => c.repeat(reverse: true),
                      )
                      .scaleXY(
                        begin: 0.5,
                        end: 1.3,
                        duration: 600.ms,
                        curve: Curves.easeInOut,
                      )
                      .fadeIn(duration: 300.ms);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_router.dart';
import '../../widgets/app_button.dart';
import '../../widgets/geometric_background.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingPage {
  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.description,
  });

  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
}

const _pages = [
  _OnboardingPage(
    title: 'Smart Monitoring',
    subtitle: 'Your shelf, always in sight',
    description:
        'Connect your ESP8266 weight sensors and track every item on your shelf in real time — from anywhere.',
    icon: Icons.sensors_rounded,
    primaryColor: Color(0xFF6C63FF),
    secondaryColor: Color(0xFF4A42D6),
  ),
  _OnboardingPage(
    title: 'Real-Time Alerts',
    subtitle: 'Never run out again',
    description:
        'Get instant notifications when items are removed or stock runs low. Stay ahead before it becomes a problem.',
    icon: Icons.notifications_active_outlined,
    primaryColor: Color(0xFF00E5FF),
    secondaryColor: Color(0xFF0097A7),
  ),
  _OnboardingPage(
    title: 'Smart Analytics',
    subtitle: 'Data-driven shelf management',
    description:
        'View historical consumption charts, detect patterns, and predict when to restock — powered by your data.',
    icon: Icons.auto_graph_rounded,
    primaryColor: Color(0xFF00E096),
    secondaryColor: Color(0xFF00897B),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _controller = PageController();
  int _currentPage = 0;
  late final AnimationController _accentCtrl;
  Color _accentColor = _pages[0].primaryColor;

  void _finish() => context.go(AppRoutes.login);

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
      _accentColor = _pages[index].primaryColor;
    });
  }

  @override
  void initState() {
    super.initState();
    _accentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _accentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background — keyed so it cross-fades on accent change
          // but sits in its own AnimatedSwitcher layer, independent of PageView
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: GeometricBackground(
              key: ValueKey(_accentColor),
              accentColor: _accentColor,
            ),
          ),

          // Stable content layer — PageView is never recreated
          SafeArea(
            child: Column(
              children: [
                // Skip
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
                    child: AnimatedOpacity(
                      opacity: _currentPage < _pages.length - 1 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: TextButton(
                        onPressed: _finish,
                        child: Text(
                          'Skip',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (ctx, i) => _OnboardingPageWidget(
                      page: _pages[i],
                      isActive: i == _currentPage,
                    ),
                  ),
                ),

                // Dots + button
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.screenPadding,
                    0,
                    AppDimensions.screenPadding,
                    AppDimensions.xl,
                  ),
                  child: Column(
                    children: [
                      // Indicator dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == i ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull,
                              ),
                              color: _currentPage == i
                                  ? _pages[i].primaryColor
                                  : AppColors.textHint,
                              boxShadow: _currentPage == i
                                  ? [
                                      BoxShadow(
                                        color: _pages[i]
                                            .primaryColor
                                            .withAlpha(120),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppDimensions.xl),

                      PrimaryButton(
                        label: _currentPage < _pages.length - 1
                            ? 'Continue'
                            : 'Get Started',
                        onPressed: _next,
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Page widget
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingPageWidget extends StatefulWidget {
  const _OnboardingPageWidget({
    required this.page,
    required this.isActive,
  });

  final _OnboardingPage page;
  final bool isActive;

  @override
  State<_OnboardingPageWidget> createState() => _OnboardingPageWidgetState();
}

class _OnboardingPageWidgetState extends State<_OnboardingPageWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.page;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated hex illustration
          SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer hex ring (slow spin)
                AnimatedBuilder(
                  animation: _spinCtrl,
                  builder: (_, child) => Transform.rotate(
                    angle: _spinCtrl.value * math.pi * 2,
                    child: child,
                  ),
                  child: CustomPaint(
                    size: const Size(220, 220),
                    painter: _HexRingPainter(
                      color: p.primaryColor.withAlpha(50),
                      strokeWidth: 1.5,
                    ),
                  ),
                ),

                // Mid hex ring (counter-spin, faster)
                AnimatedBuilder(
                  animation: _spinCtrl,
                  builder: (_, child) => Transform.rotate(
                    angle: -_spinCtrl.value * math.pi * 4,
                    child: child,
                  ),
                  child: CustomPaint(
                    size: const Size(160, 160),
                    painter: _HexRingPainter(
                      color: p.primaryColor.withAlpha(80),
                      strokeWidth: 1.0,
                      dashed: true,
                    ),
                  ),
                ),

                // Glow orb
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        p.primaryColor.withAlpha(40),
                        p.primaryColor.withAlpha(0),
                      ],
                    ),
                  ),
                ),

                // Icon badge
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [p.primaryColor, p.secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: p.primaryColor.withAlpha(100),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(p.icon, size: 48, color: Colors.white),
                )
                    .animate(
                      onPlay: widget.isActive ? null : (c) => c.stop(),
                    )
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 400.ms),

                // Dot ornaments at hex vertices
                ...List.generate(6, (i) {
                  final angle = math.pi / 180 * (60 * i - 30);
                  const r = 110.0;
                  return Positioned(
                    left: 120 + r * math.cos(angle) - 4,
                    top: 120 + r * math.sin(angle) - 4,
                    child: AnimatedBuilder(
                      animation: _spinCtrl,
                      builder: (_, __) {
                        final pulse =
                            (math.sin(_spinCtrl.value * math.pi * 2 +
                                        i * math.pi / 3) +
                                    1) /
                                2;
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.primaryColor
                                .withAlpha((60 + pulse * 80).round()),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: -0.08, end: 0),

          const SizedBox(height: AppDimensions.xl),

          Text(
            p.title,
            style: AppTypography.displaySmall,
            textAlign: TextAlign.center,
          ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.3),

          const SizedBox(height: AppDimensions.sm),

          Text(
            p.subtitle,
            style: AppTypography.headingSmall.copyWith(
              color: p.primaryColor,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 230.ms).fadeIn().slideY(begin: 0.3),

          const SizedBox(height: AppDimensions.md),

          Text(
            p.description,
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ).animate(delay: 310.ms).fadeIn().slideY(begin: 0.3),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hex ring custom painter
// ─────────────────────────────────────────────────────────────────────────────

class _HexRingPainter extends CustomPainter {
  _HexRingPainter({
    required this.color,
    required this.strokeWidth,
    this.dashed = false,
  });

  final Color color;
  final double strokeWidth;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (dashed) {
      _drawDashedHex(canvas, paint, cx, cy, r);
    } else {
      _drawHex(canvas, paint, cx, cy, r);
    }
  }

  void _drawHex(Canvas canvas, Paint paint, double cx, double cy, double r) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 180 * (60 * i - 30);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawDashedHex(
      Canvas canvas, Paint paint, double cx, double cy, double r) {
    for (var i = 0; i < 6; i++) {
      final a1 = math.pi / 180 * (60 * i - 30);
      final a2 = math.pi / 180 * (60 * (i + 1) - 30);
      final x1 = cx + r * math.cos(a1);
      final y1 = cy + r * math.sin(a1);
      final x2 = cx + r * math.cos(a2);
      final y2 = cy + r * math.sin(a2);
      // Draw only half of each edge (dashed effect)
      final mx = (x1 + x2) / 2;
      final my = (y1 + y2) / 2;
      canvas.drawLine(Offset(x1, y1), Offset(mx, my), paint);
    }
  }

  @override
  bool shouldRepaint(_HexRingPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

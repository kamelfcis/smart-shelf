import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Full-screen animated geometric background.
/// Renders floating triangles, a subtle hex grid, and pulsing glow orbs
/// using a [CustomPainter].  Pass an optional [accentColor] to shift the
/// palette when switching between onboarding pages.
class GeometricBackground extends StatefulWidget {
  const GeometricBackground({
    super.key,
    this.child,
    this.accentColor,
  });

  final Widget? child;

  /// Overrides the primary accent tint used for shapes / orbs.
  final Color? accentColor;

  @override
  State<GeometricBackground> createState() => _GeometricBackgroundState();
}

class _GeometricBackgroundState extends State<GeometricBackground>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _rotateCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppColors.primary;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.background,
                Color.lerp(AppColors.background, accent, 0.06)!,
                AppColors.background,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Animated geometry
        AnimatedBuilder(
          animation: Listenable.merge([_floatCtrl, _rotateCtrl, _pulseCtrl]),
          builder: (context, _) {
            return CustomPaint(
              painter: _GeometricPainter(
                floatT: _floatCtrl.value,
                rotateT: _rotateCtrl.value,
                pulseT: _pulseCtrl.value,
                accent: accent,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Content
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────────────────────────────────────

class _GeometricPainter extends CustomPainter {
  _GeometricPainter({
    required this.floatT,
    required this.rotateT,
    required this.pulseT,
    required this.accent,
  });

  final double floatT;
  final double rotateT;
  final double pulseT;
  final Color accent;

  static const List<_ShapeSeed> _seeds = [
    _ShapeSeed(0.12, 0.18, 0.18, 0.0),
    _ShapeSeed(0.75, 0.10, 0.22, 0.2),
    _ShapeSeed(0.88, 0.45, 0.14, 0.45),
    _ShapeSeed(0.05, 0.62, 0.20, 0.6),
    _ShapeSeed(0.55, 0.82, 0.16, 0.8),
    _ShapeSeed(0.35, 0.30, 0.12, 0.15),
    _ShapeSeed(0.65, 0.55, 0.24, 0.35),
    _ShapeSeed(0.20, 0.80, 0.18, 0.7),
    _ShapeSeed(0.90, 0.75, 0.15, 0.55),
    _ShapeSeed(0.48, 0.12, 0.19, 0.9),
    _ShapeSeed(0.30, 0.50, 0.13, 0.05),
    _ShapeSeed(0.80, 0.25, 0.21, 0.42),
  ];

  static const List<_OrbSeed> _orbs = [
    _OrbSeed(0.20, 0.15, 180, 0.0),
    _OrbSeed(0.85, 0.35, 140, 0.5),
    _OrbSeed(0.50, 0.75, 160, 0.25),
    _OrbSeed(0.10, 0.90, 120, 0.75),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _drawHexGrid(canvas, size);
    _drawOrbs(canvas, size);
    _drawTriangles(canvas, size);
  }

  // ── Hex grid ────────────────────────────────────────────────────────────────
  void _drawHexGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withAlpha(10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const hexR = 48.0;
    final dx = hexR * 1.5;
    final dy = hexR * math.sqrt(3);

    final cols = (size.width / dx).ceil() + 2;
    final rows = (size.height / dy).ceil() + 2;

    for (var col = -1; col < cols; col++) {
      for (var row = -1; row < rows; row++) {
        final cx = col * dx;
        final cy = row * dy + (col.isOdd ? dy / 2 : 0);
        _drawHex(canvas, paint, cx, cy, hexR);
      }
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

  // ── Glow orbs ───────────────────────────────────────────────────────────────
  void _drawOrbs(Canvas canvas, Size size) {
    for (final orb in _orbs) {
      final t = (floatT + orb.phaseOffset) % 1.0;
      final floatY = math.sin(t * math.pi * 2) * 30;
      final pulse = 0.3 + pulseT * 0.4;

      final cx = orb.rx * size.width;
      final cy = orb.ry * size.height + floatY;
      final radius = orb.radius.toDouble();

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withAlpha((pulse * 55).round()),
            accent.withAlpha(0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));

      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  // ── Floating triangles ──────────────────────────────────────────────────────
  void _drawTriangles(Canvas canvas, Size size) {
    for (int i = 0; i < _seeds.length; i++) {
      final seed = _seeds[i];
      final t = (floatT + seed.phaseOffset) % 1.0;
      final floatY = math.sin(t * math.pi * 2) * 40;
      final floatX = math.cos(t * math.pi * 2) * 20;
      final rotate =
          (rotateT + seed.phaseOffset) * math.pi * 2 * (i.isEven ? 1 : -1);

      final cx = seed.rx * size.width + floatX;
      final cy = seed.ry * size.height + floatY;
      final s = seed.scale * math.min(size.width, size.height);

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rotate);

      final isHex = i % 3 == 0;
      final paint = Paint()
        ..color = accent.withAlpha(i.isEven ? 18 : 12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      if (isHex) {
        _drawHexShape(canvas, paint, s * 0.6);
      } else if (i % 3 == 1) {
        _drawTriangleShape(canvas, paint, s);
      } else {
        _drawDiamondShape(canvas, paint, s * 0.7);
      }

      canvas.restore();
    }
  }

  void _drawTriangleShape(Canvas canvas, Paint paint, double s) {
    final path = Path()
      ..moveTo(0, -s)
      ..lineTo(s * 0.866, s * 0.5)
      ..lineTo(-s * 0.866, s * 0.5)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawDiamondShape(Canvas canvas, Paint paint, double s) {
    final path = Path()
      ..moveTo(0, -s)
      ..lineTo(s * 0.6, 0)
      ..lineTo(0, s)
      ..lineTo(-s * 0.6, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawHexShape(Canvas canvas, Paint paint, double r) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 180 * (60 * i);
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GeometricPainter old) =>
      old.floatT != floatT ||
      old.rotateT != rotateT ||
      old.pulseT != pulseT ||
      old.accent != accent;
}

// ─────────────────────────────────────────────────────────────────────────────
// Seed data classes (const — no allocations per frame)
// ─────────────────────────────────────────────────────────────────────────────

class _ShapeSeed {
  const _ShapeSeed(this.rx, this.ry, this.scale, this.phaseOffset);
  final double rx;
  final double ry;
  final double scale;
  final double phaseOffset;
}

class _OrbSeed {
  const _OrbSeed(this.rx, this.ry, this.radius, this.phaseOffset);
  final double rx;
  final double ry;
  final int radius;
  final double phaseOffset;
}

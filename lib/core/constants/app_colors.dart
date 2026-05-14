import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color card = Color(0xFF1A1A28);
  static const Color cardGlass = Color(0x0AFFFFFF); // rgba(255,255,255,0.04)

  // ── Accents ───────────────────────────────────────────
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4A42D6);
  static const Color primaryGlow = Color(0x336C63FF);
  static const Color secondary = Color(0xFF00E5FF);
  static const Color secondaryGlow = Color(0x3300E5FF);

  // ── Semantic ──────────────────────────────────────────
  static const Color success = Color(0xFF00E096);
  static const Color successGlow = Color(0x3300E096);
  static const Color warning = Color(0xFFFFB300);
  static const Color warningGlow = Color(0x33FFB300);
  static const Color error = Color(0xFFFF4D6D);
  static const Color errorGlow = Color(0x33FF4D6D);

  // ── Text ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF7A7A9D);
  static const Color textHint = Color(0xFF4A4A6A);

  // ── Borders ───────────────────────────────────────────
  static const Color border = Color(0x1AFFFFFF); // rgba(255,255,255,0.10)
  static const Color borderActive = Color(0x4D6C63FF);

  // ── Gradients ─────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0A0F), Color(0xFF0F0A1E), Color(0xFF0A0A0F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E30), Color(0xFF16162A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00E096), Color(0xFF00B876)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFFB300), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFFF4D6D), Color(0xFFD63050)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Light Theme ───────────────────────────────────────
  static const Color lightBackground = Color(0xFFF5F5FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0F0FA);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6A6A8A);

  // ── Overlay ───────────────────────────────────────────
  static const Color overlay = Color(0x80000000);
  static const Color shimmerBase = Color(0xFF1E1E2E);
  static const Color shimmerHighlight = Color(0xFF2A2A3E);
}

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Inter is not bundled — use Roboto (Flutter/Android default) as primary.
  // JetBrainsMono is bundled via assets/fonts/ for sensor value display.
  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        // inherit:false makes every field explicit so Flutter never has to
        // merge with an ancestor style — this also prevents the
        // "TextStyle.lerp with different inherit values" crash on theme switch.
        inherit: false,
        fontFamily: 'Roboto',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        textBaseline: TextBaseline.alphabetic,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
      );

  static TextStyle _mono({
    required double size,
    required FontWeight weight,
    Color color = AppColors.textPrimary,
  }) =>
      TextStyle(
        inherit: false,
        fontFamily: 'JetBrainsMono',
        fontSize: size,
        fontWeight: weight,
        color: color,
        textBaseline: TextBaseline.alphabetic,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
      );

  // ── Display ───────────────────────────────────────────
  static TextStyle get displayLarge => _inter(
        size: 40,
        weight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -1.0,
      );

  static TextStyle get displayMedium => _inter(
        size: 32,
        weight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.5,
      );

  static TextStyle get displaySmall => _inter(
        size: 26,
        weight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.3,
      );

  // ── Headings ──────────────────────────────────────────
  static TextStyle get headingLarge => _inter(
        size: 22,
        weight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle get headingMedium => _inter(
        size: 18,
        weight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get headingSmall => _inter(
        size: 16,
        weight: FontWeight.w600,
        height: 1.4,
      );

  // ── Body ──────────────────────────────────────────────
  static TextStyle get bodyLarge => _inter(
        size: 16,
        weight: FontWeight.w400,
        height: 1.6,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodyMedium => _inter(
        size: 14,
        weight: FontWeight.w400,
        height: 1.57,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => _inter(
        size: 12,
        weight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  // ── Labels ────────────────────────────────────────────
  static TextStyle get labelLarge => _inter(
        size: 14,
        weight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => _inter(
        size: 12,
        weight: FontWeight.w500,
        letterSpacing: 0.5,
      );

  static TextStyle get labelSmall => _inter(
        size: 11,
        weight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.textSecondary,
      );

  // ── Captions ──────────────────────────────────────────
  static TextStyle get caption => _inter(
        size: 11,
        weight: FontWeight.w400,
        color: AppColors.textHint,
        letterSpacing: 0.3,
      );

  // ── Monospace (sensor values) ─────────────────────────
  static TextStyle get monoLarge => _mono(
        size: 28,
        weight: FontWeight.w700,
      );

  static TextStyle get monoMedium => _mono(
        size: 18,
        weight: FontWeight.w500,
      );

  static TextStyle get monoSmall => _mono(
        size: 13,
        weight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // ── Button ────────────────────────────────────────────
  static TextStyle get buttonLarge => _inter(
        size: 16,
        weight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get buttonMedium => _inter(
        size: 14,
        weight: FontWeight.w600,
        letterSpacing: 0.3,
      );
}

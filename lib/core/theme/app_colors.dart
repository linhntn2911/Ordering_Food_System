import 'package:flutter/material.dart';

/// Centralized application color palette extracted from the Pixel True Food Ninja kit
/// as specified in docs/design_system.md.
/// Light mode only. Feature widgets must not hardcode hex literals.
abstract final class AppColors {
  // Brand colors
  static const Color primaryStart = Color(0xFF53E88B);
  static const Color primaryEnd = Color(0xFF15BE77);
  static const Color primarySolid = Color(0xFF21C67B);
  static const Color primarySoft = Color(0xFFE1F6F4);
  static const Color primaryTint = Color(0x1A4EE489);
  static const Color info = Color(0xFF25A0B0);

  // Neutral colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF09051C);
  static const Color textSecondary = Color(0xFF444352);
  static const Color textMuted = Color(0xFF86848F);
  static const Color border = Color(0xFFCECDD2);
  static const Color borderLight = Color(0xFFF4F4F4);
  static const Color surfaceMuted = Color(0xFFF6F6F6);

  // Food & warm accent scale
  static const Color warning = Color(0xFFFFAD1D);
  static const Color warningMedium = Color(0xFFFFC668);
  static const Color warningSoft = Color(0xFFFFDEA4);
  static const Color warningSurface = Color(0xFFFEF8E0);
  static const Color foodAccentDark = Color(0xFFDA6317);
  static const Color foodAccent = Color(0xFFE38751);
  static const Color foodAccentSoft = Color(0xFFE6A986);
  static const Color foodAccentMuted = Color(0xFFE3CBBC);

  // Application semantic additions
  static const Color error = Color(0xFFFF4B4B);
  static const Color errorSoft = Color(0xFFFFF0F0);
  static const Color success = Color(0xFF15BE77);
  static const Color successSoft = Color(0xFFE8F9F0);
  static const Color scrim = Color(0x7309051C);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryStart, primaryEnd],
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryStart, primaryEnd],
  );
}

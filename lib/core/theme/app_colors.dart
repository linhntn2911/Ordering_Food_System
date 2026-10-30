import 'package:flutter/painting.dart';

/// Semantic color tokens from `docs/design_system.md`.
///
/// Widgets must reference these tokens instead of repeating hex literals.
abstract final class AppColors {
  // Brand.
  static const primaryStart = Color(0xFF53E88B);
  static const primaryEnd = Color(0xFF15BE77);
  static const primarySolid = Color(0xFF21C67B);
  static const primarySoft = Color(0xFFE1F6F4);
  static const primaryTint = Color(0x1A4EE489);
  static const info = Color(0xFF25A0B0);

  // Neutrals.
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF09051C);
  static const textSecondary = Color(0xFF444352);
  static const textMuted = Color(0xFF86848F);
  static const border = Color(0xFFCECDD2);
  static const surfaceMuted = Color(0xFFF6F6F6);

  // Warm accents.
  static const warning = Color(0xFFFFAD1D);
  static const warningMedium = Color(0xFFFFC668);
  static const warningSoft = Color(0xFFFFDEA4);
  static const warningSurface = Color(0xFFFEF8E0);
  static const foodAccentDark = Color(0xFFDA6317);
  static const foodAccent = Color(0xFFE38751);
  static const foodAccentSoft = Color(0xFFE6A986);
  static const foodAccentMuted = Color(0xFFE3CBBC);

  // Application states.
  static const error = Color(0xFFFF4B4B);
  static const errorSoft = Color(0xFFFFF0F0);
  static const success = Color(0xFF15BE77);
  static const successSoft = Color(0xFFE8F9F0);
  static const scrim = Color(0x7309051C);
}

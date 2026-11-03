import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Poppins type scale from `docs/design_system.md`.
abstract final class AppTextStyles {
  static const fontFamily = 'Poppins';

  static const displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    color: AppColors.textPrimary,
  );

  static const headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 25,
    fontWeight: FontWeight.w700,
    height: 33 / 25,
    color: AppColors.textPrimary,
  );

  static const headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 30 / 22,
    color: AppColors.textPrimary,
  );

  static const titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 26 / 18,
    color: AppColors.textPrimary,
  );

  static const titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    color: AppColors.textPrimary,
  );

  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.textSecondary,
  );

  static const bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 21 / 14,
    color: AppColors.textSecondary,
  );

  static const labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    color: AppColors.textPrimary,
  );

  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 18 / 12,
    color: AppColors.textMuted,
  );

  static const labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 16 / 11,
    color: AppColors.textMuted,
  );

  /// Prices and totals: weight 700 with tabular figures.
  static const price = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 20 / 14,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

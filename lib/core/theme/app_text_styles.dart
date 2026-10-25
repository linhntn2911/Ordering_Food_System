import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const headlineLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 25,
    height: 1.32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const headlineMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 22,
    height: 1.36,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const titleLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    height: 1.44,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const titleMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const bodyMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const bodySmall = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
  static const labelLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w600,
  );
  static const labelSmall = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    height: 1.45,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}

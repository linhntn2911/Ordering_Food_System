import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// The only application theme. Dark mode is out of scope.
abstract final class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: AppTextStyles.fontFamily,
    primaryColor: AppColors.primarySolid,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryEnd,
      onPrimary: AppColors.surface,
      secondary: AppColors.primarySolid,
      onSecondary: AppColors.surface,
      error: AppColors.error,
      onError: AppColors.surface,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      outline: AppColors.border,
    ),
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
      labelSmall: AppTextStyles.labelSmall,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: AppTextStyles.titleLarge,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primarySolid,
        foregroundColor: AppColors.surface,
        textStyle: AppTextStyles.labelLarge,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedInput,
        ),
        minimumSize: const Size.fromHeight(56),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.p20,
        vertical: AppSpacing.p16,
      ),
      hintStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 21 / 14,
        color: AppColors.textMuted,
      ),
      border: OutlineInputBorder(
        borderRadius: AppSpacing.roundedInput,
        borderSide: BorderSide(color: AppColors.borderLight, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.roundedInput,
        borderSide: BorderSide(color: AppColors.borderLight, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.roundedInput,
        borderSide: BorderSide(color: AppColors.primarySolid, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.roundedInput,
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.roundedInput,
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.surface
            : AppColors.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primaryEnd
            : AppColors.surfaceMuted,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primarySoft,
      disabledColor: AppColors.surfaceMuted,
      labelStyle: AppTextStyles.labelLarge,
      secondaryLabelStyle: AppTextStyles.labelLarge.copyWith(
        color: AppColors.primaryEnd,
      ),
      side: const BorderSide(color: AppColors.border),
      shape: const StadiumBorder(),
      showCheckmark: false,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      modalBackgroundColor: AppColors.surface,
      modalBarrierColor: AppColors.scrim,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.surface,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryEnd,
    ),
  );
}

import 'package:flutter/material.dart';

/// Spacing and radius definitions from docs/design_system.md based on a 4-point grid.
abstract final class AppSpacing {
  // Named aliases
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;

  // 4-point grid
  static const double p4 = 4.0;
  static const double p8 = 8.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;
  static const double p40 = 40.0;

  /// Minimum touch target for interactive controls.
  static const double minTouchTarget = 48;

  // Screen horizontal padding
  static const double screenHorizontal = 24.0;
  static const double screenHorizontalCompact = 16.0;

  /// Standard screen padding: 24, reduced to 16 below 360 logical pixels.
  static double screenHorizontalFor(double width) =>
      width < 360 ? screenHorizontalCompact : screenHorizontal;

  // Corner radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusInput = 15.0;
  static const double radiusCard = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusDialog = 24.0;
  static const double radiusPill = 999.0;

  static const BorderRadius roundedSmall = BorderRadius.all(
    Radius.circular(radiusSmall),
  );
  static const BorderRadius roundedMedium = BorderRadius.all(
    Radius.circular(radiusMedium),
  );
  static const BorderRadius roundedInput = BorderRadius.all(
    Radius.circular(radiusInput),
  );
  static const BorderRadius roundedCard = BorderRadius.all(
    Radius.circular(radiusCard),
  );
  static const BorderRadius roundedLarge = BorderRadius.all(
    Radius.circular(radiusLarge),
  );
  static const BorderRadius roundedDialog = BorderRadius.all(
    Radius.circular(radiusDialog),
  );
  static const BorderRadius roundedPill = BorderRadius.all(
    Radius.circular(radiusPill),
  );

  // Elevation shadows
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x125A6CEA),
      blurRadius: 50,
      offset: Offset(12, 26),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0F5A6CEA),
      blurRadius: 20,
      offset: Offset(0, 7),
      spreadRadius: 0,
    ),
  ];
}

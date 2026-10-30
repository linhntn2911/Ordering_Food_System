/// 4-point spacing grid from `docs/design_system.md`.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;

  /// Minimum touch target for interactive controls.
  static const double minTouchTarget = 48;

  /// Standard screen padding: 24, reduced to 16 below 360 logical pixels.
  static double screenHorizontal(double width) => width < 360 ? lg : xxl;
}

import 'package:flutter/painting.dart';

import 'app_colors.dart';

abstract final class AppGradients {
  /// Food Ninja primary gradient for primary actions and small accents.
  static const primary = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primaryStart, AppColors.primaryEnd],
  );
}

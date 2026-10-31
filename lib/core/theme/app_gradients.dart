import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Food Ninja Gradient Tokens
class AppGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primaryStart, AppColors.primaryEnd],
  );
}

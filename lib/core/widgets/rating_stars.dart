import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Five stars for a 0–5 rating, with half stars for averages.
///
/// Screen readers hear "Đánh giá 4,5 trên 5" instead of five icons.
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  static String semanticLabel(double rating) {
    final value = rating.toStringAsFixed(1).replaceAll('.', ',');
    return 'Đánh giá $value trên 5';
  }

  @override
  Widget build(BuildContext context) {
    final clamped = rating.clamp(0, 5).toDouble();

    return Semantics(
      label: semanticLabel(clamped),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(_iconFor(clamped, i), size: size, color: AppColors.warning),
        ],
      ),
    );
  }

  static IconData _iconFor(double rating, int position) {
    if (rating >= position) {
      return Icons.star_rounded;
    }
    if (rating >= position - 0.5) {
      return Icons.star_half_rounded;
    }
    return Icons.star_outline_rounded;
  }
}

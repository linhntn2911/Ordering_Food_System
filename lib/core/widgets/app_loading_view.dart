import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// Loading placeholder.
///
/// The default form is a centered progress indicator. [AppLoadingView.skeleton]
/// shows grey blocks shaped like the content that is about to appear.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.semanticLabel = 'Đang tải'})
    : _skeletonRows = 0;

  const AppLoadingView.skeleton({
    super.key,
    int rows = 4,
    this.semanticLabel = 'Đang tải',
  }) : _skeletonRows = rows;

  final String semanticLabel;
  final int _skeletonRows;

  @override
  Widget build(BuildContext context) {
    if (_skeletonRows == 0) {
      return Center(
        child: Semantics(
          label: semanticLabel,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SkeletonBlock(height: 36, width: 220),
            const SizedBox(height: AppSpacing.p24),
            for (var i = 0; i < _skeletonRows; i++) ...[
              const _SkeletonBlock(height: 88),
              const SizedBox(height: AppSpacing.p12),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
    );
  }
}

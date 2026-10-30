import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.icon = Icons.restaurant_menu_rounded,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    final actionLabel = this.actionLabel;
    final onAction = this.onAction;
    final secondaryActionLabel = this.secondaryActionLabel;
    final onSecondaryAction = this.onSecondaryAction;
    final actions = [
      if (actionLabel != null && onAction != null)
        _action(actionLabel, onAction),
      if (secondaryActionLabel != null && onSecondaryAction != null)
        _action(secondaryActionLabel, onSecondaryAction),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.huge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }

  static Widget _action(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, AppSpacing.minTouchTarget),
        foregroundColor: AppColors.primaryEnd,
        side: const BorderSide(color: AppColors.primaryEnd),
        textStyle: AppTextStyles.labelLarge,
      ),
      child: Text(label),
    );
  }
}

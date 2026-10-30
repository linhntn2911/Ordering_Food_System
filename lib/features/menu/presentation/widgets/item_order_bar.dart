import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/vnd_format.dart';
import '../../domain/entities/item_selection.dart';

/// Fixed bottom bar: quantity stepper and "Thêm vào giỏ" with the running
/// total, or a disabled "Hết hàng" button for sold-out items.
class ItemOrderBar extends StatelessWidget {
  const ItemOrderBar({
    super.key,
    required this.canOrder,
    required this.quantity,
    required this.total,
    required this.onDecrease,
    required this.onIncrease,
    required this.onAddToCart,
  });

  final bool canOrder;
  final int quantity;
  final int total;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final padding = AppSpacing.screenHorizontalFor(
      MediaQuery.sizeOf(context).width,
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [AppShadows.card],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            padding,
            AppSpacing.p12,
            padding,
            AppSpacing.p12,
          ),
          child: Row(
            children: [
              if (canOrder) ...[
                _QuantityStepper(
                  quantity: quantity,
                  onDecrease: onDecrease,
                  onIncrease: onIncrease,
                ),
                const SizedBox(width: AppSpacing.p12),
              ],
              Expanded(
                child: canOrder
                    ? _AddButton(
                        label: 'Thêm vào giỏ · ${formatVnd(total)}',
                        onTap: onAddToCart,
                      )
                    : const _SoldOutButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          key: const ValueKey('detail-quantity-minus'),
          icon: Icons.remove_rounded,
          label: 'Giảm số lượng',
          onTap: quantity > ItemSelection.minQuantity ? onDecrease : null,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$quantity',
            key: const ValueKey('detail-quantity'),
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
            semanticsLabel: 'Số lượng $quantity',
          ),
        ),
        _StepButton(
          key: const ValueKey('detail-quantity-plus'),
          icon: Icons.add_rounded,
          label: 'Tăng số lượng',
          onTap: quantity < ItemSelection.maxQuantity ? onIncrease : null,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? AppColors.primarySoft : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadii.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        child: SizedBox.square(
          dimension: AppSpacing.minTouchTarget,
          child: Icon(
            icon,
            color: enabled ? AppColors.primaryEnd : AppColors.textMuted,
            semanticLabel: label,
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.input);
    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: radius,
          ),
          child: InkWell(
            key: const ValueKey('detail-add-to-cart'),
            onTap: onTap,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.p12,
                  vertical: AppSpacing.p8,
                ),
                // heightFactor keeps the bar as tall as its content.
                child: Center(
                  heightFactor: 1,
                  child: Text(
                    label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.surface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SoldOutButton extends StatelessWidget {
  const _SoldOutButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: false,
      label: 'Hết hàng, chưa thể thêm vào giỏ',
      excludeSemantics: true,
      child: Container(
        key: const ValueKey('detail-add-to-cart'),
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadii.input),
        ),
        child: Center(
          heightFactor: 1,
          child: Text(
            'Hết hàng',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

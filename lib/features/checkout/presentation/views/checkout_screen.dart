import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/theme/app_colors.dart';
import 'package:ordering_food_system/core/theme/app_gradients.dart';
import 'package:ordering_food_system/core/theme/app_radii.dart';
import 'package:ordering_food_system/core/theme/app_shadows.dart';
import 'package:ordering_food_system/core/theme/app_spacing.dart';
import 'package:ordering_food_system/core/theme/app_text_styles.dart';
import 'package:ordering_food_system/core/utils/currency_formatter.dart';
import 'package:ordering_food_system/features/address/data/models/address_model.dart';
import 'package:ordering_food_system/features/address/presentation/views/address_list_screen.dart';
import 'package:ordering_food_system/features/checkout/presentation/controllers/checkout_controller.dart';
import 'package:ordering_food_system/features/checkout/data/models/order_model.dart';

/// CheckoutScreen (Màn hình Thanh toán & Xác nhận Đơn hàng - Member 3)
/// Đáp ứng FR-014, FR-015, FR-016, FR-046, FR-047, FR-048, FR-049, FR-050, SC-005
class CheckoutScreen extends ConsumerWidget {
  final VoidCallback? onOrderSuccess;
  final VoidCallback? onBackPressed;

  const CheckoutScreen({super.key, this.onOrderSuccess, this.onBackPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkoutControllerProvider);
    final controller = ref.read(checkoutControllerProvider.notifier);

    // Error feedback
    ref.listen<CheckoutState>(checkoutControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadii.radiusMedium,
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Xác nhận đơn hàng',
          style: AppTextStyles.headlineMedium,
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            if (onBackPressed != null) {
              onBackPressed!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: state.cartItems.isEmpty && state.lastCreatedOrder == null
            ? const _EmptyCheckoutView()
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s24,
                        vertical: AppSpacing.s16,
                      ),
                      children: [
                        // 1. Delivery Address Card (FR-014, FR-046)
                        _DeliveryAddressCard(
                          address: state.selectedAddress,
                          distanceKm: state.deliveryDistanceKm,
                          isServiceable: state.isServiceable,
                          isResolvable: state.isDistanceResolvable,
                          onChangeAddress: () =>
                              _selectAddressFlow(context, controller),
                        ),

                        const SizedBox(height: AppSpacing.s20),

                        // 2. Payment Method Card (COD Only - FR-015)
                        const _PaymentMethodSection(),

                        const SizedBox(height: AppSpacing.s20),

                        // 3. Order Items Summary (Snapshot Preview)
                        _OrderItemsPreview(cartItems: state.cartItems),

                        const SizedBox(height: AppSpacing.s20),

                        // 4. Delivery Instructions / Note
                        _DeliveryNoteField(
                          onChanged: controller.updateDeliveryNote,
                        ),

                        const SizedBox(height: AppSpacing.s24),

                        // 5. Cost Breakdown Summary (FR-047, FR-049, BR-005)
                        _CostBreakdownCard(state: state),

                        const SizedBox(height: AppSpacing.s16),

                        // Validation warning banner if blocked (FR-048)
                        if (state.validationErrorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.s12),
                            decoration: const BoxDecoration(
                              color: AppColors.errorSoft,
                              borderRadius: AppRadii.radiusMedium,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.s8),
                                Expanded(
                                  child: Text(
                                    state.validationErrorMessage!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 6. Confirm Order Bottom Action (SC-005: Duplicate tap guard)
                  _CheckoutBottomButton(
                    state: state,
                    onPlaceOrder: () async {
                      final order = await controller.placeOrder();
                      if (order != null && context.mounted) {
                        _showOrderSuccessDialog(context, order);
                      }
                    },
                  ),
                ],
              ),
      ),
    );
  }

  void _selectAddressFlow(
    BuildContext context,
    CheckoutController controller,
  ) async {
    final selected = await Navigator.of(context).push<AddressModel>(
      MaterialPageRoute(
        builder: (_) => const AddressListScreen(isSelectionMode: true),
      ),
    );
    if (selected != null) {
      controller.selectAddress(selected);
    }
  }

  void _showOrderSuccessDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.radiusDialog,
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success green circle
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primarySolid,
                  size: 48,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              const Text(
                'Đặt hàng thành công!',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Mã đơn hàng: ${order.orderCode}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryEnd,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                'Đơn hàng của bạn đang ở trạng thái "${order.status.displayName}". Quán sẽ sớm chuẩn bị và giao món ăn đến bạn.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Tổng tiền: ${CurrencyFormatter.formatVND(order.total)} (COD)',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              GestureDetector(
                onTap: () {
                  Navigator.of(dialogCtx).pop();
                  if (onOrderSuccess != null) {
                    onOrderSuccess!();
                  } else if (onBackPressed != null) {
                    onBackPressed!();
                  } else if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  height: 48,
                  decoration: const BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: AppRadii.radiusMedium,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Hoàn tất',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Delivery address card showing selected recipient, full address, and distance fee badge
class _DeliveryAddressCard extends StatelessWidget {
  final AddressModel? address;
  final double? distanceKm;
  final bool isServiceable;
  final bool isResolvable;
  final VoidCallback onChangeAddress;

  const _DeliveryAddressCard({
    required this.address,
    required this.distanceKm,
    required this.isServiceable,
    required this.isResolvable,
    required this.onChangeAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.radiusCard,
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primarySolid,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    'Địa chỉ giao hàng',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onChangeAddress,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  address != null ? 'Thay đổi' : 'Chọn địa chỉ',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primarySolid,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.s12),

          if (address != null) ...[
            Text(
              '${address!.recipientName}  |  ${address!.phoneNumber}',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              address!.fullAddress,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),

            // Distance & Serviceability Badge (FR-046, FR-047, FR-048)
            if (isResolvable && distanceKm != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isServiceable
                      ? AppColors.primarySoft
                      : AppColors.errorSoft,
                  borderRadius: AppRadii.radiusSmall,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isServiceable
                          ? Icons.delivery_dining_rounded
                          : Icons.warning_amber_rounded,
                      size: 16,
                      color: isServiceable
                          ? AppColors.primarySolid
                          : AppColors.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isServiceable
                          ? 'Cự ly: ${distanceKm!.toStringAsFixed(1)} km  •  Phí giao: ${CurrencyFormatter.formatVND(address!.deliveryFee ?? 0)}'
                          : 'Cự ly: ${distanceKm!.toStringAsFixed(1)} km (Vượt quá 8km, ngoài phạm vi phục vụ)',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isServiceable
                            ? AppColors.primaryEnd
                            : AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12,
                  vertical: 6,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: AppRadii.radiusSmall,
                ),
                child: Text(
                  'Chưa xác định được tọa độ để tính cự ly giao hàng.',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ] else ...[
            GestureDetector(
              onTap: onChangeAddress,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: AppRadii.radiusMedium,
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+ Nhấn để chọn hoặc thêm địa chỉ nhận hàng',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primarySolid,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Payment method section: COD only (FR-015)
class _PaymentMethodSection extends StatelessWidget {
  const _PaymentMethodSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.radiusCard,
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phương thức thanh toán (FR-015)',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),

          // Cash on Delivery item
          Container(
            padding: const EdgeInsets.all(AppSpacing.s12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppRadii.radiusMedium,
              border: Border.all(color: AppColors.primarySolid, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.payments_rounded,
                  color: AppColors.primarySolid,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tiền mặt khi nhận hàng (COD)',
                        style: AppTextStyles.titleMedium,
                      ),
                      Text(
                        'Thanh toán bằng tiền mặt cho nhân viên giao hàng',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primarySolid,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ordered items summary snapshot
class _OrderItemsPreview extends StatelessWidget {
  final List cartItems;

  const _OrderItemsPreview({required this.cartItems});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.radiusCard,
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Món ăn đã chọn (${cartItems.length})',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Chi tiết',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          const Divider(color: AppColors.surfaceMuted, height: 1),
          const SizedBox(height: AppSpacing.s8),
          ...cartItems.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${item.quantity}x',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primaryEnd,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${item.selectedSize.name}${item.selectedToppings.isNotEmpty ? " + ${item.selectedToppings.length} topping" : ""}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatVND(item.subtotal),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Optional delivery note input field
class _DeliveryNoteField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _DeliveryNoteField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.radiusCard,
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ghi chú đơn hàng',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Ví dụ: Gọi trước khi giao, để đồ ở sảnh...',
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s12,
              ),
              filled: true,
              fillColor: AppColors.surfaceMuted,
              border: const OutlineInputBorder(
                borderRadius: AppRadii.radiusMedium,
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Authoritative cost breakdown card (FR-047, FR-049, BR-005)
class _CostBreakdownCard extends StatelessWidget {
  final CheckoutState state;

  const _CostBreakdownCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final fee = state.deliveryFee;
    final total = state.total;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.radiusCard,
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chi tiết thanh toán', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.s12),

          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tạm tính món ăn', style: AppTextStyles.bodyMedium),
              Text(
                CurrencyFormatter.formatVND(state.subtotal),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.s8),

          // Delivery Fee with distance band
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.deliveryDistanceKm != null
                    ? 'Phí giao hàng (${state.deliveryDistanceKm!.toStringAsFixed(1)} km)'
                    : 'Phí giao hàng',
                style: AppTextStyles.bodyMedium,
              ),
              Text(
                fee != null ? CurrencyFormatter.formatVND(fee) : '--',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: fee != null ? AppColors.textPrimary : AppColors.error,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.s12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: AppSpacing.s12),

          // Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán',
                style: AppTextStyles.headlineMedium,
              ),
              Text(
                total != null ? CurrencyFormatter.formatVND(total) : '--',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.primaryEnd,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Checkout CTA button with duplicate tap lock (SC-005)
class _CheckoutBottomButton extends StatelessWidget {
  final CheckoutState state;
  final VoidCallback onPlaceOrder;

  const _CheckoutBottomButton({
    required this.state,
    required this.onPlaceOrder,
  });

  @override
  Widget build(BuildContext context) {
    final canSubmit = state.canSubmitOrder;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadii.large),
          topRight: Radius.circular(AppRadii.large),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1409051C),
            offset: Offset(0, -4),
            blurRadius: 20,
          ),
        ],
      ),
      child: GestureDetector(
        onTap: canSubmit ? onPlaceOrder : null,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: canSubmit ? AppGradients.primary : null,
            color: canSubmit ? null : AppColors.surfaceMuted,
            borderRadius: AppRadii.radiusInput,
            boxShadow: canSubmit ? const [AppShadows.primaryShadow] : null,
          ),
          alignment: Alignment.center,
          child: state.isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Xác nhận đặt hàng',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: canSubmit ? Colors.white : AppColors.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: canSubmit ? Colors.white : AppColors.textMuted,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Empty view when navigated to checkout with empty cart
class _EmptyCheckoutView extends StatelessWidget {
  const _EmptyCheckoutView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.remove_shopping_cart_rounded,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.s16),
            const Text(
              'Không có món ăn để thanh toán',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Giỏ hàng của bạn đang trống, vui lòng thêm món ăn trước khi vào trang thanh toán.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySolid,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.radiusMedium,
                ),
              ),
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }
}

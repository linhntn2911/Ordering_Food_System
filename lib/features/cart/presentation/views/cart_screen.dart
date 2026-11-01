import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/features/checkout/presentation/views/checkout_screen.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/cart_item_model.dart';
import '../controllers/cart_controller.dart';

/// CartScreen (Màn hình Giỏ hàng - Phụ trách bởi Member 3 - Hồng Anh)
/// Toàn bộ giao diện được viết gọn gàng và khép kín trong duy nhất file này.
class CartScreen extends ConsumerWidget {
  final VoidCallback? onNavigateToCheckout;
  final VoidCallback? onBrowseMenu;
  final VoidCallback? onBackPressed;

  const CartScreen({
    super.key,
    this.onNavigateToCheckout,
    this.onBrowseMenu,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartControllerProvider);
    final cartController = ref.read(cartControllerProvider.notifier);

    // Lắng nghe lỗi hiển thị SnackBar
    ref.listen<CartState>(cartControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.errorMessage!,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadii.radiusMedium,
            ),
            action: SnackBarAction(
              label: 'Đóng',
              textColor: Colors.white,
              onPressed: () => cartController.clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Giỏ hàng của bạn',
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
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang ở màn hình Giỏ hàng chính.'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
        ),
        actions: [
          if (cartState.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: AppColors.error,
              ),
              tooltip: 'Xóa tất cả',
              onPressed: () => _confirmClearCart(context, ref),
            ),
        ],
      ),
      body: SafeArea(
        child: cartState.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primarySolid),
              )
            : cartState.isEmpty
            ? _buildEmptyCart(context, ref)
            : Column(
                children: [
                  // 1. Toolbar: Chọn tất cả và đếm số món
                  _buildToolbar(cartState, cartController),

                  // 2. Banner cảnh báo món hết hàng (nếu có)
                  if (cartState.hasSelectedUnavailableItems)
                    _buildWarningBanner(),

                  // 3. Danh sách món ăn kiểu Shopee + Nút "+ Thêm món khác"
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s24,
                        vertical: AppSpacing.s12,
                      ),
                      itemCount: cartState.items.length + 1,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.s12),
                      itemBuilder: (context, index) {
                        // Nút "+ Thêm món khác" ở cuối danh sách (onPressed: () {})
                        if (index == cartState.items.length) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              top: AppSpacing.s8,
                              bottom: AppSpacing.s16,
                            ),
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primarySolid,
                                side: const BorderSide(
                                  color: AppColors.primarySolid,
                                  width: 1.5,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadii.radiusInput,
                                ),
                                minimumSize: const Size.fromHeight(48),
                              ),
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                color: AppColors.primarySolid,
                              ),
                              label: const Text(
                                '+ Thêm món khác',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              onPressed: () {}, // Đứng im, không mở popup
                            ),
                          );
                        }

                        return _buildCartItem(
                          cartController,
                          cartState.items[index],
                        );
                      },
                    ),
                  ),

                  // 4. Thanh tổng tiền & Nút tiến hành đặt hàng
                  _buildBottomSummary(context, cartState, () {
                    if (cartController.validateCartForCheckout()) {
                      if (onNavigateToCheckout != null) {
                        onNavigateToCheckout!();
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CheckoutScreen(),
                          ),
                        );
                      }
                    }
                  }),
                ],
              ),
      ),
    );
  }

  // --- TOOLBAR NỘI BỘ ---
  Widget _buildToolbar(CartState state, CartController controller) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.s24,
        AppSpacing.s8,
        AppSpacing.s24,
        AppSpacing.s4,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.radiusMedium,
        boxShadow: const [AppShadows.cardShadow],
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: Row(
        children: [
          Checkbox(
            value: state.isAllSelected,
            activeColor: AppColors.primarySolid,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (val) => controller.toggleSelectAll(val ?? false),
          ),
          Text(
            'Chọn tất cả',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '(${state.itemCount} món trong giỏ)',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // --- BANNER CẢNH BÁO NỘI BỘ ---
  Widget _buildWarningBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s24,
        vertical: AppSpacing.s8,
      ),
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: const BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: AppRadii.radiusMedium,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.warningMedium),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              'Có món đang chọn hiện tạm hết hàng. Vui lòng bỏ chọn hoặc xóa để tiếp tục thanh toán.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- THẺ MÓN ĂN KIỂU SHOPEE NỘI BỘ ---
  Widget _buildCartItem(CartController controller, CartItemModel item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.radiusCard,
        boxShadow: const [AppShadows.cardShadow],
        border: item.isAvailable
            ? (item.isSelected
                ? Border.all(
                    color: AppColors.primarySolid.withValues(alpha: 0.5),
                    width: 1.2,
                  )
                : Border.all(color: AppColors.surfaceMuted, width: 1))
            : Border.all(color: AppColors.error, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Checkbox chọn món (xanh lá)
          Transform.scale(
            scale: 1.05,
            child: Checkbox(
              value: item.isSelected,
              activeColor: AppColors.primarySolid,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: item.isAvailable
                  ? (_) => controller.toggleItemSelection(item.id)
                  : null,
            ),
          ),
          const SizedBox(width: 4),

          // 2. Thumbnail vuông 70x70, bo góc 8dp
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 70,
              height: 70,
              color: AppColors.surfaceMuted,
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.fastfood_rounded,
                        color: AppColors.textMuted,
                        size: 32,
                      ),
                    )
                  : const Icon(
                      Icons.fastfood_rounded,
                      color: AppColors.textMuted,
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // 3. Tên món, phân loại, giá và cụm số lượng
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: item.isAvailable
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _buildVariantText(item),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!item.isAvailable) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Tạm hết hàng',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 6),

                // Đơn giá & Cụm nút [-] [Số lượng] [+]
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      CurrencyFormatter.formatVND(item.unitPrice),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primaryEnd,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: AppRadii.radiusPill,
                        border: Border.all(color: AppColors.border, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(14),
                            ),
                            onTap: () => controller.decrementQuantity(item.id),
                            child: Container(
                              width: 26,
                              height: 28,
                              alignment: Alignment.center,
                              child: Icon(
                                item.quantity == 1
                                    ? Icons.delete_outline_rounded
                                    : Icons.remove_rounded,
                                size: 15,
                                color: item.quantity == 1
                                    ? AppColors.error
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 22),
                            alignment: Alignment.center,
                            child: Text(
                              '${item.quantity}',
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(14),
                            ),
                            onTap: () => controller.incrementQuantity(item.id),
                            child: Container(
                              width: 26,
                              height: 28,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.add_rounded,
                                size: 15,
                                color: AppColors.primaryEnd,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // 4. Nút xóa dòng món ăn
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            tooltip: 'Xóa món',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => controller.removeItem(item.id),
          ),
        ],
      ),
    );
  }

  // --- TÓM TẮT CHI PHÍ & ĐẶT HÀNG NỘI BỘ ---
  Widget _buildBottomSummary(
    BuildContext context,
    CartState cartState,
    VoidCallback onProceed,
  ) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tạm tính (chỉ tính món đã chọn)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tạm tính (${cartState.selectedItemCount} món đã chọn)',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                CurrencyFormatter.formatVND(cartState.subtotal),
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),

          // Gợi ý phí giao hàng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Phí giao hàng',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                'Tính khi chọn địa chỉ (tối đa 8km)',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.s12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: AppSpacing.s12),

          // Tổng tiền món ăn (Chỉ tính tiền các món có isSelected == true)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng tiền món ăn',
                style: AppTextStyles.headlineMedium,
              ),
              Text(
                CurrencyFormatter.formatVND(cartState.subtotal),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.primaryEnd,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.s20),

          // Nút tiến hành đặt hàng
          GestureDetector(
            onTap: cartState.canProceedToCheckout ? onProceed : null,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: cartState.canProceedToCheckout
                    ? AppGradients.primary
                    : null,
                color: cartState.canProceedToCheckout
                    ? null
                    : AppColors.surfaceMuted,
                borderRadius: AppRadii.radiusInput,
                boxShadow: cartState.canProceedToCheckout
                    ? const [AppShadows.primaryShadow]
                    : null,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    cartState.hasSelectedItems
                        ? 'Tiến hành đặt hàng (${cartState.selectedItemCount})'
                        : 'Chọn món để đặt hàng',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: cartState.canProceedToCheckout
                          ? Colors.white
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: cartState.canProceedToCheckout
                        ? Colors.white
                        : AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- GIỎ HÀNG TRỐNG NỘI BỘ ---
  Widget _buildEmptyCart(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 50,
                color: AppColors.primarySolid,
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            const Text(
              'Giỏ hàng của bạn đang trống',
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Hãy khám phá thực đơn hoặc nạp danh sách món mẫu để trải nghiệm thử!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s24),

            // Nút "Nạp lại danh sách món mẫu để kiểm thử"
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySolid,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.radiusInput,
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text(
                'Nạp lại danh sách món mẫu để kiểm thử',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              onPressed: () {
                ref.read(cartControllerProvider.notifier).reloadDemoItems();
              },
            ),
            const SizedBox(height: AppSpacing.s12),

            // Nút "Khám phá thực đơn ngay"
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                minimumSize: const Size.fromHeight(48),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.radiusInput,
                ),
              ),
              onPressed: () {
                if (onBrowseMenu != null) {
                  onBrowseMenu!();
                } else if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'Khám phá thực đơn ngay',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildVariantText(CartItemModel item) {
    final parts = <String>[];
    if (item.selectedSize.name.isNotEmpty) {
      parts.add(item.selectedSize.name);
    }
    if (item.selectedToppings.isNotEmpty) {
      parts.add(item.selectedToppings.map((e) => e.name).join(', '));
    }
    if (item.note != null && item.note!.trim().isNotEmpty) {
      parts.add('Ghi chú: ${item.note!.trim()}');
    }
    return parts.isEmpty ? 'Mặc định' : parts.join(' • ');
  }

  void _confirmClearCart(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.radiusDialog,
        ),
        title: const Text('Xác nhận', style: AppTextStyles.titleMedium),
        content: const Text(
          'Bạn có chắc chắn muốn xóa toàn bộ món ăn trong giỏ hàng?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Hủy',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.radiusMedium,
              ),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref.read(cartControllerProvider.notifier).clearCart();
            },
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/address_model.dart';
import '../controllers/address_controller.dart';
import 'add_edit_address_screen.dart';

/// AddressListScreen (Màn hình Danh sách Địa chỉ Giao hàng - Member 3)
/// Đáp ứng FR-017, FR-018, User Story 8 Scenario 2
class AddressListScreen extends ConsumerWidget {
  /// Whether screen is in selection mode (invoked from Checkout flow)
  final bool isSelectionMode;
  final ValueChanged<AddressModel>? onAddressSelected;

  const AddressListScreen({
    super.key,
    this.isSelectionMode = false,
    this.onAddressSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addressControllerProvider);
    final controller = ref.read(addressControllerProvider.notifier);

    // Show error feedback via SnackBar
    ref.listen<AddressState>(addressControllerProvider, (previous, next) {
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
        title: Text(
          isSelectionMode ? 'Chọn địa chỉ giao hàng' : 'Sổ địa chỉ',
          style: AppTextStyles.headlineMedium,
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            // 1. Loading State
            if (state.isLoading && state.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primarySolid),
              );
            }

            // 2. Error State
            if (state.errorMessage != null && state.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      Text(
                        state.errorMessage!,
                        style: AppTextStyles.bodyLarge,
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
                        onPressed: () => controller.loadAddresses(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // 3. Empty State
            if (state.isEmpty) {
              return _EmptyAddressView(
                onAddAddress: () => _navigateToAddAddress(context),
              );
            }

            // 4. Success State (List of addresses)
            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s24,
                      vertical: AppSpacing.s16,
                    ),
                    itemCount: state.addresses.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.s16),
                    itemBuilder: (context, index) {
                      final address = state.addresses[index];
                      final isSelected = state.selectedAddressId == address.id;

                      return _AddressCard(
                        address: address,
                        isSelectionMode: isSelectionMode,
                        isSelected: isSelected,
                        onSelect: () {
                          if (isSelectionMode) {
                            controller.selectAddress(address.id);
                            if (onAddressSelected != null) {
                              onAddressSelected!(address);
                            }
                            Navigator.of(context).maybePop(address);
                          }
                        },
                        onSetDefault: () =>
                            controller.setDefaultAddress(address.id),
                        onEdit: () => _navigateToEditAddress(context, address),
                        onDelete: () =>
                            _confirmDeleteAddress(context, ref, address),
                      );
                    },
                  ),
                ),

                // Bottom CTA Button: Add new address
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.s24),
                  child: GestureDetector(
                    onTap: () => _navigateToAddAddress(context),
                    child: Container(
                      height: 56,
                      decoration: const BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: AppRadii.radiusInput,
                        boxShadow: [AppShadows.primaryShadow],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_location_alt_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          Text(
                            'Thêm địa chỉ mới',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _navigateToAddAddress(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddEditAddressScreen()));
  }

  void _navigateToEditAddress(BuildContext context, AddressModel address) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditAddressScreen(initialAddress: address),
      ),
    );
  }

  void _confirmDeleteAddress(
    BuildContext context,
    WidgetRef ref,
    AddressModel address,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.radiusDialog,
        ),
        title: const Text('Xóa địa chỉ', style: AppTextStyles.titleMedium),
        content: Text(
          'Bạn có chắc chắn muốn xóa địa chỉ "${address.streetAddress}" khỏi danh sách?',
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
              ref
                  .read(addressControllerProvider.notifier)
                  .deleteAddress(address.id);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

/// Address card displaying details, default status chip, and management actions
class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelect,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final distance = address.distanceToRestaurant;
    final deliveryFee = address.deliveryFee;

    return InkWell(
      onTap: isSelectionMode ? onSelect : null,
      borderRadius: AppRadii.radiusCard,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.radiusCard,
          boxShadow: const [AppShadows.cardShadow],
          border: Border.all(
            color: isSelected
                ? AppColors.primarySolid
                : address.isDefault
                ? AppColors.primaryStart
                : AppColors.surfaceMuted,
            width: isSelected || address.isDefault ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Label chip + Default badge + Radio/Menu
            Row(
              children: [
                // Label icon & tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: AppRadii.radiusSmall,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        address.label == 'Văn phòng'
                            ? Icons.business_rounded
                            : Icons.home_rounded,
                        size: 14,
                        color: AppColors.primarySolid,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        address.label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpacing.s8),

                // Default badge (FR-018)
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s8,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: AppRadii.radiusSmall,
                    ),
                    child: Text(
                      'Mặc định',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryEnd,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                const Spacer(),

                // Radio indicator if in selection mode
                if (isSelectionMode)
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: isSelected
                        ? AppColors.primarySolid
                        : AppColors.textMuted,
                  )
                else
                  // Quick Actions Menu
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: AppColors.primarySolid,
                        ),
                        tooltip: 'Chỉnh sửa',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: onEdit,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppColors.error,
                        ),
                        tooltip: 'Xóa',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.s12),

            // Recipient Name & Phone (FR-014)
            Row(
              children: [
                Text(
                  address.recipientName,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  '|  ${address.phoneNumber}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.s8),

            // Full address lines
            Text(
              address.fullAddress,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            // Distance & Delivery Fee Info Banner (FR-046, FR-047, FR-048)
            if (distance != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: address.isServiceable
                      ? AppColors.primarySoft
                      : AppColors.errorSoft,
                  borderRadius: AppRadii.radiusSmall,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      address.isServiceable
                          ? Icons.delivery_dining_rounded
                          : Icons.location_off_rounded,
                      size: 16,
                      color: address.isServiceable
                          ? AppColors.primarySolid
                          : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      address.isServiceable
                          ? 'Khoảng cách: ${distance.toStringAsFixed(1)} km  •  Phí giao: ${CurrencyFormatter.formatVND(deliveryFee ?? 0)}'
                          : 'Cách quán ${distance.toStringAsFixed(1)} km (Vượt quá 8km, ngoài phạm vi giao)',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: address.isServiceable
                            ? AppColors.primaryEnd
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action: Set as default if not currently default (FR-018)
            if (!address.isDefault && !isSelectionMode) ...[
              const SizedBox(height: AppSpacing.s8),
              const Divider(color: AppColors.surfaceMuted, height: 1),
              const SizedBox(height: AppSpacing.s4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onSetDefault,
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: AppColors.primarySolid,
                  ),
                  label: Text(
                    'Đặt làm mặc định',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primarySolid,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty view when no delivery address is present
class _EmptyAddressView extends StatelessWidget {
  final VoidCallback onAddAddress;

  const _EmptyAddressView({required this.onAddAddress});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 60,
                color: AppColors.primarySolid,
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            const Text(
              'Chưa có địa chỉ giao hàng',
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Vui lòng thêm địa chỉ nhận hàng để Food Ninja có thể giao những bữa ăn nóng hổi đến cho bạn!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s32),
            GestureDetector(
              onTap: onAddAddress,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
                decoration: const BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: AppRadii.radiusInput,
                  boxShadow: [AppShadows.primaryShadow],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Thêm địa chỉ ngay',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

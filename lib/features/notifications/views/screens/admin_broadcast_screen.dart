import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/admin_drawer.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../viewmodels/admin_broadcast_view_model.dart';

class AdminBroadcastScreen extends ConsumerStatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  ConsumerState<AdminBroadcastScreen> createState() =>
      _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends ConsumerState<AdminBroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  NotificationType _selectedType = NotificationType.promo;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(adminBroadcastViewModelProvider.notifier)
        .sendBroadcast(
          title: _titleController.text,
          body: _bodyController.text,
          type: _selectedType,
        );

    if (success && mounted) {
      _titleController.clear();
      _bodyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Đã phát thông báo thành công đến khách hàng!'),
              ),
            ],
          ),
          backgroundColor: AppColors.primarySolid,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final broadcastState = ref.watch(adminBroadcastViewModelProvider);
    final notificationsAsync = ref.watch(notificationsListProvider);

    // Listen for error feedback
    ref.listen<AdminBroadcastState>(adminBroadcastViewModelProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AdminDrawer(
        currentDestination: AdminDestination.broadcasts,
      ),
      appBar: AppBar(
        title: const Text(
          'Phát thông báo hệ thống',
          style: AppTextStyles.headlineMedium,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primaryEnd,
            ),
            onPressed: () => ref.invalidate(notificationsListProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryEnd,
          onRefresh: () async => ref.refresh(notificationsListProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              // Header description
              Text(
                'Tạo thông báo & ưu đãi mới',
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Gửi thông báo giảm giá, khuyến mãi hoặc bảo trì hệ thống trực tiếp đến toàn bộ khách hàng.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Compose Broadcast Form Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.large),
                  boxShadow: const [AppShadows.card],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Type selector chips
                      Text(
                        'Loại thông báo',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _TypeChip(
                              label: 'Ưu đãi / Giảm giá',
                              icon: Icons.local_offer_rounded,
                              isSelected:
                                  _selectedType == NotificationType.promo,
                              activeColor: AppColors.foodAccentDark,
                              activeBg: AppColors.warningSurface,
                              onTap: () => setState(
                                () => _selectedType = NotificationType.promo,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _TypeChip(
                              label: 'Hệ thống',
                              icon: Icons.info_rounded,
                              isSelected:
                                  _selectedType == NotificationType.system,
                              activeColor: AppColors.primarySolid,
                              activeBg: AppColors.primarySoft,
                              onTap: () => setState(
                                () => _selectedType = NotificationType.system,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Title field
                      TextFormField(
                        key: const ValueKey('broadcast-title-input'),
                        controller: _titleController,
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề thông báo *',
                          hintText: 'Ví dụ: Siêu hội giảm 30% toàn menu!',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                          prefixIcon: const Icon(
                            Icons.campaign_outlined,
                            color: AppColors.primarySolid,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.input),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tiêu đề thông báo.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Body field
                      TextFormField(
                        key: const ValueKey('broadcast-body-input'),
                        controller: _bodyController,
                        maxLines: 3,
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Nội dung chi tiết *',
                          hintText: 'Ví dụ: Nhập mã NGO30 để được giảm 30% tối đa 50.000đ khi đặt món hôm nay.',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 40),
                            child: Icon(
                              Icons.description_outlined,
                              color: AppColors.primarySolid,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.input),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập nội dung chi tiết.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Send button
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          borderRadius: BorderRadius.circular(AppRadii.large),
                          boxShadow: const [AppShadows.primary],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: const ValueKey('broadcast-send-button'),
                            borderRadius: BorderRadius.circular(AppRadii.large),
                            onTap: broadcastState.isLoading
                                ? null
                                : _handleSend,
                            child: Center(
                              child: broadcastState.isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Text(
                                          'Gửi thông báo ngay',
                                          style: AppTextStyles.labelLarge
                                              .copyWith(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Broadcast History Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Lịch sử thông báo đã gửi',
                      style: AppTextStyles.titleLarge,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      'Tất cả',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryEnd,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              notificationsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryEnd,
                    ),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Lỗi tải danh sách: $err'),
                  ),
                ),
                data: (notifications) {
                  final broadcasts = notifications
                      .where(
                        (n) =>
                            n.type == NotificationType.promo ||
                            n.type == NotificationType.system,
                      )
                      .toList();

                  if (broadcasts.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.large),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Chưa có thông báo hệ thống nào được gửi.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: broadcasts.map((notification) {
                      final isPromo =
                          notification.type == NotificationType.promo;
                      final typeLabel = isPromo ? 'ƯU ĐÃI' : 'HỆ THỐNG';
                      final typeColor = isPromo
                          ? AppColors.foodAccentDark
                          : AppColors.primarySolid;
                      final typeBg = isPromo
                          ? AppColors.warningSurface
                          : AppColors.primarySoft;
                      final icon = isPromo
                          ? Icons.local_offer_rounded
                          : Icons.info_rounded;

                      final timeString = DateFormat('dd/MM/yyyy HH:mm')
                          .format(notification.createdAt);

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          boxShadow: const [AppShadows.card],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: typeBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: typeColor, size: 22),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: typeBg,
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.small,
                                          ),
                                        ),
                                        child: Text(
                                          typeLabel,
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                color: typeColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      Text(
                                        timeString,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    notification.title,
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.body,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.activeBg,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final Color activeBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? activeBg : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.borderLight,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? activeColor : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isSelected ? activeColor : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

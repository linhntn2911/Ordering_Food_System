import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../viewmodels/admin_unread_count_provider.dart';

class AdminMessagesButton extends ConsumerWidget {
  const AdminMessagesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(adminUnreadCountProvider);
    final label = unread.when(
      data: (count) => 'Tin nhắn, $count cuộc trò chuyện chưa đọc',
      loading: () => 'Tin nhắn, đang tải số chưa đọc',
      error: (_, _) => 'Tin nhắn, không tải được số chưa đọc',
    );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.p4,
      children: [
        Semantics(
          label: label,
          button: true,
          excludeSemantics: true,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminMessages),
          child: FilledButton.tonal(
            key: const ValueKey('dashboard-messages-button'),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.adminMessages),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.minTouchTarget),
              backgroundColor: AppColors.primarySoft,
              foregroundColor: AppColors.primaryEnd,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.medium),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 24),
                const SizedBox(width: AppSpacing.p8),
                const Text('Tin nhắn'),
                unread.when(
                  data: (count) => count == 0
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.p8),
                          child: Badge(
                            key: const ValueKey('dashboard-messages-badge'),
                            backgroundColor: AppColors.error,
                            textColor: AppColors.surface,
                            label: Text(count > 99 ? '99+' : '$count'),
                          ),
                        ),
                  loading: () => const Padding(
                    padding: EdgeInsets.only(left: AppSpacing.p8),
                    child: SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (_, _) => const Padding(
                    padding: EdgeInsets.only(left: AppSpacing.p8),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 20,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (unread.hasError)
          IconButton(
            tooltip: 'Thử tải lại số chưa đọc',
            onPressed: () {
              ref.invalidate(adminUnreadCountByKindProvider(true));
              ref.invalidate(adminUnreadCountByKindProvider(false));
              if (ref.read(authStateProvider).hasError) {
                ref.invalidate(authStateProvider);
              }
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
      ],
    );
  }
}

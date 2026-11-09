import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Bell icon with the current number of unread notifications.
///
/// The count is supplied by the presentation layer so this widget stays free
/// of Firebase and Riverpod dependencies.
class NotificationBadgeIcon extends StatelessWidget {
  const NotificationBadgeIcon({
    super.key,
    required this.unreadCount,
    this.color,
    this.size = 24,
  });

  final int unreadCount;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final count = unreadCount < 0 ? 0 : unreadCount;
    final label = count > 99 ? '99+' : '$count';

    return Semantics(
      label: count == 0
          ? 'Không có thông báo chưa đọc'
          : 'Có $count thông báo chưa đọc',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size + 8,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: size, color: color),
            if (count > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  key: const ValueKey('notification-unread-badge'),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.surface, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.surface,
                      fontSize: 9,
                      height: 1,
                      fontWeight: FontWeight.w700,
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

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class ChatUnreadDot extends StatelessWidget {
  const ChatUnreadDot({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Có tin nhắn chưa đọc',
    child: const DecoratedBox(
      decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
      child: SizedBox.square(dimension: AppSpacing.p8),
    ),
  );
}

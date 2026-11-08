import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_shadows.dart';
import '../views/general_chat_screen.dart';
import '../viewmodels/admin_messages_view_model.dart';
import 'chat_unread_dot.dart';

class HomeOrderSupportButton extends ConsumerWidget {
  const HomeOrderSupportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Tooltip(
    message: 'Nhắn nhà hàng',
    child: DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.primary,
        boxShadow: [AppShadows.primary],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute<void>(builder: (_) => const GeneralChatScreen()),
          ),
          child: SizedBox.square(
            dimension: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.surface,
                  semanticLabel: 'Nhắn nhà hàng',
                ),
                if (ref.watch(generalChatUnreadProvider).value == true)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: ChatUnreadDot(key: ValueKey('home-general-unread')),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

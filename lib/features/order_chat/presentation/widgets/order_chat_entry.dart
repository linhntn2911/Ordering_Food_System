import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/chat_role.dart';
import '../viewmodels/order_chat_providers.dart';
import '../views/order_chat_screen.dart';
import 'chat_unread_dot.dart';

class OrderChatEntry extends ConsumerWidget {
  const OrderChatEntry({super.key, required this.orderId, required this.role});

  final String orderId;
  final ChatRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(chatOrderProvider(orderId));
    final conversation = ref.watch(orderChatStreamProvider(orderId));
    final isAdmin = role == ChatRole.admin;
    final currentOrder = order.value;
    final chat = conversation.value;
    if (!isAdmin &&
        currentOrder != null &&
        conversation is AsyncData &&
        chat == null &&
        !ref.watch(chatOpenProvider(currentOrder))) {
      return const Text(
        'Bạn có thể báo vấn đề trong 24 giờ sau khi đơn kết thúc.',
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        key: ValueKey(isAdmin ? 'admin-order-chat-open' : 'order-chat-open'),
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
        onPressed: () => Navigator.of(context).pushNamed(
          AppRoutes.orderChat,
          arguments: OrderChatArgs(orderId, role),
        ),
        icon: const Icon(Icons.chat_bubble_outline),
        label: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.p8,
          children: [
            Text(isAdmin ? 'Nhắn khách' : 'Nhắn nhà hàng'),
            if (chat?.unreadFor(role) == true) const ChatUnreadDot(),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/admin_gate.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/admin_drawer.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../domain/entities/chat_role.dart';
import '../viewmodels/admin_messages_view_model.dart';
import '../widgets/chat_unread_dot.dart';
import 'general_chat_screen.dart';
import 'order_chat_screen.dart';

class AdminMessagesScreen extends ConsumerWidget {
  const AdminMessagesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminMessagesViewModelProvider);
    final model = ref.read(adminMessagesViewModelProvider.notifier);
    return AdminGate(
      child: Scaffold(
        appBar: AppBar(title: const Text('Tin nhắn')),
        drawer: const AdminDrawer(
          currentDestination: AdminDestination.messages,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.p16),
                child: Wrap(
                  spacing: AppSpacing.p8,
                  children: [
                    ChoiceChip(
                      label: const Text('Chung'),
                      selected: state.general,
                      onSelected: (_) => model.select(true),
                    ),
                    ChoiceChip(
                      label: const Text('Theo đơn'),
                      selected: !state.general,
                      onSelected: (_) => model.select(false),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ref
                    .watch(adminMessagesProvider)
                    .when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) => SingleChildScrollView(
                        child: AppErrorView(
                          message: 'Không thể tải tin nhắn.',
                          onRetry: () => ref.invalidate(adminMessagesProvider),
                        ),
                      ),
                      data: (chats) => chats.isEmpty
                          ? const SingleChildScrollView(
                              child: AppEmptyView(
                                title: 'Chưa có cuộc trò chuyện',
                              ),
                            )
                          : ListView.builder(
                              key: PageStorageKey(
                                'admin-messages-${state.general}',
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.p24,
                                0,
                                AppSpacing.p24,
                                AppSpacing.p24,
                              ),
                              itemCount:
                                  chats.length +
                                  (chats.length >= state.limit ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == chats.length) {
                                  return TextButton(
                                    onPressed: model.loadMore,
                                    child: const Text('Tải thêm'),
                                  );
                                }
                                final chat = chats[index];
                                return Card(
                                  child: ListTile(
                                    key: ValueKey(
                                      'inbox-${state.general}-${chat.orderId}',
                                    ),
                                    title: Text(
                                      state.general
                                          ? chat.customerName
                                          : 'Đơn ${chat.orderCode}',
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          chat.lastMessagePreview,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (chat.lastMessageAt != null)
                                          Text(
                                            DateFormat('dd/MM/yyyy HH:mm')
                                                .format(chat.lastMessageAt!),
                                          ),
                                      ],
                                    ),
                                    trailing: chat.unreadByAdmin
                                        ? const ChatUnreadDot()
                                        : const Icon(
                                            Icons.chevron_right_rounded,
                                          ),
                                    onTap: () => state.general
                                        ? Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => GeneralChatScreen(
                                                customerId: chat.customerId,
                                              ),
                                            ),
                                          )
                                        : Navigator.of(context).pushNamed(
                                            AppRoutes.orderChat,
                                            arguments: OrderChatArgs(
                                              chat.orderId,
                                              ChatRole.admin,
                                            ),
                                          ),
                                  ),
                                );
                              },
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

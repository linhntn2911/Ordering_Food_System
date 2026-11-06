import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../auth/presentation/views/login_view.dart';
import '../../../order/presentation/widgets/order_status_chip.dart';
import '../../domain/entities/chat_failure.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_role.dart';
import '../../domain/entities/order_chat.dart';
import '../viewmodels/order_chat_providers.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_composer.dart';

class OrderChatArgs {
  const OrderChatArgs(this.orderId, this.viewerRole);

  final String orderId;
  final ChatRole viewerRole;
}

class OrderChatScreen extends ConsumerWidget {
  const OrderChatScreen({super.key, required this.args});

  final OrderChatArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(authStateProvider);
    return account.when(
      loading: () =>
          const _ChatFrame(child: Center(child: CircularProgressIndicator())),
      error: (_, _) => _ChatFrame(
        child: _ChatProblem(onRetry: () => ref.invalidate(authStateProvider)),
      ),
      data: (user) {
        if (args.orderId.isEmpty ||
            args.orderId.contains('/') ||
            user?.isActive == false) {
          return const _ChatFrame(child: _ChatProblem(denied: true));
        }
        if (user == null) return const _ChatLogin();
        final role = user.isAdmin ? ChatRole.admin : ChatRole.customer;
        final session = (orderId: args.orderId, userId: user.id, role: role);
        return _ChatConversation(key: ValueKey(session), session: session);
      },
    );
  }
}

class _ChatLogin extends StatefulWidget {
  const _ChatLogin();

  @override
  State<_ChatLogin> createState() => _ChatLoginState();
}

class _ChatLoginState extends State<_ChatLogin> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ModalRoute.isCurrentOf(context) != false) _login();
    });
  }

  void _login() => Navigator.of(context).pushNamed(
    AppRoutes.login,
    arguments: const LoginArgs(returnToCaller: true),
  );

  @override
  Widget build(BuildContext context) => _ChatFrame(
    child: Center(
      child: FilledButton(
        onPressed: _login,
        child: const Text('Đăng nhập để xem tin nhắn'),
      ),
    ),
  );
}

class _ChatConversation extends ConsumerStatefulWidget {
  const _ChatConversation({super.key, required this.session});

  final ChatSession session;

  @override
  ConsumerState<_ChatConversation> createState() => _ChatConversationState();
}

class _ChatConversationState extends ConsumerState<_ChatConversation> {
  final _text = TextEditingController();
  OrderChat? _readSnapshot;
  List<ChatMessage>? _messages;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final chatProvider = orderChatStreamProvider(session.orderId);
    final orderProvider = chatOrderProvider(session.orderId);
    final stateProvider = orderChatViewModelProvider(session);
    final state = ref.watch(stateProvider);
    final model = ref.read(stateProvider.notifier);
    final order = ref.watch(orderProvider);
    final chat = ref.watch(chatProvider);
    final query = chatMessagesProvider((
      orderId: session.orderId,
      limit: state.limit,
    ));
    final messages = ref.watch(query);
    final current = ModalRoute.isCurrentOf(context) ?? true;

    ref.listen(stateProvider, (previous, next) {
      if (previous?.sending == true &&
          !next.sending &&
          next.messageId == null) {
        _text.clear();
      }
    });

    final foodOrder = order.value;
    final wrongOwner =
        session.role == ChatRole.customer &&
        foodOrder != null &&
        foodOrder.customerId != session.userId;
    if (wrongOwner) return const _ChatFrame(child: _ChatProblem(denied: true));

    final unread = chat.value;
    if (current &&
        unread != null &&
        unread.unreadFor(session.role) &&
        !identical(_readSnapshot, unread) &&
        messages is AsyncData<List<ChatMessage>> &&
        (unread.lastMessageId == null ||
            messages.value.any(
              (message) => message.id == unread.lastMessageId,
            ))) {
      _readSnapshot = unread;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
          model.markRead(unread.lastMessageId);
        }
      });
    } else if (!current || unread?.unreadFor(session.role) != true) {
      _readSnapshot = null;
    }

    final error = chat.error ?? messages.error ?? order.error;
    if (error != null) {
      return _ChatFrame(
        child: _ChatProblem(
          denied: error == ChatFailure.permissionDenied,
          onRetry: () {
            ref.invalidate(orderProvider);
            ref.invalidate(chatProvider);
            ref.invalidate(query);
          },
        ),
      );
    }
    if (messages case AsyncData(:final value)) _messages = value;
    if (foodOrder == null || chat is! AsyncData || _messages == null) {
      return const _ChatFrame(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final closed = state.expired || !ref.watch(chatOpenProvider(foodOrder));
    final entries = _messages!;
    final pendingId = state.messageId;
    final showPending =
        pendingId != null && !entries.any((message) => message.id == pendingId);
    final pending = showPending
        ? ChatMessage(
            id: pendingId,
            senderId: session.userId,
            senderRole: session.role,
            text: state.draft.text.trim().isEmpty
                ? '[Ảnh]'
                : state.draft.text.trim(),
            imagePaths: const [],
            createdAt: null,
            isPending: state.sending,
          )
        : null;
    final visible = [?pending, ...entries];
    final canPage = entries.length >= state.limit;
    final composer = ChatComposer(
      controller: _text,
      draft: state.draft,
      onText: model.setText,
      onRemove: model.removePhoto,
      onAddImageUrl: model.addImageUrl,
      onSend: model.send,
      sending: state.sending,
      closed: closed,
      canSend: !state.sending && state.draft.canSend,
    );

    return _ChatFrame(
      orderCode: foodOrder.orderCode,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = AppSpacing.screenHorizontalFor(constraints.maxWidth);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: AppSpacing.p4,
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.p8,
                  children: [
                    OrderStatusChip(status: foodOrder.status),
                    if (chat.value case final OrderChat conversation)
                      Text(
                        conversation.issueType.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Text(
                          session.role == ChatRole.admin
                              ? 'Gửi tin nhắn cho khách'
                              : 'Hãy mô tả vấn đề của bạn',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.symmetric(
                          horizontal: padding,
                          vertical: AppSpacing.p8,
                        ),
                        itemCount: visible.length + (canPage ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == visible.length) {
                            return Center(
                              child: TextButton(
                                key: const ValueKey('chat-load-older'),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                ),
                                onPressed: messages.isLoading
                                    ? null
                                    : model.loadOlder,
                                child: const Text('Xem tin cũ hơn'),
                              ),
                            );
                          }
                          final message = visible[index];
                          final own = message.senderRole == session.role;
                          final failed =
                              identical(message, pending) && !state.sending;
                          final day = message.createdAt?.toLocal();
                          final olderDay = index + 1 < visible.length
                              ? visible[index + 1].createdAt?.toLocal()
                              : null;
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.p8,
                            ),
                            child: Column(
                              children: [
                                if (day != null &&
                                    !DateUtils.isSameDay(day, olderDay))
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.p8,
                                    ),
                                    child: Text(
                                      DateFormat('dd/MM/yyyy').format(day),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ),
                                ChatBubble(
                                  key: ValueKey(message.id),
                                  message: message,
                                  own: own,
                                  userId: session.userId,
                                  senderLabel: own
                                      ? 'Bạn'
                                      : message.senderRole == ChatRole.admin
                                      ? 'Ngô Chicken'
                                      : foodOrder.customerName,
                                  failure: failed ? state.error : null,
                                  onRetry: failed && !closed
                                      ? model.send
                                      : null,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * 0.72,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    AppSpacing.p4,
                    padding,
                    AppSpacing.p12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (closed)
                        const Text(
                          'Cuộc trò chuyện đã đóng. Bạn có thể báo vấn đề trong 24 giờ sau khi đơn kết thúc.',
                          key: ValueKey('chat-closed'),
                        ),
                      if (state.error != null && !closed && pendingId == null)
                        Text(
                          state.error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      if (!closed ||
                          state.draft.text.isNotEmpty ||
                          state.draft.imageUrls.isNotEmpty)
                        composer,
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChatFrame extends StatelessWidget {
  const _ChatFrame({required this.child, this.orderCode});

  final Widget child;
  final String? orderCode;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: BackButton(onPressed: () => _leaveChat(context)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trao đổi về đơn',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (orderCode != null)
            Text(
              orderCode!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: child,
        ),
      ),
    ),
  );
}

void _leaveChat(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
  } else {
    navigator.pushReplacementNamed(AppRoutes.home);
  }
}

class _ChatProblem extends StatelessWidget {
  const _ChatProblem({this.denied = false, this.onRetry});

  final bool denied;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.p24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            denied
                ? ChatFailure.permissionDenied.message
                : 'Không tải được cuộc trò chuyện',
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: denied ? () => _leaveChat(context) : onRetry,
            child: Text(denied ? 'Quay lại' : 'Thử lại'),
          ),
        ],
      ),
    ),
  );
}

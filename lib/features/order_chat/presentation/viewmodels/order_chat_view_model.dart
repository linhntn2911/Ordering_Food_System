import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_draft.dart';
import '../../domain/entities/chat_failure.dart';
import '../../domain/entities/chat_issue_type.dart';
import 'order_chat_providers.dart';
import 'order_chat_state.dart';

final orderChatViewModelProvider = NotifierProvider.autoDispose
    .family<OrderChatViewModel, OrderChatState, ChatSession>(
      OrderChatViewModel.new,
      dependencies: [
        orderChatRepositoryProvider,
        generalChatModeProvider,
        orderChatStreamProvider,
      ],
    );

class OrderChatViewModel extends Notifier<OrderChatState> {
  OrderChatViewModel(this.session);

  final ChatSession session;
  static const pageSize = 30;

  @override
  OrderChatState build() => (
    draft: ChatDraft(),
    sending: false,
    limit: pageSize,
    messageId: null,
    error: null,
  );

  void _update({
    ChatDraft? draft,
    bool? sending,
    int? limit,
    String? messageId,
    String? error,
    bool resetAttempt = false,
  }) {
    state = (
      draft: draft ?? state.draft,
      sending: sending ?? state.sending,
      limit: limit ?? state.limit,
      messageId: resetAttempt ? null : messageId ?? state.messageId,
      error: error,
    );
  }

  void setText(String text) {
    if (state.sending || text == state.draft.text) return;
    _update(
      draft: ChatDraft(text: text, imageUrls: state.draft.imageUrls),
      resetAttempt: true,
    );
  }

  void removePhoto(int index) {
    if (state.sending) return;
    final photos = [...state.draft.imageUrls]..removeAt(index);
    _update(
      draft: ChatDraft(text: state.draft.text, imageUrls: photos),
      resetAttempt: true,
    );
  }

  String? addImageUrl(String input) {
    final url = input.trim();
    if (!ChatDraft.isImageUrl(url)) {
      return 'Dán link ảnh HTTPS hợp lệ.';
    }
    if (state.draft.imageUrls.contains(url)) {
      return 'Link ảnh đã được đính kèm.';
    }
    if (state.draft.imageUrls.length >= ChatDraft.maxPhotos) {
      return 'Chỉ được đính kèm tối đa 3 ảnh.';
    }
    if (state.sending) {
      return 'Hiện không thể đính kèm ảnh.';
    }
    _update(
      draft: ChatDraft(
        text: state.draft.text,
        imageUrls: [...state.draft.imageUrls, url],
      ),
      resetAttempt: true,
    );
    return null;
  }

  Future<void> send() async {
    if (state.sending) return;
    final general = ref.read(generalChatModeProvider);
    final order = general
        ? null
        : ref.read(chatOrderProvider(session.orderId)).value;
    final chat = ref.read(orderChatStreamProvider(session.orderId));
    if ((!general && order == null) || chat is! AsyncData) return;
    final draft = state.draft;
    if (!draft.canSend) return;
    final repository = ref.read(orderChatRepositoryProvider);
    final messageId =
        state.messageId ?? repository.newMessageId(session.orderId);
    _update(sending: true, messageId: messageId);
    try {
      await repository.sendMessage(
        orderId: session.orderId,
        messageId: messageId,
        senderRole: session.role,
        text: draft.text.trim(),
        imagePaths: draft.imageUrls,
        issueType: ChatIssueType.other,
      );
      if (ref.mounted) {
        _update(draft: ChatDraft(), sending: false, resetAttempt: true);
      }
    } catch (error) {
      if (!ref.mounted) return;
      final failure = error is ChatFailure ? error : ChatFailure.unknown;
      _update(sending: false, error: failure.message);
    }
  }

  void loadOlder() =>
      _update(limit: state.limit + pageSize, error: state.error);

  Future<void> markRead(String? lastSeenMessageId) async {
    try {
      await ref
          .read(orderChatRepositoryProvider)
          .markRead(
            session.orderId,
            session.role,
            lastSeenMessageId: lastSeenMessageId,
          );
    } on ChatFailure {
      // A later chat snapshot or a reopened route can retry this operation.
    }
  }
}

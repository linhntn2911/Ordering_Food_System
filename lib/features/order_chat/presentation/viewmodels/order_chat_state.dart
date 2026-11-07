import '../../domain/entities/chat_draft.dart';

typedef OrderChatState = ({
  ChatDraft draft,
  bool sending,
  bool expired,
  int limit,
  String? messageId,
  String? error,
});

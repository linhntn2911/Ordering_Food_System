import '../../domain/entities/chat_draft.dart';

typedef OrderChatState = ({
  ChatDraft draft,
  bool sending,
  int limit,
  String? messageId,
  String? error,
});

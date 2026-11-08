# Contract: OrderChatRepository

`lib/features/order_chat/domain/repositories/order_chat_repository.dart`. Implemented by `FirestoreOrderChatRepository` (data layer) and `FakeOrderChatRepository` (`test/support/`). ViewModels depend only on this interface (constitution II).

```dart
abstract interface class OrderChatRepository {
  /// Conversation metadata for one order, or null when none exists yet.
  Stream<OrderChat?> watchChat(String orderId);

  /// Newest-first messages, at most [limit] (R8). Pending local writes are
  /// included with isPending = true.
  Stream<List<ChatMessage>> watchMessages(String orderId, {required int limit});

  /// Generates a message ID once per draft; reused for every retry (R3).
  String newMessageId(String orderId);

  /// One transaction: creates the conversation if absent (with issueType and
  /// openedByRole), creates the message unless it already exists, and updates
  /// metadata plus the other side's unread flag (R2, R3).
  Future<void> sendMessage({
    required String orderId,
    required String messageId,
    required ChatRole senderRole,
    required String text,
    required List<String> imagePaths,
    ChatIssueType? issueType,
  });

  /// Clears the viewer's flag if the conversation still matches the last seen message.
  Future<void> markRead(String orderId, ChatRole viewerRole, {String? lastSeenMessageId});

  /// Reads image bytes through an authenticated Storage request.
  Future<Uint8List> photoBytes(String storagePath);

  /// Admin: conversations ordered by lastMessageAt desc, at most [limit].
  Stream<List<OrderChat>> watchAdminChats({int limit = 100});

  /// Customer: whether any own conversation has unread Admin messages.
  Stream<bool> watchCustomerHasUnread(String customerId);
}
```

## Failures

`ChatFailure` with `type`:

| Type | When | UI message (vi) |
|---|---|---|
| `permissionDenied` | Not a participant or disabled account | "Bạn không có quyền xem cuộc trò chuyện này" |
| `unavailable` | Network / offline | "Không gửi được. Kiểm tra kết nối và thử lại" |
| `unknown` | Anything else | "Đã có lỗi, vui lòng thử lại" |

## Fake repository behaviour (tests)

- Emits through controllable streams (`emitChat`, `emitMessages`).
- Records `sendMessage` calls and can be told to fail the next N calls with a given `ChatFailure`.
- `sendMessage` with an already-recorded `messageId` is a no-op (mirrors R3).


## Unlimited order chat amendment — 2026-11-08

Approved rule: the owning active Customer and active Admins can start or continue order chat at any time, including after Completed, Cancelled or Rejected. There is no automatic expiry, read-only transition, resolve or reopen. This supersedes all earlier sending-window requirements. Ownership, active-account checks, immutable messages, one conversation per order, validation and retry deduplication remain required. No new schema or migration is needed. Chat remains order-scoped.

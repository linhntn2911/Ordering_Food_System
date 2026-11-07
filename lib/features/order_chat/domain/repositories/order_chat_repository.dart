import 'dart:typed_data';

import '../entities/chat_issue_type.dart';
import '../entities/chat_message.dart';
import '../entities/chat_role.dart';
import '../entities/order_chat.dart';

abstract interface class OrderChatRepository {
  Stream<OrderChat?> watchChat(String orderId);
  Stream<List<ChatMessage>> watchMessages(String orderId, {required int limit});
  String newMessageId(String orderId);
  Future<void> sendMessage({
    required String orderId,
    required String messageId,
    required ChatRole senderRole,
    required String text,
    required List<String> imagePaths,
    ChatIssueType? issueType,
  });
  Future<void> markRead(
    String orderId,
    ChatRole viewerRole, {
    String? lastSeenMessageId,
  });
  Future<Uint8List> photoBytes(String storagePath);
  Stream<List<OrderChat>> watchAdminChats({int limit = 100});
  Stream<bool> watchCustomerHasUnread(String customerId);
}

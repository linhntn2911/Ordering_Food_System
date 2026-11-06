import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/chat_issue_type.dart';
import '../../domain/entities/chat_role.dart';
import '../../domain/entities/order_chat.dart';

abstract final class OrderChatModel {
  static OrderChat? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    return OrderChat(
      orderId: doc.id,
      orderCode: data['orderCode'] as String? ?? doc.id,
      customerId: data['customerId'] as String? ?? '',
      issueType: ChatIssueType.values.byName(
        data['issueType'] as String? ?? 'other',
      ),
      openedByRole: ChatRole.values.byName(data['openedByRole'] as String),
      lastMessageId: data['lastMessageId'] as String?,
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessagePreview: data['lastMessagePreview'] as String? ?? '',
      lastSenderRole: ChatRole.values.byName(data['lastSenderRole'] as String),
      unreadByAdmin: data['unreadByAdmin'] == true,
      unreadByCustomer: data['unreadByCustomer'] == true,
    );
  }
}

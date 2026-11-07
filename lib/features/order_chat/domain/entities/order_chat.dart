import 'chat_issue_type.dart';
import 'chat_role.dart';

class OrderChat {
  const OrderChat({
    required this.orderId,
    required this.orderCode,
    required this.customerId,
    required this.issueType,
    required this.openedByRole,
    required this.lastMessageAt,
    this.lastMessageId,
    required this.lastMessagePreview,
    required this.lastSenderRole,
    required this.unreadByAdmin,
    required this.unreadByCustomer,
  });

  final String orderId;
  final String orderCode;
  final String customerId;
  final ChatIssueType issueType;
  final ChatRole openedByRole;
  final DateTime? lastMessageAt;
  final String? lastMessageId;
  final String lastMessagePreview;
  final ChatRole lastSenderRole;
  final bool unreadByAdmin;
  final bool unreadByCustomer;

  bool unreadFor(ChatRole role) =>
      role == ChatRole.admin ? unreadByAdmin : unreadByCustomer;
}

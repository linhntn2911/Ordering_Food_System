import 'package:ordering_food_system/features/order/domain/entities/food_order.dart';
import 'package:ordering_food_system/features/order/domain/entities/order_status.dart';
import 'package:ordering_food_system/features/order_chat/domain/entities/chat_issue_type.dart';
import 'package:ordering_food_system/features/order_chat/domain/entities/chat_role.dart';
import 'package:ordering_food_system/features/order_chat/domain/entities/order_chat.dart';

FoodOrder chatOrderFixture({
  String id = 'order-one',
  OrderStatus status = OrderStatus.preparing,
  DateTime? updatedAt,
}) => FoodOrder(
  id: id,
  orderCode: 'NGO001',
  customerId: 'customer',
  customerName: 'Khách hàng',
  customerPhone: '0123456789',
  deliveryAddress: 'Địa chỉ',
  totalAmount: 45000,
  paymentMethod: 'cod',
  paymentStatus: 'unpaid',
  status: status,
  createdAt: DateTime(2026, 11, 1),
  updatedAt: updatedAt ?? DateTime(2026, 11, 1),
);

OrderChat chatFixture({
  String orderId = 'order-one',
  String? lastMessageId,
  bool unreadByAdmin = false,
  bool unreadByCustomer = false,
}) => OrderChat(
  orderId: orderId,
  orderCode: 'NGO001',
  customerId: 'customer',
  issueType: ChatIssueType.lateDelivery,
  openedByRole: ChatRole.customer,
  lastMessageAt: DateTime(2026, 11, 1),
  lastMessageId: lastMessageId,
  lastMessagePreview: 'Tin nhắn',
  lastSenderRole: ChatRole.customer,
  unreadByAdmin: unreadByAdmin,
  unreadByCustomer: unreadByCustomer,
);

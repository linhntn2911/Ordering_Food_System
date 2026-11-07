import '../../../order/domain/entities/order_status.dart';

abstract final class ChatWindow {
  static DateTime? closesAt({
    required OrderStatus orderStatus,
    required DateTime? completedAt,
    required DateTime updatedAt,
  }) => switch (orderStatus) {
    OrderStatus.completed || OrderStatus.cancelled || OrderStatus.rejected =>
      (completedAt ?? updatedAt).add(const Duration(hours: 24)),
    _ => null,
  };

  static bool isOpen({
    required OrderStatus orderStatus,
    required DateTime? completedAt,
    required DateTime updatedAt,
    required DateTime now,
  }) {
    final deadline = closesAt(
      orderStatus: orderStatus,
      completedAt: completedAt,
      updatedAt: updatedAt,
    );
    return deadline == null || now.isBefore(deadline);
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/order/domain/entities/order_status.dart';
import 'package:ordering_food_system/features/order_chat/domain/entities/chat_window.dart';

void main() {
  final ended = DateTime.utc(2026, 11, 1);
  const window = Duration(hours: 24);

  test('active order has no deadline', () {
    expect(
      ChatWindow.isOpen(
        orderStatus: OrderStatus.preparing,
        completedAt: null,
        updatedAt: ended,
        now: ended.add(window * 2),
      ),
      isTrue,
    );
  });

  for (final status in [
    OrderStatus.completed,
    OrderStatus.cancelled,
    OrderStatus.rejected,
  ]) {
    test('${status.name} is closed at exactly 24 hours', () {
      bool open(DateTime now) => ChatWindow.isOpen(
        orderStatus: status,
        completedAt: null,
        updatedAt: ended,
        now: now,
      );
      expect(
        open(ended.add(window).subtract(const Duration(milliseconds: 1))),
        isTrue,
      );
      expect(open(ended.add(window)), isFalse);
    });
  }

  test('completedAt takes precedence over later updatedAt', () {
    expect(
      ChatWindow.isOpen(
        orderStatus: OrderStatus.completed,
        completedAt: ended,
        updatedAt: ended.add(window),
        now: ended.add(window),
      ),
      isFalse,
    );
  });
}

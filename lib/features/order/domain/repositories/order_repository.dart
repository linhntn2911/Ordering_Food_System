import '../entities/food_order.dart';
import '../entities/order_item.dart';
import '../entities/order_status.dart';
import '../entities/order_status_event.dart';
import '../entities/sales_report.dart';

abstract interface class OrderRepository {
  Stream<List<FoodOrder>> watchAdminOrders({int limit = 100});

  Stream<FoodOrder> watchOrder(String orderId);

  Stream<List<OrderItem>> watchOrderItems(String orderId);

  Stream<List<OrderStatusEvent>> watchStatusEvents(String orderId);

  Future<void> transitionStatus({
    required String orderId,
    required OrderStatus expectedStatus,
    required OrderStatus targetStatus,
    String reason = '',
  });

  Stream<SalesReport> watchSalesReport({
    required DateTime startInclusive,
    required DateTime endExclusive,
  });
}

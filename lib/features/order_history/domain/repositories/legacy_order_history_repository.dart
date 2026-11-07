import 'package:ordering_food_system/features/order_history/data/models/legacy_order_model.dart';

/// Legacy interface retained for older screens. The active provider maps
/// checkout orders into this model and never supplies sample data.
abstract class OrderHistoryRepository {
  Future<List<OrderModel>> getOrders({String? filter});
  Future<OrderModel?> getOrderById(String orderId);
  Stream<List<OrderModel>> watchOrders({String? filter});
  Stream<OrderModel?> watchOrderById(String orderId);
}

class MockOrderHistoryRepository implements OrderHistoryRepository {
  const MockOrderHistoryRepository();

  @override
  Future<List<OrderModel>> getOrders({String? filter}) async => const [];

  @override
  Future<OrderModel?> getOrderById(String orderId) async => null;

  @override
  Stream<List<OrderModel>> watchOrders({String? filter}) =>
      Stream.value(const []);

  @override
  Stream<OrderModel?> watchOrderById(String orderId) => Stream.value(null);
}

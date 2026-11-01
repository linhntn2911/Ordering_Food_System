import 'package:ordering_food_system/features/order_history/models/order_model.dart';

/// Legacy interface retained for older screens. The active provider maps
/// checkout orders into this model and never supplies sample data.
abstract class OrderHistoryRepository {
  Future<List<OrderModel>> getOrders({String? filter});
  Future<OrderModel?> getOrderById(String orderId);
}

class MockOrderHistoryRepository implements OrderHistoryRepository {
  const MockOrderHistoryRepository();

  @override
  Future<List<OrderModel>> getOrders({String? filter}) async => const [];

  @override
  Future<OrderModel?> getOrderById(String orderId) async => null;
}

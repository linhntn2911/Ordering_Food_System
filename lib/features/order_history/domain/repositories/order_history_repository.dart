import 'package:ordering_food_system/features/order_history/data/models/order_model.dart';

abstract class OrderHistoryRepository {
  Future<List<OrderModel>> getOrders({String? filter});
  Future<OrderModel?> getOrderById(String orderId);
}

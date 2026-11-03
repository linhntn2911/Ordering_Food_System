import 'package:ordering_food_system/features/order_history/data/models/order_model.dart';
import 'package:ordering_food_system/features/order_history/domain/repositories/order_history_repository.dart';

/// Legacy repository kept for compatibility with older imports. The active
/// order-history provider is backed by CheckoutRepository and does not inject
/// sample orders.
class OrderHistoryRepositoryImpl implements OrderHistoryRepository {
  const OrderHistoryRepositoryImpl();

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

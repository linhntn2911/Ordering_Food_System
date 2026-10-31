import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/features/order_history/data/models/order_model.dart';
import 'package:ordering_food_system/features/order_history/data/repositories/order_history_repository_impl.dart';
import 'package:ordering_food_system/features/order_history/domain/repositories/order_history_repository.dart';

final orderHistoryRepositoryProvider = Provider<OrderHistoryRepository>((ref) {
  return OrderHistoryRepositoryImpl();
});

class OrderHistoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  @override
  set state(String value) => super.state = value;
}

final orderHistoryFilterProvider = NotifierProvider<OrderHistoryFilterNotifier, String>(OrderHistoryFilterNotifier.new);

final orderHistoryListProvider = FutureProvider<List<OrderModel>>((ref) async {
  final repo = ref.watch(orderHistoryRepositoryProvider);
  final filter = ref.watch(orderHistoryFilterProvider);
  return repo.getOrders(filter: filter);
});

final orderDetailByIdProvider = FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  final repo = ref.watch(orderHistoryRepositoryProvider);
  return repo.getOrderById(orderId);
});

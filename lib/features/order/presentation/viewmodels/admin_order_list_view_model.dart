import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_providers.dart';
import '../../data/repositories/firestore_order_repository.dart';
import '../../domain/entities/food_order.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return FirestoreOrderRepository(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final adminOrdersProvider = StreamProvider.autoDispose<List<FoodOrder>>((ref) {
  return ref.watch(orderRepositoryProvider).watchAdminOrders();
});

class AdminOrderListFilter {
  const AdminOrderListFilter({this.query = '', this.status});

  final String query;
  final OrderStatus? status;

  AdminOrderListFilter copyWith({
    String? query,
    OrderStatus? status,
    bool clearStatus = false,
  }) {
    return AdminOrderListFilter(
      query: query ?? this.query,
      status: clearStatus ? null : status ?? this.status,
    );
  }

  List<FoodOrder> apply(List<FoodOrder> orders) {
    final normalized = query.trim().toLowerCase();
    return List<FoodOrder>.unmodifiable(
      orders.where((order) {
        final matchesStatus = status == null || order.status == status;
        final matchesQuery =
            normalized.isEmpty ||
            order.orderCode.toLowerCase().contains(normalized) ||
            order.customerName.toLowerCase().contains(normalized) ||
            order.customerPhone.toLowerCase().contains(normalized);
        return matchesStatus && matchesQuery;
      }),
    );
  }
}

final adminOrderListFilterProvider =
    NotifierProvider<AdminOrderListViewModel, AdminOrderListFilter>(
      AdminOrderListViewModel.new,
    );

final filteredAdminOrdersProvider = Provider<AsyncValue<List<FoodOrder>>>((
  ref,
) {
  final orders = ref.watch(adminOrdersProvider);
  final filter = ref.watch(adminOrderListFilterProvider);
  return orders.whenData(filter.apply);
});

class AdminOrderListViewModel extends Notifier<AdminOrderListFilter> {
  @override
  AdminOrderListFilter build() => const AdminOrderListFilter();

  void setQuery(String value) {
    state = state.copyWith(query: value);
  }

  void setStatus(OrderStatus? value) {
    state = value == null
        ? state.copyWith(clearStatus: true)
        : state.copyWith(status: value);
  }

  void clearFilters() {
    state = const AdminOrderListFilter();
  }
}

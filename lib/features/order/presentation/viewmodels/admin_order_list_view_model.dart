import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_providers.dart';
import '../../../order_chat/domain/entities/order_chat.dart';
import '../../../order_chat/presentation/viewmodels/order_chat_providers.dart';
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
  const AdminOrderListFilter({
    this.query = '',
    this.status,
    this.hasChat = false,
  });

  final String query;
  final OrderStatus? status;
  final bool hasChat;

  AdminOrderListFilter copyWith({
    String? query,
    OrderStatus? status,
    bool clearStatus = false,
    bool? hasChat,
  }) {
    return AdminOrderListFilter(
      query: query ?? this.query,
      hasChat: hasChat ?? this.hasChat,
      status: clearStatus ? null : status ?? this.status,
    );
  }

  List<FoodOrder> apply(
    List<FoodOrder> orders, {
    Set<String> chatIds = const {},
  }) {
    final normalized = query.trim().toLowerCase();
    return List<FoodOrder>.unmodifiable(
      orders.where((order) {
        final matchesStatus = status == null || order.status == status;
        final matchesQuery =
            normalized.isEmpty ||
            order.orderCode.toLowerCase().contains(normalized) ||
            order.customerName.toLowerCase().contains(normalized) ||
            order.customerPhone.toLowerCase().contains(normalized);
        return matchesStatus &&
            matchesQuery &&
            (!hasChat || chatIds.contains(order.id));
      }),
    );
  }
}

final adminOrderListFilterProvider =
    NotifierProvider<AdminOrderListViewModel, AdminOrderListFilter>(
      AdminOrderListViewModel.new,
    );

final adminOrderChatsProvider =
    StreamProvider.autoDispose<Map<String, OrderChat>>(
      (ref) => ref
          .watch(orderChatRepositoryProvider)
          .watchAdminChats()
          .map(
            (chats) => Map.unmodifiable({
              for (final chat in chats) chat.orderId: chat,
            }),
          ),
    );

final filteredAdminOrdersProvider = Provider<AsyncValue<List<FoodOrder>>>((
  ref,
) {
  final orders = ref.watch(adminOrdersProvider);
  final filter = ref.watch(adminOrderListFilterProvider);
  if (!filter.hasChat) return orders.whenData(filter.apply);
  final chats = ref.watch(adminOrderChatsProvider);
  if (orders is! AsyncData) return orders;
  return chats.whenData(
    (items) => filter.apply(orders.value!, chatIds: items.keys.toSet()),
  );
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

  void setHasChat(bool value) => state = state.copyWith(hasChat: value);

  void clearFilters() {
    state = const AdminOrderListFilter();
  }
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/food_order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/order_status_event.dart';
import 'admin_order_list_view_model.dart';

final adminOrderProvider = StreamProvider.autoDispose.family<FoodOrder, String>(
  (ref, orderId) => ref.watch(orderRepositoryProvider).watchOrder(orderId),
);

final adminOrderItemsProvider = StreamProvider.autoDispose
    .family<List<OrderItem>, String>(
      (ref, orderId) =>
          ref.watch(orderRepositoryProvider).watchOrderItems(orderId),
    );

final adminOrderEventsProvider = StreamProvider.autoDispose
    .family<List<OrderStatusEvent>, String>(
      (ref, orderId) =>
          ref.watch(orderRepositoryProvider).watchStatusEvents(orderId),
    );

final adminOrderActionProvider =
    AsyncNotifierProvider.autoDispose<AdminOrderActionViewModel, void>(
      AdminOrderActionViewModel.new,
    );

class AdminOrderActionViewModel extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> transition(
    FoodOrder order,
    OrderStatus target, {
    String reason = '',
  }) async {
    if (!order.status.canTransitionTo(target)) {
      state = AsyncError(
        ArgumentError('This order status transition is not allowed.'),
        StackTrace.current,
      );
      return false;
    }
    if (target == OrderStatus.rejected && reason.trim().isEmpty) {
      state = AsyncError(
        ArgumentError('Enter a reason before rejecting this order.'),
        StackTrace.current,
      );
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(orderRepositoryProvider)
          .transitionStatus(
            orderId: order.id,
            expectedStatus: order.status,
            targetStatus: target,
            reason: reason,
          ),
    );
    return !state.hasError;
  }
}

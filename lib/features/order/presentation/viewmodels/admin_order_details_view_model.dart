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
        ArgumentError('Không thể chuyển đơn hàng sang trạng thái này.'),
        StackTrace.current,
      );
      return false;
    }
    if (target == OrderStatus.rejected && reason.trim().isEmpty) {
      state = AsyncError(
        ArgumentError('Vui lòng nhập lý do trước khi từ chối đơn hàng.'),
        StackTrace.current,
      );
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(orderRepositoryProvider)
          .transitionStatus(
            orderId: order.id,
            expectedStatus: order.status,
            targetStatus: target,
            reason: reason,
          );

      // Recreate the detail streams after the transaction. Keeping the action
      // loading until the updated order arrives prevents a second tap from
      // submitting the same transition with a stale expected status.
      ref.invalidate(adminOrderProvider(order.id));
      ref.invalidate(adminOrderEventsProvider(order.id));
      await ref.read(adminOrderProvider(order.id).future);
    });
    return !state.hasError;
  }
}

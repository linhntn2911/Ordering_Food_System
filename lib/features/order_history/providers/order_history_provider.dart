import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/features/cart/presentation/controllers/cart_controller.dart';
import 'package:ordering_food_system/features/checkout/data/checkout_repository.dart';
import 'package:ordering_food_system/features/checkout/data/models/order_model.dart'
    as checkout;
import 'package:ordering_food_system/features/order_history/models/order_model.dart';

final orderHistoryRepositoryProvider =
    Provider<_CheckoutOrderHistoryRepository>((ref) {
      return _CheckoutOrderHistoryRepository(
        checkoutRepository: ref.watch(checkoutRepositoryProvider),
        customerId: ref.watch(activeCustomerIdProvider),
      );
    });

class OrderHistoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  @override
  set state(String value) => super.state = value;
}

final orderHistoryFilterProvider =
    NotifierProvider<OrderHistoryFilterNotifier, String>(
      OrderHistoryFilterNotifier.new,
    );

final orderHistoryListProvider = FutureProvider<List<OrderModel>>((ref) async {
  final repo = ref.watch(orderHistoryRepositoryProvider);
  final filter = ref.watch(orderHistoryFilterProvider);
  return repo.getOrders(filter: filter);
});

final orderDetailByIdProvider = FutureProvider.family<OrderModel?, String>((
  ref,
  orderId,
) async {
  final repo = ref.watch(orderHistoryRepositoryProvider);
  return repo.getOrderById(orderId);
});

class _CheckoutOrderHistoryRepository {
  const _CheckoutOrderHistoryRepository({
    required this.checkoutRepository,
    required this.customerId,
  });

  final CheckoutRepository checkoutRepository;
  final String? customerId;

  Future<List<OrderModel>> getOrders({String? filter}) async {
    final id = customerId;
    if (id == null || id.isEmpty) return const [];
    final orders = await checkoutRepository.getCustomerOrders(id);
    return orders.map(_map).where((order) {
      return switch (filter) {
        'ongoing' => order.status.isOngoing,
        'completed' => order.status.isCompleted,
        'cancelled' => order.status.isCancelled,
        _ => true,
      };
    }).toList();
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    final id = customerId;
    if (id == null || id.isEmpty) return null;
    final order = (await checkoutRepository.getCustomerOrders(id))
        .where(
          (candidate) =>
              candidate.id == orderId || candidate.orderCode == orderId,
        )
        .firstOrNull;
    return order == null ? null : _map(order);
  }

  OrderModel _map(checkout.OrderModel order) {
    return OrderModel(
      orderId: order.orderCode,
      userId: order.customerId,
      items: order.items
          .map(
            (item) => OrderItem(
              id: item.menuItemId,
              name: item.name,
              imageUrl: item.imageUrl,
              quantity: item.quantity,
              price: item.unitPrice,
            ),
          )
          .toList(growable: false),
      subtotal: order.subtotal,
      deliveryFee: order.deliveryFee,
      discount: 0,
      totalPrice: order.total,
      status: _mapStatus(order.status),
      createdAt: order.createdAt,
      address: order.addressSnapshot.fullAddress,
      paymentMethod: order.paymentMethod,
    );
  }

  OrderStatus _mapStatus(checkout.OrderStatus status) {
    return switch (status) {
      checkout.OrderStatus.pending ||
      checkout.OrderStatus.confirmed => OrderStatus.pending,
      checkout.OrderStatus.preparing => OrderStatus.preparing,
      checkout.OrderStatus.outForDelivery => OrderStatus.delivering,
      checkout.OrderStatus.completed => OrderStatus.completed,
      checkout.OrderStatus.cancelled ||
      checkout.OrderStatus.rejected => OrderStatus.cancelled,
    };
  }
}

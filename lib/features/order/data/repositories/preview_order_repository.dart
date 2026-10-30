import 'dart:async';

import '../../domain/entities/food_order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/order_status_event.dart';
import '../../domain/entities/sales_report.dart';
import '../../domain/repositories/order_repository.dart';

class PreviewOrderRepository implements OrderRepository {
  PreviewOrderRepository()
    : _orders = _seedOrders(),
      _items = _seedItems(),
      _events = _seedEvents();

  final List<FoodOrder> _orders;
  final Map<String, List<OrderItem>> _items;
  final Map<String, List<OrderStatusEvent>> _events;
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<List<FoodOrder>> watchAdminOrders({int limit = 100}) =>
      _watch(() => List<FoodOrder>.unmodifiable(_orders.take(limit)));

  @override
  Stream<FoodOrder> watchOrder(String orderId) => _watch(() => _find(orderId));

  @override
  Stream<List<OrderItem>> watchOrderItems(String orderId) =>
      _watch(() => List<OrderItem>.unmodifiable(_items[orderId] ?? const []));

  @override
  Stream<List<OrderStatusEvent>> watchStatusEvents(String orderId) => _watch(
    () => List<OrderStatusEvent>.unmodifiable(_events[orderId] ?? const []),
  );

  @override
  Future<void> transitionStatus({
    required String orderId,
    required OrderStatus expectedStatus,
    required OrderStatus targetStatus,
    String reason = '',
  }) async {
    final order = _find(orderId);
    if (order.status != expectedStatus) {
      throw StateError('The order was updated. Refresh and try again.');
    }
    if (!expectedStatus.canTransitionTo(targetStatus)) {
      throw ArgumentError('This order status transition is not allowed.');
    }
    final normalizedReason = reason.trim();
    if (targetStatus == OrderStatus.rejected && normalizedReason.isEmpty) {
      throw ArgumentError('A rejection reason is required.');
    }
    final now = DateTime.now();
    final index = _orders.indexWhere((candidate) => candidate.id == orderId);
    _orders[index] = order.copyWith(
      status: targetStatus,
      updatedAt: now,
      rejectionReason: normalizedReason,
    );
    (_events[orderId] ??= []).add(
      OrderStatusEvent(
        id: 'preview-${now.microsecondsSinceEpoch}',
        fromStatus: expectedStatus,
        toStatus: targetStatus,
        actorId: 'preview-admin',
        actorRole: 'admin',
        reason: normalizedReason,
        createdAt: now,
      ),
    );
    _changes.add(null);
  }

  @override
  Stream<SalesReport> watchSalesReport({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) => _watch(() {
    final completed = _orders.where(
      (order) =>
          order.status == OrderStatus.completed &&
          !order.createdAt.isBefore(startInclusive) &&
          order.createdAt.isBefore(endExclusive),
    );
    final totals = <String, TopSellingItem>{};
    var revenue = 0;
    var count = 0;
    for (final order in completed) {
      count++;
      revenue += order.totalAmount;
      for (final item in _items[order.id] ?? const <OrderItem>[]) {
        final key = item.menuItemId.isEmpty ? item.name : item.menuItemId;
        final current = totals[key];
        totals[key] = TopSellingItem(
          menuItemId: key,
          name: item.name,
          quantity: (current?.quantity ?? 0) + item.quantity,
          revenue: (current?.revenue ?? 0) + item.lineTotal,
        );
      }
    }
    final topItems = totals.values.toList()
      ..sort(
        (a, b) => b.quantity != a.quantity
            ? b.quantity.compareTo(a.quantity)
            : b.revenue.compareTo(a.revenue),
      );
    return SalesReport(
      completedOrderCount: count,
      revenue: revenue,
      topItems: List<TopSellingItem>.unmodifiable(topItems),
    );
  });

  FoodOrder _find(String orderId) => _orders.firstWhere(
    (order) => order.id == orderId,
    orElse: () => throw StateError('Order $orderId was not found.'),
  );

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  void dispose() => _changes.close();
}

List<FoodOrder> _seedOrders() {
  final now = DateTime.now();
  FoodOrder order({
    required String id,
    required String code,
    required String customer,
    required String phone,
    required String address,
    required int total,
    required OrderStatus status,
    required Duration ago,
  }) {
    final createdAt = now.subtract(ago);
    const deliveryFee = 15000;
    return FoodOrder(
      id: id,
      orderCode: code,
      customerId: 'customer-$id',
      customerName: customer,
      customerPhone: phone,
      deliveryAddress: address,
      totalAmount: total,
      subtotal: total - deliveryFee,
      deliveryFee: deliveryFee,
      deliveryDistanceKm: 2.4,
      customerNote: id == 'order-1'
          ? 'Please make the chicken mildly spicy.'
          : '',
      rejectionReason: status == OrderStatus.rejected
          ? 'Item was sold out.'
          : '',
      paymentMethod: 'cod',
      paymentStatus: status == OrderStatus.completed ? 'paid' : 'unpaid',
      status: status,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  return [
    order(
      id: 'order-1',
      code: 'ORD-20261019-0008',
      customer: 'Nguyễn Minh Anh',
      phone: '0912 345 678',
      address: '12 Nguyễn Trãi, Thanh Xuân, Hà Nội',
      total: 125000,
      status: OrderStatus.pending,
      ago: const Duration(minutes: 4),
    ),
    order(
      id: 'order-2',
      code: 'ORD-20261019-0007',
      customer: 'Trần Thu Hà',
      phone: '0988 120 456',
      address: '88 Láng Hạ, Đống Đa, Hà Nội',
      total: 85000,
      status: OrderStatus.pending,
      ago: const Duration(minutes: 18),
    ),
    order(
      id: 'order-3',
      code: 'ORD-20261019-0006',
      customer: 'Lê Quốc Bảo',
      phone: '0904 888 221',
      address: '25 Trần Duy Hưng, Cầu Giấy, Hà Nội',
      total: 215000,
      status: OrderStatus.confirmed,
      ago: const Duration(minutes: 37),
    ),
    order(
      id: 'order-4',
      code: 'ORD-20261019-0005',
      customer: 'Phạm Ngọc Linh',
      phone: '0961 524 342',
      address: '6 Hồ Tùng Mậu, Nam Từ Liêm, Hà Nội',
      total: 142000,
      status: OrderStatus.preparing,
      ago: const Duration(hours: 1, minutes: 5),
    ),
    order(
      id: 'order-5',
      code: 'ORD-20261019-0004',
      customer: 'Đỗ Hoàng Nam',
      phone: '0936 440 115',
      address: '19 Nguyễn Khang, Cầu Giấy, Hà Nội',
      total: 97000,
      status: OrderStatus.outForDelivery,
      ago: const Duration(hours: 1, minutes: 32),
    ),
    order(
      id: 'order-6',
      code: 'ORD-20261018-0003',
      customer: 'Vũ Thảo My',
      phone: '0972 601 886',
      address: '31 Tây Sơn, Đống Đa, Hà Nội',
      total: 180000,
      status: OrderStatus.completed,
      ago: const Duration(days: 1, hours: 2),
    ),
    order(
      id: 'order-7',
      code: 'ORD-20261018-0002',
      customer: 'Bùi Đức Long',
      phone: '0902 113 790',
      address: '15 Vũ Phạm Hàm, Cầu Giấy, Hà Nội',
      total: 65000,
      status: OrderStatus.cancelled,
      ago: const Duration(days: 1, hours: 4),
    ),
    order(
      id: 'order-8',
      code: 'ORD-20261018-0001',
      customer: 'Hoàng Hải Yến',
      phone: '0981 992 310',
      address: '42 Khương Trung, Thanh Xuân, Hà Nội',
      total: 76000,
      status: OrderStatus.rejected,
      ago: const Duration(days: 1, hours: 6),
    ),
  ];
}

Map<String, List<OrderItem>> _seedItems() {
  List<OrderItem> items(String suffix) => [
    OrderItem(
      id: '$suffix-1',
      menuItemId: 'fried-chicken',
      name: 'Gà sốt phô mai cay',
      selectedSize: 'Regular',
      selectedToppings: const ['Extra cheese'],
      quantity: 2,
      unitPrice: 35000,
      lineTotal: 70000,
    ),
    OrderItem(
      id: '$suffix-2',
      menuItemId: 'lemon-tea',
      name: 'Trà chanh',
      selectedSize: 'Large',
      quantity: 1,
      unitPrice: 15000,
      lineTotal: 15000,
      note: 'Less ice',
    ),
  ];
  return {
    for (var index = 1; index <= 8; index++)
      'order-$index': items('order-$index'),
  };
}

Map<String, List<OrderStatusEvent>> _seedEvents() {
  final now = DateTime.now();
  final statuses = {
    'order-1': OrderStatus.pending,
    'order-2': OrderStatus.pending,
    'order-3': OrderStatus.confirmed,
    'order-4': OrderStatus.preparing,
    'order-5': OrderStatus.outForDelivery,
    'order-6': OrderStatus.completed,
    'order-7': OrderStatus.cancelled,
    'order-8': OrderStatus.rejected,
  };
  return statuses.map(
    (id, status) => MapEntry(id, [
      OrderStatusEvent(
        id: '$id-created',
        toStatus: status,
        actorId: status == OrderStatus.pending
            ? 'customer-$id'
            : 'preview-admin',
        actorRole: status == OrderStatus.pending ? 'customer' : 'admin',
        reason: status == OrderStatus.rejected ? 'Item was sold out.' : '',
        createdAt: now.subtract(const Duration(minutes: 20)),
      ),
    ]),
  );
}

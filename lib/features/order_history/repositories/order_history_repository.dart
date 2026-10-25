import 'package:oder_food/features/order_history/models/order_model.dart';

abstract class OrderHistoryRepository {
  Future<List<OrderModel>> getOrders({String? filter});
  Future<OrderModel?> getOrderById(String orderId);
}

class MockOrderHistoryRepository implements OrderHistoryRepository {
  MockOrderHistoryRepository();

  final List<OrderModel> _mockOrders = [
    OrderModel(
      orderId: 'ORD-1001',
      userId: 'user_01',
      items: const [
        OrderItem(id: 'item_1', name: 'Cơm Gà Xối Mỡ', imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c', quantity: 1, price: 45000),
        OrderItem(id: 'item_2', name: 'Trà Sữa Trân Châu', imageUrl: 'https://images.unsplash.com/photo-1558160074-4d7d8bdf4256', quantity: 1, price: 35000),
      ],
      subtotal: 80000,
      deliveryFee: 15000,
      discount: 10000,
      totalPrice: 85000,
      status: OrderStatus.delivering,
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      address: '123 Nguyễn Văn Linh, Q.7, TP.HCM',
      paymentMethod: 'COD',
      note: 'Giao nhanh giúp mình nhé',
      estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 15)),
    ),
    OrderModel(
      orderId: 'ORD-1002',
      userId: 'user_01',
      items: const [OrderItem(id: 'item_3', name: 'Bún Bò Huế', imageUrl: 'https://images.unsplash.com/photo-1569058242567-93de6f36f8e6', quantity: 1, price: 55000)],
      subtotal: 55000,
      deliveryFee: 12000,
      discount: 0,
      totalPrice: 67000,
      status: OrderStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      address: '45 Lê Văn Việt, Q.9, TP.HCM',
      paymentMethod: 'Momo',
    ),
    OrderModel(
      orderId: 'ORD-1003',
      userId: 'user_01',
      items: const [OrderItem(id: 'item_4', name: 'Pizza Hải Sản', imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591', quantity: 1, price: 159000)],
      subtotal: 159000,
      deliveryFee: 20000,
      discount: 20000,
      totalPrice: 159000,
      status: OrderStatus.preparing,
      createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
      address: '78 Võ Văn Ngân, Thủ Đức, TP.HCM',
      paymentMethod: 'ZaloPay',
    ),
    OrderModel(
      orderId: 'ORD-1004',
      userId: 'user_01',
      items: const [OrderItem(id: 'item_5', name: 'Phở Bò Tái', imageUrl: 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43', quantity: 2, price: 50000)],
      subtotal: 100000,
      deliveryFee: 15000,
      discount: 0,
      totalPrice: 115000,
      status: OrderStatus.cancelled,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      address: '12 Trần Não, Q.2, TP.HCM',
      paymentMethod: 'COD',
      note: 'Khách hủy do thay đổi địa chỉ',
    ),
  ];

  @override
  Future<List<OrderModel>> getOrders({String? filter}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (filter == null || filter == 'all') return List.of(_mockOrders);
    if (filter == 'ongoing') return _mockOrders.where((e) => e.status.isOngoing).toList();
    if (filter == 'completed') return _mockOrders.where((e) => e.status.isCompleted).toList();
    if (filter == 'cancelled') return _mockOrders.where((e) => e.status.isCancelled).toList();
    return List.of(_mockOrders);
  }

  @override
  Future<OrderModel?> getOrderById(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    try {
      return _mockOrders.firstWhere((e) => e.orderId == orderId);
    } catch (_) {
      return null;
    }
  }
}

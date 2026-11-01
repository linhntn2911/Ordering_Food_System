import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/errors/failures.dart';

import 'models/cart_item_model.dart';

/// Abstract repository interface for Cart operations
/// Shields presentation layer from data sources / Firebase / SharedPreferences
abstract class CartRepository {
  /// Retrieve cached cart items synchronously (instant local access)
  List<CartItemModel> getCachedCart(String customerId);

  /// Retrieve current cart items for an authenticated customer
  Future<List<CartItemModel>> getCart(String customerId);

  /// Persist cart items for an authenticated customer
  Future<void> saveCart(String customerId, List<CartItemModel> items);

  /// Clear all cart items for an authenticated customer
  Future<void> clearCart(String customerId);

  /// Reload the rich 4 demo items for simulation
  Future<List<CartItemModel>> reloadDemoItems(String customerId);

  /// Watch real-time changes to the cart
  Stream<List<CartItemModel>> watchCart(String customerId);
}

/// Implementation of CartRepository
/// Handles local/remote data synchronization and translates errors into domain Failures
class CartRepositoryImpl implements CartRepository {
  static List<CartItemModel> createDemoCartItems() => [
    CartItemModel(
      id: 'mock_cart_1',
      menuItemId: 'ga_sot_cay_01',
      name: 'Gà sốt cay ngọt Hàn Quốc',
      imageUrl:
          'https://images.unsplash.com/photo-1562967914-608f82629710?w=400',
      basePrice: 35000.0,
      selectedSize: const CartOptionItem(
        id: 'size_l',
        name: 'Size L',
        additionalPrice: 5000.0,
      ),
      selectedToppings: const [
        CartOptionItem(
          id: 'top_cheese',
          name: 'Phô mai rắc',
          additionalPrice: 5000.0,
        ),
      ],
      note: null,
      quantity: 2,
      isAvailable: true,
      isSelected: true,
      createdAt: DateTime.now(),
    ),
    CartItemModel(
      id: 'mock_cart_2',
      menuItemId: 'com_rang_ga_02',
      name: 'Cơm rang gà chiên mắm tỏi',
      imageUrl:
          'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400',
      basePrice: 50000.0,
      selectedSize: const CartOptionItem(
        id: 'size_m',
        name: 'Size M',
        additionalPrice: 0.0,
      ),
      selectedToppings: const [],
      note: 'Ít cay',
      quantity: 1,
      isAvailable: true,
      isSelected: true,
      createdAt: DateTime.now(),
    ),
    CartItemModel(
      id: 'mock_cart_3',
      menuItemId: 'my_cay_03',
      name: 'Mỳ cay xúc xích (Cấp độ 2)',
      imageUrl:
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400',
      basePrice: 30000.0,
      selectedSize: const CartOptionItem(
        id: 'size_cap2',
        name: 'Cấp độ 2',
        additionalPrice: 0.0,
      ),
      selectedToppings: const [],
      note: null,
      quantity: 1,
      isAvailable: true,
      isSelected: true,
      createdAt: DateTime.now(),
    ),
    CartItemModel(
      id: 'mock_cart_4',
      menuItemId: 'tra_sua_04',
      name: 'Trà sữa trân châu đường đen',
      imageUrl:
          'https://images.unsplash.com/photo-1558857563-b37cf5a88206?w=400',
      basePrice: 20000.0,
      selectedSize: const CartOptionItem(
        id: 'size_l',
        name: 'Size L',
        additionalPrice: 5000.0,
      ),
      selectedToppings: const [
        CartOptionItem(
          id: 'top_pearl',
          name: 'Thạch ngọc trai',
          additionalPrice: 5000.0,
        ),
      ],
      note: null,
      quantity: 2,
      isAvailable: true,
      isSelected: true,
      createdAt: DateTime.now(),
    ),
  ];

  // In-memory backing store keyed by customerId for rapid response & local offline support
  final Map<String, List<CartItemModel>> _storage = {
    'customer_demo_uid': createDemoCartItems(),
  };
  final Map<String, StreamController<List<CartItemModel>>> _controllers = {};

  StreamController<List<CartItemModel>> _getController(String customerId) {
    return _controllers.putIfAbsent(
      customerId,
      () => StreamController<List<CartItemModel>>.broadcast(),
    );
  }

  @override
  List<CartItemModel> getCachedCart(String customerId) {
    return List.unmodifiable(_storage[customerId] ?? []);
  }

  @override
  Future<List<CartItemModel>> getCart(String customerId) async {
    if (customerId.trim().isEmpty) {
      throw const AuthFailure('Không tìm thấy thông tin định danh khách hàng.');
    }
    try {
      final items = _storage[customerId] ?? [];
      return List.unmodifiable(items);
    } catch (e) {
      throw CartFailure('Không thể tải giỏ hàng: ${e.toString()}');
    }
  }

  @override
  Future<void> saveCart(String customerId, List<CartItemModel> items) async {
    if (customerId.trim().isEmpty) {
      throw const AuthFailure('Bạn cần đăng nhập để lưu giỏ hàng.');
    }
    try {
      _storage[customerId] = List.from(items);
      _getController(customerId).add(List.unmodifiable(items));
    } catch (e) {
      throw CartFailure('Lỗi khi lưu giỏ hàng: ${e.toString()}');
    }
  }

  @override
  Future<void> clearCart(String customerId) async {
    if (customerId.trim().isEmpty) {
      throw const AuthFailure('Bạn cần đăng nhập để xóa giỏ hàng.');
    }
    try {
      _storage[customerId] = [];
      _getController(customerId).add(const []);
    } catch (e) {
      throw CartFailure('Lỗi khi làm trống giỏ hàng: ${e.toString()}');
    }
  }

  @override
  Future<List<CartItemModel>> reloadDemoItems(String customerId) async {
    if (customerId.trim().isEmpty) {
      throw const AuthFailure('Bạn cần đăng nhập để thao tác giỏ hàng.');
    }
    try {
      final items = createDemoCartItems();
      _storage[customerId] = List.from(items);
      _getController(customerId).add(List.unmodifiable(items));
      return List.unmodifiable(items);
    } catch (e) {
      throw CartFailure('Lỗi khi nạp lại danh sách mẫu: ${e.toString()}');
    }
  }

  @override
  Stream<List<CartItemModel>> watchCart(String customerId) {
    if (customerId.trim().isEmpty) {
      return Stream.error(
        const AuthFailure('Bạn cần đăng nhập để theo dõi giỏ hàng.'),
      );
    }
    final controller = _getController(customerId);
    final currentItems = _storage[customerId] ?? [];
    // Emit initial cached state immediately
    return Stream<List<CartItemModel>>.value(List.unmodifiable(currentItems))
        .concatWith([controller.stream]);
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}

/// Helper extension to prepend initial item to a stream
extension _StreamConcat<T> on Stream<T> {
  Stream<T> concatWith(Iterable<Stream<T>> others) async* {
    yield* this;
    for (final stream in others) {
      yield* stream;
    }
  }
}

/// Provider for the CartRepository
final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final repo = CartRepositoryImpl();
  ref.onDispose(() => repo.dispose());
  return repo;
});

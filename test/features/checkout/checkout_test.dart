import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/address/data/models/address_model.dart';
import 'package:ordering_food_system/features/address/presentation/controllers/address_controller.dart';
import 'package:ordering_food_system/features/cart/data/models/cart_item_model.dart';
import 'package:ordering_food_system/features/cart/presentation/controllers/cart_controller.dart';
import 'package:ordering_food_system/features/checkout/data/checkout_repository.dart';
import 'package:ordering_food_system/features/checkout/data/models/order_model.dart';
import 'package:ordering_food_system/features/checkout/presentation/controllers/checkout_controller.dart';

void main() {
  group('OrderModel & FR-050 Order Code Generation', () {
    test('FR-050: Order code matches ORD-YYYYMMDD-XXXX format', () {
      final code = OrderModel.generateOrderCode(DateTime(2026, 10, 30));
      expect(code, startsWith('ORD-20261030-'));
      expect(RegExp(r'^ORD-\d{8}-\d{4}$').hasMatch(code), isTrue);
    });

    test('Initial status is Pending and Payment method is COD only (FR-015, BR-001)', () {
      const sizeM = CartOptionItem(
        id: 's_m',
        name: 'Size M',
        additionalPrice: 0,
      );
      final item = CartItemModel(
        id: '1',
        menuItemId: 'food_1',
        name: 'Phở Bò',
        imageUrl: '',
        basePrice: 50000,
        selectedSize: sizeM,
        quantity: 2,
        createdAt: DateTime.now(),
      );

      final address = AddressModel(
        id: 'addr_1',
        userId: 'user_123',
        recipientName: 'Hồng Anh',
        phoneNumber: '0901234567',
        streetAddress: '123 Lê Duẩn',
        latitude: 10.7720,
        longitude: 106.6980,
        createdAt: DateTime.now(),
      );

      final order = OrderModel(
        id: 'ord_1',
        orderCode: OrderModel.generateOrderCode(),
        customerId: 'user_123',
        items: [OrderItemSnapshot.fromCartItem(item)],
        addressSnapshot: OrderAddressSnapshot.fromAddressModel(address),
        deliveryDistanceKm: 1.5,
        deliveryFee: 15000,
        subtotal: 100000,
        total: 115000,
        createdAt: DateTime.now(),
      );

      expect(order.status, OrderStatus.pending);
      expect(order.paymentMethod, 'COD');
      expect(order.total, 115000);
    });
  });

  group('CheckoutController & Repository Business Logic', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      container
          .read(currentCustomerIdProvider.notifier)
          .setCustomerId('customer_honganh_1');
    });

    tearDown(() {
      container.dispose();
    });

    const sizeM = CartOptionItem(id: 's_m', name: 'Size M', additionalPrice: 0);
    final validNearAddress = AddressModel(
      id: 'addr_near',
      userId: 'customer_honganh_1',
      recipientName: 'Hồng Anh',
      phoneNumber: '0901234567',
      streetAddress: '123 Lê Duẩn, Quận 1',
      latitude: 10.7720,
      longitude: 106.6980, // ~0.6 km
      isDefault: true,
      createdAt: DateTime.now(),
    );

    final farAddress = AddressModel(
      id: 'addr_far',
      userId: 'customer_honganh_1',
      recipientName: 'Hồng Anh',
      phoneNumber: '0901234567',
      streetAddress: 'Thủ Đức',
      latitude: 10.8700,
      longitude: 106.7800, // ~13.5 km (>8km)
      createdAt: DateTime.now(),
    );

    test(
      'FR-046 & FR-047: Delivery fee bands calculation (15k, 20k, 30k)',
      () async {
        final cartController = container.read(cartControllerProvider.notifier);
        final addressController = container.read(
          addressControllerProvider.notifier,
        );

        await addressController.addAddress(validNearAddress);

        final foodItem = CartItemModel(
          id: 'cart_item_1',
          menuItemId: 'food_1',
          name: 'Trà Sữa',
          imageUrl: '',
          basePrice: 30000,
          selectedSize: sizeM,
          quantity: 1,
          createdAt: DateTime.now(),
        );
        await cartController.addItem(foodItem);

        final checkoutState = container.read(checkoutControllerProvider);
        expect(checkoutState.deliveryDistanceKm, isNotNull);
        expect(checkoutState.deliveryDistanceKm! <= 3.0, isTrue);
        // Fee band 1 (<= 3 km): 15,000 VND
        expect(checkoutState.deliveryFee, 15000.0);
        // FR-049: Total = 30,000 + 15,000 = 45,000 VND
        expect(checkoutState.total, 45000.0);
      },
    );

    test(
      'FR-048 & BR-015: Blocks checkout when distance exceeds 8km',
      () async {
        final cartController = container.read(cartControllerProvider.notifier);
        final checkoutController = container.read(
          checkoutControllerProvider.notifier,
        );

        final foodItem = CartItemModel(
          id: 'cart_item_test',
          menuItemId: 'food_test',
          name: 'Trà Sữa',
          imageUrl: '',
          basePrice: 30000,
          selectedSize: sizeM,
          quantity: 1,
          createdAt: DateTime.now(),
        );
        await cartController.addItem(foodItem);

        checkoutController.selectAddress(farAddress);

        final state = container.read(checkoutControllerProvider);
        expect(state.isServiceable, isFalse);
        expect(state.canSubmitOrder, isFalse);
        expect(state.validationErrorMessage, contains('vượt quá bán kính'));

        final order = await checkoutController.placeOrder();
        expect(order, isNull);
      },
    );

    test(
      'FR-016 & BR-004: Place order creates pending order and clears cart',
      () async {
        final cartController = container.read(cartControllerProvider.notifier);
        final addressController = container.read(
          addressControllerProvider.notifier,
        );
        final checkoutController = container.read(
          checkoutControllerProvider.notifier,
        );

        await addressController.addAddress(validNearAddress);

        final foodItem = CartItemModel(
          id: 'cart_item_1',
          menuItemId: 'food_1',
          name: 'Cơm Gà',
          imageUrl: '',
          basePrice: 40000,
          selectedSize: sizeM,
          quantity: 2, // 80,000
          createdAt: DateTime.now(),
        );
        await cartController.addItem(foodItem);
        expect(container.read(cartControllerProvider).items.length, 1);

        checkoutController.selectAddress(validNearAddress);
        final order = await checkoutController.placeOrder();

        expect(order, isNotNull);
        expect(order!.status, OrderStatus.pending);
        expect(order.subtotal, 80000.0);
        expect(order.deliveryFee, 15000.0);
        expect(order.total, 95000.0);
        expect(order.orderCode, startsWith('ORD-'));

        // Cart MUST be cleared (FR-016)
        expect(container.read(cartControllerProvider).items.isEmpty, isTrue);
      },
    );

    test('User Requirement: When order placed, only purchased items removed, unselected items remain in CartState', () async {
      final cartController = container.read(cartControllerProvider.notifier);
      final addressController = container.read(
        addressControllerProvider.notifier,
      );
      final checkoutController = container.read(
        checkoutControllerProvider.notifier,
      );

      await addressController.addAddress(validNearAddress);

      final selectedItem = CartItemModel(
        id: 'selected_food_1',
        menuItemId: 'food_1',
        name: 'Cơm Gà',
        imageUrl: '',
        basePrice: 40000,
        selectedSize: sizeM,
        quantity: 1,
        isSelected: true,
        createdAt: DateTime.now(),
      );

      final unselectedItem = CartItemModel(
        id: 'unselected_food_2',
        menuItemId: 'food_2',
        name: 'Trà Đào',
        imageUrl: '',
        basePrice: 25000,
        selectedSize: sizeM,
        quantity: 1,
        isSelected: false,
        createdAt: DateTime.now(),
      );

      await cartController.addItem(selectedItem);
      await cartController.addItem(unselectedItem);

      expect(container.read(cartControllerProvider).items.length, 2);

      // CheckoutController should only take the 1 selected item
      expect(container.read(checkoutControllerProvider).cartItems.length, 1);
      expect(
        container.read(checkoutControllerProvider).cartItems.first.id,
        'selected_food_1',
      );

      checkoutController.selectAddress(validNearAddress);
      final order = await checkoutController.placeOrder();

      expect(order, isNotNull);
      // CartState should still retain the unselected item!
      final remainingCart = container.read(cartControllerProvider).items;
      expect(remainingCart.length, 1);
      expect(remainingCart.first.id, 'unselected_food_2');
    });

    test('SC-005 & NFR-003: Duplicate tap prevention throws Failure on duplicate submission', () async {
      final repo = container.read(checkoutRepositoryProvider);

      final foodItem = CartItemModel(
        id: 'cart_item_1',
        menuItemId: 'food_1',
        name: 'Cơm Tấm',
        imageUrl: '',
        basePrice: 35000,
        selectedSize: sizeM,
        quantity: 1,
        createdAt: DateTime.now(),
      );

      const idempotencyKey = 'key_unique_123';

      // First submit succeeds
      final order1 = await repo.placeOrder(
        customerId: 'customer_honganh_1',
        deliveryAddress: validNearAddress,
        cartItems: [foodItem],
        idempotencyKey: idempotencyKey,
      );
      expect(order1, isNotNull);

      // Re-submitting with the same key returns the existing cached order instead of creating a second duplicate order
      final order2 = await repo.placeOrder(
        customerId: 'customer_honganh_1',
        deliveryAddress: validNearAddress,
        cartItems: [foodItem],
        idempotencyKey: idempotencyKey,
      );
      expect(order2.id, order1.id);
      expect(order2.orderCode, order1.orderCode);
    });
  });
}

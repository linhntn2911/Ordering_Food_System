import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/core/errors/failures.dart';
import 'package:ordering_food_system/features/cart/data/models/cart_item_model.dart';
import 'package:ordering_food_system/features/cart/presentation/controllers/cart_controller.dart';

void main() {
  group('CartItemModel Business Rules', () {
    const sizeM = CartOptionItem(id: 's_m', name: 'Size M', additionalPrice: 0);
    const sizeL = CartOptionItem(
      id: 's_l',
      name: 'Size L',
      additionalPrice: 10000,
    );
    const toppingBoba = CartOptionItem(
      id: 't_boba',
      name: 'Trân châu',
      additionalPrice: 5000,
    );
    const toppingJelly = CartOptionItem(
      id: 't_jelly',
      name: 'Thạch',
      additionalPrice: 6000,
    );

    test('FR-011 & BR-012: Unit price and subtotal calculation with size and toppings', () {
      final item = CartItemModel(
        id: 'cart_1',
        menuItemId: 'food_1',
        name: 'Trà Sữa Trân Châu',
        imageUrl: '',
        basePrice: 30000,
        selectedSize: sizeL, // +10,000
        selectedToppings: const [
          toppingBoba,
          toppingJelly,
        ], // +5,000 + 6,000 = +11,000
        note: 'Ít đường',
        quantity: 2,
        createdAt: DateTime.now(),
      );

      // unitPrice = 30000 + 10000 + 11000 = 51000
      expect(item.unitPrice, 51000.0);
      // subtotal = 51000 * 2 = 102000
      expect(item.subtotal, 102000.0);
    });

    test('BR-006 & BR-013: Identical configuration matching logic', () {
      final item1 = CartItemModel(
        id: '1',
        menuItemId: 'food_1',
        name: 'Trà Sữa',
        imageUrl: '',
        basePrice: 30000,
        selectedSize: sizeM,
        selectedToppings: const [toppingBoba, toppingJelly],
        note: 'Ít đá',
        quantity: 1,
        createdAt: DateTime.now(),
      );

      // Same food, same size, same toppings (different order), same note
      final item2 = CartItemModel(
        id: '2',
        menuItemId: 'food_1',
        name: 'Trà Sữa',
        imageUrl: '',
        basePrice: 30000,
        selectedSize: sizeM,
        selectedToppings: const [toppingJelly, toppingBoba],
        note: ' ít đá ',
        quantity: 2,
        createdAt: DateTime.now(),
      );

      // Different note
      final item3 = item1.copyWith(note: 'Nhiều đá');

      // Different size
      final item4 = item1.copyWith(selectedSize: sizeL);

      expect(item1.isIdenticalConfiguration(item2), isTrue);
      expect(item1.isIdenticalConfiguration(item3), isFalse);
      expect(item1.isIdenticalConfiguration(item4), isFalse);
    });

    test(
      'FR-013: Validation for checkout (availability & required options)',
      () {
        final availableItem = CartItemModel(
          id: '1',
          menuItemId: 'food_1',
          name: 'Burger Gà',
          imageUrl: '',
          basePrice: 45000,
          selectedSize: sizeM,
          isAvailable: true,
          quantity: 1,
          createdAt: DateTime.now(),
        );

        final unavailableItem = availableItem.copyWith(isAvailable: false);

        expect(availableItem.isValidForCheckout, isTrue);
        expect(unavailableItem.isValidForCheckout, isFalse);
        expect(
          unavailableItem.validationErrorMessage,
          contains('tạm hết hàng'),
        );
      },
    );
  });

  group('CartController Business Logic with Riverpod', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      container
          .read(currentCustomerIdProvider.notifier)
          .setCustomerId('test_customer_123');
    });

    tearDown(() {
      container.dispose();
    });

    const sizeM = CartOptionItem(id: 's_m', name: 'Size M', additionalPrice: 0);
    const topping = CartOptionItem(
      id: 't_1',
      name: 'Phô mai',
      additionalPrice: 5000,
    );

    test(
      'BR-011: Throws AuthFailure when customer is not authenticated',
      () async {
        container.read(currentCustomerIdProvider.notifier).setCustomerId(null);

        final controller = container.read(cartControllerProvider.notifier);

        final item = CartItemModel(
          id: '1',
          menuItemId: 'food_1',
          name: 'Pizza',
          imageUrl: '',
          basePrice: 50000,
          selectedSize: sizeM,
          createdAt: DateTime.now(),
        );

        expect(() => controller.addItem(item), throwsA(isA<AuthFailure>()));
      },
    );

    test('BR-006 & BR-013: Adding identical item increases quantity instead of duplicate line', () async {
      final controller = container.read(cartControllerProvider.notifier);

      final item1 = CartItemModel(
        id: 'item_1',
        menuItemId: 'food_1',
        name: 'Trà Sữa Đào',
        imageUrl: '',
        basePrice: 25000,
        selectedSize: sizeM,
        selectedToppings: const [topping],
        note: 'Ít đường',
        quantity: 1,
        createdAt: DateTime.now(),
      );

      final item2 = CartItemModel(
        id: 'item_2',
        menuItemId: 'food_1',
        name: 'Trà Sữa Đào',
        imageUrl: '',
        basePrice: 25000,
        selectedSize: sizeM,
        selectedToppings: const [topping],
        note: 'Ít đường',
        quantity: 3,
        createdAt: DateTime.now(),
      );

      await controller.addItem(item1);
      expect(container.read(cartControllerProvider).items.length, 1);
      expect(container.read(cartControllerProvider).items.first.quantity, 1);

      // Add identical item2
      await controller.addItem(item2);
      final state = container.read(cartControllerProvider);

      // Should still be 1 line, with quantity = 4
      expect(state.items.length, 1);
      expect(state.items.first.quantity, 4);
      // Subtotal should immediately recalculate: (25000 + 5000) * 4 = 120000
      expect(state.subtotal, 120000.0);
    });

    test('FR-012: Quantity update and line removal recalculates totals immediately', () async {
      final controller = container.read(cartControllerProvider.notifier);

      final item = CartItemModel(
        id: 'cart_item_a',
        menuItemId: 'food_a',
        name: 'Cơm Gà',
        imageUrl: '',
        basePrice: 40000,
        selectedSize: sizeM,
        quantity: 2,
        createdAt: DateTime.now(),
      );

      await controller.addItem(item);
      expect(container.read(cartControllerProvider).subtotal, 80000.0);

      // Update quantity to 5
      await controller.updateQuantity('cart_item_a', 5);
      expect(container.read(cartControllerProvider).subtotal, 200000.0);

      // Decrement quantity
      await controller.decrementQuantity('cart_item_a');
      expect(container.read(cartControllerProvider).items.first.quantity, 4);

      // Remove item
      await controller.removeItem('cart_item_a');
      expect(container.read(cartControllerProvider).items.isEmpty, isTrue);
      expect(container.read(cartControllerProvider).subtotal, 0.0);
    });

    test(
      'FR-013: Checkout validation blocks checkout when an item is unavailable',
      () async {
        final controller = container.read(cartControllerProvider.notifier);

        final outOfStockItem = CartItemModel(
          id: 'cart_item_out',
          menuItemId: 'food_out',
          name: 'Bánh Mì Chảo',
          imageUrl: '',
          basePrice: 35000,
          selectedSize: sizeM,
          isAvailable: false,
          quantity: 1,
          createdAt: DateTime.now(),
        );

        await controller.addItem(outOfStockItem);
        final state = container.read(cartControllerProvider);

        expect(state.hasUnavailableItems, isTrue);
        expect(state.canProceedToCheckout, isFalse);

        final canCheckout = controller.validateCartForCheckout();
        expect(canCheckout, isFalse);
        expect(
          container.read(cartControllerProvider).errorMessage,
          contains('tạm hết hàng'),
        );
      },
    );

    test('Shopee-style selection: subtotal calculates ONLY selected items and blocks checkout when no items selected', () async {
      final controller = container.read(cartControllerProvider.notifier);

      final item1 = CartItemModel(
        id: 'item_sel_1',
        menuItemId: 'food_1',
        name: 'Gà sốt cay',
        imageUrl: '',
        basePrice: 45000,
        selectedSize: sizeM,
        quantity: 2, // subtotal = 90,000
        isSelected: true,
        createdAt: DateTime.now(),
      );

      final item2 = CartItemModel(
        id: 'item_sel_2',
        menuItemId: 'food_2',
        name: 'Cơm rang gà',
        imageUrl: '',
        basePrice: 50000,
        selectedSize: sizeM,
        quantity: 1, // subtotal = 50,000
        isSelected: true,
        createdAt: DateTime.now(),
      );

      await controller.addItem(item1);
      await controller.addItem(item2);

      var state = container.read(cartControllerProvider);
      // Both selected: subtotal = 90,000 + 50,000 = 140,000
      expect(state.subtotal, 140000.0);
      expect(state.selectedItemCount, 3);
      expect(state.canProceedToCheckout, isTrue);

      // Unselect item 1
      await controller.toggleItemSelection('item_sel_1');
      state = container.read(cartControllerProvider);

      // Only item 2 selected: subtotal = 50,000
      expect(state.subtotal, 50000.0);
      expect(state.selectedItemCount, 1);
      expect(state.canProceedToCheckout, isTrue);

      // Deselect all items
      await controller.toggleSelectAll(false);
      state = container.read(cartControllerProvider);

      // No item selected: subtotal = 0, canProceedToCheckout = false
      expect(state.subtotal, 0.0);
      expect(state.selectedItemCount, 0);
      expect(state.hasSelectedItems, isFalse);
      expect(state.canProceedToCheckout, isFalse);

      final canCheckout = controller.validateCartForCheckout();
      expect(canCheckout, isFalse);
      expect(
        container.read(cartControllerProvider).errorMessage,
        contains('chọn ít nhất một món'),
      );
    });

    test('Reload demo items restores 4 rich mock items', () async {
      final controller = container.read(cartControllerProvider.notifier);

      await controller.clearCart();
      expect(container.read(cartControllerProvider).items.isEmpty, isTrue);

      await controller.reloadDemoItems();
      final state = container.read(cartControllerProvider);

      expect(state.items.length, 4);
      expect(state.items.any((e) => e.name.contains('Gà sốt cay')), isTrue);
      expect(state.items.any((e) => e.name.contains('Cơm rang gà')), isTrue);
      expect(state.items.any((e) => e.name.contains('Mỳ cay')), isTrue);
      expect(state.items.any((e) => e.name.contains('Trà sữa')), isTrue);
      expect(state.canProceedToCheckout, isTrue);
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/core/errors/failures.dart';
import 'package:ordering_food_system/features/address/data/models/address_model.dart';
import 'package:ordering_food_system/features/address/presentation/controllers/address_controller.dart';
import 'package:ordering_food_system/features/cart/presentation/controllers/cart_controller.dart';

void main() {
  group('AddressModel Unit Tests', () {
    test('Phone validation accepts valid VN phone numbers and rejects invalid ones', () {
      expect(AddressModel.isValidPhone('0901234567'), isTrue);
      expect(AddressModel.isValidPhone('0388889999'), isTrue);
      expect(AddressModel.isValidPhone('0771234567'), isTrue);
      expect(AddressModel.isValidPhone('0561234567'), isTrue);

      expect(
        AddressModel.isValidPhone('1234567890'),
        isFalse,
      ); // Doesn't start with 0
      expect(
        AddressModel.isValidPhone('0123456789'),
        isFalse,
      ); // 01 is not valid mobile prefix
      expect(AddressModel.isValidPhone('090123456'), isFalse); // 9 digits
      expect(AddressModel.isValidPhone('09012345678'), isFalse); // 11 digits
      expect(AddressModel.isValidPhone('abcdefghij'), isFalse);
    });

    test('Distance and delivery fee calculation according to FR-046, FR-047, FR-048', () {
      // Restaurant reference: lat 10.7769, lng 106.7009 (District 1)
      final nearAddress = AddressModel(
        id: '1',
        userId: 'user_1',
        recipientName: 'Hồng Anh',
        phoneNumber: '0901234567',
        streetAddress: 'Số 10 Đồng Khởi',
        latitude: 10.7720,
        longitude: 106.6980, // ~0.6 km
        createdAt: DateTime.now(),
      );

      expect(nearAddress.distanceToRestaurant, isNotNull);
      expect(nearAddress.distanceToRestaurant! <= 3.0, isTrue);
      expect(nearAddress.isServiceable, isTrue);
      expect(nearAddress.deliveryFee, 15000.0); // <= 3km is 15,000 VND

      // Far address (> 8km)
      final farAddress = AddressModel(
        id: '2',
        userId: 'user_1',
        recipientName: 'Hồng Anh',
        phoneNumber: '0901234567',
        streetAddress: 'Phường Linh Trung',
        latitude: 10.8700,
        longitude: 106.7800, // ~13.5 km
        createdAt: DateTime.now(),
      );

      expect(farAddress.distanceToRestaurant! > 8.0, isTrue);
      expect(farAddress.isServiceable, isFalse);
      expect(farAddress.deliveryFee, isNull); // Blocked
    });
  });

  group('AddressController & Repository Business Logic', () {
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

    test(
      'BR-008: Auth check throws AuthFailure if customer not logged in',
      () async {
        container.read(currentCustomerIdProvider.notifier).setCustomerId(null);
        final controller = container.read(addressControllerProvider.notifier);

        final address = AddressModel(
          id: 'addr_1',
          userId: '',
          recipientName: 'Hồng Anh',
          phoneNumber: '0901234567',
          streetAddress: '123 Nguyễn Huệ, Quận 1',
          createdAt: DateTime.now(),
        );

        expect(
          () => controller.addAddress(address),
          throwsA(isA<AuthFailure>()),
        );
      },
    );

    test('FR-017 & FR-018 & User Story 8 Scenario 2: Adding and setting single default address', () async {
      final controller = container.read(addressControllerProvider.notifier);

      final addr1 = AddressModel(
        id: 'addr_home',
        userId: 'customer_honganh_1',
        label: 'Nhà riêng',
        recipientName: 'Hồng Anh',
        phoneNumber: '0901234567',
        streetAddress: '123 Lê Lợi, Bến Nghé, Quận 1',
        isDefault: true,
        createdAt: DateTime.now(),
      );

      final addr2 = AddressModel(
        id: 'addr_office',
        userId: 'customer_honganh_1',
        label: 'Văn phòng',
        recipientName: 'Hồng Anh',
        phoneNumber: '0901234567',
        streetAddress: '45 Đinh Tiên Hoàng, Quận 1',
        isDefault: false,
        createdAt: DateTime.now(),
      );

      await controller.addAddress(addr1);
      await controller.addAddress(addr2);

      var state = container.read(addressControllerProvider);
      expect(state.addresses.length, 2);
      expect(state.defaultAddress?.id, 'addr_home');

      // Now set addr2 as default: addr1 must automatically lose default status!
      await controller.setDefaultAddress('addr_office');
      state = container.read(addressControllerProvider);

      final homeAfter = state.addresses.firstWhere((e) => e.id == 'addr_home');
      final officeAfter = state.addresses.firstWhere(
        (e) => e.id == 'addr_office',
      );

      expect(officeAfter.isDefault, isTrue);
      expect(homeAfter.isDefault, isFalse);
      expect(state.defaultAddress?.id, 'addr_office');
    });

    test('FR-017: Deleting an address promotes remaining address to default if needed', () async {
      final controller = container.read(addressControllerProvider.notifier);

      final addr1 = AddressModel(
        id: 'addr_delete_me',
        userId: 'customer_honganh_1',
        recipientName: 'Hồng Anh',
        phoneNumber: '0901234567',
        streetAddress: '123 Đường A, Quận 1',
        isDefault: true,
        createdAt: DateTime.now(),
      );

      final addr2 = AddressModel(
        id: 'addr_keep_me',
        userId: 'customer_honganh_1',
        recipientName: 'Hồng Anh',
        phoneNumber: '0901234567',
        streetAddress: '456 Đường B, Quận 1',
        isDefault: false,
        createdAt: DateTime.now(),
      );

      await controller.addAddress(addr1);
      await controller.addAddress(addr2);

      // Delete the default address
      await controller.deleteAddress('addr_delete_me');
      final state = container.read(addressControllerProvider);

      expect(state.addresses.length, 1);
      expect(state.addresses.first.id, 'addr_keep_me');
      expect(state.addresses.first.isDefault, isTrue);
    });
  });
}

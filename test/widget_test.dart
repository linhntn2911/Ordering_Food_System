import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/auth/domain/entities/app_user.dart';
import 'package:ordering_food_system/features/auth/data/models/user_model.dart';

void main() {
  group('AppUser & UserModel Tests', () {
    test('AppUser role and status helpers return expected flags', () {
      const customer = AppUser(
        id: 'user_1',
        fullName: 'Nguyen Van A',
        email: 'customer@example.com',
        phone: '0912345678',
        role: 'customer',
        status: 'active',
      );

      expect(customer.isAdmin, isFalse);
      expect(customer.isCustomer, isTrue);
      expect(customer.isActive, isTrue);
      expect(customer.isDisabled, isFalse);

      const admin = AppUser(
        id: 'admin_1',
        fullName: 'Admin User',
        email: 'admin@foodninja.vn',
        phone: '0988888888',
        role: 'admin',
        status: 'active',
      );

      expect(admin.isAdmin, isTrue);
      expect(admin.isCustomer, isFalse);

      const disabledUser = AppUser(
        id: 'disabled_1',
        fullName: 'Disabled User',
        email: 'disabled@foodninja.vn',
        phone: '0900000000',
        role: 'customer',
        status: 'disabled',
      );

      expect(disabledUser.isDisabled, isTrue);
      expect(disabledUser.isActive, isFalse);
    });

    test('UserModel converts to and from Map correctly', () {
      final now = DateTime(2026, 10, 20);
      final model = UserModel(
        id: 'uid_123',
        fullName: 'Tran Van Thai',
        email: 'thai@example.com',
        phone: '0987654321',
        avatarUrl: 'https://example.com/avatar.png',
        role: 'customer',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      final entity = model.toEntity();
      expect(entity.id, equals('uid_123'));
      expect(entity.fullName, equals('Tran Van Thai'));
      expect(entity.email, equals('thai@example.com'));
      expect(entity.phone, equals('0987654321'));
      expect(entity.avatarUrl, equals('https://example.com/avatar.png'));
      expect(entity.role, equals('customer'));
      expect(entity.status, equals('active'));

      final fromEntity = UserModel.fromEntity(entity);
      expect(fromEntity.id, equals(model.id));
      expect(fromEntity.fullName, equals(model.fullName));
      expect(fromEntity.email, equals(model.email));
    });
  });
}

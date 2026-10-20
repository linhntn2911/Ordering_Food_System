import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/register_view_model.dart';

void main() {
  group('RegisterViewModel Validation Tests (FR-002)', () {
    late RegisterViewModel viewModel;

    setUp(() {
      viewModel = RegisterViewModel();
    });

    test('Full name validation requires at least 2 characters', () {
      expect(viewModel.validateFullName(null), isNotNull);
      expect(viewModel.validateFullName(''), isNotNull);
      expect(viewModel.validateFullName('A'), isNotNull);
      expect(viewModel.validateFullName('Nguyen Van A'), isNull);
    });

    test('Email validation checks for valid format', () {
      expect(viewModel.validateEmail(null), isNotNull);
      expect(viewModel.validateEmail('invalid-email'), isNotNull);
      expect(viewModel.validateEmail('user@'), isNotNull);
      expect(viewModel.validateEmail('user@domain.com'), isNull);
    });

    test('Phone validation checks for valid VN phone format', () {
      expect(viewModel.validatePhone(null), isNotNull);
      expect(viewModel.validatePhone('123'), isNotNull);
      expect(viewModel.validatePhone('abcdefghij'), isNotNull);
      expect(viewModel.validatePhone('0912345678'), isNull);
      expect(viewModel.validatePhone('+84912345678'), isNull);
    });

    test('Password validation enforces minimum 6 characters', () {
      expect(viewModel.validatePassword(null), isNotNull);
      expect(viewModel.validatePassword('12345'), isNotNull);
      expect(viewModel.validatePassword('123456'), isNull);
      expect(viewModel.validatePassword('strongPassword123'), isNull);
    });

    test('Confirm password must match password', () {
      expect(viewModel.validateConfirmPassword(null, 'secret123'), isNotNull);
      expect(
        viewModel.validateConfirmPassword('mismatch', 'secret123'),
        isNotNull,
      );
      expect(
        viewModel.validateConfirmPassword('secret123', 'secret123'),
        isNull,
      );
    });
  });
}

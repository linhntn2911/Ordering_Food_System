import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/core/errors/app_exception.dart';
import 'package:ordering_food_system/features/auth/domain/entities/app_user.dart';
import 'package:ordering_food_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/auth_providers.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/forgot_password_view_model.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/login_view_model.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/register_view_model.dart';

class MockAuthRepository implements AuthRepository {
  final Set<String> registeredEmails = {'existing@foodninja.com'};
  final Set<String> registeredPhones = {'0912345678'};

  @override
  Future<void> checkRegistrationAvailability({
    required String email,
    required String phone,
    String? password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final cleanPhone = phone
        .trim()
        .replaceAll(' ', '')
        .replaceFirst('+84', '0');

    if (registeredEmails.contains(normalizedEmail)) {
      throw const ValidationException(
        'Email này đã được sử dụng. Vui lòng đăng nhập hoặc dùng email khác.',
      );
    }
    if (registeredPhones.contains(cleanPhone)) {
      throw const ValidationException(
        'Số điện thoại này đã được sử dụng. Vui lòng dùng số khác.',
      );
    }
  }

  @override
  Future<bool> checkEmailExists(String email) async {
    return registeredEmails.contains(email.trim().toLowerCase());
  }

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(null);

  @override
  Future<AppUser?> getCurrentUser() async => null;

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> signInWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> registerCustomer({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {}
}

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

  group('Immediate Duplicate Email & Phone Checking Tests', () {
    late ProviderContainer container;
    late MockAuthRepository mockAuthRepo;

    setUp(() {
      mockAuthRepo = MockAuthRepository();
      container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
      );
    });

    tearDown(() => container.dispose());

    test('Immediately blocks registration if email is already taken', () async {
      final notifier = container.read(registerViewModelProvider.notifier);
      final result = await notifier.prepareRegistrationWithOtp(
        fullName: 'Nguyen Van B',
        email: 'existing@foodninja.com',
        phone: '0988776655',
        password: 'Password123',
        confirmPassword: 'Password123',
      );

      expect(result, isNull);
      final state = container.read(registerViewModelProvider);
      expect(state.errorMessage, contains('Email này đã được sử dụng'));
    });

    test('Immediately blocks registration if phone is already taken', () async {
      final notifier = container.read(registerViewModelProvider.notifier);
      final result = await notifier.prepareRegistrationWithOtp(
        fullName: 'Nguyen Van C',
        email: 'newuser@foodninja.com',
        phone: '0912345678', // already in registeredPhones
        password: 'Password123',
        confirmPassword: 'Password123',
      );

      expect(result, isNull);
      final state = container.read(registerViewModelProvider);
      expect(state.errorMessage, contains('Số điện thoại này đã được sử dụng'));
    });

    test('Immediately blocks registration if phone is in +84 format matching existing', () async {
      final notifier = container.read(registerViewModelProvider.notifier);
      final result = await notifier.prepareRegistrationWithOtp(
        fullName: 'Nguyen Van C',
        email: 'newuser2@foodninja.com',
        phone: '+84912345678', // matches 0912345678
        password: 'Password123',
        confirmPassword: 'Password123',
      );

      expect(result, isNull);
      final state = container.read(registerViewModelProvider);
      expect(state.errorMessage, contains('Số điện thoại này đã được sử dụng'));
    });

    test(
      'Allows registration preparation when email and phone are both unique',
      () async {
        final notifier = container.read(registerViewModelProvider.notifier);
        final result = await notifier.prepareRegistrationWithOtp(
          fullName: 'Nguyen Van D',
          email: 'unique@foodninja.com',
          phone: '0977112233',
          password: 'Password123',
          confirmPassword: 'Password123',
        );

        expect(result, isNotNull);
        expect(result!.email, 'unique@foodninja.com');
        expect(result.phone, '0977112233');
        final state = container.read(registerViewModelProvider);
        expect(state.errorMessage, isNull);
      },
    );
  });

  group('ForgotPasswordViewModel Existence Validation Tests', () {
    late ProviderContainer container;
    late MockAuthRepository mockAuthRepo;

    setUp(() {
      mockAuthRepo = MockAuthRepository();
      container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
      );
    });

    tearDown(() => container.dispose());

    test(
      'Immediately blocks next step if email does NOT exist in system',
      () async {
        final notifier = container.read(
          forgotPasswordViewModelProvider.notifier,
        );
        final exists = await notifier.verifyEmailExists(
          'notfound@foodninja.com',
        );

        expect(exists, isFalse);
        final state = container.read(forgotPasswordViewModelProvider);
        expect(
          state.errorMessage,
          contains('Email này chưa được đăng ký trong hệ thống'),
        );
      },
    );

    test('Allows next step if email exists in system', () async {
      final notifier = container.read(forgotPasswordViewModelProvider.notifier);
      final exists = await notifier.verifyEmailExists('existing@foodninja.com');

      expect(exists, isTrue);
      final state = container.read(forgotPasswordViewModelProvider);
      expect(state.errorMessage, isNull);
    });
  });

  group('LoginViewModel Validation Tests', () {
    late LoginViewModel viewModel;

    setUp(() {
      viewModel = LoginViewModel();
    });

    test('Email validation checks for valid format', () {
      expect(viewModel.validateEmail(null), isNotNull);
      expect(viewModel.validateEmail(''), isNotNull);
      expect(viewModel.validateEmail('invalid-email'), isNotNull);
      expect(viewModel.validateEmail('user@'), isNotNull);
      expect(viewModel.validateEmail('user@foodninja.com'), isNull);
    });

    test('Password validation enforces minimum 6 characters', () {
      expect(viewModel.validatePassword(null), isNotNull);
      expect(viewModel.validatePassword(''), isNotNull);
      expect(viewModel.validatePassword('12345'), isNotNull);
      expect(viewModel.validatePassword('123456'), isNull);
      expect(viewModel.validatePassword('strongPassword123'), isNull);
    });
  });
}

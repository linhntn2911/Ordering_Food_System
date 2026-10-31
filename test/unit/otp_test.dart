import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/auth/domain/entities/app_user.dart';
import 'package:ordering_food_system/features/auth/domain/repositories/otp_repository.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/reset_password_view_model.dart';

class MockOtpRepository implements OtpRepository {
  String? _lastOtp;
  final Map<String, String> _storage = {};
  final Map<String, DateTime> _expiry = {};
  final Set<String> _used = {};

  @override
  String? get lastGeneratedOtp => _lastOtp;

  @override
  Future<String> sendOtp({required String email, required OtpType type}) async {
    _lastOtp = '123456';
    final key = '${email.trim().toLowerCase()}_${type.name}';
    _storage[key] = _lastOtp!;
    _expiry[key] = DateTime.now().add(const Duration(minutes: 5));
    return _lastOtp!;
  }

  @override
  Future<bool> verifyOtp({
    required String email,
    required String code,
    required OtpType type,
  }) async {
    final key = '${email.trim().toLowerCase()}_${type.name}';
    final stored = _storage[key];
    if (stored == null) return false;
    if (_used.contains(key)) return false;
    if (DateTime.now().isAfter(_expiry[key]!)) return false;
    if (stored != code) return false;

    _used.add(key);
    return true;
  }

  @override
  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final verified = await verifyOtp(
      email: email,
      code: otp,
      type: OtpType.forgotPassword,
    );
    if (!verified) throw Exception('Invalid OTP');
  }

  @override
  Future<AppUser> completeRegistration({
    required PendingRegistration pending,
    required String otp,
  }) async {
    final verified = await verifyOtp(
      email: pending.email,
      code: otp,
      type: OtpType.registration,
    );
    if (!verified) throw Exception('Invalid OTP');
    return AppUser(
      id: 'mock-user-id',
      fullName: pending.fullName,
      email: pending.email,
      phone: pending.phone,
      role: 'customer',
      status: 'active',
    );
  }
}

void main() {
  group('OTP Logic & Reset Password Validation Tests', () {
    late MockOtpRepository otpRepo;
    late ResetPasswordViewModel resetViewModel;

    setUp(() {
      otpRepo = MockOtpRepository();
      resetViewModel = ResetPasswordViewModel();
    });

    test('sendOtp generates a valid 6-digit OTP', () async {
      final code = await otpRepo.sendOtp(
        email: 'test@example.com',
        type: OtpType.forgotPassword,
      );

      expect(code.length, 6);
      expect(int.tryParse(code), isNotNull);
      expect(otpRepo.lastGeneratedOtp, equals(code));
    });

    test(
      'verifyOtp returns true for matching code and false for incorrect code',
      () async {
        await otpRepo.sendOtp(
          email: 'user@example.com',
          type: OtpType.registration,
        );

        final incorrect = await otpRepo.verifyOtp(
          email: 'user@example.com',
          code: '999999',
          type: OtpType.registration,
        );
        expect(incorrect, isFalse);

        final correct = await otpRepo.verifyOtp(
          email: 'user@example.com',
          code: '123456',
          type: OtpType.registration,
        );
        expect(correct, isTrue);

        // Subsequent check returns false because OTP is marked used
        final reused = await otpRepo.verifyOtp(
          email: 'user@example.com',
          code: '123456',
          type: OtpType.registration,
        );
        expect(reused, isFalse);
      },
    );

    test('ResetPasswordViewModel validates minimum password length of 6', () {
      expect(resetViewModel.validatePassword(null), isNotNull);
      expect(resetViewModel.validatePassword(''), isNotNull);
      expect(resetViewModel.validatePassword('12345'), isNotNull);
      expect(resetViewModel.validatePassword('123456'), isNull);
      expect(resetViewModel.validatePassword('complexPass!'), isNull);
    });

    test('ResetPasswordViewModel validates matching confirm password', () {
      expect(
        resetViewModel.validateConfirmPassword(null, 'secret123'),
        isNotNull,
      );
      expect(
        resetViewModel.validateConfirmPassword('wrong', 'secret123'),
        isNotNull,
      );
      expect(
        resetViewModel.validateConfirmPassword('secret123', 'secret123'),
        isNull,
      );
    });
  });
}

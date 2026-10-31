import '../entities/app_user.dart';

enum OtpType { registration, forgotPassword }

class PendingRegistration {
  final String fullName;
  final String email;
  final String phone;
  final String password;

  const PendingRegistration({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
  });
}

abstract class OtpRepository {
  /// Stores the most recently generated OTP for testing and UI display.
  String? get lastGeneratedOtp;

  /// Generates a 6-digit OTP, saves it with an expiration timestamp,
  /// and dispatches a branded email.
  Future<String> sendOtp({required String email, required OtpType type});

  /// Verifies that the provided [code] matches the active OTP for [email] and [type].
  Future<bool> verifyOtp({
    required String email,
    required String code,
    required OtpType type,
  });

  /// Resets the user's password after verifying the [otp].
  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  });

  /// Completes pending registration after OTP verification.
  Future<AppUser> completeRegistration({
    required PendingRegistration pending,
    required String otp,
  });
}

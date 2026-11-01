import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/errors/app_exception.dart';
import 'package:ordering_food_system/features/auth/domain/entities/app_user.dart';
import 'package:ordering_food_system/features/auth/domain/repositories/otp_repository.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/auth_providers.dart';

class RegisterState {
  final bool isLoading;
  final String? errorMessage;
  final AppUser? user;
  final PendingRegistration? pendingRegistration;

  const RegisterState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
    this.pendingRegistration,
  });

  RegisterState copyWith({
    bool? isLoading,
    String? errorMessage,
    AppUser? user,
    PendingRegistration? pendingRegistration,
    bool clearError = false,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      user: user ?? this.user,
      pendingRegistration: pendingRegistration ?? this.pendingRegistration,
    );
  }
}

class RegisterViewModel extends Notifier<RegisterState> {
  @override
  RegisterState build() {
    return const RegisterState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name.';
    }
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters.';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email.';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number.';
    }
    final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9,10}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid 10-digit phone number.';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  /// Validates input and sends OTP before creating the account
  Future<PendingRegistration?> prepareRegistrationWithOtp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    final nameErr = validateFullName(fullName);
    if (nameErr != null) {
      state = state.copyWith(errorMessage: nameErr);
      return null;
    }

    final emailErr = validateEmail(email);
    if (emailErr != null) {
      state = state.copyWith(errorMessage: emailErr);
      return null;
    }

    final phoneErr = validatePhone(phone);
    if (phoneErr != null) {
      state = state.copyWith(errorMessage: phoneErr);
      return null;
    }

    final passErr = validatePassword(password);
    if (passErr != null) {
      state = state.copyWith(errorMessage: passErr);
      return null;
    }

    final confirmErr = validateConfirmPassword(confirmPassword, password);
    if (confirmErr != null) {
      state = state.copyWith(errorMessage: confirmErr);
      return null;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final otpRepo = ref.read(otpRepositoryProvider);
      await otpRepo.sendOtp(email: email.trim(), type: OtpType.registration);

      final pending = PendingRegistration(
        fullName: fullName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        password: password,
      );

      state = state.copyWith(isLoading: false, pendingRegistration: pending);
      return pending;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể gửi mã xác thực. Vui lòng thử lại.',
      );
      return null;
    }
  }

  Future<AppUser?> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    final nameErr = validateFullName(fullName);
    if (nameErr != null) {
      state = state.copyWith(errorMessage: nameErr);
      return null;
    }

    final emailErr = validateEmail(email);
    if (emailErr != null) {
      state = state.copyWith(errorMessage: emailErr);
      return null;
    }

    final phoneErr = validatePhone(phone);
    if (phoneErr != null) {
      state = state.copyWith(errorMessage: phoneErr);
      return null;
    }

    final passErr = validatePassword(password);
    if (passErr != null) {
      state = state.copyWith(errorMessage: passErr);
      return null;
    }

    final confirmErr = validateConfirmPassword(confirmPassword, password);
    if (confirmErr != null) {
      state = state.copyWith(errorMessage: confirmErr);
      return null;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.registerCustomer(
        fullName: fullName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        password: password,
      );

      state = state.copyWith(isLoading: false, user: user);
      return user;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Registration failed. Please try again.',
      );
      return null;
    }
  }
}

final registerViewModelProvider =
    NotifierProvider<RegisterViewModel, RegisterState>(RegisterViewModel.new);

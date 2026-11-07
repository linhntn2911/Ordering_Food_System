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
      return 'Vui lòng nhập họ và tên.';
    }
    if (value.trim().length < 2) {
      return 'Họ và tên phải có ít nhất 2 ký tự.';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email.';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Vui lòng nhập địa chỉ email hợp lệ.';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại.';
    }
    final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9,10}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Vui lòng nhập số điện thoại hợp lệ gồm 10 chữ số.';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu.';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    return null;
  }

  String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu.';
    }
    if (value != password) {
      return 'Mật khẩu xác nhận không khớp.';
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
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.checkRegistrationAvailability(
        email: email.trim(),
        phone: phone.trim(),
        password: password,
      );

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
        errorMessage: 'Không thể chuẩn bị đăng ký. Vui lòng thử lại.',
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
        errorMessage: 'Đăng ký không thành công. Vui lòng thử lại.',
      );
      return null;
    }
  }
}

final registerViewModelProvider =
    NotifierProvider<RegisterViewModel, RegisterState>(RegisterViewModel.new);

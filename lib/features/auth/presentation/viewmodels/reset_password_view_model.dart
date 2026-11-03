import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/errors/app_exception.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/auth_providers.dart';

class ResetPasswordState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  const ResetPasswordState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  ResetPasswordState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ResetPasswordState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ResetPasswordViewModel extends Notifier<ResetPasswordState> {
  @override
  ResetPasswordState build() {
    return const ResetPasswordState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu mới.';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    return null;
  }

  String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận lại mật khẩu mới.';
    }
    if (value != password) {
      return 'Mật khẩu xác nhận không khớp.';
    }
    return null;
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final passErr = validatePassword(newPassword);
    if (passErr != null) {
      state = state.copyWith(errorMessage: passErr);
      return false;
    }

    final confirmErr = validateConfirmPassword(confirmPassword, newPassword);
    if (confirmErr != null) {
      state = state.copyWith(errorMessage: confirmErr);
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final otpRepo = ref.read(otpRepositoryProvider);
      await otpRepo.resetPasswordWithOtp(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Đặt lại mật khẩu thất bại. Vui lòng thử lại.',
      );
      return false;
    }
  }

  void reset() {
    state = const ResetPasswordState();
  }
}

final resetPasswordViewModelProvider =
    NotifierProvider<ResetPasswordViewModel, ResetPasswordState>(
      ResetPasswordViewModel.new,
    );

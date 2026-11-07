import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/errors/app_exception.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/auth_providers.dart';

class ForgotPasswordState {
  final bool isLoading;
  final String? errorMessage;

  const ForgotPasswordState({this.isLoading = false, this.errorMessage});

  ForgotPasswordState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ForgotPasswordViewModel extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() {
    return const ForgotPasswordState();
  }

  void reset() {
    state = const ForgotPasswordState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  bool validateEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(errorMessage: 'Vui lòng nhập địa chỉ email.');
      return false;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(trimmed)) {
      state = state.copyWith(
        errorMessage: 'Địa chỉ email không đúng định dạng.',
      );
      return false;
    }
    state = state.copyWith(clearError: true);
    return true;
  }

  Future<bool> verifyEmailExists(String email) async {
    if (!validateEmail(email)) return false;

    final trimmed = email.trim().toLowerCase();
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final exists = await authRepo.checkEmailExists(trimmed);
      if (!exists) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Email này chưa được đăng ký trong hệ thống. Vui lòng kiểm tra lại.',
        );
        return false;
      }

      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể kiểm tra tài khoản. Vui lòng thử lại.',
      );
      return false;
    }
  }

  Future<bool> sendResetEmail(String email) async {
    if (!validateEmail(email)) {
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } on AppException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể gửi email đặt lại mật khẩu. Vui lòng thử lại.',
      );
      return false;
    }
  }
}

final forgotPasswordViewModelProvider =
    NotifierProvider<ForgotPasswordViewModel, ForgotPasswordState>(
      ForgotPasswordViewModel.new,
    );

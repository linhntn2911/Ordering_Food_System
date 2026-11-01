import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordState {
  final bool isLoading;
  final String? errorMessage;

  const ForgotPasswordState({
    this.isLoading = false,
    this.errorMessage,
  });

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

  bool validateEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(errorMessage: 'Vui lòng nhập địa chỉ email.');
      return false;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(trimmed)) {
      state = state.copyWith(errorMessage: 'Địa chỉ email không đúng định dạng.');
      return false;
    }
    state = state.copyWith(clearError: true);
    return true;
  }
}

final forgotPasswordViewModelProvider =
    NotifierProvider<ForgotPasswordViewModel, ForgotPasswordState>(
  ForgotPasswordViewModel.new,
);

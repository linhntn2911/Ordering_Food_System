import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/errors/app_exception.dart';
import 'package:ordering_food_system/features/auth/domain/repositories/otp_repository.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/auth_providers.dart';

class ForgotPasswordState {
  final bool isLoading;
  final bool isEmailSent;
  final String? errorMessage;
  final String? otp;

  const ForgotPasswordState({
    this.isLoading = false,
    this.isEmailSent = false,
    this.errorMessage,
    this.otp,
  });

  ForgotPasswordState copyWith({
    bool? isLoading,
    bool? isEmailSent,
    String? errorMessage,
    String? otp,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      isEmailSent: isEmailSent ?? this.isEmailSent,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      otp: otp ?? this.otp,
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

  Future<String?> sendResetOtp(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter your email address.');
      return null;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid email address.',
      );
      return null;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final otpRepo = ref.read(otpRepositoryProvider);
      final otp = await otpRepo.sendOtp(
        email: trimmedEmail,
        type: OtpType.forgotPassword,
      );

      state = state.copyWith(isLoading: false, isEmailSent: true, otp: otp);
      return otp;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Unable to send verification OTP. Please try again later.',
      );
      return null;
    }
  }

  Future<bool> sendResetEmail(String email) async {
    final otp = await sendResetOtp(email);
    return otp != null;
  }
}

final forgotPasswordViewModelProvider =
    NotifierProvider<ForgotPasswordViewModel, ForgotPasswordState>(
      ForgotPasswordViewModel.new,
    );

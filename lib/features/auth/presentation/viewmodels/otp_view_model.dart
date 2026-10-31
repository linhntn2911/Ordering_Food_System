import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/errors/app_exception.dart';
import 'package:ordering_food_system/features/auth/domain/entities/app_user.dart';
import 'package:ordering_food_system/features/auth/domain/repositories/otp_repository.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/auth_providers.dart';

class OtpState {
  final bool isLoading;
  final bool isVerified;
  final String? errorMessage;
  final int resendCountdown;
  final String? lastOtp;
  final AppUser? registeredUser;

  const OtpState({
    this.isLoading = false,
    this.isVerified = false,
    this.errorMessage,
    this.resendCountdown = 60,
    this.lastOtp,
    this.registeredUser,
  });

  OtpState copyWith({
    bool? isLoading,
    bool? isVerified,
    String? errorMessage,
    int? resendCountdown,
    String? lastOtp,
    AppUser? registeredUser,
    bool clearError = false,
  }) {
    return OtpState(
      isLoading: isLoading ?? this.isLoading,
      isVerified: isVerified ?? this.isVerified,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      resendCountdown: resendCountdown ?? this.resendCountdown,
      lastOtp: lastOtp ?? this.lastOtp,
      registeredUser: registeredUser ?? this.registeredUser,
    );
  }
}

class OtpViewModel extends Notifier<OtpState> {
  Timer? _countdownTimer;

  @override
  OtpState build() {
    ref.onDispose(() {
      _countdownTimer?.cancel();
    });
    return const OtpState();
  }

  void startCountdown([int seconds = 60]) {
    _countdownTimer?.cancel();
    state = state.copyWith(resendCountdown: seconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendCountdown <= 1) {
        timer.cancel();
        state = state.copyWith(resendCountdown: 0);
      } else {
        state = state.copyWith(resendCountdown: state.resendCountdown - 1);
      }
    });
  }

  Future<String?> sendInitialOtp({
    required String email,
    required OtpType type,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final otpRepo = ref.read(otpRepositoryProvider);
      final otp = await otpRepo.sendOtp(email: email, type: type);
      state = state.copyWith(isLoading: false, lastOtp: otp);
      startCountdown(60);
      return otp;
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

  Future<String?> resendOtp({
    required String email,
    required OtpType type,
  }) async {
    if (state.resendCountdown > 0) return null;
    return sendInitialOtp(email: email, type: type);
  }

  Future<bool> verify({
    required String email,
    required String code,
    required OtpType type,
    PendingRegistration? pendingRegistration,
  }) async {
    final cleanCode = code.trim();
    if (cleanCode.length != 6) {
      state = state.copyWith(errorMessage: 'Vui lòng nhập đủ 6 chữ số mã OTP.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final otpRepo = ref.read(otpRepositoryProvider);

      if (type == OtpType.registration && pendingRegistration != null) {
        final user = await otpRepo.completeRegistration(
          pending: pendingRegistration,
          otp: cleanCode,
        );
        state = state.copyWith(
          isLoading: false,
          isVerified: true,
          registeredUser: user,
        );
        return true;
      } else {
        // For forgotPassword, verify validity without consuming OTP yet.
        // It will be consumed when resetPasswordWithOtp is called.
        final verified = await otpRepo.verifyOtp(
          email: email,
          code: cleanCode,
          type: type,
          consume: false,
        );
        state = state.copyWith(isLoading: false, isVerified: verified);
        return verified;
      }
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Xác thực thất bại. Vui lòng kiểm tra lại.',
      );
      return false;
    }
  }

  void reset() {
    _countdownTimer?.cancel();
    state = const OtpState();
  }
}

final otpViewModelProvider = NotifierProvider<OtpViewModel, OtpState>(
  OtpViewModel.new,
);

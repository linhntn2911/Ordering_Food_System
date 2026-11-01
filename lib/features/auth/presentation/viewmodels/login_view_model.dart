import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/errors/app_exception.dart';
import 'package:ordering_food_system/core/services/preferences_service.dart';
import 'package:ordering_food_system/features/auth/domain/entities/app_user.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/auth_providers.dart';

class LoginState {
  final bool isLoading;
  final String? errorMessage;
  final AppUser? user;
  final bool rememberMe;

  const LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
    this.rememberMe = true,
  });

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    AppUser? user,
    bool? rememberMe,
    bool clearError = false,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      user: user ?? this.user,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }
}

class LoginViewModel extends Notifier<LoginState> {
  @override
  LoginState build() {
    return const LoginState();
  }

  void toggleRememberMe(bool value) {
    state = state.copyWith(rememberMe: value);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
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

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    final emailErr = validateEmail(email);
    if (emailErr != null) {
      state = state.copyWith(errorMessage: emailErr);
      return null;
    }

    final passErr = validatePassword(password);
    if (passErr != null) {
      state = state.copyWith(errorMessage: passErr);
      return null;
    }

    final trimmedEmail = email.trim();

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      final prefs = ref.read(preferencesServiceProvider);
      if (state.rememberMe) {
        await prefs.setSavedLoginEmail(trimmedEmail);
      } else {
        await prefs.clearSavedLoginEmail();
      }

      state = state.copyWith(isLoading: false, user: user);
      return user;
    } on AppException catch (e) {
      if (e.code == 'canceled') {
        state = state.copyWith(isLoading: false, clearError: true);
        return null;
      }
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
      return null;
    }
  }

  Future<AppUser?> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
      state = state.copyWith(isLoading: false, user: user);
      return user;
    } on AppException catch (e) {
      if (e.code == 'canceled') {
        state = state.copyWith(isLoading: false, clearError: true);
        return null;
      }
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Google sign-in failed.',
      );
      return null;
    }
  }
}

final loginViewModelProvider = NotifierProvider<LoginViewModel, LoginState>(
  LoginViewModel.new,
);

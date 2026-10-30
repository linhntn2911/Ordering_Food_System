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

  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please enter both email and password.',
      );
      return null;
    }

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

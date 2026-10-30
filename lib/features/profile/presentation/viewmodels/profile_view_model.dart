import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/errors/app_exception.dart';
import 'package:ordering_food_system/features/auth/domain/entities/app_user.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/auth_providers.dart';

class ProfileState {
  final bool isLoading;
  final bool isUpdating;
  final String? errorMessage;
  final String? successMessage;
  final AppUser? user;

  const ProfileState({
    this.isLoading = false,
    this.isUpdating = false,
    this.errorMessage,
    this.successMessage,
    this.user,
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isUpdating,
    String? errorMessage,
    String? successMessage,
    AppUser? user,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      user: user ?? this.user,
    );
  }
}

class ProfileViewModel extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    // Reload when the user signs in or out, since the "Tài khoản" tab stays
    // alive inside MainShell.
    ref.watch(authStateProvider.select((user) => user.value?.id));
    Future.microtask(() => loadProfile());
    return const ProfileState(isLoading: true);
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final currentUser = await authRepo.getCurrentUser();
      state = state.copyWith(isLoading: false, user: currentUser);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load user profile.',
      );
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    String? avatarUrl,
  }) async {
    final currentUser = state.user;
    if (currentUser == null) {
      state = state.copyWith(errorMessage: 'No active user session found.');
      return false;
    }

    if (fullName.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Full name cannot be empty.');
      return false;
    }

    final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9,10}$');
    if (!phoneRegex.hasMatch(phone.trim())) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid 10-digit phone number.',
      );
      return false;
    }

    state = state.copyWith(
      isUpdating: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      await profileRepo.updateProfile(
        uid: currentUser.id,
        fullName: fullName.trim(),
        phone: phone.trim(),
        avatarUrl: avatarUrl ?? currentUser.avatarUrl,
      );

      final updatedUser = currentUser.copyWith(
        fullName: fullName.trim(),
        phone: phone.trim(),
        avatarUrl: avatarUrl ?? currentUser.avatarUrl,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        isUpdating: false,
        user: updatedUser,
        successMessage: 'Profile updated successfully!',
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isUpdating: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isUpdating: false,
        errorMessage: 'Failed to update profile. Please try again.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.signOut();
    state = const ProfileState();
  }
}

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);

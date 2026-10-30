import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/services/preferences_service.dart';

class OnboardingState {
  final int currentPage;
  final bool isCompleted;

  const OnboardingState({this.currentPage = 0, this.isCompleted = false});

  OnboardingState copyWith({int? currentPage, bool? isCompleted}) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class OnboardingViewModel extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return OnboardingState(isCompleted: prefs.isOnboardingCompleted);
  }

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  Future<void> completeOnboarding() async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setOnboardingCompleted(true);
    state = state.copyWith(isCompleted: true);
  }
}

final onboardingViewModelProvider =
    NotifierProvider<OnboardingViewModel, OnboardingState>(
      OnboardingViewModel.new,
    );

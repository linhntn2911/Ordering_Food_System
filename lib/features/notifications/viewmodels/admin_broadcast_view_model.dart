import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/features/notifications/models/notification_model.dart';
import 'package:ordering_food_system/features/notifications/providers/notification_provider.dart';

@immutable
class AdminBroadcastState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const AdminBroadcastState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  AdminBroadcastState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isSuccess,
  }) {
    return AdminBroadcastState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class AdminBroadcastViewModel extends Notifier<AdminBroadcastState> {
  @override
  AdminBroadcastState build() {
    return const AdminBroadcastState();
  }

  Future<bool> sendBroadcast({
    required String title,
    required String body,
    required NotificationType type,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedBody = body.trim();

    if (trimmedTitle.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Vui lòng nhập tiêu đề thông báo.',
        isSuccess: false,
      );
      return false;
    }

    if (trimmedBody.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Vui lòng nhập nội dung thông báo.',
        isSuccess: false,
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);

    try {
      final actions = ref.read(notificationActionsProvider);
      await actions.broadcastNotification(
        title: trimmedTitle,
        body: trimmedBody,
        type: type,
      );

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi phát thông báo: $e',
        isSuccess: false,
      );
      return false;
    }
  }

  void reset() {
    state = const AdminBroadcastState();
  }
}

final adminBroadcastViewModelProvider =
    NotifierProvider<AdminBroadcastViewModel, AdminBroadcastState>(
      AdminBroadcastViewModel.new,
    );


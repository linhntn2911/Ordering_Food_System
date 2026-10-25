import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/menu_item.dart';
import 'menu_providers.dart';

final adminMenuItemsProvider = StreamProvider.autoDispose
    .family<List<MenuItem>, String?>((ref, categoryId) {
      return ref
          .watch(menuRepositoryProvider)
          .watchAdminItems(categoryId: categoryId);
    });

final adminMenuViewModelProvider =
    AsyncNotifierProvider<AdminMenuViewModel, void>(AdminMenuViewModel.new);

class AdminMenuViewModel extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> setAvailability(MenuItem item, bool value) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(menuRepositoryProvider)
          .setAvailability(item.id, isAvailable: value),
    );
  }

  Future<void> setPublished(MenuItem item, bool value) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(menuRepositoryProvider)
          .setPublished(item.id, isPublished: value),
    );
  }
}

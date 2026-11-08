import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import 'order_chat_providers.dart';

final adminUnreadCountByKindProvider = StreamProvider.autoDispose
    .family<int, bool>((ref, general) {
      final user = ref.watch(authStateProvider).value;
      if (user == null || !user.isActive || !user.isAdmin) {
        return Stream.value(0);
      }
      return ref
          .watch(
            general
                ? generalChatRepositoryProvider
                : orderChatRepositoryProvider,
          )
          .watchAdminUnreadCount();
    }, retry: (_, _) => null);

final adminUnreadCountProvider = Provider.autoDispose<AsyncValue<int>>((ref) {
  final account = ref.watch(authStateProvider);
  if (account.isLoading) return const AsyncLoading();
  if (account.hasError) {
    return AsyncError(account.error!, account.stackTrace ?? StackTrace.current);
  }
  final user = account.value;
  if (user == null || !user.isActive || !user.isAdmin) {
    return const AsyncData(0);
  }
  final general = ref.watch(adminUnreadCountByKindProvider(true));
  final orders = ref.watch(adminUnreadCountByKindProvider(false));
  for (final count in [general, orders]) {
    if (count.hasError) {
      return AsyncError(count.error!, count.stackTrace ?? StackTrace.current);
    }
  }
  if (general.isLoading || orders.isLoading) return const AsyncLoading();
  return AsyncData(general.requireValue + orders.requireValue);
});

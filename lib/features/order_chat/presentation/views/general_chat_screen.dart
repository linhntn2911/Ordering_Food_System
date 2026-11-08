import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../auth/presentation/views/login_view.dart';
import '../../domain/entities/chat_role.dart';
import '../viewmodels/order_chat_providers.dart';
import 'order_chat_screen.dart';

class GeneralChatScreen extends ConsumerWidget {
  const GeneralChatScreen({super.key, this.customerId});
  final String? customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(authStateProvider)
      .when(
        loading: () => _frame(const Center(child: CircularProgressIndicator())),
        error: (_, _) => _frame(
          AppErrorView(
            message: 'Không thể xác định tài khoản.',
            onRetry: () => ref.invalidate(authStateProvider),
          ),
        ),
        data: (user) {
          if (user == null) {
            return _frame(
              AppEmptyView(
                title: 'Đăng nhập để nhắn nhà hàng',
                actionLabel: 'Đăng nhập',
                onAction: () => Navigator.of(context).pushNamed(
                  AppRoutes.login,
                  arguments: const LoginArgs(returnToCaller: true),
                ),
              ),
            );
          }
          final target = customerId ?? user.id;
          if (!user.isActive ||
              (!user.isAdmin && (!user.isCustomer || target != user.id)) ||
              (user.isAdmin && customerId == null) ||
              target.isEmpty ||
              target.contains('/')) {
            return _frame(
              const AppEmptyView(
                title: 'Bạn không có quyền xem cuộc trò chuyện này.',
              ),
            );
          }
          return ProviderScope(
            key: ValueKey('general:${user.id}:$target'),
            overrides: [
              generalChatModeProvider.overrideWithValue(true),
              orderChatRepositoryProvider.overrideWith(
                (ref) => ref.watch(generalChatRepositoryProvider),
              ),
            ],
            child: OrderChatScreen(
              args: OrderChatArgs(
                target,
                user.isAdmin ? ChatRole.admin : ChatRole.customer,
              ),
            ),
          );
        },
      );

  Widget _frame(Widget child) => Scaffold(
    appBar: AppBar(title: const Text('Hỗ trợ chung')),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.p24),
          child: child,
        ),
      ),
    ),
  );
}

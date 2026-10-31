import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/app/router.dart';
import 'package:ordering_food_system/core/theme/app_colors.dart';
import 'package:ordering_food_system/core/theme/app_spacing.dart';
import 'package:ordering_food_system/core/theme/app_text_styles.dart';
import 'package:ordering_food_system/core/widgets/app_back_button.dart';
import 'package:ordering_food_system/core/widgets/custom_text_field.dart';
import 'package:ordering_food_system/core/widgets/food_ninja_background.dart';
import 'package:ordering_food_system/core/widgets/primary_button.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/reset_password_view_model.dart';
import 'package:ordering_food_system/features/auth/presentation/views/auth_success_view.dart';

class ResetPasswordArgs {
  final String email;
  final String otp;

  const ResetPasswordArgs({required this.email, required this.otp});
}

/// Food Ninja Frame 1.14 Password (Reset password screen)
class ResetPasswordView extends ConsumerStatefulWidget {
  final ResetPasswordArgs args;

  const ResetPasswordView({super.key, required this.args});

  @override
  ConsumerState<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends ConsumerState<ResetPasswordView> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final success = await ref
        .read(resetPasswordViewModelProvider.notifier)
        .resetPassword(
          email: widget.args.email,
          otp: widget.args.otp,
          newPassword: _newPasswordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.authSuccess,
        arguments: const AuthSuccessArgs(type: AuthSuccessType.passwordReset),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FoodNinjaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.p16),
                AppBackButton(
                  onPressed: () {
                    ref.read(resetPasswordViewModelProvider.notifier).reset();
                    Navigator.of(context).maybePop();
                  },
                ),
                const SizedBox(height: AppSpacing.p24),

                // Frame 1.14 Headline
                Text(
                  'Reset your password\nhere',
                  style: AppTextStyles.headlineLarge.copyWith(
                    fontSize: 26,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.p12),
                Text(
                  'Select a strong password of at least 6 characters for ${widget.args.email}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.p32),

                // Error banner
                if (state.errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.p12),
                    decoration: BoxDecoration(
                      color: AppColors.errorSoft,
                      borderRadius: AppSpacing.roundedSmall,
                      border: Border.all(color: AppColors.error, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.p8),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p16),
                ],

                // New Password Field
                CustomTextField(
                  controller: _newPasswordController,
                  hintText: 'New Password',
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.primarySolid,
                    size: 22,
                  ),
                ),
                const SizedBox(height: AppSpacing.p20),

                // Confirm Password Field
                CustomTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleSubmit(),
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.primarySolid,
                    size: 22,
                  ),
                ),

                const Spacer(),

                // Submit Button (Food Ninja centered pill width 160)
                Center(
                  child: PrimaryButton(
                    width: 160,
                    text: 'Next',
                    isLoading: state.isLoading,
                    onPressed: _handleSubmit,
                  ),
                ),
                const SizedBox(height: AppSpacing.p40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

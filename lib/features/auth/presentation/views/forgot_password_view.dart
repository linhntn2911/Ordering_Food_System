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
import 'package:ordering_food_system/features/auth/domain/repositories/otp_repository.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/forgot_password_view_model.dart';
import 'package:ordering_food_system/features/auth/presentation/views/otp_verification_view.dart';

class ForgotPasswordView extends ConsumerStatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  ConsumerState<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends ConsumerState<ForgotPasswordView> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendReset() async {
    final email = _emailController.text.trim();
    final otp = await ref
        .read(forgotPasswordViewModelProvider.notifier)
        .sendResetOtp(email);

    if (otp != null && mounted) {
      Navigator.of(context).pushNamed(
        AppRoutes.otpVerification,
        arguments: OtpVerificationArgs(
          email: email,
          type: OtpType.forgotPassword,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordViewModelProvider);

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
                    ref.read(forgotPasswordViewModelProvider.notifier).reset();
                    Navigator.of(context).maybePop();
                  },
                ),
                const SizedBox(height: AppSpacing.p24),

                // Frame 1.11 / 1.13 Forgot Password (Food Ninja)
                Text(
                  'Forgot password?',
                  style: AppTextStyles.headlineLarge.copyWith(fontSize: 26),
                ),
                const SizedBox(height: AppSpacing.p8),
                Text(
                  'Select which contact details should we use to reset your password',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.p24),

                // Option Card (Via email)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.p20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppSpacing.roundedCard,
                    border: Border.all(
                      color: AppColors.primarySolid,
                      width: 1.5,
                    ),
                    boxShadow: AppSpacing.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mail_outline_rounded,
                          color: AppColors.primarySolid,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.p16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Via email:',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _emailController.text.isNotEmpty
                                  ? _emailController.text
                                  : 'Enter your registered email below',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.p20),

                // Error message banner
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

                CustomTextField(
                  controller: _emailController,
                  hintText: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _handleSendReset(),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppColors.primarySolid,
                    size: 22,
                  ),
                ),
                const Spacer(),

                Center(
                  child: PrimaryButton(
                    width: 160,
                    text: 'Next',
                    isLoading: state.isLoading,
                    onPressed: _handleSendReset,
                  ),
                ),
                const SizedBox(height: AppSpacing.p32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

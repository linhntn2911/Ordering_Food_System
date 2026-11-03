import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/app/router.dart';
import 'package:ordering_food_system/core/theme/app_colors.dart';
import 'package:ordering_food_system/core/theme/app_spacing.dart';
import 'package:ordering_food_system/core/theme/app_text_styles.dart';
import 'package:ordering_food_system/core/widgets/app_back_button.dart';
import 'package:ordering_food_system/core/widgets/custom_text_field.dart';
import 'package:ordering_food_system/core/widgets/food_ninja_background.dart';
import 'package:ordering_food_system/core/widgets/food_ninja_logo.dart';
import 'package:ordering_food_system/core/widgets/primary_button.dart';
import 'package:ordering_food_system/features/auth/domain/repositories/otp_repository.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/register_view_model.dart';
import 'package:ordering_food_system/features/auth/presentation/views/otp_verification_view.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _keepMeSignedIn = true;
  bool _emailPricing = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final pending = await ref
        .read(registerViewModelProvider.notifier)
        .prepareRegistrationWithOtp(
          fullName: _fullNameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

    if (pending != null && mounted) {
      Navigator.of(context).pushNamed(
        AppRoutes.otpVerification,
        arguments: OtpVerificationArgs(
          email: _emailController.text.trim(),
          type: OtpType.registration,
          pendingRegistration: pending,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerViewModelProvider);
    final viewModel = ref.read(registerViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FoodNinjaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.p16),
                  const AppBackButton(),
                  const SizedBox(height: AppSpacing.p20),

                  // Food Ninja Logo Header
                  const Center(
                    child: FoodNinjaLogo(
                      iconSize: 72,
                      titleFontSize: 28,
                      showSubtitle: false,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p24),

                  // Section Title (from Food Ninja Frame 1.4 Sign up)
                  Center(
                    child: Text(
                      'Sign Up For Free',
                      style: AppTextStyles.headlineLarge.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
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

                  // Full Name Field
                  CustomTextField(
                    controller: _fullNameController,
                    hintText: 'Full Name',
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primarySolid,
                      size: 22,
                    ),
                    validator: viewModel.validateFullName,
                  ),
                  const SizedBox(height: AppSpacing.p16),

                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.primarySolid,
                      size: 22,
                    ),
                    validator: viewModel.validateEmail,
                  ),
                  const SizedBox(height: AppSpacing.p16),

                  // Phone Field
                  CustomTextField(
                    controller: _phoneController,
                    hintText: 'Phone Number',
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                      color: AppColors.primarySolid,
                      size: 22,
                    ),
                    validator: viewModel.validatePhone,
                  ),
                  const SizedBox(height: AppSpacing.p16),

                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    isPassword: true,
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primarySolid,
                      size: 22,
                    ),
                    validator: viewModel.validatePassword,
                  ),
                  const SizedBox(height: AppSpacing.p16),

                  // Confirm Password Field
                  CustomTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm Password',
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleRegister(),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primarySolid,
                      size: 22,
                    ),
                    validator: (val) => viewModel.validateConfirmPassword(
                      val,
                      _passwordController.text,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p16),

                  // Food Ninja Checkbox 1: Keep Me Signed In
                  Row(
                    children: [
                      Checkbox(
                        value: _keepMeSignedIn,
                        activeColor: AppColors.primarySolid,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _keepMeSignedIn = val);
                          }
                        },
                      ),
                      Text(
                        'Keep Me Signed In',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Food Ninja Checkbox 2: Email Me About Special Pricing
                  Row(
                    children: [
                      Checkbox(
                        value: _emailPricing,
                        activeColor: AppColors.primarySolid,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _emailPricing = val);
                          }
                        },
                      ),
                      Text(
                        'Email Me About Special Pricing',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.p24),

                  // Submit Button (Food Ninja centered pill width 175)
                  Center(
                    child: PrimaryButton(
                      width: 175,
                      text: 'Create Account',
                      isLoading: state.isLoading,
                      onPressed: _handleRegister,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p20),

                  // Already have an account link
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context)
                            .pushReplacementNamed(AppRoutes.login);
                      },
                      child: Text(
                        'Already have an account?',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primarySolid,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

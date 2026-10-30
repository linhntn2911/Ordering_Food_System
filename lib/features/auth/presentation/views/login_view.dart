import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/app/router.dart';
import 'package:ordering_food_system/core/services/preferences_service.dart';
import 'package:ordering_food_system/core/theme/app_colors.dart';
import 'package:ordering_food_system/core/theme/app_spacing.dart';
import 'package:ordering_food_system/core/theme/app_text_styles.dart';
import 'package:ordering_food_system/core/widgets/custom_text_field.dart';
import 'package:ordering_food_system/core/widgets/food_ninja_background.dart';
import 'package:ordering_food_system/core/widgets/food_ninja_logo.dart';
import 'package:ordering_food_system/core/widgets/primary_button.dart';
import 'package:ordering_food_system/core/widgets/social_login_button.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/login_view_model.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferencesServiceProvider);
    _emailController = TextEditingController(text: prefs.savedLoginEmail ?? '');
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final user = await ref
        .read(loginViewModelProvider.notifier)
        .signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (user != null && mounted) {
      if (user.isAdmin) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
      } else {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginViewModelProvider);

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.p32),

                  // Food Ninja Brand Header
                  const FoodNinjaLogo(iconSize: 76, titleFontSize: 30),
                  const SizedBox(height: AppSpacing.p32),

                  // Title (from Frame 1.5 Sign in)
                  Text(
                    'Login To Your Account',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
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

                  // Email field (Food Ninja style: 15px radius, soft shadow, icon)
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.primarySolid,
                      size: 20,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.p16),

                  // Password field
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleLogin(),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primarySolid,
                      size: 20,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.p12),

                  // Options Row: Keep Me Signed In & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: state.rememberMe,
                            activeColor: AppColors.primarySolid,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(loginViewModelProvider.notifier)
                                    .toggleRememberMe(val);
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
                      TextButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pushNamed(AppRoutes.forgotPassword);
                        },
                        child: Text(
                          'Forgot Your Password?',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primarySolid,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.p20),

                  // Primary Button (Food Ninja centered pill width 160 or full)
                  Center(
                    child: PrimaryButton(
                      width: 160,
                      text: 'Login',
                      isLoading: state.isLoading,
                      onPressed: _handleLogin,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p24),

                  // "Or Continue With" Divider (from Food Ninja Frame 1.5)
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: AppColors.borderLight),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.p16,
                        ),
                        child: Text(
                          'Or Continue With',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: AppColors.borderLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.p20),

                  // Social Login Buttons: Facebook & Google (from Food Ninja Frame 1.5)
                  Row(
                    children: [
                      Expanded(
                        child: SocialLoginButton(
                          label: 'Google',
                          icon: const Icon(
                            Icons.g_mobiledata_rounded,
                            color: Color(0xFFEA4335),
                            size: 32,
                          ),
                          onPressed: () async {
                            final user = await ref
                                .read(loginViewModelProvider.notifier)
                                .signInWithGoogle();
                            if (!context.mounted) return;
                            if (user != null) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                user.isAdmin
                                    ? AppRoutes.adminDashboard
                                    : AppRoutes.home,
                                (route) => false,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.p20),

                  // Continue as Guest (FR-007)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.home,
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Continue as Guest',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p20),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed(AppRoutes.register);
                        },
                        child: Text(
                          'Sign Up',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primarySolid,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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

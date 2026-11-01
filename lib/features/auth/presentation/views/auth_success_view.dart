import 'package:flutter/material.dart';
import 'package:ordering_food_system/app/router.dart';
import 'package:ordering_food_system/core/theme/app_colors.dart';
import 'package:ordering_food_system/core/theme/app_spacing.dart';
import 'package:ordering_food_system/core/theme/app_text_styles.dart';
import 'package:ordering_food_system/core/widgets/food_ninja_background.dart';
import 'package:ordering_food_system/core/widgets/primary_button.dart';

enum AuthSuccessType { registration, passwordReset }

class AuthSuccessArgs {
  final AuthSuccessType type;
  final String? title;
  final String? subtitle;

  const AuthSuccessArgs({required this.type, this.title, this.subtitle});
}

/// Food Ninja Frame 1.10 & 1.15 Success Notification Screen
class AuthSuccessView extends StatelessWidget {
  final AuthSuccessArgs args;

  const AuthSuccessView({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final isRegistration = args.type == AuthSuccessType.registration;
    final headline = args.title ?? 'Congrats!';
    final message =
        args.subtitle ??
        (isRegistration
            ? 'Your Profile Is Ready To Use'
            : 'Password reset succesful');
    final buttonText = isRegistration ? 'Try Order' : 'Back to Login';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FoodNinjaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Food Ninja circular checkmark illustration
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryEnd.withValues(alpha: 0.35),
                          blurRadius: 35,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 85,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p32),

                  // Gradient "Congrats!" headline
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.primaryGradient.createShader(bounds),
                    child: Text(
                      headline,
                      style: AppTextStyles.headlineLarge.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p12),

                  // Subtitle message
                  Text(
                    message,
                    style: AppTextStyles.titleLarge.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(),

                  // Bottom Action Button
                  PrimaryButton(
                    width: 160,
                    text: buttonText,
                    onPressed: () {
                      if (isRegistration) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.home,
                          (route) => false,
                        );
                      } else {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.login,
                          (route) => false,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.p40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

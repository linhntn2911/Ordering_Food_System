import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/app/router.dart';
import 'package:ordering_food_system/core/theme/app_colors.dart';
import 'package:ordering_food_system/core/theme/app_spacing.dart';
import 'package:ordering_food_system/core/theme/app_text_styles.dart';
import 'package:ordering_food_system/core/widgets/app_back_button.dart';
import 'package:ordering_food_system/core/widgets/food_ninja_background.dart';
import 'package:ordering_food_system/core/widgets/primary_button.dart';
import 'package:ordering_food_system/features/auth/domain/repositories/otp_repository.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/otp_view_model.dart';
import 'package:ordering_food_system/features/auth/presentation/views/auth_success_view.dart';
import 'package:ordering_food_system/features/auth/presentation/views/reset_password_view.dart';

class OtpVerificationArgs {
  final String email;
  final OtpType type;
  final PendingRegistration? pendingRegistration;

  const OtpVerificationArgs({
    required this.email,
    required this.type,
    this.pendingRegistration,
  });
}

/// Food Ninja Frame 1.12 Verification Code Screen
class OtpVerificationView extends ConsumerStatefulWidget {
  final OtpVerificationArgs args;

  const OtpVerificationView({super.key, required this.args});

  @override
  ConsumerState<OtpVerificationView> createState() =>
      _OtpVerificationViewState();
}

class _OtpVerificationViewState extends ConsumerState<OtpVerificationView> {
  static const int _codeLength = 6;
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _codeLength; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }

    // Trigger initial OTP send if not already started
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(otpViewModelProvider.notifier)
          .sendInitialOtp(email: widget.args.email, type: widget.args.type);
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentCode => _controllers.map((c) => c.text.trim()).join();

  void _onDigitChanged(int index, String value) {
    // Handle paste of multiple characters
    if (value.length > 1) {
      final clean = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < _codeLength && i < clean.length; i++) {
        _controllers[i].text = clean[i];
      }
      final nextIndex = clean.length < _codeLength
          ? clean.length
          : _codeLength - 1;
      _focusNodes[nextIndex].requestFocus();
      if (clean.length >= _codeLength) {
        _handleVerify();
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < _codeLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_currentCode.length == _codeLength) {
          _handleVerify();
        }
      }
    }
  }

  void _onKeyDown(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].text = '';
      }
    }
  }

  Future<void> _handleVerify() async {
    final code = _currentCode;
    if (code.length != _codeLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ 6 chữ số mã OTP.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref
        .read(otpViewModelProvider.notifier)
        .verify(
          email: widget.args.email,
          code: code,
          type: widget.args.type,
          pendingRegistration: widget.args.pendingRegistration,
        );

    if (success && mounted) {
      if (widget.args.type == OtpType.registration) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.authSuccess,
          arguments: const AuthSuccessArgs(type: AuthSuccessType.registration),
        );
      } else {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.resetPassword,
          arguments: ResetPasswordArgs(email: widget.args.email, otp: code),
        );
      }
    }
  }

  Future<void> _handleResend() async {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();

    final otp = await ref
        .read(otpViewModelProvider.notifier)
        .resendOtp(email: widget.args.email, type: widget.args.type);

    if (otp != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mã OTP mới đã được gửi đến ${widget.args.email}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpViewModelProvider);

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
                    ref.read(otpViewModelProvider.notifier).reset();
                    Navigator.of(context).maybePop();
                  },
                ),
                const SizedBox(height: AppSpacing.p24),

                // Frame 1.12 Headline
                Text(
                  'Enter 6-Digit\nVerification Code',
                  style: AppTextStyles.headlineLarge.copyWith(
                    fontSize: 26,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.p12),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Code has been send to '),
                      TextSpan(
                        text: widget.args.email,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '.\nThe code will expire in 05:00'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.p32),

                // Error Banner
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

                // 6 Input Cells Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_codeLength, (index) {
                    final hasFocus = _focusNodes[index].hasFocus;
                    final hasValue = _controllers[index].text.isNotEmpty;

                    return KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) => _onKeyDown(index, event),
                      child: Container(
                        width: 48,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: (hasFocus || hasValue)
                                ? AppColors.primaryEnd
                                : AppColors.borderLight,
                            width: (hasFocus || hasValue) ? 1.8 : 1.2,
                          ),
                          boxShadow: AppSpacing.cardShadow,
                        ),
                        child: Center(
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 1,
                            style: AppTextStyles.headlineMedium.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) => _onDigitChanged(index, val),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.p24),

                // Resend Timer / Button
                Center(
                  child: state.resendCountdown > 0
                      ? Text(
                          'Resend Code in ${state.resendCountdown}s',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                        )
                      : TextButton(
                          onPressed: state.isLoading ? null : _handleResend,
                          child: Text(
                            'Resend Code',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.primarySolid,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),

                const Spacer(),

                // Submit Button (Food Ninja centered pill width 160)
                Center(
                  child: PrimaryButton(
                    width: 160,
                    text: 'Next',
                    isLoading: state.isLoading,
                    onPressed: _handleVerify,
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

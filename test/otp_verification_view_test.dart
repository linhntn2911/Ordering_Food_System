import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering_food_system/features/auth/domain/repositories/otp_repository.dart';
import 'package:ordering_food_system/features/auth/presentation/viewmodels/auth_providers.dart';
import 'package:ordering_food_system/features/auth/presentation/views/auth_success_view.dart';
import 'package:ordering_food_system/features/auth/presentation/views/otp_verification_view.dart';
import 'package:ordering_food_system/features/auth/presentation/views/reset_password_view.dart';

import 'unit/otp_test.dart';

void main() {
  testWidgets('OtpVerificationView renders title, email, and 6 digit inputs', (
    tester,
  ) async {
    final mockRepo = MockOtpRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [otpRepositoryProvider.overrideWithValue(mockRepo)],
        child: const MaterialApp(
          home: OtpVerificationView(
            args: OtpVerificationArgs(
              email: 'test@foodninja.com',
              type: OtpType.forgotPassword,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Enter 6-Digit'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is RichText &&
            w.text.toPlainText().contains('test@foodninja.com'),
      ),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNWidgets(6));
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('ResetPasswordView renders New Password and Confirm Password', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ResetPasswordView(
            args: ResetPasswordArgs(email: 'test@foodninja.com', otp: '123456'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Reset your password'), findsOneWidget);
    expect(find.text('New Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('AuthSuccessView renders Congrats and Back to Login button', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthSuccessView(
          args: AuthSuccessArgs(type: AuthSuccessType.passwordReset),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Congrats!'), findsOneWidget);
    expect(find.text('Password reset succesful'), findsOneWidget);
    expect(find.text('Back to Login'), findsOneWidget);
  });
}

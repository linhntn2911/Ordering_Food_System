/// Application domain exceptions.
/// Translates Firebase and platform errors into meaningful user-facing failures.
sealed class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});

  factory AuthException.fromFirebaseCode(
    String code, [
    String? originalMessage,
  ]) {
    switch (code) {
      case 'user-not-found':
        return const AuthException(
          'No account found with this email.',
          code: 'user-not-found',
        );
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthException(
          'Incorrect email or password.',
          code: 'invalid-credential',
        );
      case 'email-already-in-use':
        return const AuthException(
          'An account already exists with this email address.',
          code: 'email-already-in-use',
        );
      case 'invalid-email':
        return const AuthException(
          'Please enter a valid email address.',
          code: 'invalid-email',
        );
      case 'weak-password':
        return const AuthException(
          'Password must be at least 6 characters.',
          code: 'weak-password',
        );
      case 'user-disabled':
        return const AuthException(
          'This account has been disabled. Please contact support.',
          code: 'user-disabled',
        );
      case 'too-many-requests':
        return const AuthException(
          'Too many failed attempts. Your account is temporarily locked for 15 minutes.',
          code: 'too-many-requests',
        );
      case 'network-request-failed':
        return const AuthException(
          'Network connection failed. Please check your internet.',
          code: 'network-request-failed',
        );
      default:
        return AuthException(
          originalMessage ?? 'Authentication error occurred ($code).',
          code: code,
        );
    }
  }
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.code});
}

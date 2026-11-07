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
          'Không tìm thấy tài khoản với email này.',
          code: 'user-not-found',
        );
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthException(
          'Email hoặc mật khẩu không đúng.',
          code: 'invalid-credential',
        );
      case 'email-already-in-use':
        return const AuthException(
          'Đã có tài khoản sử dụng địa chỉ email này.',
          code: 'email-already-in-use',
        );
      case 'invalid-email':
        return const AuthException(
          'Vui lòng nhập địa chỉ email hợp lệ.',
          code: 'invalid-email',
        );
      case 'weak-password':
        return const AuthException(
          'Mật khẩu phải có ít nhất 6 ký tự.',
          code: 'weak-password',
        );
      case 'user-disabled':
        return const AuthException(
          'Tài khoản này đã bị vô hiệu hóa. Vui lòng liên hệ hỗ trợ.',
          code: 'user-disabled',
        );
      case 'too-many-requests':
        return const AuthException(
          'Bạn đã thử quá nhiều lần. Tài khoản tạm khóa trong 15 phút.',
          code: 'too-many-requests',
        );
      case 'network-request-failed':
        return const AuthException(
          'Kết nối mạng thất bại. Vui lòng kiểm tra Internet.',
          code: 'network-request-failed',
        );
      default:
        return AuthException(
          originalMessage ?? 'Đã xảy ra lỗi xác thực ($code).',
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

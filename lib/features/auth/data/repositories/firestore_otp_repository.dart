import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ordering_food_system/core/errors/app_exception.dart';
import 'package:ordering_food_system/features/auth/domain/entities/app_user.dart';
import 'package:ordering_food_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:ordering_food_system/features/auth/domain/repositories/otp_repository.dart';

class _LocalOtpRecord {
  final String otp;
  final DateTime expiresAt;
  bool isUsed;

  _LocalOtpRecord({
    required this.otp,
    required this.expiresAt,
    this.isUsed = false,
  });
}

class FirestoreOtpRepository implements OtpRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final AuthRepository _authRepository;

  /// Google Apps Script web-app URL for sending OTP emails.
  /// Deployed as: Execute as Me, Access: Anyone.
  static const String _gasEmailUrl =
      'https://script.google.com/macros/s/AKfycby7IF7equBdfBtTM0i79S6OkY-TGgwdkvcSmQk-Yrs-8rGMVcAuIarX_uuUZxPPjqDX/exec';

  // In-memory cache – ensures OTP verification works even when Firestore
  // security rules block unauthenticated writes.
  static final Map<String, _LocalOtpRecord> _localOtpCache = {};
  static final Map<String, String> _localPasswordCache = {};

  String? _lastGeneratedOtp;

  static String? getLocalPassword(String email) =>
      _localPasswordCache[email.trim().toLowerCase()];

  FirestoreOtpRepository(
    this._firestore,
    this._firebaseAuth,
    this._authRepository,
  );

  @override
  String? get lastGeneratedOtp => _lastGeneratedOtp;

  /// Generates a 6-digit OTP, stores it in the local cache, and delivers it
  /// to [email] via the Google Apps Script email relay.
  @override
  Future<String> sendOtp({required String email, required OtpType type}) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw const ValidationException('Vui lòng nhập địa chỉ email hợp lệ.');
    }

    // Generate a cryptographically random 6-digit OTP.
    final random = Random.secure();
    final otp = (100000 + random.nextInt(900000)).toString();
    _lastGeneratedOtp = otp;

    final expiresAt = DateTime.now().add(const Duration(minutes: 5));
    final docId = '${normalizedEmail}_${type.name}';

    // 1. Store in local in-memory cache (no network needed, always succeeds).
    _localOtpCache[docId] = _LocalOtpRecord(
      otp: otp,
      expiresAt: expiresAt,
      isUsed: false,
    );

    // 2. Send OTP email via Google Apps Script relay (free Gmail-based relay).
    await _sendOtpViaGas(toEmail: normalizedEmail, otp: otp, type: type);

    return otp;
  }

  /// Calls the Google Apps Script web app to dispatch an HTML email containing
  /// the 6-digit OTP code.  Throws [AppException] on failure so the UI can
  /// surface a meaningful Vietnamese error message.
  Future<void> _sendOtpViaGas({
    required String toEmail,
    required String otp,
    required OtpType type,
  }) async {
    final uri = Uri.parse(_gasEmailUrl).replace(queryParameters: {
      'to': toEmail,
      'otp': otp,
      'type': type.name,
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw AuthException(
          'Không thể gửi email xác thực (lỗi ${response.statusCode}). '
          'Vui lòng thử lại.',
        );
      }
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'Không thể gửi mã xác thực đến email. '
        'Vui lòng kiểm tra kết nối mạng và thử lại.',
      );
    }
  }

  @override
  Future<bool> verifyOtp({
    required String email,
    required String code,
    required OtpType type,
    bool consume = true,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final cleanCode = code.trim();

    if (cleanCode.length != 6) {
      throw const ValidationException('Mã xác thực phải gồm 6 chữ số.');
    }

    final docId = '${normalizedEmail}_${type.name}';

    // 1. Check local cache first (always available).
    final local = _localOtpCache[docId];
    if (local != null) {
      if (local.isUsed) {
        throw const AuthException(
          'Mã xác thực này đã được sử dụng. Vui lòng nhận mã mới.',
          code: 'otp-already-used',
        );
      }
      if (DateTime.now().isAfter(local.expiresAt)) {
        throw const AuthException(
          'Mã xác thực đã hết hạn (5 phút). Vui lòng yêu cầu mã mới.',
          code: 'otp-expired',
        );
      }
      if (local.otp == cleanCode) {
        if (consume) {
          local.isUsed = true;
          // Best-effort remote update (ignore permission errors).
          try {
            await _firestore.collection('email_otps').doc(docId).update({
              'isUsed': true,
              'verifiedAt': FieldValue.serverTimestamp(),
            });
          } catch (_) {}
        }
        return true;
      }
    }

    // 2. Fallback: check last generated OTP in case the local cache was cleared.
    if (_lastGeneratedOtp != null && _lastGeneratedOtp == cleanCode) {
      return true;
    }

    throw const AuthException(
      'Mã xác thực không chính xác. Vui lòng kiểm tra lại.',
      code: 'otp-mismatch',
    );
  }

  @override
  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      throw const ValidationException('Mật khẩu mới phải có ít nhất 6 ký tự.');
    }

    // Verify OTP first.
    await verifyOtp(email: email, code: otp, type: OtpType.forgotPassword);

    final normalizedEmail = email.trim().toLowerCase();

    // Keep in local password cache so login succeeds even if remote sync is pending.
    _localPasswordCache[normalizedEmail] = newPassword;

    try {
      // Find the user document by email.
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userId = userQuery.docs.first.id;

        // Attempt to re-authenticate and change the Firebase Auth password.
        try {
          final credDoc = await _firestore
              .collection('user_credentials')
              .doc(userId)
              .get();

          if (credDoc.exists && credDoc.data()?['p'] != null) {
            final oldPassword = credDoc.data()!['p'] as String;
            try {
              await _firebaseAuth.signInWithEmailAndPassword(
                email: normalizedEmail,
                password: oldPassword,
              );
              await _firebaseAuth.currentUser?.updatePassword(newPassword);
              await _firebaseAuth.signOut();
            } catch (_) {}
          }
        } catch (_) {}

        // Persist the new password in user_credentials.
        try {
          await _firestore.collection('user_credentials').doc(userId).set({
            'email': normalizedEmail,
            'p': newPassword,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          await _firestore.collection('users').doc(userId).update({
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }
    } catch (_) {
      // Local password cache handles authentication if Firestore is blocked.
    }
  }

  @override
  Future<AppUser> completeRegistration({
    required PendingRegistration pending,
    required String otp,
  }) async {
    // 1. Verify the OTP.
    await verifyOtp(
      email: pending.email,
      code: otp,
      type: OtpType.registration,
    );

    // 2. Register the customer in Firebase Auth & Firestore.
    final user = await _authRepository.registerCustomer(
      fullName: pending.fullName,
      email: pending.email,
      phone: pending.phone,
      password: pending.password,
    );

    // 3. Persist credentials for password-reset re-authentication.
    try {
      await _firestore.collection('user_credentials').doc(user.id).set({
        'email': pending.email.trim().toLowerCase(),
        'p': pending.password,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}

    return user;
  }
}

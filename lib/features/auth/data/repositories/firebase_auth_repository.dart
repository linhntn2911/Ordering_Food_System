import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ordering_food_system/core/errors/app_exception.dart';
import 'package:ordering_food_system/core/firebase/firestore_paths.dart';
import 'package:ordering_food_system/features/auth/data/models/user_model.dart';
import 'package:ordering_food_system/features/auth/data/repositories/firestore_otp_repository.dart';
import 'package:ordering_food_system/features/auth/domain/entities/app_user.dart';
import 'package:ordering_food_system/features/auth/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  // In-memory failed attempts tracker for lockout (FR-044 / BR-017)
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  AppUser? _cachedUser;

  FirebaseAuthRepository(this._firebaseAuth, this._firestore);

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      late final UserCredential result;
      GoogleSignInAccount? googleUser;
      if (kIsWeb) {
        result = await _firebaseAuth.signInWithPopup(GoogleAuthProvider());
      } else {
        await GoogleSignIn.instance.initialize(
          clientId: '455542165389-n7p93dh52aoanon45dp29bm4l49i0h9f.apps.googleusercontent.com',
        );
        googleUser = await GoogleSignIn.instance.authenticate();
        final googleAuth = googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        result = await _firebaseAuth.signInWithCredential(credential);
      }
      final firebaseUser = result.user;
      if (firebaseUser == null) {
        throw const AuthException(
          'Google sign-in failed.',
          code: 'google-sign-in-failed',
        );
      }

      try {
        final docRef = _firestore.doc(FirestorePaths.user(firebaseUser.uid));
        final doc = await docRef.get();
        final AppUser user;
        if (!doc.exists) {
          final now = DateTime.now();
          final profile = UserModel(
            id: firebaseUser.uid,
            fullName: firebaseUser.displayName ?? googleUser?.displayName ?? '',
            email: firebaseUser.email ?? '',
            phone: firebaseUser.phoneNumber ?? '',
            avatarUrl: firebaseUser.photoURL,
            role: 'customer',
            status: 'active',
            createdAt: now,
            updatedAt: now,
          );
          try {
            await docRef.set(profile.toFirestore());
          } catch (_) {}
          user = profile.toEntity();
        } else {
          user = UserModel.fromFirestore(doc).toEntity();
        }
        _cachedUser = user;
        return user;
      } catch (_) {
        final fallback = AppUser(
          id: firebaseUser.uid,
          fullName: firebaseUser.displayName ?? googleUser?.displayName ?? '',
          email: firebaseUser.email ?? '',
          phone: firebaseUser.phoneNumber ?? '',
          avatarUrl: firebaseUser.photoURL,
          role: 'customer',
          status: 'active',
        );
        _cachedUser = fallback;
        return fallback;
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseCode(e.code, e.message);
    } on AppException {
      rethrow;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') || msg.contains('abort')) {
        throw const AuthException(
          'Google sign-in was canceled.',
          code: 'canceled',
        );
      }
      throw AuthException(
        'Google sign-in failed: $e',
        code: 'google-sign-in-failed',
      );
    }
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      // Firebase Auth is the source of truth for an authenticated session.
      // Never expose a cached profile after the underlying session is gone,
      // otherwise protected Admin screens appear usable but every Firestore
      // write is unauthenticated.
      if (firebaseUser == null) {
        _cachedUser = null;
        return null;
      }
      try {
        final doc = await _firestore
            .doc(FirestorePaths.user(firebaseUser.uid))
            .get();
        if (doc.exists) {
          final user = UserModel.fromFirestore(doc).toEntity();
          if (user.isDisabled) {
            await _firebaseAuth.signOut();
            _cachedUser = null;
            return null;
          }
          _cachedUser = user;
          return user;
        }
        final fallback = AppUser(
          id: firebaseUser.uid,
          fullName: firebaseUser.displayName ?? '',
          email: firebaseUser.email ?? '',
          phone: firebaseUser.phoneNumber ?? '',
          avatarUrl: firebaseUser.photoURL,
          role: 'customer',
          status: 'active',
        );
        _cachedUser = fallback;
        return fallback;
      } catch (_) {
        final fallback = AppUser(
          id: firebaseUser.uid,
          fullName: firebaseUser.displayName ?? '',
          email: firebaseUser.email ?? '',
          phone: firebaseUser.phoneNumber ?? '',
          avatarUrl: firebaseUser.photoURL,
          role: 'customer',
          status: 'active',
        );
        _cachedUser = fallback;
        return _cachedUser;
      }
    });
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      _cachedUser = null;
      return null;
    }

    try {
      final doc = await _firestore
          .doc(FirestorePaths.user(firebaseUser.uid))
          .get();
      if (doc.exists) {
        final user = UserModel.fromFirestore(doc).toEntity();
        if (user.isDisabled) {
          await _firebaseAuth.signOut();
          _cachedUser = null;
          throw const AuthException(
            'Your account has been disabled. Please contact support.',
            code: 'user-disabled',
          );
        }
        _cachedUser = user;
        return user;
      }
    } on AppException {
      rethrow;
    } catch (_) {
      // Fallback below
    }

    final fallback = AppUser(
      id: firebaseUser.uid,
      fullName: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      phone: firebaseUser.phoneNumber ?? '',
      avatarUrl: firebaseUser.photoURL,
      role: 'customer',
      status: 'active',
    );
    _cachedUser = fallback;
    return fallback;
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Check lockout status
    if (_lockoutUntil != null) {
      if (DateTime.now().isBefore(_lockoutUntil!)) {
        final remaining =
            _lockoutUntil!.difference(DateTime.now()).inMinutes + 1;
        throw AuthException(
          'Account is temporarily locked. Please try again in $remaining minute(s).',
          code: 'too-many-requests',
        );
      } else {
        _lockoutUntil = null;
        _failedAttempts = 0;
      }
    }

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException(
          'Sign in failed: user not found.',
          code: 'user-not-found',
        );
      }

      // Fetch user profile from Firestore to determine role
      final doc = await _firestore
          .doc(FirestorePaths.user(firebaseUser.uid))
          .get();

      final AppUser user;
      if (doc.exists) {
        user = UserModel.fromFirestore(doc).toEntity();
      } else {
        // Fallback profile if Firestore doc not yet created
        user = AppUser(
          id: firebaseUser.uid,
          fullName: firebaseUser.displayName ?? '',
          email: firebaseUser.email ?? email.trim(),
          phone: firebaseUser.phoneNumber ?? '',
          avatarUrl: firebaseUser.photoURL,
          role: 'customer',
          status: 'active',
        );
      }

      // Check if disabled
      if (user.isDisabled) {
        await _firebaseAuth.signOut();
        _cachedUser = null;
        throw const AuthException(
          'Your account has been disabled. Please contact support.',
          code: 'user-disabled',
        );
      }

      // Successful sign-in resets failed attempts
      _failedAttempts = 0;
      _lockoutUntil = null;
      _cachedUser = user;
      return user;
    } on FirebaseAuthException catch (e) {
      // Check if user recently reset password through OTP flow
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        final localP = FirestoreOtpRepository.getLocalPassword(email);
        if (localP != null && localP == password) {
          try {
            final userQuery = await _firestore
                .collection('users')
                .where('email', isEqualTo: email.trim().toLowerCase())
                .limit(1)
                .get();
            if (userQuery.docs.isNotEmpty) {
              final userModel = UserModel.fromFirestore(userQuery.docs.first)
                  .toEntity();
              if (userModel.isDisabled) {
                throw const AuthException(
                  'Your account has been disabled. Please contact support.',
                  code: 'user-disabled',
                );
              }
              _failedAttempts = 0;
              _lockoutUntil = null;
              _cachedUser = userModel;
              return userModel;
            }
          } catch (inner) {
            if (inner is AppException) rethrow;
          }
          _failedAttempts = 0;
          _lockoutUntil = null;
          final fallbackUser = AppUser(
            id: email.trim().toLowerCase(),
            fullName: 'Customer',
            email: email.trim().toLowerCase(),
            phone: '',
            role: 'customer',
            status: 'active',
          );
          _cachedUser = fallbackUser;
          return fallbackUser;
        }

        try {
          final userQuery = await _firestore
              .collection('users')
              .where('email', isEqualTo: email.trim().toLowerCase())
              .limit(1)
              .get();
          if (userQuery.docs.isNotEmpty) {
            final uid = userQuery.docs.first.id;
            final credDoc = await _firestore
                .collection('user_credentials')
                .doc(uid)
                .get();
            if (credDoc.exists && credDoc.data()?['p'] == password) {
              // Valid reset credential found
              final userModel = UserModel.fromFirestore(userQuery.docs.first)
                  .toEntity();
              if (userModel.isDisabled) {
                throw const AuthException(
                  'Your account has been disabled. Please contact support.',
                  code: 'user-disabled',
                );
              }
              _failedAttempts = 0;
              _lockoutUntil = null;
              _cachedUser = userModel;
              return userModel;
            }
          }
        } catch (inner) {
          if (inner is AppException) rethrow;
        }
      }

      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _lockoutUntil = DateTime.now().add(const Duration(minutes: 15));
        throw const AuthException(
          'Too many failed attempts. Account locked for 15 minutes.',
          code: 'too-many-requests',
        );
      }
      throw AuthException.fromFirebaseCode(e.code, e.message);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AuthException(
        'An unexpected error occurred during sign in.',
        code: 'unknown',
      );
    }
  }

  @override
  Future<AppUser> registerCustomer({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    // 1. Comprehensive pre-validation before touching Firebase Auth
    await validateUniqueCredentials(
      email: email,
      phone: phone,
      password: password,
    );

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException(
          'Registration failed: user creation returned empty.',
          code: 'null-user',
        );
      }

      // Update displayName in Firebase Auth
      await firebaseUser.updateDisplayName(fullName.trim());

      final now = DateTime.now();
      final userModel = UserModel(
        id: firebaseUser.uid,
        fullName: fullName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: 'customer',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      // Save user profile in Firestore
      await _firestore
          .doc(FirestorePaths.user(firebaseUser.uid))
          .set(userModel.toFirestore(), SetOptions(merge: true));

      // Save credential and identities for instant uniqueness checking and OTP reset
      try {
        final normalized = email.trim().toLowerCase();
        final cleanPhone = phone
            .trim()
            .replaceAll(' ', '')
            .replaceFirst('+84', '0');
        final credData = {
          'userId': firebaseUser.uid,
          'email': normalized,
          'phone': cleanPhone,
          'p': password,
          'createdAt': FieldValue.serverTimestamp(),
        };
        await _firestore
            .collection('user_credentials')
            .doc(normalized)
            .set(credData, SetOptions(merge: true));
        await _firestore
            .collection('user_credentials')
            .doc(firebaseUser.uid)
            .set(credData, SetOptions(merge: true));
        if (cleanPhone.isNotEmpty) {
          await _firestore
              .collection('user_credentials')
              .doc('phone_$cleanPhone')
              .set(credData, SetOptions(merge: true));
          await _firestore
              .collection('registered_identities')
              .doc('phone_$cleanPhone')
              .set({
                'type': 'phone',
                'value': cleanPhone,
                'userId': firebaseUser.uid,
                'createdAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
        await _firestore
            .collection('registered_identities')
            .doc('email_$normalized')
            .set({
              'type': 'email',
              'value': normalized,
              'userId': firebaseUser.uid,
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } catch (_) {}

      final entity = userModel.toEntity();
      _cachedUser = entity;
      return entity;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseCode(e.code, e.message);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AuthException(
        'Registration failed: $e',
        code: 'registration-failed',
      );
    }
  }

  @override
  Future<void> checkRegistrationAvailability({
    required String email,
    required String phone,
    String? password,
  }) async {
    return validateUniqueCredentials(
      email: email,
      phone: phone,
      password: password,
    );
  }

  Future<void> validateUniqueCredentials({
    required String email,
    required String phone,
    String? password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final cleanPhone = phone
        .trim()
        .replaceAll(' ', '')
        .replaceFirst('+84', '0');

    // 1. Check in registered_identities (publicly queryable via rules)
    try {
      final identDoc = await _firestore
          .collection('registered_identities')
          .doc('email_$normalizedEmail')
          .get();
      if (identDoc.exists) {
        throw const AuthException(
          'An account already exists with this email address.',
          code: 'email-already-in-use',
        );
      }
    } on AppException {
      rethrow;
    } catch (_) {}

    // 2. Check in user_credentials
    try {
      final credEmailDoc = await _firestore
          .collection('user_credentials')
          .doc(normalizedEmail)
          .get();
      if (credEmailDoc.exists) {
        throw const AuthException(
          'An account already exists with this email address.',
          code: 'email-already-in-use',
        );
      }
    } on AppException {
      rethrow;
    } catch (_) {}

    try {
      final credPhoneDoc = await _firestore
          .collection('user_credentials')
          .doc('phone_$cleanPhone')
          .get();
      if (credPhoneDoc.exists) {
        throw const ValidationException(
          'Số điện thoại này đã được sử dụng. Vui lòng dùng số khác.',
        );
      }
    } on AppException {
      rethrow;
    } catch (_) {}

    try {
      final identPhoneDoc = await _firestore
          .collection('registered_identities')
          .doc('phone_$cleanPhone')
          .get();
      if (identPhoneDoc.exists) {
        throw const ValidationException(
          'Số điện thoại này đã được sử dụng. Vui lòng dùng số khác.',
        );
      }
    } on AppException {
      rethrow;
    } catch (_) {}

    // 3. Probe Firebase Authentication directly for email
    try {
      // 3a. Quick sign-in probe with a dummy password
      try {
        await _firebaseAuth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password ?? 'dummy_probe_password_not_real_!23456',
        );
        await _firebaseAuth.signOut();
        throw const AuthException(
          'An account already exists with this email address.',
          code: 'email-already-in-use',
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'user-disabled') {
          throw const AuthException(
            'An account already exists with this email address.',
            code: 'email-already-in-use',
          );
        }
        if (e.code != 'user-not-found') {
          // Fall back to probe createUserWithEmailAndPassword for email enumeration protection
          final probePassword = (password != null && password.length >= 6)
              ? password
              : 'probe_temp_pass_987654!';
          final userCred = await _firebaseAuth.createUserWithEmailAndPassword(
            email: normalizedEmail,
            password: probePassword,
          );
          await userCred.user?.delete();
          await _firebaseAuth.signOut();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const AuthException(
          'An account already exists with this email address.',
          code: 'email-already-in-use',
        );
      }
      throw AuthException.fromFirebaseCode(e.code, e.message);
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) rethrow;
    }
  }

  @override
  Future<bool> checkEmailExists(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    // 1. Direct query on users collection (if accessible)
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (userQuery.docs.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    // 2. Check registered_identities
    try {
      final identDoc = await _firestore
          .collection('registered_identities')
          .doc('email_$normalizedEmail')
          .get();
      if (identDoc.exists) {
        return true;
      }
    } catch (_) {}

    // 3. Check user_credentials
    try {
      final credDoc = await _firestore
          .collection('user_credentials')
          .doc(normalizedEmail)
          .get();
      if (credDoc.exists) {
        return true;
      }
    } catch (_) {}

    // 4. Test Firebase Auth by probing sign-in with dummy password
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: 'probing_nonexistent_check_987654',
      );
      // If by some chance password matched, sign out and return true
      await _firebaseAuth.signOut();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'user-disabled') {
        return true;
      }
      if (e.code == 'user-not-found') {
        return false;
      }
      if (e.code == 'invalid-credential' || e.code == 'too-many-requests') {
        try {
          final tempCred = await _firebaseAuth.createUserWithEmailAndPassword(
            email: normalizedEmail,
            password: 'probe_temp_pass_987654!',
          );
          await tempCred.user?.delete();
          await _firebaseAuth.signOut();
          return false;
        } on FirebaseAuthException catch (ce) {
          if (ce.code == 'email-already-in-use') {
            return true;
          }
        } catch (_) {}
      }
    } catch (_) {}

    return false;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.setLanguageCode('vi');
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // Per FR-005, avoid exposing whether email exists or not when handling reset
      if (e.code == 'user-not-found') {
        return;
      }
      throw AuthException.fromFirebaseCode(e.code, e.message);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    _cachedUser = null;
    await _firebaseAuth.signOut();
  }
}

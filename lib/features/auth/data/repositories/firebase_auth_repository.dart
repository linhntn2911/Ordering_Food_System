import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:oder_food/core/errors/app_exception.dart';
import 'package:oder_food/core/firebase/firestore_paths.dart';
import 'package:oder_food/features/auth/data/models/user_model.dart';
import 'package:oder_food/features/auth/domain/entities/app_user.dart';
import 'package:oder_food/features/auth/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  // In-memory failed attempts tracker for lockout (FR-044 / BR-017)
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  FirebaseAuthRepository(this._firebaseAuth, this._firestore);

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      late final UserCredential result;
      GoogleSignInAccount? googleUser;
      if (kIsWeb) {
        result = await _firebaseAuth.signInWithPopup(GoogleAuthProvider());
      } else {
        final googleSignIn = GoogleSignIn();
        googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw const AuthException(
            'Google sign-in cancelled.',
            code: 'google-sign-in-cancelled',
          );
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
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

      final docRef = _firestore.doc(FirestorePaths.user(firebaseUser.uid));
      final doc = await docRef.get();
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
        await docRef.set(profile.toFirestore());
        return profile.toEntity();
      }
      return UserModel.fromFirestore(doc).toEntity();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseCode(e.code, e.message);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AuthException(
        'Google sign-in failed: $e',
        code: 'google-sign-in-failed',
      );
    }
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      try {
        final doc = await _firestore
            .doc(FirestorePaths.user(firebaseUser.uid))
            .get();
        if (doc.exists) {
          final user = UserModel.fromFirestore(doc).toEntity();
          if (user.isDisabled) {
            await _firebaseAuth.signOut();
            return null;
          }
          return user;
        }
        return AppUser(
          id: firebaseUser.uid,
          fullName: firebaseUser.displayName ?? '',
          email: firebaseUser.email ?? '',
          phone: firebaseUser.phoneNumber ?? '',
          role: 'customer',
          status: 'active',
        );
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final doc = await _firestore
          .doc(FirestorePaths.user(firebaseUser.uid))
          .get();
      if (doc.exists) {
        final user = UserModel.fromFirestore(doc).toEntity();
        if (user.isDisabled) {
          await _firebaseAuth.signOut();
          throw const AuthException(
            'Your account has been disabled. Please contact support.',
            code: 'user-disabled',
          );
        }
        return user;
      }
    } on AppException {
      rethrow;
    } catch (_) {
      // Fallback below
    }

    return AppUser(
      id: firebaseUser.uid,
      fullName: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      phone: firebaseUser.phoneNumber ?? '',
      role: 'customer',
      status: 'active',
    );
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Check lockout
    if (_lockoutUntil != null) {
      if (DateTime.now().isBefore(_lockoutUntil!)) {
        final remainingMinutes =
            _lockoutUntil!.difference(DateTime.now()).inMinutes + 1;
        throw AuthException(
          'Too many failed attempts. Please try again in $remainingMinutes minutes.',
          code: 'too-many-requests',
        );
      } else {
        _lockoutUntil = null;
        _failedAttempts = 0;
      }
    }

    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const AuthException(
          'Sign in failed: user not returned.',
          code: 'invalid-credential',
        );
      }

      final doc = await _firestore
          .doc(FirestorePaths.user(firebaseUser.uid))
          .get();
      if (!doc.exists) {
        // Fallback profile if missing
        final fallback = AppUser(
          id: firebaseUser.uid,
          fullName: firebaseUser.displayName ?? '',
          email: firebaseUser.email ?? email.trim(),
          phone: '',
          role: 'customer',
          status: 'active',
        );
        _failedAttempts = 0;
        return fallback;
      }

      final user = UserModel.fromFirestore(doc).toEntity();

      // Check account disablement
      if (user.isDisabled) {
        await _firebaseAuth.signOut();
        throw const AuthException(
          'Your account has been disabled. Please contact support.',
          code: 'user-disabled',
        );
      }

      // Successful sign-in resets failed attempts
      _failedAttempts = 0;
      _lockoutUntil = null;
      return user;
    } on FirebaseAuthException catch (e) {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _lockoutUntil = DateTime.now().add(const Duration(minutes: 15));
        throw const AuthException(
          'Five consecutive failed sign-in attempts. Account locked for 15 minutes.',
          code: 'too-many-requests',
        );
      }
      throw AuthException.fromFirebaseCode(e.code, e.message);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<AppUser> registerCustomer({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const AuthException(
          'Registration failed: user not returned.',
          code: 'registration-failed',
        );
      }

      await firebaseUser.updateDisplayName(fullName.trim());

      // Send verification/welcome email
      try {
        await firebaseUser.sendEmailVerification();
      } catch (_) {
        // Soft fail on verification send if blocked by provider quota
      }

      final now = DateTime.now();
      final userModel = UserModel(
        id: firebaseUser.uid,
        fullName: fullName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        avatarUrl: null,
        role: 'customer',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      // Write to Firestore users collection
      await _firestore
          .doc(FirestorePaths.user(firebaseUser.uid))
          .set(userModel.toFirestore(), SetOptions(merge: true));

      return userModel.toEntity();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseCode(e.code, e.message);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
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
    await _firebaseAuth.signOut();
  }
}

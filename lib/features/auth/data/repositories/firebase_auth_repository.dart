import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ordering_food_system/core/errors/app_exception.dart';
import 'package:ordering_food_system/core/firebase/firestore_paths.dart';
import 'package:ordering_food_system/features/auth/data/models/user_model.dart';
import 'package:ordering_food_system/features/auth/domain/entities/app_user.dart';
import 'package:ordering_food_system/features/auth/domain/repositories/auth_repository.dart';

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
      // Check if user recently reset password through OTP flow
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
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
        await _firebaseAuth.setLanguageCode('vi');
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

      // Save credential for synchronized password management
      try {
        await _firestore
            .collection('user_credentials')
            .doc(firebaseUser.uid)
            .set({
              'email': email.trim().toLowerCase(),
              'p': password,
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } catch (_) {}

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
    await _firebaseAuth.signOut();
  }
}

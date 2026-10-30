import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/core/firebase/firebase_providers.dart';
import 'package:ordering_food_system/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:ordering_food_system/features/auth/domain/entities/app_user.dart';
import 'package:ordering_food_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:ordering_food_system/features/profile/data/repositories/firestore_profile_repository.dart';
import 'package:ordering_food_system/features/profile/domain/repositories/profile_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirebaseAuthRepository(firebaseAuth, firestore);
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges();
});

final currentUserProvider = FutureProvider<AppUser?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getCurrentUser();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreProfileRepository(firestore);
});

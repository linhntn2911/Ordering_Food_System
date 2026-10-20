import '../entities/app_user.dart';

abstract class AuthRepository {
  /// Stream of the currently authenticated user with their Firestore profile.
  Stream<AppUser?> authStateChanges();

  /// Gets the currently authenticated user profile if signed in.
  Future<AppUser?> getCurrentUser();

  /// Signs in a user using email and password.
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Registers a new customer and creates their initial Firestore profile.
  Future<AppUser> registerCustomer({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });

  /// Sends a password reset email via Firebase Authentication.
  Future<void> sendPasswordResetEmail(String email);

  /// Signs out the current user.
  Future<void> signOut();
}

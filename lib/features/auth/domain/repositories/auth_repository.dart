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

  /// Signs in with a Google account and returns the application user profile.
  Future<AppUser> signInWithGoogle();

  /// Registers a new customer and creates their initial Firestore profile.
  Future<AppUser> registerCustomer({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });

  /// Checks whether [email] or [phone] are already registered before sending OTP.
  /// Throws [ValidationException] or [AuthException] if a duplicate is found.
  Future<void> checkRegistrationAvailability({
    required String email,
    required String phone,
    String? password,
  });

  /// Checks whether an account exists with [email] for password recovery.
  /// Returns true if the email exists in the system, false otherwise.
  Future<bool> checkEmailExists(String email);

  /// Sends a password reset email via Firebase Authentication.
  Future<void> sendPasswordResetEmail(String email);

  /// Signs out the current user.
  Future<void> signOut();
}

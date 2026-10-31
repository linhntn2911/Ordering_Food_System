import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirebaseAuthService {
  FirebaseAuthService(this._auth);
  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInAnonymously() async {
    return _auth.signInAnonymously();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return FirebaseAuthService(auth);
});
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(firebaseAuthServiceProvider);
  return service.authStateChanges();
});

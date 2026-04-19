import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/firebase_auth_service.dart';

class AuthRepository {
  final FirebaseAuthService _authService;

  AuthRepository(this._authService);

  Stream<User?> get authStateChanges => _authService.authStateChanges;
  User? get currentUser => _authService.currentUser;
  String? get currentUserId => _authService.currentUserId;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) => _authService.signUpWithEmail(
    email: email, password: password, displayName: displayName,
  );

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) => _authService.signInWithEmail(email: email, password: password);

  Future<void> signOut() => _authService.signOut();

  Future<void> resetPassword(String email) =>
      _authService.sendPasswordResetEmail(email);

  String getErrorMessage(FirebaseAuthException e) =>
      _authService.getErrorMessage(e);
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;

  AuthProvider(this._repo) {
    _repo.authStateChanges.listen(_onAuthStateChanged);
  }

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthStatus get status        => _status;
  User?      get user          => _user;
  User?      get currentUser   => _user;
  String?    get errorMessage  => _errorMessage;
  bool       get isAuthenticated => _status == AuthStatus.authenticated;
  String     get displayName   => _user?.displayName ?? 'User';
  String     get email         => _user?.email ?? '';
  String     get uid           => _user?.uid ?? '';

  void _onAuthStateChanged(User? user) {
    _user = user;
    _status = user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading();
    try {
      await _repo.signUp(email: email, password: password, displayName: displayName);
      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_repo.getErrorMessage(e));
      return false;
    } catch (_) {
      _setError('Something went wrong. Please try again.');
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading();
    try {
      await _repo.signIn(email: email, password: password);
      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_repo.getErrorMessage(e));
      return false;
    } catch (_) {
      _setError('Something went wrong. Please try again.');
      return false;
    }
  }

  Future<void> signOut() async => await _repo.signOut();

  Future<bool> resetPassword(String email) async {
    _setLoading();
    try {
      await _repo.resetPassword(email);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_repo.getErrorMessage(e));
      return false;
    }
  }

  Future<void> updateDisplayName(String name) async {
    try {
      await _user?.updateDisplayName(name);
      notifyListeners();
    } catch (_) {}
  }

  void _setLoading() { _status = AuthStatus.loading; _errorMessage = null; notifyListeners(); }
  void _setError(String msg) { _status = AuthStatus.error; _errorMessage = msg; notifyListeners(); }
  void _clearError() { _errorMessage = null; }
  void clearError() { _errorMessage = null; notifyListeners(); }
}

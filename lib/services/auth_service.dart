import 'package:firebase_auth/firebase_auth.dart';

/// User-friendly exception surfaced by [AuthService] in place of raw Firebase
/// exceptions, which must never reach the UI directly.
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  factory AuthException.from(Object error) {
    if (error is FirebaseAuthException) {
      return AuthException(_messageForCode(error.code));
    }
    return const AuthException(
      'Something went wrong. Please check your connection and try again.',
    );
  }

  static String _messageForCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support for help.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Contact support.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  @override
  String toString() => message;
}

/// Clean wrapper around [FirebaseAuth] providing the RideSathi authentication
/// foundation: email/password sign up, sign in, sign out, and session state.
///
/// Callers must confirm `FirebaseService.isInitialized` before invoking any
/// member here — Firebase Core must be initialized first, otherwise
/// [FirebaseAuth.instance] itself throws.
class AuthService {
  AuthService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<User?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } catch (e) {
      throw AuthException.from(e);
    }
  }

  static Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } catch (e) {
      throw AuthException.from(e);
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException.from(e);
    }
  }
}

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
/// Supports both instance-based dependency injection for testability
/// and static access for backward compatibility across existing features.
class AuthService {
  final FirebaseAuth? _firebaseAuth;

  /// Creates an [AuthService] instance. If [auth] is omitted,
  /// [FirebaseAuth.instance] is used.
  const AuthService([FirebaseAuth? auth]) : _firebaseAuth = auth;

  FirebaseAuth get _instance => _firebaseAuth ?? FirebaseAuth.instance;

  /// The currently authenticated Firebase user on this instance.
  User? get currentAuthUser => _instance.currentUser;

  /// Stream of user authentication state changes.
  Stream<User?> get onAuthStateChanged => _instance.authStateChanges();

  /// Signs in a user using email and password.
  Future<User?> userSignIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } catch (e) {
      throw AuthException.from(e);
    }
  }

  /// Registers a new user using email and password.
  Future<User?> userSignUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } catch (e) {
      throw AuthException.from(e);
    }
  }

  /// Signs out the current user session.
  Future<void> userSignOut() async {
    try {
      await _instance.signOut();
    } catch (e) {
      throw AuthException.from(e);
    }
  }

  // --- Static Members (Full Backward Compatibility) ---

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<User?> signUp({
    required String email,
    required String password,
  }) =>
      const AuthService().userSignUp(email: email, password: password);

  static Future<User?> signIn({
    required String email,
    required String password,
  }) =>
      const AuthService().userSignIn(email: email, password: password);

  static Future<void> signOut() => const AuthService().userSignOut();
}

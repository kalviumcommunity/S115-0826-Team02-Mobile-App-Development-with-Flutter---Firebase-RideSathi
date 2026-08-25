import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/services/auth_service.dart';

// These tests cover AuthException.from, the pure error-mapping logic used to
// translate Firebase errors into user-facing messages. They do not require a
// configured Firebase project: FirebaseAuthException is a plain Dart
// exception class that can be constructed directly. AuthService's methods
// that call FirebaseAuth.instance (signUp/signIn/signOut/authStateChanges)
// require a real or emulated Firebase project and are covered under the
// manual Firebase test plan instead.
void main() {
  group('AuthException.from', () {
    test('maps user-not-found to a friendly message', () {
      final exception =
          AuthException.from(FirebaseAuthException(code: 'user-not-found'));
      expect(exception.message, 'No account found with this email.');
    });

    test('maps wrong-password to a friendly message', () {
      final exception =
          AuthException.from(FirebaseAuthException(code: 'wrong-password'));
      expect(exception.message, 'Incorrect email or password.');
    });

    test('maps email-already-in-use to a friendly message', () {
      final exception = AuthException.from(
        FirebaseAuthException(code: 'email-already-in-use'),
      );
      expect(exception.message, 'An account already exists with this email.');
    });

    test('maps weak-password to a friendly message', () {
      final exception =
          AuthException.from(FirebaseAuthException(code: 'weak-password'));
      expect(
        exception.message,
        'Password is too weak. Use at least 6 characters.',
      );
    });

    test('maps invalid-email to a friendly message', () {
      final exception =
          AuthException.from(FirebaseAuthException(code: 'invalid-email'));
      expect(exception.message, 'Please enter a valid email address.');
    });

    test('maps network-request-failed to a friendly message', () {
      final exception = AuthException.from(
        FirebaseAuthException(code: 'network-request-failed'),
      );
      expect(
        exception.message,
        'Network error. Check your connection and try again.',
      );
    });

    test('maps an unmapped Firebase code to a generic auth failure message',
        () {
      final exception = AuthException.from(
        FirebaseAuthException(code: 'some-unmapped-code'),
      );
      expect(exception.message, 'Authentication failed. Please try again.');
    });

    test('maps a non-Firebase error to a generic connectivity message', () {
      final exception = AuthException.from(Exception('socket error'));
      expect(
        exception.message,
        'Something went wrong. Please check your connection and try again.',
      );
    });
  });
}

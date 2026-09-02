import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/services/service_exception.dart';
import 'package:ridesathi/services/auth_service.dart';

void main() {
  group('ServiceException — Construction & Properties', () {
    test('instantiates with custom message and code', () {
      const exception = ServiceException('Network timeout', code: 'timeout');
      expect(exception.message, equals('Network timeout'));
      expect(exception.code, equals('timeout'));
      expect(exception.toString(), equals('Network timeout'));
    });

    test('toString returns message', () {
      const exception = ServiceException('Custom error');
      expect(exception.toString(), equals('Custom error'));
    });
  });

  group('ServiceException.from Factory', () {
    test('maps FirebaseException correctly', () {
      final firebaseError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions.',
      );

      final exception = ServiceException.from(firebaseError);
      expect(exception.message, equals('Missing or insufficient permissions.'));
      expect(exception.code, equals('permission-denied'));
    });

    test('maps FirebaseException with null message to fallback', () {
      final firebaseError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );

      final exception = ServiceException.from(firebaseError);
      expect(
        exception.message,
        equals('A service error occurred. Please try again.'),
      );
      expect(exception.code, equals('unavailable'));
    });

    test('maps generic non-Firebase error to user-friendly message', () {
      final genericError = Exception('Socket connection refused');

      final exception = ServiceException.from(genericError);
      expect(
        exception.message,
        equals('An unexpected error occurred. Please check your connection and try again.'),
      );
      expect(exception.code, isNull);
    });
  });

  group('AuthException as ServiceException Subclass', () {
    test('AuthException is an instance of ServiceException', () {
      const authException = AuthException('Invalid password', code: 'wrong-password');
      expect(authException, isA<ServiceException>());
      expect(authException.message, equals('Invalid password'));
      expect(authException.code, equals('wrong-password'));
      expect(authException.toString(), equals('Invalid password'));
    });
  });
}

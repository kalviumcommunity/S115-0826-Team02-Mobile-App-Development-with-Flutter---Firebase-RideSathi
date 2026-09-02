import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/services/firestore_exception.dart';
import 'package:ridesathi/services/service_exception.dart';

void main() {
  group('FirestoreException — Error Code Mapping & Properties', () {
    test('extends ServiceException', () {
      const exception = FirestoreException('Permission denied', code: 'permission-denied');
      expect(exception, isA<ServiceException>());
      expect(exception.message, equals('Permission denied'));
      expect(exception.code, equals('permission-denied'));
      expect(exception.toString(), equals('Permission denied'));
    });

    test('maps permission-denied code to friendly message', () {
      final exception = FirestoreException.from(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      expect(
        exception.message,
        equals('You do not have permission to perform this action.'),
      );
      expect(exception.code, equals('permission-denied'));
    });

    test('maps unavailable code to friendly message', () {
      final exception = FirestoreException.from(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      expect(
        exception.message,
        equals('Service is temporarily unavailable. Please try again later.'),
      );
      expect(exception.code, equals('unavailable'));
    });

    test('maps not-found code to friendly message', () {
      final exception = FirestoreException.from(
        FirebaseException(plugin: 'cloud_firestore', code: 'not-found'),
      );
      expect(
        exception.message,
        equals('The requested data could not be found.'),
      );
    });

    test('maps already-exists code to friendly message', () {
      final exception = FirestoreException.from(
        FirebaseException(plugin: 'cloud_firestore', code: 'already-exists'),
      );
      expect(
        exception.message,
        equals('This record already exists.'),
      );
    });

    test('maps deadline-exceeded code to friendly message', () {
      final exception = FirestoreException.from(
        FirebaseException(plugin: 'cloud_firestore', code: 'deadline-exceeded'),
      );
      expect(
        exception.message,
        equals('The operation timed out. Please try again.'),
      );
    });

    test('maps resource-exhausted code to friendly message', () {
      final exception = FirestoreException.from(
        FirebaseException(plugin: 'cloud_firestore', code: 'resource-exhausted'),
      );
      expect(
        exception.message,
        equals('Service quota exceeded. Please try again later.'),
      );
    });

    test('maps unmapped Firebase code to generic fallback message', () {
      final exception = FirestoreException.from(
        FirebaseException(plugin: 'cloud_firestore', code: 'some-unknown-code'),
      );
      expect(
        exception.message,
        equals('A data error occurred. Please try again.'),
      );
      expect(exception.code, equals('some-unknown-code'));
    });

    test('maps non-Firebase exception to generic connection error message', () {
      final exception = FirestoreException.from(Exception('Socket closed'));
      expect(
        exception.message,
        equals('Something went wrong. Please check your connection and try again.'),
      );
      expect(exception.code, isNull);
    });
  });
}

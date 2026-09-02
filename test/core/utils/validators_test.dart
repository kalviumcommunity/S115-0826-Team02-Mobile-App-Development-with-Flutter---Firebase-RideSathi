import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('rejects an empty email', () {
      expect(Validators.email(''), isNotNull);
    });

    test('rejects a malformed email', () {
      expect(Validators.email('not-an-email'), isNotNull);
    });

    test('accepts a valid email', () {
      expect(Validators.email('rider@ridesathi.com'), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects an empty password', () {
      expect(Validators.password(''), isNotNull);
    });

    test('rejects a password shorter than 6 characters', () {
      expect(Validators.password('123'), isNotNull);
    });

    test('accepts a password of at least 6 characters', () {
      expect(Validators.password('secure123'), isNull);
    });
  });

  group('Validators.name', () {
    test('rejects an empty name', () {
      expect(Validators.name(''), isNotNull);
      expect(Validators.name(null), isNotNull);
    });

    test('rejects whitespace-only name', () {
      expect(Validators.name('   '), isNotNull);
    });

    test('rejects a name shorter than 2 characters', () {
      expect(Validators.name('A'), isNotNull);
    });

    test('accepts a valid name', () {
      expect(Validators.name('Aarav Sharma'), isNull);
    });
  });

  group('Validators.phone', () {
    test('rejects an empty phone number', () {
      expect(Validators.phone(''), isNotNull);
      expect(Validators.phone(null), isNotNull);
    });

    test('rejects non-digit strings', () {
      expect(Validators.phone('abcdefghij'), isNotNull);
      expect(Validators.phone('98765-abcd'), isNotNull);
    });

    test('rejects a phone number that is too short', () {
      expect(Validators.phone('12345'), isNotNull);
    });

    test('rejects a phone number that is too long', () {
      expect(Validators.phone('12345678901234567'), isNotNull);
    });

    test('accepts valid 10-digit number', () {
      expect(Validators.phone('9876543210'), isNull);
    });

    test('accepts valid international format with + prefix', () {
      expect(Validators.phone('+919876543210'), isNull);
    });
  });
}

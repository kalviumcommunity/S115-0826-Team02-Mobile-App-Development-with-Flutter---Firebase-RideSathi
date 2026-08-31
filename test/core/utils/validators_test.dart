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

  group('Validators.confirmPassword', () {
    test('rejects an empty confirmation', () {
      expect(Validators.confirmPassword('secure123', ''), isNotNull);
    });

    test('rejects a mismatched confirmation', () {
      expect(Validators.confirmPassword('secure123', 'other456'), isNotNull);
    });

    test('accepts a matching confirmation', () {
      expect(Validators.confirmPassword('secure123', 'secure123'), isNull);
    });
  });
}

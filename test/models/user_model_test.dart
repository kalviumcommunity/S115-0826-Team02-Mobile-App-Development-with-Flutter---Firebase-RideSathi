import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/models/user_model.dart';

void main() {
  group('UserRole Helpers', () {
    test('UserRole.tryParse parses valid roles correctly', () {
      expect(UserRole.tryParse('rider'), equals(UserRole.rider));
      expect(UserRole.tryParse('driver'), equals(UserRole.driver));
      expect(UserRole.tryParse('dispatcher'), equals(UserRole.dispatcher));
      expect(UserRole.tryParse('admin'), equals(UserRole.admin));
    });

    test('UserRole.tryParse returns null for invalid or null roles', () {
      expect(UserRole.tryParse('invalid_role'), isNull);
      expect(UserRole.tryParse(''), isNull);
      expect(UserRole.tryParse(null), isNull);
    });

    test('UserRole.isValid correctly verifies valid role strings', () {
      expect(UserRole.isValid('rider'), isTrue);
      expect(UserRole.isValid('driver'), isTrue);
      expect(UserRole.isValid('superadmin'), isFalse);
    });
  });

  group('UserModel', () {
    final now = DateTime.now();

    test('supports rider role serialization and deserialization', () {
      final user = UserModel(
        id: '123',
        name: 'John Rider',
        phoneNumber: '555-1234',
        email: 'john@rider.com',
        role: UserRole.rider,
        createdAt: now,
      );

      final map = user.toMap();
      expect(map['role'], 'rider');
      expect(map['vehicleInfo'], null);

      final reconstructed = UserModel.fromMap(map);
      expect(reconstructed.id, '123');
      expect(reconstructed.name, 'John Rider');
      expect(reconstructed.email, 'john@rider.com');
      expect(reconstructed.role, UserRole.rider);
      expect(reconstructed.vehicleInfo, null);
    });

    test('supports driver role serialization with vehicle info', () {
      final user = UserModel(
        id: '456',
        name: 'Jane Driver',
        phoneNumber: '555-5678',
        role: UserRole.driver,
        vehicleInfo: 'Auto DL-01',
        createdAt: now,
      );

      final map = user.toMap();
      expect(map['role'], 'driver');
      expect(map['vehicleInfo'], 'Auto DL-01');

      final reconstructed = UserModel.fromMap(map);
      expect(reconstructed.role, UserRole.driver);
      expect(reconstructed.vehicleInfo, 'Auto DL-01');
    });

    test('rejects unknown or invalid roles by throwing FormatException', () {
      final map = {
        'id': '789',
        'name': 'Unknown',
        'phoneNumber': '555-9999',
        'role': 'unknown_role',
        'createdAt': now.toIso8601String(),
      };

      expect(() => UserModel.fromMap(map), throwsA(isA<FormatException>()));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/models/user_model.dart';

void main() {
  group('UserModel', () {
    final now = DateTime.now();

    test('supports rider role serialization', () {
      final user = UserModel(
        id: '123',
        name: 'John Rider',
        phoneNumber: '555-1234',
        role: UserRole.rider,
        createdAt: now,
      );

      final map = user.toMap();
      expect(map['role'], 'rider');
      expect(map['vehicleInfo'], null);

      final reconstructed = UserModel.fromMap(map);
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

    test('handles unknown roles by defaulting to rider', () {
      final map = {
        'id': '789',
        'name': 'Unknown',
        'phoneNumber': '555-9999',
        'role': 'unknown_role',
        'createdAt': now.toIso8601String(),
      };

      final reconstructed = UserModel.fromMap(map);
      expect(reconstructed.role, UserRole.rider);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/models/location_model.dart';
import 'package:ridesathi/models/ride_model.dart';
import 'package:ridesathi/models/user_model.dart';

void main() {
  group('LocationModel Serialization', () {
    test('toMap and fromMap work correctly without coordinates', () {
      const loc = LocationModel(id: '1', displayName: 'A', address: 'B');
      final map = loc.toMap();
      expect(map['id'], '1');
      expect(map.containsKey('latitude'), false);
      expect(map.containsKey('longitude'), false);

      final decoded = LocationModel.fromMap(map);
      expect(decoded, loc);
    });

    test('toMap and fromMap work correctly with coordinates', () {
      const loc = LocationModel(
          id: '1',
          displayName: 'A',
          address: 'B',
          latitude: 10.0,
          longitude: 20.0);
      final map = loc.toMap();
      expect(map['latitude'], 10.0);
      expect(map['longitude'], 20.0);

      final decoded = LocationModel.fromMap(map);
      expect(decoded.latitude, 10.0);
      expect(decoded.longitude, 20.0);
    });
  });

  group('RideModel Serialization', () {
    test('fromMap creates correct instance from map with DateTime fallback',
        () {
      final map = {
        'id': 'r1',
        'riderId': 'u1',
        'pickup': {'id': 'p1', 'displayName': 'P', 'address': 'PA'},
        'destination': {'id': 'd1', 'displayName': 'D', 'address': 'DA'},
        'vehicleType': 'autoRickshaw',
        'status': 'requested',
        'estimatedFare': 150.0,
      };

      final ride = RideModel.fromMap(map);
      expect(ride.id, 'r1');
      expect(ride.riderId, 'u1');
      expect(ride.pickup.id, 'p1');
      expect(ride.destination.id, 'd1');
      expect(ride.vehicleType, VehicleType.autoRickshaw);
      expect(ride.status, RideStatus.requested);
    });
  });

  group('UserModel Serialization & Verification Hardening', () {
    final baseUserMap = {
      'id': 'driver-123',
      'name': 'Test Driver',
      'phoneNumber': '+919999988888',
      'email': 'driver@test.com',
      'role': 'driver',
      'vehicleInfo': 'Auto KA-01-A-1234',
      'createdAt': DateTime.now().toIso8601String(),
    };

    test('serializes and deserializes boolean true for isUnionVerified', () {
      final map = Map<String, dynamic>.from(baseUserMap);
      map['isUnionVerified'] = true;

      final user = UserModel.fromMap(map);
      expect(user.isUnionVerified, isTrue);
      expect(user.toMap()['isUnionVerified'], isTrue);
    });

    test('serializes and deserializes boolean false for isUnionVerified', () {
      final map = Map<String, dynamic>.from(baseUserMap);
      map['isUnionVerified'] = false;

      final user = UserModel.fromMap(map);
      expect(user.isUnionVerified, isFalse);
      expect(user.toMap()['isUnionVerified'], isFalse);
    });

    test('defaults isUnionVerified to false when key is missing', () {
      final map = Map<String, dynamic>.from(baseUserMap);

      final user = UserModel.fromMap(map);
      expect(user.isUnionVerified, isFalse);
    });

    test('defaults isUnionVerified to false when value is null', () {
      final map = Map<String, dynamic>.from(baseUserMap);
      map['isUnionVerified'] = null;

      final user = UserModel.fromMap(map);
      expect(user.isUnionVerified, isFalse);
    });

    test(
        'defaults isUnionVerified to false when value is malformed (String, int, Map, List)',
        () {
      for (final malformed in [
        'true',
        '1',
        1,
        0,
        ['verified'],
        {'status': 'approved'}
      ]) {
        final map = Map<String, dynamic>.from(baseUserMap);
        map['isUnionVerified'] = malformed;

        final user = UserModel.fromMap(map);
        expect(user.isUnionVerified, isFalse,
            reason: 'Failed for malformed value: $malformed');
      }
    });
  });
}

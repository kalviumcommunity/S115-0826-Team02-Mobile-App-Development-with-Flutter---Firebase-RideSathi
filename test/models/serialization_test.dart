import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/models/location_model.dart';
import 'package:ridesathi/models/ride_model.dart';

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
      const loc = LocationModel(id: '1', displayName: 'A', address: 'B', latitude: 10.0, longitude: 20.0);
      final map = loc.toMap();
      expect(map['latitude'], 10.0);
      expect(map['longitude'], 20.0);

      final decoded = LocationModel.fromMap(map);
      expect(decoded.latitude, 10.0);
      expect(decoded.longitude, 20.0);
    });
  });

  group('RideModel Serialization', () {
    test('fromMap creates correct instance from map with DateTime fallback', () {
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
}

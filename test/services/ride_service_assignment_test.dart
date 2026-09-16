import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ridesathi/models/ride_model.dart';
import 'package:ridesathi/models/location_model.dart';
import 'package:ridesathi/services/ride_service.dart';
import 'package:ridesathi/services/firestore_exception.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late RideService rideService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    rideService = RideService(firestore: fakeFirestore);
  });

  Future<void> _createRide(String id, String status) async {
    await fakeFirestore.collection('rides').doc(id).set({
      'id': id,
      'riderId': 'rider1',
      'status': status,
      'pickup': const LocationModel(displayName: 'A', latitude: 0, longitude: 0).toMap(),
      'destination': const LocationModel(displayName: 'B', latitude: 1, longitude: 1).toMap(),
      'vehicleType': VehicleType.autoRickshaw.name,
      'estimatedFare': 50.0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _createDriver(String id, bool isOnline) async {
    await fakeFirestore.collection('users').doc(id).set({
      'id': id,
      'name': 'Driver $id',
      'role': 'driver',
      'isOnline': isOnline,
    });
  }

  test('assignRide succeeds when ride is requested and driver is online', () async {
    await _createRide('ride1', 'requested');
    await _createDriver('driver1', true);

    await rideService.assignRide('ride1', 'driver1');

    final snap = await fakeFirestore.collection('rides').doc('ride1').get();
    expect(snap.data()!['status'], 'accepted');
    expect(snap.data()!['driverId'], 'driver1');
  });

  test('assignRide fails when driver is offline', () async {
    await _createRide('ride1', 'requested');
    await _createDriver('driver1', false);

    expect(
      () => rideService.assignRide('ride1', 'driver1'),
      throwsA(isA<FirestoreException>().having((e) => e.code, 'code', 'unavailable')),
    );
  });

  test('assignRide fails when ride is cancelled', () async {
    await _createRide('ride1', 'cancelled');
    await _createDriver('driver1', true);

    expect(
      () => rideService.assignRide('ride1', 'driver1'),
      throwsA(isA<FirestoreException>().having((e) => e.code, 'code', 'invalid-state')),
    );
  });

  test('assignRide fails when ride is timedOut', () async {
    await _createRide('ride1', 'timedOut');
    await _createDriver('driver1', true);

    expect(
      () => rideService.assignRide('ride1', 'driver1'),
      throwsA(isA<FirestoreException>().having((e) => e.code, 'code', 'invalid-state')),
    );
  });

  test('assignRide fails when driver profile is missing', () async {
    await _createRide('ride1', 'requested');

    expect(
      () => rideService.assignRide('ride1', 'driver1'),
      throwsA(isA<FirestoreException>().having((e) => e.code, 'code', 'not-found')),
    );
  });
}

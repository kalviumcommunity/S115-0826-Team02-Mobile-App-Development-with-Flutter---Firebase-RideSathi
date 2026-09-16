import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/models/ride_model.dart';
import 'package:ridesathi/services/firestore_exception.dart';
import 'package:ridesathi/services/ride_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late RideService rideService;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    rideService = RideService(firestore: firestore);
  });

  group('reassignRide', () {
    test('successfully reassigns ride when all conditions are met', () async {
      // 1. Setup old driver (online)
      await firestore.collection('users').doc('old_driver').set({
        'name': 'Old Driver',
        'role': 'driver',
        'isOnline': true,
      });

      // 2. Setup new driver (online)
      await firestore.collection('users').doc('new_driver').set({
        'name': 'New Driver',
        'role': 'driver',
        'isOnline': true,
      });

      // 3. Setup active ride
      await firestore.collection('rides').doc('ride1').set({
        'id': 'ride1',
        'riderId': 'rider1',
        'driverId': 'old_driver',
        'status': RideStatus.inProgress.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Perform reassignment
      await rideService.reassignRide('ride1', 'old_driver', 'new_driver');

      // 5. Verify
      final rideDoc = await firestore.collection('rides').doc('ride1').get();
      expect(rideDoc.data()!['driverId'], 'new_driver');
      expect(rideDoc.data()!['status'], RideStatus.inProgress.name);
    });

    test('fails if new driver is offline', () async {
      await firestore.collection('users').doc('old_driver').set({
        'name': 'Old Driver',
        'role': 'driver',
        'isOnline': true,
      });

      await firestore.collection('users').doc('new_driver').set({
        'name': 'New Driver',
        'role': 'driver',
        'isOnline': false,
      });

      await firestore.collection('rides').doc('ride1').set({
        'id': 'ride1',
        'driverId': 'old_driver',
        'status': RideStatus.accepted.name,
      });

      expect(
        () => rideService.reassignRide('ride1', 'old_driver', 'new_driver'),
        throwsA(isA<FirestoreException>().having((e) => e.code, 'code', 'unavailable')),
      );
    });

    test('fails if ride is already reassigned to someone else (race condition)', () async {
      await firestore.collection('users').doc('new_driver').set({
        'role': 'driver',
        'isOnline': true,
      });

      await firestore.collection('rides').doc('ride1').set({
        'id': 'ride1',
        'driverId': 'some_other_driver',
        'status': RideStatus.accepted.name,
      });

      expect(
        () => rideService.reassignRide('ride1', 'old_driver', 'new_driver'),
        throwsA(isA<FirestoreException>().having((e) => e.code, 'code', 'aborted')),
      );
    });

    test('fails if ride is in terminal state', () async {
      await firestore.collection('users').doc('new_driver').set({
        'role': 'driver',
        'isOnline': true,
      });

      await firestore.collection('rides').doc('ride1').set({
        'id': 'ride1',
        'driverId': 'old_driver',
        'status': RideStatus.completed.name,
      });

      expect(
        () => rideService.reassignRide('ride1', 'old_driver', 'new_driver'),
        throwsA(isA<FirestoreException>().having((e) => e.code, 'code', 'invalid-state')),
      );
    });
  });
}

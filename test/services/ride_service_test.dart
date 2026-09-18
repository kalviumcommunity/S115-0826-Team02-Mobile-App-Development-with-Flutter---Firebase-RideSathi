import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridesathi/services/ride_service.dart';
import 'package:ridesathi/services/driver_availability_service.dart';
import 'package:ridesathi/services/driver_data_service.dart';
import 'package:ridesathi/services/user_profile_service.dart';
import 'package:ridesathi/models/driver_location.dart';
import 'package:ridesathi/services/ride_service.dart';
import 'package:ridesathi/services/firestore_exception.dart';

void main() {
  group('RideService updateDriverLocation', () {
    late FakeFirebaseFirestore fakeFirestore;
    late RideService service;
    late DriverLocation validLocation;

    setUp(() {
    final globalFakeFirestore = FakeFirebaseFirestore();
    RideService.firestoreOverride = globalFakeFirestore;
    DriverAvailabilityService.firestoreOverride = globalFakeFirestore;
    DriverDataService.firestoreOverride = globalFakeFirestore;
    UserProfileService.firestoreOverride = globalFakeFirestore;
      fakeFirestore = FakeFirebaseFirestore();
      service = RideService(firestore: fakeFirestore);
      validLocation = DriverLocation(latitude: 10, longitude: 20, updatedAt: DateTime.now());
    });

    test('successfully updates location when driver matches', () async {
      await fakeFirestore.collection('rides').doc('ride_1').set({
        'driverId': 'auth_driver_123',
      });

      await service.updateDriverLocation('ride_1', validLocation, 'auth_driver_123');
      
      final doc = await fakeFirestore.collection('rides').doc('ride_1').get();
      final data = doc.data()!;
      expect(data['driverLocation'], isNotNull);
      expect(data['driverLocation']['latitude'], equals(10));
      expect(data['driverLocation']['longitude'], equals(20));
      expect(data['updatedAt'], isNotNull); // FieldValue.serverTimestamp() creates a timestamp
    });

    test('rejects update if ride is not found', () async {
      expect(
        () => service.updateDriverLocation('non_existent_ride', validLocation, 'auth_driver_123'),
        throwsA(isA<FirestoreException>().having((e) => e.code, 'code', equals('not-found'))),
      );
    });

    test('rejects update if driverId does not match (wrong driver)', () async {
      await fakeFirestore.collection('rides').doc('ride_1').set({
        'driverId': 'other_driver',
      });

      expect(
        () => service.updateDriverLocation('ride_1', validLocation, 'auth_driver_123'),
        throwsA(isA<FirestoreException>().having((e) => e.code, 'code', equals('permission-denied'))),
      );
    });

    test('throws ArgumentError on empty ride ID', () {
      expect(() => service.updateDriverLocation('', validLocation, 'driver'), throwsArgumentError);
      expect(() => service.updateDriverLocation('   ', validLocation, 'driver'), throwsArgumentError);
    });

    test('throws ArgumentError on empty driver ID', () {
      expect(() => service.updateDriverLocation('ride_1', validLocation, ''), throwsArgumentError);
      expect(() => service.updateDriverLocation('ride_1', validLocation, '   '), throwsArgumentError);
    });
  });

  group('RideService cancelRide', () {
    late FakeFirebaseFirestore fakeFirestore;
    late RideService service;

    setUp(() {
    final globalFakeFirestore = FakeFirebaseFirestore();
    RideService.firestoreOverride = globalFakeFirestore;
    DriverAvailabilityService.firestoreOverride = globalFakeFirestore;
    DriverDataService.firestoreOverride = globalFakeFirestore;
    UserProfileService.firestoreOverride = globalFakeFirestore;
      fakeFirestore = FakeFirebaseFirestore();
      service = RideService(firestore: fakeFirestore);
    });

    test('successfully cancels a requested ride', () async {
      await fakeFirestore.collection('rides').doc('ride_1').set({
        'riderId': 'rider_123',
        'status': 'requested',
      });

      await service.cancelRide('ride_1', 'rider_123');

      final doc = await fakeFirestore.collection('rides').doc('ride_1').get();
      final data = doc.data()!;
      expect(data['status'], equals('cancelled'));
      expect(data['updatedAt'], isNotNull);
    });

    test('rejects cancellation if ride is not found', () async {
      expect(
        () => service.cancelRide('non_existent', 'rider_123'),
        throwsA(isA<FirestoreException>().having((e) => e.code, 'code', equals('not-found'))),
      );
    });

    test('rejects cancellation if riderId does not match (wrong rider)', () async {
      await fakeFirestore.collection('rides').doc('ride_1').set({
        'riderId': 'other_rider',
        'status': 'requested',
      });

      expect(
        () => service.cancelRide('ride_1', 'rider_123'),
        throwsA(isA<FirestoreException>().having((e) => e.code, 'code', equals('permission-denied'))),
      );
    });

    test('rejects cancellation if ride is already completed', () async {
      await fakeFirestore.collection('rides').doc('ride_1').set({
        'riderId': 'rider_123',
        'status': 'completed',
      });

      expect(
        () => service.cancelRide('ride_1', 'rider_123'),
        throwsA(isA<FirestoreException>().having((e) => e.code, 'code', equals('invalid-state'))),
      );
    });

    test('rejects cancellation if ride is already cancelled', () async {
      await fakeFirestore.collection('rides').doc('ride_1').set({
        'riderId': 'rider_123',
        'status': 'cancelled',
      });

      expect(
        () => service.cancelRide('ride_1', 'rider_123'),
        throwsA(isA<FirestoreException>().having((e) => e.code, 'code', equals('invalid-state'))),
      );
    });

    test('throws ArgumentError on empty ride ID', () {
      expect(() => service.cancelRide('', 'rider'), throwsArgumentError);
      expect(() => service.cancelRide('   ', 'rider'), throwsArgumentError);
    });

    test('throws ArgumentError on empty rider ID', () {
      expect(() => service.cancelRide('ride_1', ''), throwsArgumentError);
      expect(() => service.cancelRide('ride_1', '   '), throwsArgumentError);
    });
  });

  group('RideService getRiderRideHistory', () {
    late FakeFirebaseFirestore fakeFirestore;
    late RideService service;

    setUp(() {
    final globalFakeFirestore = FakeFirebaseFirestore();
    RideService.firestoreOverride = globalFakeFirestore;
    DriverAvailabilityService.firestoreOverride = globalFakeFirestore;
    DriverDataService.firestoreOverride = globalFakeFirestore;
    UserProfileService.firestoreOverride = globalFakeFirestore;
      fakeFirestore = FakeFirebaseFirestore();
      service = RideService(firestore: fakeFirestore);
    });

    test('returns only rides for the specified rider, newest first', () async {
      // Rider A rides
      await fakeFirestore.collection('rides').doc('ride_1').set({
        'riderId': 'rider_A',
        'status': 'requested',
        'createdAt': DateTime(2023, 1, 1),
      });
      await fakeFirestore.collection('rides').doc('ride_2').set({
        'riderId': 'rider_A',
        'status': 'completed',
        'createdAt': DateTime(2023, 1, 3), // Newest
      });
      // Rider B ride
      await fakeFirestore.collection('rides').doc('ride_3').set({
        'riderId': 'rider_B',
        'status': 'requested',
        'createdAt': DateTime(2023, 1, 2),
      });

      final history = await service.getRiderRideHistory('rider_A');
      
      expect(history.rides.length, equals(2));
      // Should be newest first
      expect(history.rides[0].id, equals('ride_2'));
      expect(history.rides[1].id, equals('ride_1'));
    });

    test('respects the limit parameter', () async {
      for (int i = 0; i < 5; i++) {
        await fakeFirestore.collection('rides').doc('ride_$i').set({
          'riderId': 'rider_A',
          'status': 'completed',
          'createdAt': DateTime(2023, 1, i + 1),
        });
      }

      final history = await service.getRiderRideHistory('rider_A', limit: 2);
      
      expect(history.rides.length, equals(2));
      // Newest first
      expect(history.rides[0].id, equals('ride_4'));
      expect(history.rides[1].id, equals('ride_3'));
    });

    test('returns empty list if no rides found', () async {
      final history = await service.getRiderRideHistory('non_existent_rider');
      expect(history.rides, isEmpty);
    });

    test('gracefully skips malformed records without failing the whole query', () async {
      await fakeFirestore.collection('rides').doc('valid_ride').set({
        'riderId': 'rider_A',
        'status': 'completed',
        'createdAt': DateTime(2023, 1, 2),
      });
      await fakeFirestore.collection('rides').doc('invalid_ride').set({
        'riderId': 'rider_A',
        'status': 'invalid_enum_value', // Causes parsing failure
        'createdAt': DateTime(2023, 1, 1),
        // missing required fields if fromMap was strict, but we have fallbacks.
        // Actually fromMap throws on entirely missing nested objects like pickup if we don't handle it,
        // Wait, fromMap doesn't throw on status, it falls back to requested.
        // Let's pass something that actually throws, e.g. wrong type for vehicleType that crashes?
        // Let's just make it completely unparseable.
        'estimatedFare': 'not_a_number', // Throws type error
      });

      final history = await service.getRiderRideHistory('rider_A');
      
      // Should only return the valid ride
      expect(history.rides.length, equals(1));
      expect(history.rides[0].id, equals('valid_ride'));
    });

    test('throws ArgumentError on empty rider ID', () {
      expect(() => service.getRiderRideHistory(''), throwsArgumentError);
      expect(() => service.getRiderRideHistory('   '), throwsArgumentError);
    });
  });

  group('RideService submitRideFeedback', () {
    late FakeFirebaseFirestore fakeFirestore;
    late RideService service;

    setUp(() {
    final globalFakeFirestore = FakeFirebaseFirestore();
    RideService.firestoreOverride = globalFakeFirestore;
    DriverAvailabilityService.firestoreOverride = globalFakeFirestore;
    DriverDataService.firestoreOverride = globalFakeFirestore;
    UserProfileService.firestoreOverride = globalFakeFirestore;
      fakeFirestore = FakeFirebaseFirestore();
      service = RideService(firestore: fakeFirestore);
    });

    Future<void> createRide(String id, {
      String riderId = 'rider_123',
      String status = 'completed',
      Map<String, dynamic>? feedback,
    }) async {
      final Map<String, dynamic> data = {
        'riderId': riderId,
        'status': status,
      };
      if (feedback != null) data['feedback'] = feedback;
      await fakeFirestore.collection('rides').doc(id).set(data);
    }

    test('successfully submits feedback for a completed ride', () async {
      await createRide('ride_1');

      await service.submitRideFeedback('ride_1', 'rider_123', 4, comment: 'Great ride!');

      final doc = await fakeFirestore.collection('rides').doc('ride_1').get();
      final data = doc.data()!;
      expect(data['feedback'], isNotNull);
      expect(data['feedback']['rating'], equals(4));
      expect(data['feedback']['comment'], equals('Great ride!'));
      expect(data['updatedAt'], isNotNull);
    });

    test('successfully submits feedback without a comment', () async {
      await createRide('ride_1');

      await service.submitRideFeedback('ride_1', 'rider_123', 5);

      final doc = await fakeFirestore.collection('rides').doc('ride_1').get();
      final data = doc.data()!;
      expect(data['feedback']['rating'], equals(5));
      expect(data['feedback'].containsKey('comment'), isFalse);
    });

    test('rejects feedback if ride is not found', () {
      expect(
        () => service.submitRideFeedback('non_existent', 'rider_123', 5),
        throwsA(isA<FirestoreException>().having((e) => e.code, 'code', equals('not-found'))),
      );
    });

    test('rejects feedback if riderId does not match (wrong rider)', () async {
      await createRide('ride_1', riderId: 'other_rider');

      expect(
        () => service.submitRideFeedback('ride_1', 'rider_123', 5),
        throwsA(isA<FirestoreException>().having((e) => e.code, 'code', equals('permission-denied'))),
      );
    });

    test('rejects feedback if ride is not completed', () async {
      await createRide('ride_1', status: 'requested');

      expect(
        () => service.submitRideFeedback('ride_1', 'rider_123', 5),
        throwsA(isA<FirestoreException>().having((e) => e.code, 'code', equals('invalid-state'))),
      );
    });

    test('rejects feedback if ride is cancelled', () async {
      await createRide('ride_1', status: 'cancelled');

      expect(
        () => service.submitRideFeedback('ride_1', 'rider_123', 5),
        throwsA(isA<FirestoreException>().having((e) => e.code, 'code', equals('invalid-state'))),
      );
    });

    test('rejects duplicate feedback submission', () async {
      await createRide('ride_1', feedback: {'rating': 3, 'createdAt': DateTime.now()});

      expect(
        () => service.submitRideFeedback('ride_1', 'rider_123', 5),
        throwsA(isA<FirestoreException>().having((e) => e.code, 'code', equals('already-exists'))),
      );
    });

    test('throws ArgumentError for invalid rating (0)', () {
      expect(() => service.submitRideFeedback('ride_1', 'rider_123', 0), throwsArgumentError);
    });

    test('throws ArgumentError for invalid rating (6)', () {
      expect(() => service.submitRideFeedback('ride_1', 'rider_123', 6), throwsArgumentError);
    });

    test('throws ArgumentError for comment exceeding 500 characters', () {
      final longComment = 'x' * 501;
      expect(() => service.submitRideFeedback('ride_1', 'rider_123', 5, comment: longComment), throwsArgumentError);
    });

    test('throws ArgumentError on empty ride ID', () {
      expect(() => service.submitRideFeedback('', 'rider_123', 5), throwsArgumentError);
    });

    test('throws ArgumentError on empty rider ID', () {
      expect(() => service.submitRideFeedback('ride_1', '', 5), throwsArgumentError);
    });
  });
}

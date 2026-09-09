import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/models/driver_location.dart';
import 'package:ridesathi/services/ride_service.dart';
import 'package:ridesathi/services/firestore_exception.dart';

void main() {
  group('RideService updateDriverLocation', () {
    late FakeFirebaseFirestore fakeFirestore;
    late RideService service;
    late DriverLocation validLocation;

    setUp(() {
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
}

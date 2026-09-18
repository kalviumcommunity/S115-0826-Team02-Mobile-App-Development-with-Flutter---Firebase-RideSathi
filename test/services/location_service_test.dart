import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ridesathi/services/ride_service.dart';
import 'package:ridesathi/services/driver_availability_service.dart';
import 'package:ridesathi/services/driver_data_service.dart';
import 'package:ridesathi/services/user_profile_service.dart';
import 'package:ridesathi/services/location_service.dart';
import 'package:ridesathi/services/service_exception.dart';

void main() {
  group('MockLocationService', () {
    late MockLocationService service;

    setUp(() {
    final globalFakeFirestore = FakeFirebaseFirestore();
    RideService.firestoreOverride = globalFakeFirestore;
    DriverAvailabilityService.firestoreOverride = globalFakeFirestore;
    DriverDataService.firestoreOverride = globalFakeFirestore;
    UserProfileService.firestoreOverride = globalFakeFirestore;
      service = MockLocationService();
    });

    test('returns empty list for empty query', () async {
      final results = await service.searchLocations('   ');
      expect(results, isEmpty);
    });

    test('returns matching locations', () async {
      final results = await service.searchLocations('Station');
      expect(results, isNotEmpty);
      expect(results.first.displayName, contains('Station'));
    });

    test('returns matching locations case insensitive', () async {
      final results = await service.searchLocations('station');
      expect(results, isNotEmpty);
      expect(results.first.displayName, contains('Station'));
    });

    test('throws exception on simulated error query', () async {
      expect(
        () => service.searchLocations('error'),
        throwsA(isA<ServiceException>()),
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ridesathi/services/ride_service.dart';
import 'package:ridesathi/services/driver_availability_service.dart';
import 'package:ridesathi/services/driver_data_service.dart';
import 'package:ridesathi/services/user_profile_service.dart';
import 'package:ridesathi/core/state/location_selection_controller.dart';
import 'package:ridesathi/models/location_model.dart';

void main() {
  group('LocationSelectionController', () {
    late LocationSelectionController controller;
    const loc1 = LocationModel(id: '1', displayName: 'Loc 1', address: 'A');
    const loc2 = LocationModel(id: '2', displayName: 'Loc 2', address: 'B');

    setUp(() {
    final globalFakeFirestore = FakeFirebaseFirestore();
    RideService.firestoreOverride = globalFakeFirestore;
    DriverAvailabilityService.firestoreOverride = globalFakeFirestore;
    DriverDataService.firestoreOverride = globalFakeFirestore;
    UserProfileService.firestoreOverride = globalFakeFirestore;
      controller = LocationSelectionController();
    });

    test('initial state is empty draft', () {
      expect(controller.draft.pickup, isNull);
      expect(controller.draft.destination, isNull);
    });

    test('setting locations updates draft and notifies listeners', () {
      int notifications = 0;
      controller.addListener(() {
        notifications++;
      });

      controller.setPickup(loc1);
      expect(controller.pickup, loc1);
      expect(notifications, 1);

      controller.setDestination(loc2);
      expect(controller.destination, loc2);
      expect(notifications, 2);
    });

    test('clearing locations updates draft', () {
      controller.setPickup(loc1);
      controller.setDestination(loc2);

      controller.clearPickup();
      expect(controller.pickup, isNull);
      
      controller.clearDestination();
      expect(controller.destination, isNull);
    });

    test('clear resets everything', () {
      controller.setPickup(loc1);
      controller.setDestination(loc2);

      controller.clear();
      expect(controller.pickup, isNull);
      expect(controller.destination, isNull);
    });

    test('validation works as expected', () {
      expect(controller.validate(), 'Please select a pickup location.');

      controller.setPickup(loc1);
      expect(controller.validate(), 'Please select a destination.');

      controller.setDestination(loc1);
      expect(controller.validate(), 'Pickup and destination cannot be the same.');

      controller.setDestination(loc2);
      expect(controller.validate(), isNull);
    });
  });
}

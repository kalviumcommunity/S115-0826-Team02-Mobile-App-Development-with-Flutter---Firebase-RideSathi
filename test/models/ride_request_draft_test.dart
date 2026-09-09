import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/models/location_model.dart';
import 'package:ridesathi/models/ride_request_draft.dart';

void main() {
  group('RideRequestDraft', () {
    const pickup = LocationModel(id: '1', displayName: 'P', address: 'P');
    const dest = LocationModel(id: '2', displayName: 'D', address: 'D');

    test('isComplete returns true only when both locations are set', () {
      expect(const RideRequestDraft().isComplete, false);
      expect(const RideRequestDraft(pickup: pickup).isComplete, false);
      expect(const RideRequestDraft(destination: dest).isComplete, false);
      expect(const RideRequestDraft(pickup: pickup, destination: dest).isComplete, true);
    });

    test('hasIdenticalLocations returns true when pickup and destination are the same', () {
      expect(const RideRequestDraft(pickup: pickup, destination: pickup).hasIdenticalLocations, true);
      expect(const RideRequestDraft(pickup: pickup, destination: dest).hasIdenticalLocations, false);
    });

    test('copyWith updates fields and clear methods set fields to null', () {
      const draft = RideRequestDraft(pickup: pickup, destination: dest);
      
      final clearedPickup = draft.copyWith(clearPickup: true);
      expect(clearedPickup.pickup, isNull);
      expect(clearedPickup.destination, dest);

      final clearedDest = draft.copyWith(clearDestination: true);
      expect(clearedDest.pickup, pickup);
      expect(clearedDest.destination, isNull);
    });
  });
}

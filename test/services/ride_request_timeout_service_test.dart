import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/models/ride_model.dart';
import 'package:ridesathi/models/location_model.dart';
import 'package:ridesathi/services/ride_request_timeout_service.dart';
import 'package:ridesathi/utils/clock.dart';

class FakeClock extends Clock {
  DateTime _now = DateTime(2026, 1, 1, 12, 0);

  @override
  DateTime now() => _now;

  void setTime(DateTime time) {
    _now = time;
  }
}

void main() {
  group('RideRequestTimeoutService', () {
    late RideRequestTimeoutService service;
    late FakeClock clock;
    const timeout = Duration(minutes: 2);

    setUp(() {
      service = const RideRequestTimeoutService();
      clock = FakeClock();
    });

    RideModel createRide({
      required RideStatus status,
      required DateTime createdAt,
    }) {
      return RideModel(
        id: 'ride123',
        riderId: 'rider123',
        pickup: const LocationModel(latitude: 0, longitude: 0, address: ''),
        destination: const LocationModel(latitude: 0, longitude: 0, address: ''),
        vehicleType: VehicleType.autoRickshaw,
        status: status,
        estimatedFare: 100,
        createdAt: createdAt,
        updatedAt: createdAt,
      );
    }

    test('requested ride younger than timeout -> not expired', () {
      final ride = createRide(
        status: RideStatus.requested,
        createdAt: clock.now().subtract(const Duration(minutes: 1)),
      );
      final result = service.isEligibleForTimeout(ride, timeout: timeout, clock: clock);
      expect(result, isFalse);
    });

    test('requested ride exactly at timeout -> expired', () {
      final ride = createRide(
        status: RideStatus.requested,
        createdAt: clock.now().subtract(const Duration(minutes: 2)),
      );
      final result = service.isEligibleForTimeout(ride, timeout: timeout, clock: clock);
      expect(result, isTrue);
    });

    test('requested ride older than timeout -> expired', () {
      final ride = createRide(
        status: RideStatus.requested,
        createdAt: clock.now().subtract(const Duration(minutes: 5)),
      );
      final result = service.isEligibleForTimeout(ride, timeout: timeout, clock: clock);
      expect(result, isTrue);
    });

    test('accepted ride -> not expired (ignores timeout)', () {
      final ride = createRide(
        status: RideStatus.accepted,
        createdAt: clock.now().subtract(const Duration(minutes: 5)),
      );
      final result = service.isEligibleForTimeout(ride, timeout: timeout, clock: clock);
      expect(result, isFalse);
    });

    test('arrived ride -> not expired', () {
      final ride = createRide(
        status: RideStatus.arrived,
        createdAt: clock.now().subtract(const Duration(minutes: 5)),
      );
      final result = service.isEligibleForTimeout(ride, timeout: timeout, clock: clock);
      expect(result, isFalse);
    });

    test('inProgress ride -> not expired', () {
      final ride = createRide(
        status: RideStatus.inProgress,
        createdAt: clock.now().subtract(const Duration(minutes: 5)),
      );
      final result = service.isEligibleForTimeout(ride, timeout: timeout, clock: clock);
      expect(result, isFalse);
    });

    test('completed ride -> not expired', () {
      final ride = createRide(
        status: RideStatus.completed,
        createdAt: clock.now().subtract(const Duration(minutes: 5)),
      );
      final result = service.isEligibleForTimeout(ride, timeout: timeout, clock: clock);
      expect(result, isFalse);
    });

    test('cancelled ride -> not expired', () {
      final ride = createRide(
        status: RideStatus.cancelled,
        createdAt: clock.now().subtract(const Duration(minutes: 5)),
      );
      final result = service.isEligibleForTimeout(ride, timeout: timeout, clock: clock);
      expect(result, isFalse);
    });

    test('rejected ride -> not expired', () {
      final ride = createRide(
        status: RideStatus.rejected,
        createdAt: clock.now().subtract(const Duration(minutes: 5)),
      );
      final result = service.isEligibleForTimeout(ride, timeout: timeout, clock: clock);
      expect(result, isFalse);
    });

    test('timedOut ride -> not expired', () {
      final ride = createRide(
        status: RideStatus.timedOut,
        createdAt: clock.now().subtract(const Duration(minutes: 5)),
      );
      final result = service.isEligibleForTimeout(ride, timeout: timeout, clock: clock);
      expect(result, isFalse);
    });
  });
}

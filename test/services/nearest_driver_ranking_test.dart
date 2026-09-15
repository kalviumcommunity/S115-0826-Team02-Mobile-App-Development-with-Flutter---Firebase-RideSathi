import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/models/candidate_evaluation.dart';
import 'package:ridesathi/models/driver_location.dart';
import 'package:ridesathi/models/driver_operational_data.dart';

DriverOperationalData _makeDriver({
  String id = 'driver_1',
  String name = 'Driver One',
  bool isOnline = true,
  bool isUnionVerified = true,
  DriverLocation? location,
  String? activeRideId,
}) {
  return DriverOperationalData(
    id: id,
    name: name,
    phoneNumber: '9999999999',
    isUnionVerified: isUnionVerified,
    isOnline: isOnline,
    location: location,
    activeRideId: activeRideId,
  );
}

DriverLocation _loc(double lat, double lon) => DriverLocation(
      latitude: lat,
      longitude: lon,
      updatedAt: DateTime.now(),
    );

void main() {
  group('CandidateEvaluation model', () {
    test('eligible evaluation has isEligible == true and no exclusion reason', () {
      final eval = CandidateEvaluation(
        driver: _makeDriver(),
        isEligible: true,
      );
      expect(eval.isEligible, isTrue);
      expect(eval.exclusionReason, isNull);
    });

    test('ineligible evaluation must have exclusion reason', () {
      expect(
        () => CandidateEvaluation(
          driver: _makeDriver(),
          isEligible: false,
          // exclusionReason deliberately omitted
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('distanceKm defaults to null', () {
      final eval = CandidateEvaluation(
        driver: _makeDriver(),
        isEligible: true,
      );
      expect(eval.distanceKm, isNull);
    });

    test('copyWith distanceKm returns updated evaluation', () {
      final eval = CandidateEvaluation(
        driver: _makeDriver(),
        isEligible: true,
      );
      final withDist = eval.copyWith(distanceKm: 1.5);
      expect(withDist.distanceKm, 1.5);
      expect(withDist.isEligible, isTrue);
    });

    test('equality holds when all fields match', () {
      final driver = _makeDriver(location: _loc(12.9, 77.6));
      final a = CandidateEvaluation(driver: driver, isEligible: true, distanceKm: 1.2);
      final b = CandidateEvaluation(driver: driver, isEligible: true, distanceKm: 1.2);
      expect(a, equals(b));
    });

    test('inequality when distanceKm differs', () {
      final driver = _makeDriver(location: _loc(12.9, 77.6));
      final a = CandidateEvaluation(driver: driver, isEligible: true, distanceKm: 1.2);
      final b = CandidateEvaluation(driver: driver, isEligible: true, distanceKm: 3.4);
      expect(a, isNot(equals(b)));
    });
  });

  group('Ranking sort order', () {
    test('eligible candidates appear before excluded ones', () {
      final excluded = CandidateEvaluation(
        driver: _makeDriver(id: 'a', isOnline: false),
        isEligible: false,
        exclusionReason: 'OFFLINE',
        distanceKm: null,
      );
      final eligible = CandidateEvaluation(
        driver: _makeDriver(id: 'b', location: _loc(12.9, 77.6)),
        isEligible: true,
        distanceKm: 2.0,
      );

      final list = [excluded, eligible];
      list.sort((a, b) {
        if (a.isEligible && !b.isEligible) return -1;
        if (!a.isEligible && b.isEligible) return 1;
        return 0;
      });

      expect(list.first.isEligible, isTrue);
    });

    test('nearest eligible driver appears first', () {
      final far = CandidateEvaluation(
        driver: _makeDriver(id: 'far', location: _loc(13.0, 77.7)),
        isEligible: true,
        distanceKm: 5.0,
      );
      final near = CandidateEvaluation(
        driver: _makeDriver(id: 'near', location: _loc(12.92, 77.61)),
        isEligible: true,
        distanceKm: 0.5,
      );

      final list = [far, near];
      list.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));

      expect(list.first.driver.id, 'near');
    });

    test('tie-breaking by driver UID ascending', () {
      final evalA = CandidateEvaluation(
        driver: _makeDriver(id: 'abc123', location: _loc(12.9, 77.6)),
        isEligible: true,
        distanceKm: 1.5,
      );
      final evalB = CandidateEvaluation(
        driver: _makeDriver(id: 'def456', location: _loc(12.9, 77.6)),
        isEligible: true,
        distanceKm: 1.5,
      );

      final list = [evalB, evalA];
      list.sort((a, b) {
        final distCompare = a.distanceKm!.compareTo(b.distanceKm!);
        if (distCompare != 0) return distCompare;
        return a.driver.id.compareTo(b.driver.id);
      });

      expect(list.first.driver.id, 'abc123');
    });

    test('single candidate produces list of one', () {
      final only = CandidateEvaluation(
        driver: _makeDriver(location: _loc(12.9, 77.6)),
        isEligible: true,
        distanceKm: 0.8,
      );
      final list = [only];
      list.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
      expect(list.length, 1);
      expect(list.first.driver.id, 'driver_1');
    });

    test('empty candidate list sorts safely', () {
      final list = <CandidateEvaluation>[];
      list.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
      expect(list, isEmpty);
    });
  });
}

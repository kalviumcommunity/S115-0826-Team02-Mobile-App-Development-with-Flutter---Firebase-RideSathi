import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/utils/distance_calculator.dart';

void main() {
  group('DistanceCalculator', () {
    // ── Distance correctness ────────────────────────────────────────────────

    test('same coordinates return 0 km', () {
      final dist = DistanceCalculator.calculateDistanceKm(12.9, 77.6, 12.9, 77.6);
      expect(dist, 0.0);
    });

    test('Bangalore to Mumbai is approximately 840–850 km (straight-line)', () {
      // Bangalore: ~12.9716° N, 77.5946° E
      // Mumbai:    ~19.0760° N, 72.8777° E
      final dist = DistanceCalculator.calculateDistanceKm(12.9716, 77.5946, 19.0760, 72.8777);
      expect(dist, greaterThan(800));
      expect(dist, lessThan(900));
    });

    test('distance is symmetric (A→B == B→A)', () {
      final ab = DistanceCalculator.calculateDistanceKm(10.0, 20.0, 30.0, 40.0);
      final ba = DistanceCalculator.calculateDistanceKm(30.0, 40.0, 10.0, 20.0);
      expect(ab, closeTo(ba, 0.0001));
    });

    test('distance is never negative', () {
      final dist = DistanceCalculator.calculateDistanceKm(0, 0, 90, 180);
      expect(dist, greaterThanOrEqualTo(0.0));
    });

    test('north pole to south pole is approximately 20,000 km', () {
      final dist = DistanceCalculator.calculateDistanceKm(90, 0, -90, 0);
      expect(dist, closeTo(20015.0, 10.0));
    });

    // ── Coordinate validation ───────────────────────────────────────────────

    test('NaN latitude throws ArgumentError', () {
      expect(
        () => DistanceCalculator.calculateDistanceKm(double.nan, 0, 0, 0),
        throwsArgumentError,
      );
    });

    test('NaN longitude throws ArgumentError', () {
      expect(
        () => DistanceCalculator.calculateDistanceKm(0, double.nan, 0, 0),
        throwsArgumentError,
      );
    });

    test('Infinity latitude throws ArgumentError', () {
      expect(
        () => DistanceCalculator.calculateDistanceKm(double.infinity, 0, 0, 0),
        throwsArgumentError,
      );
    });

    test('Infinity longitude throws ArgumentError', () {
      expect(
        () => DistanceCalculator.calculateDistanceKm(0, double.infinity, 0, 0),
        throwsArgumentError,
      );
    });

    test('latitude > 90 throws ArgumentError', () {
      expect(
        () => DistanceCalculator.calculateDistanceKm(91, 0, 0, 0),
        throwsArgumentError,
      );
    });

    test('latitude < -90 throws ArgumentError', () {
      expect(
        () => DistanceCalculator.calculateDistanceKm(-91, 0, 0, 0),
        throwsArgumentError,
      );
    });

    test('longitude > 180 throws ArgumentError', () {
      expect(
        () => DistanceCalculator.calculateDistanceKm(0, 181, 0, 0),
        throwsArgumentError,
      );
    });

    test('longitude < -180 throws ArgumentError', () {
      expect(
        () => DistanceCalculator.calculateDistanceKm(0, -181, 0, 0),
        throwsArgumentError,
      );
    });

    test('boundary values (90, 180) are valid', () {
      expect(
        () => DistanceCalculator.calculateDistanceKm(90, 180, -90, -180),
        returnsNormally,
      );
    });

    // ── Precision / rounding ────────────────────────────────────────────────

    test('returns full precision (not pre-rounded)', () {
      final dist = DistanceCalculator.calculateDistanceKm(12.9716, 77.5946, 13.0, 77.6);
      // Should not be a round integer
      expect(dist % 1, isNot(0.0));
    });
  });
}

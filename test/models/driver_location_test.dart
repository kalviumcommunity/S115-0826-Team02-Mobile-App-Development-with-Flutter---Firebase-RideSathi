import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/models/driver_location.dart';

void main() {
  group('DriverLocation', () {
    final now = DateTime.now();

    test('Validates correct latitude and longitude', () {
      final loc =
          DriverLocation(latitude: 19.9975, longitude: 73.7898, updatedAt: now);
      expect(loc.isValid, isTrue);
    });

    test('Identifies invalid latitude via constructor assert', () {
      expect(
          () => DriverLocation(
              latitude: 91.0, longitude: 73.7898, updatedAt: now),
          throwsAssertionError);
      expect(
          () => DriverLocation(
              latitude: -91.0, longitude: 73.7898, updatedAt: now),
          throwsAssertionError);
    });

    test('Identifies invalid longitude via constructor assert', () {
      expect(
          () => DriverLocation(
              latitude: 19.9975, longitude: 181.0, updatedAt: now),
          throwsAssertionError);
      expect(
          () => DriverLocation(
              latitude: 19.9975, longitude: -181.0, updatedAt: now),
          throwsAssertionError);
    });

    test('Identifies NaN and infinite via constructor assert', () {
      expect(
          () => DriverLocation(
              latitude: double.nan, longitude: 73.7898, updatedAt: now),
          throwsAssertionError);
      expect(
          () => DriverLocation(
              latitude: 19.9975, longitude: double.infinity, updatedAt: now),
          throwsAssertionError);
    });

    test('Serializes correctly to Map', () {
      final loc =
          DriverLocation(latitude: 19.9975, longitude: 73.7898, updatedAt: now);
      final map = loc.toMap();

      expect(map['latitude'], equals(19.9975));
      expect(map['longitude'], equals(73.7898));
      expect(map['updatedAt'], isNotNull);
    });

    test('Deserializes correctly from Map', () {
      final map = {
        'latitude': 19.9975,
        'longitude': 73.7898,
      };

      final loc = DriverLocation.fromMap(map);

      expect(loc.latitude, equals(19.9975));
      expect(loc.longitude, equals(73.7898));
      expect(loc.updatedAt, isA<DateTime>());
    });

    test('fromMap throws FormatException for missing coordinates', () {
      expect(() => DriverLocation.fromMap({}), throwsFormatException);
      expect(
          () => DriverLocation.fromMap({'latitude': 19.9975}),
          throwsFormatException);
    });

    test('fromMap throws FormatException for out of bound latitude/longitude',
        () {
      expect(
          () => DriverLocation.fromMap({'latitude': 99.0, 'longitude': 70.0}),
          throwsFormatException);
      expect(
          () => DriverLocation.fromMap({'latitude': 19.0, 'longitude': 200.0}),
          throwsFormatException);
    });
  });
}

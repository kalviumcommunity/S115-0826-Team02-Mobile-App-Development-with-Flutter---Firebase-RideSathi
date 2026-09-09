import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/services/location_service.dart';
import 'package:ridesathi/services/service_exception.dart';

void main() {
  group('MockLocationService', () {
    late MockLocationService service;

    setUp(() {
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

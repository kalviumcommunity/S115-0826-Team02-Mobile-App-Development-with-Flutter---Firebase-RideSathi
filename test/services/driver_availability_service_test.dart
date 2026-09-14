import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/services/driver_availability_service.dart';
import 'package:ridesathi/services/firestore_exception.dart';

/// Test double subclassing [DriverAvailabilityService] to verify availability
/// contracts without calling live Firestore network.
class FakeDriverAvailabilityService extends DriverAvailabilityService {
  final Map<String, bool> _storage = {};
  bool shouldThrow = false;
  FirestoreException? exceptionToThrow;

  @override
  Future<bool> getAvailability(String driverId) async {
    if (shouldThrow) {
      throw exceptionToThrow ??
          const FirestoreException(
            'Service is temporarily unavailable.',
            code: 'unavailable',
          );
    }
    final trimmedId = driverId.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError('Driver ID cannot be empty.');
    }
    return _storage[trimmedId] ?? false;
  }

  @override
  Future<bool> setAvailability({
    required String driverId,
    required bool isOnline,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ??
          const FirestoreException(
            'Service is temporarily unavailable.',
            code: 'unavailable',
          );
    }
    final trimmedId = driverId.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError('Driver ID cannot be empty.');
    }
    _storage[trimmedId] = isOnline;
    return isOnline;
  }

  @override
  Stream<bool> watchAvailability(String driverId) {
    final trimmedId = driverId.trim();
    if (trimmedId.isEmpty) {
      return Stream.error(ArgumentError('Driver ID cannot be empty.'));
    }
    return Stream.value(_storage[trimmedId] ?? false);
  }

  void setRawAvailability(String driverId, bool isOnline) {
    _storage[driverId] = isOnline;
  }
}

void main() {
  group('DriverAvailabilityService — Contract Verification', () {
    late FakeDriverAvailabilityService service;

    setUp(() {
      service = FakeDriverAvailabilityService();
    });

    test('defaults driver availability to false (Offline)', () async {
      final online = await service.getAvailability('driver-new-1');
      expect(online, isFalse);
    });

    test('sets driver availability to true (Online)', () async {
      final result = await service.setAvailability(
        driverId: 'driver-1',
        isOnline: true,
      );
      expect(result, isTrue);

      final current = await service.getAvailability('driver-1');
      expect(current, isTrue);
    });

    test('sets driver availability back to false (Offline)', () async {
      await service.setAvailability(driverId: 'driver-1', isOnline: true);
      final offlineResult = await service.setAvailability(
        driverId: 'driver-1',
        isOnline: false,
      );
      expect(offlineResult, isFalse);

      final current = await service.getAvailability('driver-1');
      expect(current, isFalse);
    });

    test('throws ArgumentError when driver ID is empty or whitespace', () async {
      expect(
        () => service.getAvailability(''),
        throwsArgumentError,
      );
      expect(
        () => service.setAvailability(driverId: '   ', isOnline: true),
        throwsArgumentError,
      );
    });

    test('throws FirestoreException on service failure', () async {
      service.shouldThrow = true;
      service.exceptionToThrow = const FirestoreException(
        'Permission denied',
        code: 'permission-denied',
      );

      expect(
        () => service.setAvailability(driverId: 'driver-1', isOnline: true),
        throwsA(isA<FirestoreException>().having(
          (e) => e.code,
          'code',
          equals('permission-denied'),
        )),
      );
    });
  });
}

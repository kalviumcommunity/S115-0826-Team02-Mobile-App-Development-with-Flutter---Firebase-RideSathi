import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/services/firestore_exception.dart';
import 'package:ridesathi/services/user_profile_service.dart';

/// Test double subclassing [UserProfileService] to verify profile persistence
/// contracts and controller integrations without calling live Firestore network.
class FakeUserProfileService extends UserProfileService {
  final Map<String, Map<String, dynamic>> _storage = {};
  bool shouldThrow = false;
  FirestoreException? exceptionToThrow;

  @override
  Future<void> createRiderProfile(UserModel user) async {
    if (shouldThrow) {
      throw exceptionToThrow ??
          const FirestoreException(
            'Service is temporarily unavailable. Please try again later.',
            code: 'unavailable',
          );
    }
    final data = user.toMap();
    data['createdAt'] = DateTime.now().toIso8601String();
    data['updatedAt'] = DateTime.now().toIso8601String();
    _storage[user.id] = data;
  }

  @override
  Future<void> createDriverProfile(UserModel user) async {
    if (shouldThrow) {
      throw exceptionToThrow ??
          const FirestoreException(
            'Service is temporarily unavailable. Please try again later.',
            code: 'unavailable',
          );
    }
    final data = user.toMap();
    data['createdAt'] = DateTime.now().toIso8601String();
    data['updatedAt'] = DateTime.now().toIso8601String();
    _storage[user.id] = data;
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    if (shouldThrow) {
      throw exceptionToThrow ??
          const FirestoreException(
            'Service is temporarily unavailable. Please try again later.',
            code: 'unavailable',
          );
    }
    final data = _storage[uid];
    if (data == null) return null;
    try {
      return UserModel.fromMap(data);
    } on FormatException catch (_) {
      throw const FirestoreException(
        'User profile data is corrupted or contains an invalid role.',
        code: 'invalid-profile',
      );
    }
  }

  void setRawData(String uid, Map<String, dynamic> data) {
    _storage[uid] = data;
  }

  bool hasProfile(String uid) => _storage.containsKey(uid);
  Map<String, dynamic>? getRawData(String uid) => _storage[uid];
}

void main() {
  group('UserProfileService — Contract & In-Memory Verification', () {
    late FakeUserProfileService profileService;

    setUp(() {
      profileService = FakeUserProfileService();
    });

    test('creates rider profile using UID as document identifier', () async {
      final user = UserModel(
        id: 'rider-uid-12345',
        name: 'Priya Patel',
        phoneNumber: '+919876543210',
        email: 'priya@ridesathi.com',
        role: UserRole.rider,
        isUnionVerified: false,
        createdAt: DateTime.now(),
      );

      await profileService.createRiderProfile(user);

      expect(profileService.hasProfile('rider-uid-12345'), isTrue);

      final retrieved = await profileService.getUserProfile('rider-uid-12345');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('rider-uid-12345'));
      expect(retrieved.name, equals('Priya Patel'));
      expect(retrieved.phoneNumber, equals('+919876543210'));
      expect(retrieved.email, equals('priya@ridesathi.com'));
      expect(retrieved.role, equals(UserRole.rider));
      expect(retrieved.isUnionVerified, isFalse);
    });

    test('verifies rider role is explicitly set to UserRole.rider', () async {
      final user = UserModel(
        id: 'rider-abc',
        name: 'Rohan Gupta',
        phoneNumber: '9811223344',
        email: 'rohan@example.com',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      await profileService.createRiderProfile(user);
      final raw = profileService.getRawData('rider-abc');
      expect(raw, isNotNull);
      expect(raw!['role'], equals('rider'));
      expect(raw['id'], equals('rider-abc'));
    });

    test('creates driver profile using UID as document identifier', () async {
      final user = UserModel(
        id: 'driver-uid-999',
        name: 'Amit Driver',
        phoneNumber: '+919999900000',
        email: 'amit@ridesathi.com',
        role: UserRole.driver,
        vehicleInfo: 'Auto KA-01',
        isUnionVerified: false,
        createdAt: DateTime.now(),
      );

      await profileService.createDriverProfile(user);

      expect(profileService.hasProfile('driver-uid-999'), isTrue);

      final retrieved = await profileService.getUserProfile('driver-uid-999');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('driver-uid-999'));
      expect(retrieved.name, equals('Amit Driver'));
      expect(retrieved.role, equals(UserRole.driver));
      expect(retrieved.vehicleInfo, equals('Auto KA-01'));
    });

    test('verifies timestamps are populated on creation', () async {
      final user = UserModel(
        id: 'rider-time-test',
        name: 'Ananya Sen',
        phoneNumber: '+919876501234',
        email: 'ananya@ridesathi.com',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      await profileService.createRiderProfile(user);
      final raw = profileService.getRawData('rider-time-test');
      expect(raw!['createdAt'], isNotNull);
      expect(raw['updatedAt'], isNotNull);
    });

    test('throws FirestoreException when service write fails', () async {
      profileService.shouldThrow = true;
      profileService.exceptionToThrow = const FirestoreException(
        'You do not have permission to perform this action.',
        code: 'permission-denied',
      );

      final user = UserModel(
        id: 'fail-rider',
        name: 'Test Rider',
        phoneNumber: '9999999999',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      expect(
        () => profileService.createRiderProfile(user),
        throwsA(isA<FirestoreException>().having(
          (e) => e.code,
          'code',
          equals('permission-denied'),
        )),
      );
    });

    test('returns null when profile does not exist', () async {
      final result = await profileService.getUserProfile('non-existent-uid');
      expect(result, isNull);
    });

    test('throws FirestoreException when profile has an invalid role', () async {
      profileService.setRawData('corrupt-uid', {
        'id': 'corrupt-uid',
        'name': 'Corrupt User',
        'phoneNumber': '1234567890',
        'role': 'super_admin_unauthorized',
      });

      expect(
        () => profileService.getUserProfile('corrupt-uid'),
        throwsA(isA<FirestoreException>().having(
          (e) => e.code,
          'code',
          equals('invalid-profile'),
        )),
      );
    });
  });
}

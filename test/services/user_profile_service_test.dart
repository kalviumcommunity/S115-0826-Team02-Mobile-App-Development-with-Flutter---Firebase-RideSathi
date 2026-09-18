import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ridesathi/services/ride_service.dart';
import 'package:ridesathi/services/driver_availability_service.dart';
import 'package:ridesathi/services/driver_data_service.dart';
import 'package:ridesathi/services/user_profile_service.dart';
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

  @override
  Future<UserModel> updateProfile({
    required String uid,
    required Map<String, dynamic> updates,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ??
          const FirestoreException(
            'Service is temporarily unavailable. Please try again later.',
            code: 'unavailable',
          );
    }
    final trimmedUid = uid.trim();
    if (trimmedUid.isEmpty) {
      throw ArgumentError('UID cannot be empty.');
    }
    if (updates.isEmpty) {
      throw ArgumentError('Updates map cannot be empty.');
    }

    for (final key in updates.keys) {
      if (UserProfileService.protectedKeys.contains(key)) {
        throw ArgumentError('Cannot update immutable or protected field "$key".');
      }
      if (!UserProfileService.allowedUpdateKeys.contains(key)) {
        throw ArgumentError('Field "$key" is not permitted for profile update.');
      }
    }

    final existing = _storage[trimmedUid];
    if (existing == null) {
      throw const FirestoreException(
        'User profile not found after update.',
        code: 'not-found',
      );
    }

    final updated = Map<String, dynamic>.from(existing);
    for (final entry in updates.entries) {
      updated[entry.key] = entry.value;
    }
    updated['updatedAt'] = DateTime.now().toIso8601String();
    _storage[trimmedUid] = updated;

    return UserModel.fromMap(updated);
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
    final globalFakeFirestore = FakeFirebaseFirestore();
    RideService.firestoreOverride = globalFakeFirestore;
    DriverAvailabilityService.firestoreOverride = globalFakeFirestore;
    DriverDataService.firestoreOverride = globalFakeFirestore;
    UserProfileService.firestoreOverride = globalFakeFirestore;
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

    group('updateProfile', () {
      setUp(() async {
        await profileService.createRiderProfile(UserModel(
          id: 'rider-up-1',
          name: 'Original Rider',
          phoneNumber: '+911111111111',
          email: 'rider1@ridesathi.com',
          role: UserRole.rider,
          createdAt: DateTime.now(),
        ));

        await profileService.createDriverProfile(UserModel(
          id: 'driver-up-1',
          name: 'Original Driver',
          phoneNumber: '+912222222222',
          email: 'driver1@ridesathi.com',
          role: UserRole.driver,
          vehicleInfo: 'Auto DL-01-AB-1234',
          createdAt: DateTime.now(),
        ));
      });

      test('updates permitted mutable fields (name, phone) on rider profile', () async {
        final updated = await profileService.updateProfile(
          uid: 'rider-up-1',
          updates: {
            'name': 'Updated Rider',
            'phoneNumber': '+919999988888',
          },
        );

        expect(updated.name, equals('Updated Rider'));
        expect(updated.phoneNumber, equals('+919999988888'));
        expect(updated.email, equals('rider1@ridesathi.com'));
        expect(updated.role, equals(UserRole.rider));
      });

      test('updates vehicleInfo on driver profile', () async {
        final updated = await profileService.updateProfile(
          uid: 'driver-up-1',
          updates: {
            'vehicleInfo': 'Cab DL-04-XY-9999',
          },
        );

        expect(updated.vehicleInfo, equals('Cab DL-04-XY-9999'));
        expect(updated.name, equals('Original Driver'));
        expect(updated.role, equals(UserRole.driver));
      });

      test('throws ArgumentError when uid is empty or whitespace', () async {
        expect(
          () => profileService.updateProfile(uid: '', updates: {'name': 'Test'}),
          throwsArgumentError,
        );
        expect(
          () => profileService.updateProfile(uid: '   ', updates: {'name': 'Test'}),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError when updates map is empty', () async {
        expect(
          () => profileService.updateProfile(uid: 'rider-up-1', updates: {}),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError when attempting to update immutable field "id"', () async {
        expect(
          () => profileService.updateProfile(
            uid: 'rider-up-1',
            updates: {'id': 'hacked-id'},
          ),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError when attempting to update immutable field "email"', () async {
        expect(
          () => profileService.updateProfile(
            uid: 'rider-up-1',
            updates: {'email': 'hacked@ridesathi.com'},
          ),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError when attempting to update immutable field "role"', () async {
        expect(
          () => profileService.updateProfile(
            uid: 'rider-up-1',
            updates: {'role': 'driver'},
          ),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError when attempting to update protected field "isUnionVerified"', () async {
        expect(
          () => profileService.updateProfile(
            uid: 'driver-up-1',
            updates: {'isUnionVerified': true},
          ),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError when attempting to update immutable field "createdAt"', () async {
        expect(
          () => profileService.updateProfile(
            uid: 'rider-up-1',
            updates: {'createdAt': DateTime.now().toIso8601String()},
          ),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError when attempting to update unwhitelisted arbitrary fields', () async {
        expect(
          () => profileService.updateProfile(
            uid: 'rider-up-1',
            updates: {'isAdmin': true},
          ),
          throwsArgumentError,
        );
      });

      test('updates updatedAt timestamp on successful save', () async {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final updated = await profileService.updateProfile(
          uid: 'rider-up-1',
          updates: {'name': 'New Name'},
        );

        expect(updated.updatedAt, isNotNull);
        expect(updated.updatedAt!.isAfter(before), isTrue);
      });

      test('throws FirestoreException when document does not exist', () async {
        expect(
          () => profileService.updateProfile(
            uid: 'non-existent-uid',
            updates: {'name': 'Ghost'},
          ),
          throwsA(isA<FirestoreException>().having(
            (e) => e.code,
            'code',
            equals('not-found'),
          )),
        );
      });

      test('throws FirestoreException on service failure', () async {
        profileService.shouldThrow = true;
        profileService.exceptionToThrow = const FirestoreException(
          'Network unavailable',
          code: 'unavailable',
        );

        expect(
          () => profileService.updateProfile(
            uid: 'rider-up-1',
            updates: {'name': 'Network Fail'},
          ),
          throwsA(isA<FirestoreException>().having(
            (e) => e.code,
            'code',
            equals('unavailable'),
          )),
        );
      });

      test('updateProfileFields convenience wrapper properly applies updates', () async {
        final updated = await profileService.updateProfileFields(
          uid: 'rider-up-1',
          name: 'Convenience Name',
          phoneNumber: '+918888877777',
        );

        expect(updated.name, equals('Convenience Name'));
        expect(updated.phoneNumber, equals('+918888877777'));
      });
    });
  });
}


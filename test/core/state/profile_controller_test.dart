import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ridesathi/services/ride_service.dart';
import 'package:ridesathi/services/driver_availability_service.dart';
import 'package:ridesathi/services/driver_data_service.dart';
import 'package:ridesathi/services/user_profile_service.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/auth_state.dart';
import 'package:ridesathi/core/state/profile_controller.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/services/auth_service.dart';
import 'package:ridesathi/services/firestore_exception.dart';
import 'package:ridesathi/services/user_profile_service.dart';

class _FakeAuthService extends AuthService {
  UserModel? _currentAuthUser;
  final StreamController<UserModel?> _streamController =
      StreamController<UserModel?>.broadcast();

  _FakeAuthService({UserModel? initialUser}) : _currentAuthUser = initialUser;

  @override
  UserModel? get currentAuthUser => _currentAuthUser;

  @override
  Stream<UserModel?> get onAuthStateChanged => _streamController.stream;

  @override
  Future<void> userSignOut() async {
    _currentAuthUser = null;
    _streamController.add(null);
  }
}

class _FakeUserProfileService extends UserProfileService {
  final Map<String, UserModel> profiles = {};
  int updateCallCount = 0;
  int getProfileCallCount = 0;
  bool shouldThrow = false;
  FirestoreException? exceptionToThrow;
  Completer<UserModel>? updateCompleter;

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    getProfileCallCount++;
    if (shouldThrow) {
      throw exceptionToThrow ??
          const FirestoreException(
            'Service unavailable',
            code: 'unavailable',
          );
    }
    return profiles[uid];
  }

  @override
  Future<UserModel> updateProfile({
    required String uid,
    required Map<String, dynamic> updates,
  }) async {
    updateCallCount++;
    if (updateCompleter != null) {
      return updateCompleter!.future;
    }
    if (shouldThrow) {
      throw exceptionToThrow ??
          const FirestoreException(
            'Failed to update profile',
            code: 'unavailable',
          );
    }

    final current = profiles[uid];
    if (current == null) {
      throw const FirestoreException('Not found', code: 'not-found');
    }

    final updated = current.copyWith(
      name: updates['name'] as String? ?? current.name,
      phoneNumber: updates['phoneNumber'] as String? ?? current.phoneNumber,
      vehicleInfo: updates.containsKey('vehicleInfo')
          ? updates['vehicleInfo'] as String?
          : current.vehicleInfo,
      updatedAt: DateTime.now(),
    );
    profiles[uid] = updated;
    return updated;
  }
}

void main() {
  group('ProfileController', () {
    late _FakeAuthService authService;
    late _FakeUserProfileService profileService;
    late AuthController authController;

    final riderUser = UserModel(
      id: 'rider-123',
      name: 'Aarav Sharma',
      phoneNumber: '+919876543210',
      email: 'aarav@ridesathi.com',
      role: UserRole.rider,
      isUnionVerified: false,
      createdAt: DateTime.parse('2026-01-01T10:00:00Z'),
    );

    final driverUser = UserModel(
      id: 'driver-456',
      name: 'Sunil Kumar',
      phoneNumber: '+919876500000',
      email: 'sunil@ridesathi.com',
      role: UserRole.driver,
      vehicleInfo: 'Auto DL-01-AB-1234',
      isUnionVerified: true,
      createdAt: DateTime.parse('2026-01-01T10:00:00Z'),
    );

    setUp(() {
    final globalFakeFirestore = FakeFirebaseFirestore();
    RideService.firestoreOverride = globalFakeFirestore;
    DriverAvailabilityService.firestoreOverride = globalFakeFirestore;
    DriverDataService.firestoreOverride = globalFakeFirestore;
    UserProfileService.firestoreOverride = globalFakeFirestore;
      authService = _FakeAuthService(initialUser: riderUser);
      profileService = _FakeUserProfileService();
      profileService.profiles[riderUser.id] = riderUser;
      profileService.profiles[driverUser.id] = driverUser;

      authController = AuthController(
        authService: authService,
        userProfileService: profileService,
        initialState: AuthState.authenticated(riderUser),
      );
    });

    tearDown(() {
      authController.dispose();
      AuthController.resetInstance();
    });

    test('initial state correctly reflects current authenticated user', () {
      final controller = ProfileController(
        authController: authController,
        userProfileService: profileService,
      );

      expect(controller.state.isSuccess, isTrue);
      expect(controller.currentUser?.id, equals('rider-123'));
      expect(controller.name, equals('Aarav Sharma'));
      expect(controller.phoneNumber, equals('+919876543210'));
      expect(controller.vehicleInfo, isNull);
      expect(controller.isDirty, isFalse);
      expect(controller.isSaving, isFalse);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('isDirty returns false initially and true after field change', () {
      final controller = ProfileController(
        authController: authController,
        userProfileService: profileService,
      );

      expect(controller.isDirty, isFalse);

      controller.setName('Aarav S.');
      expect(controller.isDirty, isTrue);

      controller.setName('Aarav Sharma');
      expect(controller.isDirty, isFalse);

      controller.setPhoneNumber('+919999999999');
      expect(controller.isDirty, isTrue);
    });

    test('isDirty returns false after resetting form to original values', () {
      final controller = ProfileController(
        authController: authController,
        userProfileService: profileService,
      );

      controller.setName('Changed Name');
      controller.setPhoneNumber('+919999999999');
      expect(controller.isDirty, isTrue);

      controller.resetForm();
      expect(controller.isDirty, isFalse);
      expect(controller.name, equals('Aarav Sharma'));
      expect(controller.phoneNumber, equals('+919876543210'));
    });

    test('saveProfile updates name and phoneNumber on rider profile', () async {
      final controller = ProfileController(
        authController: authController,
        userProfileService: profileService,
      );

      controller.setName('Aarav Verma');
      controller.setPhoneNumber('+919811122233');

      final success = await controller.saveProfile();
      expect(success, isTrue);
      expect(controller.state.isSuccess, isTrue);
      expect(controller.isDirty, isFalse);
      expect(controller.currentUser?.name, equals('Aarav Verma'));
      expect(controller.currentUser?.phoneNumber, equals('+919811122233'));

      // AuthController should be synchronized
      expect(authController.currentUser?.name, equals('Aarav Verma'));
      expect(authController.currentUser?.phoneNumber, equals('+919811122233'));
      expect(authController.currentUser?.email, equals('aarav@ridesathi.com'));
      expect(authController.currentUser?.role, equals(UserRole.rider));
    });

    test('saveProfile updates vehicleInfo on driver profile', () async {
      authController.updateState(AuthState.authenticated(driverUser));

      final controller = ProfileController(
        authController: authController,
        userProfileService: profileService,
      );

      expect(controller.vehicleInfo, equals('Auto DL-01-AB-1234'));

      controller.setVehicleInfo('Electric Auto DL-02-EE-5678');
      expect(controller.isDirty, isTrue);

      final success = await controller.saveProfile();
      expect(success, isTrue);
      expect(controller.state.isSuccess, isTrue);
      expect(controller.isDirty, isFalse);
      expect(
        controller.currentUser?.vehicleInfo,
        equals('Electric Auto DL-02-EE-5678'),
      );

      // AuthController should be synchronized
      expect(
        authController.currentUser?.vehicleInfo,
        equals('Electric Auto DL-02-EE-5678'),
      );
      expect(authController.currentUser?.role, equals(UserRole.driver));
      expect(authController.currentUser?.isUnionVerified, isTrue);
    });

    test('saveProfile validates fields before attempting network save', () async {
      final controller = ProfileController(
        authController: authController,
        userProfileService: profileService,
      );

      // Invalid name
      controller.setName('');
      var success = await controller.saveProfile();
      expect(success, isFalse);
      expect(controller.errorMessage, isNotNull);
      expect(profileService.updateCallCount, equals(0));

      // Reset and test invalid phone
      controller.resetForm();
      controller.setPhoneNumber('invalid-phone');
      success = await controller.saveProfile();
      expect(success, isFalse);
      expect(controller.errorMessage, isNotNull);
      expect(profileService.updateCallCount, equals(0));

      // Test driver with invalid vehicle info
      authController.updateState(AuthState.authenticated(driverUser));
      final driverController = ProfileController(
        authController: authController,
        userProfileService: profileService,
      );
      driverController.setVehicleInfo('');
      success = await driverController.saveProfile();
      expect(success, isFalse);
      expect(driverController.errorMessage, isNotNull);
      expect(profileService.updateCallCount, equals(0));
    });

    test('saveProfile rejects save when user is not authenticated', () async {
      authController.updateState(const AuthState.unauthenticated());

      final controller = ProfileController(
        authController: authController,
        userProfileService: profileService,
        initialUser: riderUser,
      );

      controller.setName('New Name');
      final success = await controller.saveProfile();

      expect(success, isFalse);
      expect(controller.errorMessage, contains('signed in'));
      expect(profileService.updateCallCount, equals(0));
    });

    test('saveProfile does not update AuthController if session generation changes during save', () async {
      final controller = ProfileController(
        authController: authController,
        userProfileService: profileService,
      );

      controller.setName('Stale Name');
      profileService.updateCompleter = Completer<UserModel>();

      final saveFuture = controller.saveProfile();

      // Bump session generation while save is in flight (e.g. by re-authenticating or signing out)
      authController.signOut();

      // Now complete the pending profile update
      final updatedRider = riderUser.copyWith(name: 'Stale Name');
      profileService.updateCompleter!.complete(updatedRider);

      final success = await saveFuture;

      expect(success, isFalse);
      // AuthController should remain unauthenticated, not resurrected!
      expect(authController.isAuthenticated, isFalse);
      expect(authController.currentUser, isNull);
    });

    test('saveProfile does not update AuthController if user logs out during save', () async {
      final controller = ProfileController(
        authController: authController,
        userProfileService: profileService,
      );

      controller.setName('Logged Out Name');
      profileService.updateCompleter = Completer<UserModel>();

      final saveFuture = controller.saveProfile();

      // User initiates sign out while save is in flight
      await authController.signOut();
      expect(authController.isAuthenticated, isFalse);

      // Now complete the profile service write
      profileService.updateCompleter!.complete(
        riderUser.copyWith(name: 'Logged Out Name'),
      );

      final success = await saveFuture;

      expect(success, isFalse);
      // Verified: Session was NOT resurrected!
      expect(authController.isAuthenticated, isFalse);
      expect(authController.currentUser, isNull);
    });

    test('saveProfile handles FirestoreException gracefully and exposes error state', () async {
      profileService.shouldThrow = true;
      profileService.exceptionToThrow = const FirestoreException(
        'Permission denied for profile update.',
        code: 'permission-denied',
      );

      final controller = ProfileController(
        authController: authController,
        userProfileService: profileService,
      );

      controller.setName('Perm Denied');
      final success = await controller.saveProfile();

      expect(success, isFalse);
      expect(controller.state.isError, isTrue);
      expect(controller.errorMessage, equals('Permission denied for profile update.'));
      expect(controller.isSaving, isFalse);
      expect(authController.currentUser?.name, equals('Aarav Sharma'));
    });

    test('saveProfile with no changes returns true immediately without calling service', () async {
      final controller = ProfileController(
        authController: authController,
        userProfileService: profileService,
      );

      expect(controller.isDirty, isFalse);

      final success = await controller.saveProfile();
      expect(success, isTrue);
      expect(profileService.updateCallCount, equals(0));
    });

    test('refreshProfile fetches fresh profile from Firestore and syncs state', () async {
      final controller = ProfileController(
        authController: authController,
        userProfileService: profileService,
      );

      // External update occurs in Firestore
      profileService.profiles[riderUser.id] = riderUser.copyWith(
        name: 'Aarav Backend Update',
      );

      final refreshed = await controller.refreshProfile();

      expect(refreshed, isNotNull);
      expect(refreshed!.name, equals('Aarav Backend Update'));
      expect(controller.name, equals('Aarav Backend Update'));
      expect(authController.currentUser?.name, equals('Aarav Backend Update'));
    });
  });
}

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/auth_state.dart';
import 'package:ridesathi/core/state/driver_availability_controller.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/services/firestore_exception.dart';
import '../../services/driver_availability_service_test.dart';

void main() {
  late AuthController authController;
  late FakeDriverAvailabilityService fakeService;

  final dummyDriver = UserModel(
    id: 'driver-123',
    name: 'Vikram Driver',
    phoneNumber: '+919988776655',
    role: UserRole.driver,
    isUnionVerified: true,
    isOnline: false,
    createdAt: DateTime.now(),
  );

  final dummyRider = UserModel(
    id: 'rider-456',
    name: 'Ramesh Rider',
    phoneNumber: '+919876543210',
    role: UserRole.rider,
    createdAt: DateTime.now(),
  );

  setUp(() {
    AuthController.resetInstance();
    fakeService = FakeDriverAvailabilityService();
    authController = AuthController(
      initialState: AuthState.authenticated(dummyDriver),
    );
  });

  tearDown(() {
    AuthController.resetInstance();
  });

  group('DriverAvailabilityController — Basic Operations', () {
    test('initializes with offline availability state', () {
      final controller = DriverAvailabilityController(
        authController: authController,
        availabilityService: fakeService,
      );

      expect(controller.isOnline, isFalse);
      expect(controller.isUpdating, isFalse);
      expect(controller.state.isSuccess, isTrue);
    });

    test('toggles availability from Offline to Online', () async {
      final controller = DriverAvailabilityController(
        authController: authController,
        availabilityService: fakeService,
      );

      final success = await controller.setOnline();
      expect(success, isTrue);
      expect(controller.isOnline, isTrue);
      expect(authController.currentUser?.isOnline, isTrue);
    });

    test('toggles availability from Online to Offline', () async {
      final controller = DriverAvailabilityController(
        authController: authController,
        availabilityService: fakeService,
        initialOnline: true,
      );

      final success = await controller.setOffline();
      expect(success, isFalse);
      expect(controller.isOnline, isFalse);
      expect(authController.currentUser?.isOnline, isFalse);
    });

    test('toggleAvailability switches state', () async {
      final controller = DriverAvailabilityController(
        authController: authController,
        availabilityService: fakeService,
      );

      await controller.toggleAvailability();
      expect(controller.isOnline, isTrue);

      await controller.toggleAvailability();
      expect(controller.isOnline, isFalse);
    });
  });

  group('DriverAvailabilityController — Ownership & Role Protection', () {
    test('rejects availability update for Rider account', () async {
      final riderAuthController = AuthController(
        initialState: AuthState.authenticated(dummyRider),
      );

      final controller = DriverAvailabilityController(
        authController: riderAuthController,
        availabilityService: fakeService,
      );

      final success = await controller.setOnline();
      expect(success, isFalse);
      expect(controller.errorMessage,
          equals('Only driver accounts can update availability.'));
    });

    test('rejects availability update when unauthenticated', () async {
      final unauthController = AuthController(
        initialState: const AuthState.unauthenticated(),
      );

      final controller = DriverAvailabilityController(
        authController: unauthController,
        availabilityService: fakeService,
      );

      final success = await controller.setOnline();
      expect(success, isFalse);
      expect(controller.errorMessage,
          equals('You must be signed in to change availability.'));
    });
  });

  group('DriverAvailabilityController — Session Isolation & Safety', () {
    test('aborts in-flight toggle if session generation changes during write',
        () async {
      final controller = DriverAvailabilityController(
        authController: authController,
        availabilityService: fakeService,
      );

      final completer = Completer<bool>();
      // Simulate slow network write
      fakeService.setRawAvailability('driver-123', false);

      final toggleFuture = controller.setOnline();

      // Driver signs out while write is in-flight
      await authController.signOut();

      final result = await toggleFuture;
      expect(result, isFalse);
    });

    test('Session isolation: Driver A Online does not leak into Driver B Offline session',
        () async {
      final driverA = dummyDriver.copyWith(id: 'driver-A', name: 'Driver Alpha');
      final driverB = dummyDriver.copyWith(
          id: 'driver-B', name: 'Driver Bravo', isOnline: false);

      authController.updateState(AuthState.authenticated(driverA));

      final ctrlA = DriverAvailabilityController(
        authController: authController,
        availabilityService: fakeService,
      );
      await ctrlA.setOnline();
      expect(ctrlA.isOnline, isTrue);

      // Sign out A, sign in B
      await authController.signOut();
      authController.restoreSession(driverB);

      final ctrlB = DriverAvailabilityController(
        authController: authController,
        availabilityService: fakeService,
      );

      expect(ctrlB.isOnline, isFalse);
    });
  });

  group('DriverAvailabilityController — Error Handling', () {
    test('retains previous state and surfaces error message on service failure',
        () async {
      fakeService.shouldThrow = true;
      fakeService.exceptionToThrow = const FirestoreException(
        'Network error during write',
        code: 'unavailable',
      );

      final controller = DriverAvailabilityController(
        authController: authController,
        availabilityService: fakeService,
      );

      final success = await controller.setOnline();
      expect(success, isFalse);
      expect(controller.isOnline, isFalse);
      expect(controller.errorMessage, equals('Network error during write'));
    });

    test('clearError resets error state to previous valid data', () async {
      fakeService.shouldThrow = true;

      final controller = DriverAvailabilityController(
        authController: authController,
        availabilityService: fakeService,
      );

      await controller.setOnline();
      expect(controller.errorMessage, isNotNull);

      controller.clearError();
      expect(controller.errorMessage, isNull);
      expect(controller.state.isSuccess, isTrue);
    });
  });
}

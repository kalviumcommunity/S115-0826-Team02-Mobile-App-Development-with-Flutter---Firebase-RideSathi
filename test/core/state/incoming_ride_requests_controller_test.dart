import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/auth_state.dart';
import 'package:ridesathi/core/state/incoming_ride_requests_controller.dart';
import 'package:ridesathi/services/driver_availability_service.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/services/ride_service.dart';

void main() {
  group('IncomingRideRequestsController', () {
    late FakeFirebaseFirestore fakeFirestore;
    late RideService rideService;
    late DriverAvailabilityService availabilityService;
    late AuthController authController;
    late UserModel driverUser;
    late UserModel riderUser;

    setUp(() {
    final globalFakeFirestore = FakeFirebaseFirestore();
    RideService.firestoreOverride = globalFakeFirestore;
    DriverAvailabilityService.firestoreOverride = globalFakeFirestore;
    DriverDataService.firestoreOverride = globalFakeFirestore;
    UserProfileService.firestoreOverride = globalFakeFirestore;
      fakeFirestore = FakeFirebaseFirestore();
      rideService = RideService(firestore: fakeFirestore);
      availabilityService = DriverAvailabilityService(fakeFirestore);
      authController = AuthController(initialState: const AuthState.unauthenticated());

      driverUser = const UserModel(
        id: 'driver_123',
        name: 'Test Driver',
        email: 'driver@test.com',
        phoneNumber: '+919876543210',
        role: UserRole.driver,
        isUnionVerified: true,
        vehicleInfo: 'Auto Rickshaw',
      );

      riderUser = const UserModel(
        id: 'rider_123',
        name: 'Test Rider',
        email: 'rider@test.com',
        phoneNumber: '+919876543211',
        role: UserRole.rider,
      );
    });

    test('initial state is idle with isOnline false and zero requests', () {
      final controller = IncomingRideRequestsController(
        rideService: rideService,
        authController: authController,
        availabilityService: availabilityService,
      );

      expect(controller.isOnline, isFalse);
      expect(controller.state.isInitial, isTrue);
      expect(controller.requestCount, equals(0));
      controller.dispose();
    });

    test('rejects activation if user is unauthenticated or rider', () {
      final controller = IncomingRideRequestsController(
        rideService: rideService,
        authController: authController,
        availabilityService: availabilityService,
      );

      // Unauthenticated
      controller.setOnline(true);
      expect(controller.state.isError, isTrue);
      expect(controller.state.message, contains('Driver authentication required'));

      // Authenticated as Rider
      authController.updateState(AuthState.authenticated(riderUser));
      controller.setOnline(true);
      expect(controller.state.isError, isTrue);
      expect(controller.state.message, contains('Driver authentication required'));

      controller.dispose();
    });

    test('starts streaming requests when driver is authenticated and goes Online', () async {
      authController.updateState(AuthState.authenticated(driverUser));

      await fakeFirestore.collection('rides').doc('ride_1').set({
        'riderId': 'rider_1',
        'driverId': 'driver_123',
        'status': 'requested',
        'estimatedFare': 140.0,
        'createdAt': DateTime(2026, 9, 14, 10, 0),
      });

      final controller = IncomingRideRequestsController(
        rideService: rideService,
        authController: authController,
        availabilityService: availabilityService,
      );

      controller.setOnline(true);
      expect(controller.isOnline, isTrue);

      // Allow stream snapshot microtask execution
      await Future.delayed(Duration.zero);

      expect(controller.state.isSuccess, isTrue);
      expect(controller.requestCount, equals(1));
      expect(controller.state.data!.first.id, equals('ride_1'));

      controller.dispose();
    });

    test('resets state to initial when driver transitions to Offline', () async {
      authController.updateState(AuthState.authenticated(driverUser));

      await fakeFirestore.collection('rides').doc('ride_1').set({
        'riderId': 'rider_1',
        'driverId': 'driver_123',
        'status': 'requested',
      });

      final controller = IncomingRideRequestsController(
        rideService: rideService,
        authController: authController,
        availabilityService: availabilityService,
      );

      controller.setOnline(true);
      await Future.delayed(Duration.zero);

      expect(controller.state.isSuccess, isTrue);

      // Transition to Offline
      controller.setOnline(false);
      expect(controller.isOnline, isFalse);
      expect(controller.state.isInitial, isTrue);

      controller.dispose();
    });

    test('emits ViewState.empty when driver is online but no requests exist', () async {
      authController.updateState(AuthState.authenticated(driverUser));

      final controller = IncomingRideRequestsController(
        rideService: rideService,
        authController: authController,
        availabilityService: availabilityService,
      );

      controller.setOnline(true);
      await Future.delayed(Duration.zero);

      expect(controller.state.isEmpty, isTrue);
      expect(controller.requestCount, equals(0));

      controller.dispose();
    });

    test('cancels stream and clears state on logout (session safety)', () async {
      authController.updateState(AuthState.authenticated(driverUser));

      await fakeFirestore.collection('rides').doc('ride_1').set({
        'riderId': 'rider_1',
        'driverId': 'driver_123',
        'status': 'requested',
      });

      final controller = IncomingRideRequestsController(
        rideService: rideService,
        authController: authController,
        availabilityService: availabilityService,
      );

      controller.setOnline(true);
      await Future.delayed(Duration.zero);

      expect(controller.state.isSuccess, isTrue);

      // Simulate sign out
      authController.updateState(const AuthState.unauthenticated());

      expect(controller.state.isInitial, isTrue);

      controller.dispose();
    });
  });
}

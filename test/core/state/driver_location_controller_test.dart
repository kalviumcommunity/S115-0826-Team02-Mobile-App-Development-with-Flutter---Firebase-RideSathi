import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/driver_location_controller.dart';
import 'package:ridesathi/models/driver_location.dart';
import 'package:ridesathi/models/location_model.dart';
import 'package:ridesathi/models/ride_model.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/services/location_provider.dart';
import 'package:ridesathi/services/ride_service.dart';

class MockLocationProvider implements LocationProvider {
  LocationPermissionState permissionResult = LocationPermissionState.granted;
  bool isEnabled = true;
  final StreamController<DriverLocation> streamController =
      StreamController<DriverLocation>.broadcast();

  @override
  Future<LocationPermissionState> checkPermission() async => permissionResult;

  @override
  Future<LocationPermissionState> requestPermission() async =>
      permissionResult;

  @override
  Stream<DriverLocation> getPositionStream() => streamController.stream;
}

class MockRideService extends Fake implements RideService {
  final StreamController<RideModel?> streamController =
      StreamController<RideModel?>.broadcast();
  int updateCallCount = 0;
  bool throwOnUpdate = false;

  @override
  Stream<RideModel?> watchRide(String rideId) => streamController.stream;

  @override
  Future<void> updateDriverLocation(
      String rideId, DriverLocation location, String driverId) async {
    if (throwOnUpdate) throw Exception('Firebase error');
    updateCallCount++;
  }

  // Unimplemented methods
  @override
  Future<RideModel> createRideRequest(dynamic draft, String riderId) =>
      throw UnimplementedError();

  @override
  Future<void> cancelRide(String rideId, String riderId) =>
      throw UnimplementedError();

}

class MockAuthController extends AuthController {
  UserModel? _mockUser;

  MockAuthController() : super(authService: null, userProfileService: null);

  @override
  UserModel? get currentUser => _mockUser;

  void setMockUser(UserModel? user) {
    _mockUser = user;
    notifyListeners();
  }
}

void main() {
  group('DriverLocationController', () {
    late MockLocationProvider mockLocation;
    late MockRideService mockRideService;
    late MockAuthController authController;
    late DriverLocationController controller;

    final testDriver = UserModel(
      id: 'driver_123',
      name: 'Test Driver',
      phoneNumber: '1234',
      role: UserRole.driver,
      createdAt: DateTime.now(),
    );

    final testRider = UserModel(
      id: 'rider_123',
      name: 'Test Rider',
      phoneNumber: '5678',
      role: UserRole.rider,
      createdAt: DateTime.now(),
    );

    setUp(() {
      mockLocation = MockLocationProvider();
      mockRideService = MockRideService();
      authController = MockAuthController();
      authController.setMockUser(testDriver);

      controller = DriverLocationController(
        rideId: 'ride_123',
        rideService: mockRideService,
        locationProvider: mockLocation,
        authController: authController,
      );
    });

    test('Initial state is unassigned', () {
      expect(controller.state.isInitial, isTrue);
    });

    test('Starts publishing when permission is granted and driver is logged in',
        () async {
      await controller.startPublishing();
      expect(controller.state.isSuccess, isTrue);

      final loc = DriverLocation(
          latitude: 10.0, longitude: 20.0, updatedAt: DateTime.now());
      mockLocation.streamController.add(loc);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(mockRideService.updateCallCount, equals(1));
    });

    test('Stops publishing if location permission is denied', () async {
      mockLocation.permissionResult = LocationPermissionState.denied;
      await controller.startPublishing();
      expect(controller.state.isError, isTrue);
      expect(controller.state.message, contains('permission is required'));
    });

    test('Rejects location publishing for rider account', () async {
      authController.setMockUser(testRider);
      await controller.startPublishing();

      expect(controller.state.isError, isTrue);
      expect(controller.state.message, contains('Only authenticated driver'));
    });

    test('Rejects location publishing for empty ride ID', () async {
      final emptyRideCtrl = DriverLocationController(
        rideId: '',
        rideService: mockRideService,
        locationProvider: mockLocation,
        authController: authController,
      );

      await emptyRideCtrl.startPublishing();
      expect(emptyRideCtrl.state.isError, isTrue);
      expect(emptyRideCtrl.state.message, contains('Invalid or empty ride ID'));
    });

    test('Stops publishing when ride is completed', () async {
      await controller.startPublishing();
      expect(controller.state.isSuccess, isTrue);

      final completedRide = RideModel(
        id: 'ride_123',
        riderId: 'rider',
        driverId: 'driver_123',
        pickup: const LocationModel(id: '', displayName: '', address: ''),
        destination:
            const LocationModel(id: '', displayName: '', address: ''),
        vehicleType: VehicleType.autoRickshaw,
        status: RideStatus.completed,
        estimatedFare: 100,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      mockRideService.streamController.add(completedRide);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.state.isInitial, isTrue);
    });

    test('Stops publishing when user logs out', () async {
      await controller.startPublishing();
      expect(controller.state.isSuccess, isTrue);

      authController.setMockUser(null);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.state.isInitial, isTrue);
    });
  });
}

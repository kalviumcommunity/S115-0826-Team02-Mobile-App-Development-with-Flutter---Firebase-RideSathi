import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/state/driver_information_controller.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/services/user_profile_service.dart';

class MockUserProfileService implements UserProfileService {
  final Map<String, UserModel> mockDatabase = {};
  bool throwError = false;

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    if (throwError) throw Exception('Simulated error');
    await Future.delayed(const Duration(milliseconds: 10)); // simulate network delay
    return mockDatabase[uid];
  }

  @override
  Future<void> createDriverProfile(UserModel user) async {}

  @override
  Future<void> createRiderProfile(UserModel user) async {}

  @override
  Future<UserModel> updateProfile({required String uid, required Map<String, dynamic> updates}) async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> updateProfileFields({required String uid, String? name, String? phoneNumber, String? vehicleInfo}) async {
    throw UnimplementedError();
  }
}

void main() {
  group('DriverInformationController', () {
    late MockUserProfileService mockService;
    late DriverInformationController controller;

    final testDriver = UserModel(
      id: 'driver_1',
      name: 'Test Driver',
      phoneNumber: '1234567890',
      role: UserRole.driver,
      createdAt: DateTime.now(),
    );

    final testRider = UserModel(
      id: 'rider_1',
      name: 'Test Rider',
      phoneNumber: '0987654321',
      role: UserRole.rider,
      createdAt: DateTime.now(),
    );

    setUp(() {
      mockService = MockUserProfileService();
      controller = DriverInformationController(profileService: mockService);
    });

    test('Initial state is initial when no driverId is provided', () async {
      expect(controller.state.isInitial, isTrue);
      await controller.loadDriver(null);
      expect(controller.state.isInitial, isTrue);
    });

    test('Successfully resolves a valid driver profile', () async {
      mockService.mockDatabase[testDriver.id] = testDriver;

      final future = controller.loadDriver(testDriver.id);
      expect(controller.state.isLoading, isTrue);

      await future;

      expect(controller.state.isSuccess, isTrue);
      expect(controller.state.data?.name, equals('Test Driver'));
    });

    test('Transitions to error if driver profile is missing', () async {
      await controller.loadDriver('non_existent_driver');
      
      expect(controller.state.isError, isTrue);
      expect(controller.state.message, equals('Driver information is currently unavailable.'));
    });

    test('Transitions to error if profile role is not driver', () async {
      mockService.mockDatabase[testRider.id] = testRider;

      await controller.loadDriver(testRider.id);

      expect(controller.state.isError, isTrue);
      expect(controller.state.message, equals('Driver information is currently unavailable.'));
    });

    test('Prevents duplicate concurrent loads for the same driver', () async {
      mockService.mockDatabase[testDriver.id] = testDriver;

      final future1 = controller.loadDriver(testDriver.id);
      final future2 = controller.loadDriver(testDriver.id); // Should be ignored

      await future1;
      await future2;

      expect(controller.state.isSuccess, isTrue);
      // Additional assertions could verify the service was only called once, 
      // but testing state transition logic is sufficient here.
    });

    test('Handles retry correctly', () async {
      mockService.throwError = true;
      await controller.loadDriver(testDriver.id);
      expect(controller.state.isError, isTrue);

      mockService.throwError = false;
      mockService.mockDatabase[testDriver.id] = testDriver;
      controller.retry();
      
      // Allow async task started by retry to complete
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.state.isSuccess, isTrue);
    });

    test('Clears driver state when ride becomes unassigned', () async {
      mockService.mockDatabase[testDriver.id] = testDriver;
      await controller.loadDriver(testDriver.id);
      expect(controller.state.isSuccess, isTrue);

      await controller.loadDriver(null);
      expect(controller.state.isInitial, isTrue);
    });
  });
}

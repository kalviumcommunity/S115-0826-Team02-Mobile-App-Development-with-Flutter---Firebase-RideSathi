import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/ride_cancellation_controller.dart';

import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/services/ride_service.dart';

class MockRideService extends Fake implements RideService {
  int cancelCallCount = 0;
  bool throwOnCancel = false;

  @override
  Future<void> cancelRide(String rideId, String riderId) async {
    if (throwOnCancel) throw Exception('Firebase error');
    cancelCallCount++;
  }
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
  group('RideCancellationController', () {
    late MockRideService mockRideService;
    late MockAuthController mockAuthController;
    late RideCancellationController controller;

    final testRider = UserModel(
      id: 'rider_123',
      name: 'Test Rider',
      phoneNumber: '1234',
      role: UserRole.rider,
      createdAt: DateTime.now(),
    );

    setUp(() {
      mockRideService = MockRideService();
      mockAuthController = MockAuthController();
      mockAuthController.setMockUser(testRider);

      controller = RideCancellationController(
        rideService: mockRideService,
        authController: mockAuthController,
      );
    });

    test('Initial state is initial', () {
      expect(controller.state.isInitial, isTrue);
    });

    test('successfully cancels ride and transitions to success', () async {
      await controller.cancelRide('ride_1');
      expect(controller.state.isSuccess, isTrue);
      expect(mockRideService.cancelCallCount, equals(1));
    });

    test('fails if user is logged out', () async {
      mockAuthController.setMockUser(null);
      await controller.cancelRide('ride_1');
      expect(controller.state.isError, isTrue);
      expect(controller.state.message, contains('logged in'));
      expect(mockRideService.cancelCallCount, equals(0));
    });

    test('fails if ride ID is empty', () async {
      await controller.cancelRide('  ');
      expect(controller.state.isError, isTrue);
      expect(controller.state.message, contains('Invalid ride ID'));
    });

    test('displays error from service failure', () async {
      mockRideService.throwOnCancel = true;
      await controller.cancelRide('ride_1');
      expect(controller.state.isError, isTrue);
      expect(controller.state.message, contains('Firebase error'));
    });

    test('prevents concurrent cancellation calls', () async {
      // Create a slow mock
      final completer = Completer<void>();
      var callCount = 0;
      
      final customMockService = _SlowMockRideService(() {
        callCount++;
        return completer.future;
      });

      final customController = RideCancellationController(
        rideService: customMockService,
        authController: mockAuthController,
      );

      // Fire twice synchronously
      final first = customController.cancelRide('ride_1');
      final second = customController.cancelRide('ride_1');
      
      expect(customController.state.isLoading, isTrue);
      
      completer.complete();
      await Future.wait([first, second]);

      expect(callCount, equals(1)); // the second call should be blocked
    });
  });
}

class _SlowMockRideService extends Fake implements RideService {
  final Future<void> Function() onCancel;
  _SlowMockRideService(this.onCancel);

  @override
  Future<void> cancelRide(String rideId, String riderId) => onCancel();
}

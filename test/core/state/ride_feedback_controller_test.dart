import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/ride_feedback_controller.dart';
import 'package:ridesathi/core/state/view_state.dart';
import 'package:ridesathi/models/driver_location.dart';
import 'package:ridesathi/models/location_model.dart';
import 'package:ridesathi/models/ride_model.dart';
import 'package:ridesathi/models/ride_request_draft.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/services/firestore_exception.dart';
import 'package:ridesathi/services/ride_service.dart';

class MockRideService implements RideService {
  Exception? feedbackError;
  bool feedbackCalled = false;

  @override
  Future<void> submitRideFeedback(String rideId, String riderId, int rating, {String? comment}) async {
    feedbackCalled = true;
    if (feedbackError != null) throw feedbackError!;
  }

  @override
  Future<RideModel> createRideRequest(RideRequestDraft draft, String riderId) async => throw UnimplementedError();
  @override
  Future<void> cancelRide(String rideId, String riderId) async {}
  @override
  Future<RideModel?> getRide(String rideId) async => null;
  @override
  Stream<RideModel> streamRideStatus(String rideId) => const Stream.empty();
  @override
  Stream<RideModel?> watchRide(String rideId) => const Stream.empty();
  @override
  Future<void> updateDriverLocation(String rideId, DriverLocation location, String driverId) async {}
  @override
  Future<List<RideModel>> getRiderRideHistory(String riderId, {int limit = 20}) async => [];
}

class MockAuthController extends AuthController {
  UserModel? mockUser;
  int mockSessionGeneration = 1;

  @override
  UserModel? get currentUser => mockUser;
  @override
  int get sessionGeneration => mockSessionGeneration;
}

void main() {
  group('RideFeedbackController', () {
    late MockRideService mockService;
    late MockAuthController mockAuthController;
    late RideFeedbackController controller;

    final mockUser = UserModel(
      id: 'rider_123',
      role: UserRole.rider,
      name: 'Rider',
      createdAt: DateTime.now(),
    );

    setUp(() {
      mockService = MockRideService();
      mockAuthController = MockAuthController()..mockUser = mockUser;
      controller = RideFeedbackController(
        rideService: mockService,
        authController: mockAuthController,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state is correct', () {
      expect(controller.state, const ViewState<void>.initial());
    });

    test('returns false and sets error if user is unauthenticated', () async {
      mockAuthController.mockUser = null;
      final result = await controller.submitFeedback('ride_1', 4, null);
      expect(result, isFalse);
      expect(controller.state.hasError, isTrue);
      expect(controller.state.message, contains('not authenticated'));
    });

    test('returns false and sets error for rating below 1', () async {
      final result = await controller.submitFeedback('ride_1', 0, null);
      expect(result, isFalse);
      expect(controller.state.hasError, isTrue);
    });

    test('returns false and sets error for rating above 5', () async {
      final result = await controller.submitFeedback('ride_1', 6, null);
      expect(result, isFalse);
      expect(controller.state.hasError, isTrue);
    });

    test('returns false and sets error for comment over 500 chars', () async {
      final result = await controller.submitFeedback('ride_1', 5, 'x' * 501);
      expect(result, isFalse);
      expect(controller.state.hasError, isTrue);
    });

    test('returns true on successful submission', () async {
      final result = await controller.submitFeedback('ride_1', 4, 'Great ride!');
      expect(result, isTrue);
      expect(mockService.feedbackCalled, isTrue);
      expect(controller.state.isSuccess, isTrue);
    });

    test('handles FirestoreException duplicate feedback', () async {
      mockService.feedbackError = FirestoreException('Feedback already submitted.', code: 'already-exists');
      final result = await controller.submitFeedback('ride_1', 4, null);
      expect(result, isFalse);
      expect(controller.state.hasError, isTrue);
      expect(controller.state.message, equals('Feedback already submitted.'));
    });

    test('handles FirestoreException permission-denied', () async {
      mockService.feedbackError = FirestoreException('Access denied.', code: 'permission-denied');
      final result = await controller.submitFeedback('ride_1', 4, null);
      expect(result, isFalse);
      expect(controller.state.hasError, isTrue);
    });

    test('prevents concurrent duplicate submissions', () async {
      // Simulate controller already in loading state
      final firstFuture = controller.submitFeedback('ride_1', 4, null);
      // Immediately call again — should be blocked
      final secondResult = controller.submitFeedback('ride_1', 4, null);
      // The second call should be rejected since state.isLoading guard fires
      final second = await secondResult;
      final first = await firstFuture;
      expect(second, isFalse);
      expect(first, isTrue);
    });

    test('reset clears error state', () async {
      mockService.feedbackError = FirestoreException('Ride not found.', code: 'not-found');
      await controller.submitFeedback('ride_1', 4, null);
      expect(controller.state.hasError, isTrue);
      controller.reset();
      expect(controller.state, const ViewState<void>.initial());
    });
  });
}

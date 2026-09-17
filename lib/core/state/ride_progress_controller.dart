import 'package:flutter/foundation.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_exception.dart';
import '../../services/ride_service.dart';
import 'active_ride_controller.dart';
import 'auth_controller.dart';
import 'view_state.dart';

/// Controls the operational ride progression for a driver:
///
///   accepted → arrived → inProgress → completed
///
/// Uses the trusted [AuthController] for driver identity.
/// Uses [ActiveRideController] as the source of truth for the current ride.
/// Prevents duplicate submissions with an operation guard.
/// Enforces session-generation safety on all async completions.
class RideProgressController extends ChangeNotifier {
  final RideService _rideService;
  final AuthController _authController;
  final ActiveRideController _activeRideController;

  ViewState<void> _state = const ViewState.initial();
  bool _isDisposed = false;

  RideProgressController({
    RideService? rideService,
    AuthController? authController,
    required ActiveRideController activeRideController,
  })  : _rideService = rideService ?? RideService(),
        _authController = authController ?? AuthController.instance,
        // ignore: prefer_initializing_formals
        _activeRideController = activeRideController {
    _authController.addListener(_onAuthChanged);
  }

  /// Current transition state.
  ViewState<void> get state => _state;

  void _onAuthChanged() {
    if (_authController.currentUser == null && !_state.isInitial) {
      _reset();
    }
  }

  void _reset() {
    if (_isDisposed) return;
    _state = const ViewState.initial();
    notifyListeners();
  }

  void clearError() {
    if (_state.isError && !_isDisposed) _reset();
  }

  /// Attempts [accepted → arrived].
  Future<bool> markArrived() => _doTransition(
        expectedStatus: RideStatus.accepted,
        loadingMessage: 'Marking as arrived...',
        perform: (rideId, driverId) =>
            _rideService.markRideArrived(rideId, driverId),
      );

  /// Attempts [arrived → inProgress].
  Future<bool> startRide() => _doTransition(
        expectedStatus: RideStatus.arrived,
        loadingMessage: 'Starting ride...',
        perform: (rideId, driverId) =>
            _rideService.startRide(rideId, driverId),
      );

  /// Attempts [inProgress → completed].
  Future<bool> completeRide() => _doTransition(
        expectedStatus: RideStatus.inProgress,
        loadingMessage: 'Completing ride...',
        perform: (rideId, driverId) =>
            _rideService.completeRide(rideId, driverId),
      );

  Future<bool> _doTransition({
    required RideStatus expectedStatus,
    required String loadingMessage,
    required Future<void> Function(String rideId, String driverId) perform,
  }) async {
    if (_isDisposed) return false;
    if (_state.isLoading) return false; // Duplicate-submit guard

    final user = _authController.currentUser;
    if (user == null || user.role != UserRole.driver) {
      _state = const ViewState.error('Driver authentication required.');
      notifyListeners();
      return false;
    }

    final ride = _activeRideController.activeRide;
    if (ride == null) {
      _state = const ViewState.error('No active ride found.');
      notifyListeners();
      return false;
    }

    if (ride.status != expectedStatus) {
      _state = ViewState.error(
        'Cannot perform this action: ride is currently "${ride.status.name}".',
      );
      notifyListeners();
      return false;
    }

    if (ride.driverId != user.id) {
      _state = const ViewState.error(
        'Unauthorized: this ride is not assigned to you.',
      );
      notifyListeners();
      return false;
    }

    final capturedGen = _authController.sessionGeneration;
    _state = ViewState.loading(message: loadingMessage);
    notifyListeners();

    try {
      await perform(ride.id, user.id);

      if (_isDisposed || _authController.sessionGeneration != capturedGen) {
        return false;
      }
      _state = const ViewState.success(null);
      notifyListeners();
      return true;
    } on FirestoreException catch (e) {
      if (_isDisposed || _authController.sessionGeneration != capturedGen) {
        return false;
      }
      _state = ViewState.error(e.message, code: e.code);
      notifyListeners();
      return false;
    } catch (e) {
      if (_isDisposed || _authController.sessionGeneration != capturedGen) {
        return false;
      }
      _state = const ViewState.error(
          'An unexpected error occurred. Please try again.');
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authController.removeListener(_onAuthChanged);
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import '../../services/firestore_exception.dart';
import '../../services/ride_service.dart';
import 'auth_controller.dart';
import 'incoming_ride_requests_controller.dart';
import 'view_state.dart';

/// Manages the state of a ride rejection operation.
///
/// Enforces driver role, online availability, and session safety.
/// Ensures duplicate taps are prevented during an active transaction.
class RideRejectionController extends ChangeNotifier {
  final RideService _rideService;
  final AuthController _authController;
  final IncomingRideRequestsController _requestsController;

  ViewState<void> _state = const ViewState.initial();
  bool _isDisposed = false;

  RideRejectionController({
    RideService? rideService,
    AuthController? authController,
    required IncomingRideRequestsController requestsController,
  })  : _rideService = rideService ?? RideService(),
        _authController = authController ?? AuthController.instance,
        // ignore: prefer_initializing_formals
        _requestsController = requestsController {
    _authController.addListener(_onAuthChanged);
  }

  ViewState<void> get state => _state;

  void _onAuthChanged() {
    if (_authController.currentUser == null && !_state.isInitial) {
      _resetState();
    }
  }

  void _resetState() {
    if (_isDisposed) return;
    _state = const ViewState.initial();
    notifyListeners();
  }

  /// Attempts to reject an explicitly assigned ride request on behalf of the driver.
  Future<bool> rejectRide(String rideId) async {
    if (_isDisposed) return false;
    if (_state.isLoading) return false; // Prevent concurrent taps

    final user = _authController.currentUser;
    if (user == null || user.role != UserRole.driver) {
      _state = const ViewState.error('You must be logged in as a driver to reject a ride.');
      notifyListeners();
      return false;
    }

    if (!_requestsController.isOnline) {
      _state = const ViewState.error('You must be online to reject a ride.');
      notifyListeners();
      return false;
    }

    final driverId = user.id;
    final currentGen = _authController.sessionGeneration;

    _state = const ViewState.loading(message: 'Rejecting ride...');
    notifyListeners();

    try {
      // For broadcast requests (no explicit assignment), just locally reject.
      // A more complex app would have the backend filter this, but for now we handle it client-side.
      _requestsController.locallyReject(rideId);
      
      // Still attempt to reject on the server if it WAS explicitly assigned to us.
      // We wrap this in a try-catch and ignore "Not assigned to you" errors.
      try {
        await _rideService.rejectRide(rideId, driverId);
      } on FirestoreException catch (e) {
        if (e.message.contains('Not assigned to you')) {
          // This is expected for broadcast requests, safe to ignore.
        } else {
          rethrow;
        }
      }

      if (_isDisposed || _authController.sessionGeneration != currentGen) {
        return false; // Stale session, discard result
      }

      _state = const ViewState.success(null, message: 'Ride rejected.');
      notifyListeners();
      return true;
    } on FirestoreException catch (e) {
      if (_isDisposed || _authController.sessionGeneration != currentGen) {
        return false;
      }
      _state = ViewState.error(e.message, code: e.code);
      notifyListeners();
      return false;
    } catch (e) {
      if (_isDisposed || _authController.sessionGeneration != currentGen) {
        return false;
      }
      _state = const ViewState.error('An unexpected error occurred while rejecting the ride.');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_state.isError && !_isDisposed) {
      _resetState();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authController.removeListener(_onAuthChanged);
    super.dispose();
  }
}

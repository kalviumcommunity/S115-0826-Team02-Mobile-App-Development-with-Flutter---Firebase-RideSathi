import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_exception.dart';
import '../../services/ride_service.dart';
import 'auth_controller.dart';
import 'view_state.dart';

/// Manages the driver's active (accepted) ride state in real-time.
///
/// This controller:
/// - Resolves the authenticated driver from [AuthController].
/// - Streams the current accepted ride via [RideService.watchDriverActiveRide].
/// - Enforces driver-role and session-generation safety.
/// - Handles rider cancellation and other status changes via real-time updates.
/// - Cancels subscriptions on logout, session change, or disposal.
class ActiveRideController extends ChangeNotifier {
  final RideService _rideService;
  final AuthController _authController;

  ViewState<RideModel> _state = const ViewState.initial();
  StreamSubscription<RideModel?>? _subscription;
  bool _isDisposed = false;
  bool _isInitialized = false;
  int _activeSessionGeneration = 0;

  ActiveRideController({
    RideService? rideService,
    AuthController? authController,
  })  : _rideService = rideService ?? RideService(),
        _authController = authController ?? AuthController.instance {
    _authController.addListener(_onAuthChanged);
  }

  /// Current view state containing the active ride (if any).
  ViewState<RideModel> get state => _state;

  /// The active ride model if available.
  RideModel? get activeRide => _state.data;

  void _onAuthChanged() {
    final user = _authController.currentUser;
    final currentGen = _authController.sessionGeneration;

    if (user == null || user.role != UserRole.driver) {
      // Logged out or role changed — clear all state
      _cancelSubscription();
      _isInitialized = false;
      if (!_isDisposed) {
        _state = const ViewState.initial();
        notifyListeners();
      }
      return;
    }

    if (_activeSessionGeneration != currentGen) {
      // New session (re-login) — restart the listener
      _cancelSubscription();
      _isInitialized = false;
      startListening();
    }
  }

  /// Starts listening to the driver's active ride stream.
  ///
  /// Safe to call multiple times; duplicate initialization is prevented.
  void startListening() {
    if (_isDisposed) return;
    if (_isInitialized) return; // Prevent duplicate subscriptions

    final user = _authController.currentUser;
    if (user == null || user.role != UserRole.driver) {
      _state = const ViewState.error('Driver authentication required.');
      notifyListeners();
      return;
    }

    _isInitialized = true;
    _activeSessionGeneration = _authController.sessionGeneration;
    final capturedGen = _activeSessionGeneration;
    final driverId = user.id;

    _state = const ViewState.loading(message: 'Loading active ride...');
    notifyListeners();

    try {
      _subscription = _rideService.watchDriverActiveRide(driverId).listen(
        (ride) {
          if (_isDisposed) return;
          // Session guard: discard if session changed or driver changed
          if (_authController.sessionGeneration != capturedGen ||
              _authController.currentUser?.id != driverId) {
            return;
          }

          if (ride == null) {
            _state = const ViewState.empty(message: 'No active ride.');
          } else {
            _state = ViewState.success(ride);
          }
          notifyListeners();
        },
        onError: (error) {
          if (_isDisposed) return;
          if (_authController.sessionGeneration != capturedGen) return;

          final message = error is FirestoreException
              ? error.message
              : 'Failed to load active ride.';
          _state = ViewState.error(
            message,
            code: error is FirestoreException ? error.code : null,
          );
          notifyListeners();
        },
      );
    } catch (e) {
      if (_isDisposed) return;
      _state = ViewState.error(
        e is FirestoreException ? e.message : 'Could not start active ride listener.',
      );
      notifyListeners();
    }
  }

  /// Retries by restarting the subscription.
  void retry() {
    if (_isDisposed) return;
    _cancelSubscription();
    _isInitialized = false;
    startListening();
  }

  void _cancelSubscription() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelSubscription();
    _authController.removeListener(_onAuthChanged);
    super.dispose();
  }
}

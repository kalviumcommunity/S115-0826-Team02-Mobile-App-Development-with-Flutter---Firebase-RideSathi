import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/ride_model.dart';
import '../../services/ride_service.dart';
import '../../services/firestore_exception.dart';
import '../../services/ride_request_timeout_service.dart';
import '../../utils/clock.dart';
import '../../core/constants/app_constants.dart';
import 'view_state.dart';
import 'auth_controller.dart';

/// Controller handling the real-time observation of a specific ride.
///
/// Ensures the listener is safely cancelled upon disposal, session change, or error.
/// Also actively monitors for `requested` rides exceeding their timeout limit.
class RideStatusController extends ChangeNotifier {
  final RideService _rideService;
  final AuthController _authController;
  final RideRequestTimeoutService _timeoutService;
  final Clock _clock;
  final String _rideId;

  ViewState<RideModel> _state = const ViewState.initial();
  StreamSubscription<RideModel?>? _rideSubscription;
  Timer? _timeoutTimer;
  bool _isDisposed = false;
  int _sessionGeneration = 0;

  RideStatusController({
    required String rideId,
    RideService? rideService,
    AuthController? authController,
    RideRequestTimeoutService? timeoutService,
    Clock? clock,
  })  : _rideId = rideId,
        _rideService = rideService ?? RideService(),
        _authController = authController ?? AuthController.instance,
        _timeoutService = timeoutService ?? const RideRequestTimeoutService(),
        _clock = clock ?? const SystemClock() {
    _sessionGeneration = _authController.sessionGeneration;
    _startWatching();
    _authController.addListener(_onAuthChanged);
  }

  /// Current async state of the active ride.
  ViewState<RideModel> get state => _state;

  void _onAuthChanged() {
    if (_isDisposed) return;
    
    final currentUser = _authController.currentUser;
    final currentGeneration = _authController.sessionGeneration;

    // If the session changed or user logged out, cancel the subscription and show error.
    if (currentGeneration != _sessionGeneration || currentUser == null) {
      _cancelSubscription();
      _cancelTimeoutTimer();
      _setState(const ViewState.error('Session ended. Please log in again.'));
    }
  }

  void _startWatching() {
    if (_isDisposed) return;

    if (_rideId.trim().isEmpty) {
      _setState(const ViewState.error('Invalid ride ID.'));
      return;
    }

    _cancelSubscription();
    _cancelTimeoutTimer();
    _setState(const ViewState.loading());

    try {
      _rideSubscription = _rideService.watchRide(_rideId).listen(
        (RideModel? ride) {
          if (_isDisposed) return;
          
          if (ride == null) {
            _setState(const ViewState.error('We couldn\'t find this ride request.'));
            return;
          }

          // Verify ownership (client side)
          if (ride.riderId != _authController.currentUser?.id) {
            _setState(const ViewState.error('You do not have permission to view this ride.'));
            return;
          }

          _setState(ViewState.success(ride));
          _checkTimeout(ride);
        },
        onError: (error) {
          if (_isDisposed) return;
          final message = error is FirestoreException
              ? error.message
              : 'Failed to connect to ride status.';
          _setState(ViewState.error(message));
        },
      );
    } catch (e) {
      if (_isDisposed) return;
      _setState(const ViewState.error('Failed to initiate ride status observation.'));
    }
  }

  void _checkTimeout(RideModel ride) {
    _cancelTimeoutTimer();

    if (ride.status != RideStatus.requested) {
      return;
    }

    final isTimedOut = _timeoutService.isEligibleForTimeout(
      ride,
      timeout: AppConstants.rideRequestTimeout,
      clock: _clock,
    );

    if (isTimedOut) {
      _executeTimeout(ride.id);
    } else {
      final now = _clock.now();
      final deadline = ride.createdAt.add(AppConstants.rideRequestTimeout);
      final remaining = deadline.difference(now);
      
      _timeoutTimer = Timer(remaining, () {
        if (_isDisposed) return;
        _executeTimeout(ride.id);
      });
    }
  }

  Future<void> _executeTimeout(String id) async {
    try {
      await _rideService.timeoutRide(id);
    } catch (e) {
      // If the timeout transition fails due to network/permissions, the stream
      // will eventually retry or update when possible. We swallow the error
      // here to avoid disrupting the UI with internal transition failures.
    }
  }

  /// Retries observing the ride if previously failed.
  void retry() {
    if (_state.isError) {
      _startWatching();
    }
  }

  void _cancelSubscription() {
    _rideSubscription?.cancel();
    _rideSubscription = null;
  }

  void _cancelTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  void _setState(ViewState<RideModel> newState) {
    if (!_isDisposed && _state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelSubscription();
    _cancelTimeoutTimer();
    _authController.removeListener(_onAuthChanged);
    super.dispose();
  }
}

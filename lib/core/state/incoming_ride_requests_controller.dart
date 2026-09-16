import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_exception.dart';
import '../../services/ride_service.dart';
import '../../services/driver_availability_service.dart';
import 'auth_controller.dart';
import 'view_state.dart';

/// Manages incoming ride request state and real-time subscription for authenticated drivers.
///
/// Ensures incoming requests are only streamed when:
/// 1. User is authenticated with role `UserRole.driver`.
/// 2. Driver is currently online (`isOnline == true`).
///
/// Enforces session safety by invalidating stream callbacks if the authentication
/// session generation changes (e.g. logout/re-login).
class IncomingRideRequestsController extends ChangeNotifier {
  final RideService _rideService;
  final AuthController _authController;
  final DriverAvailabilityService _availabilityService;

  ViewState<List<RideModel>> _state = const ViewState.initial();
  StreamSubscription<List<RideModel>>? _subscription;
  bool _isOnline = false;
  bool _isDisposed = false;
  int _activeSessionGeneration = 0;

  IncomingRideRequestsController({
    RideService? rideService,
    AuthController? authController,
    DriverAvailabilityService? availabilityService,
  })  : _rideService = rideService ?? RideService(),
        _authController = authController ?? AuthController.instance,
        _availabilityService = availabilityService ?? const DriverAvailabilityService() {
    _init();
  }

  /// Current UI view state containing the list of incoming ride requests.
  ViewState<List<RideModel>> get state => _state;

  /// Whether the driver is currently online for receiving ride requests.
  bool get isOnline => _isOnline;

  /// Number of active incoming ride requests.
  int get requestCount => _state.data?.length ?? 0;

  void _init() {
    _authController.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    final user = _authController.currentUser;
    final currentGen = _authController.sessionGeneration;

    if (user == null || user.role != UserRole.driver || _activeSessionGeneration != currentGen) {
      stopListening();
      if (user == null) {
        _isOnline = false;
      }
    }
  }

  /// Sets driver availability to Online (`true`) or Offline (`false`).
  ///
  /// Starting or stopping incoming request streaming dynamically based on availability.
  Future<void> setOnline(bool online) async {
    if (_isDisposed) return;
    if (_isOnline == online) return;

    final user = _authController.currentUser;
    if (user != null) {
      try {
        await _availabilityService.setDriverOnlineStatus(user.id, online);
      } catch (e) {
        // If Firestore fails, we log and don't change local state, or change it back.
        // For now, we proceed to change local state. In a robust app, we'd handle this cleanly.
        debugPrint('Failed to sync online status: $e');
        return; // Early return if we fail to update the server.
      }
    }

    if (_isDisposed) return;

    _isOnline = online;

    if (_isOnline) {
      startListening();
    } else {
      stopListening();
    }
    notifyListeners();
  }

  /// Toggles driver availability state between Online and Offline.
  void toggleOnline() {
    setOnline(!_isOnline);
  }

  /// Starts listening to incoming ride requests if driver is authenticated and online.
  void startListening() {
    if (_isDisposed) return;

    final user = _authController.currentUser;
    if (user == null || user.role != UserRole.driver) {
      _state = const ViewState.error('Driver authentication required.');
      notifyListeners();
      return;
    }

    if (!_isOnline) {
      stopListening();
      return;
    }

    _subscription?.cancel();
    _activeSessionGeneration = _authController.sessionGeneration;
    final captureSessionGen = _activeSessionGeneration;
    final driverId = user.id;

    _state = const ViewState.loading(message: 'Listening for incoming ride requests...');
    notifyListeners();

    try {
      _subscription = _rideService.watchIncomingRideRequests(driverId).listen(
        (requests) {
          if (_isDisposed) return;

          // Session generation guard: discard snapshot if session changed or driver went offline
          if (_authController.sessionGeneration != captureSessionGen ||
              _authController.currentUser?.id != driverId ||
              !_isOnline) {
            return;
          }

          if (requests.isEmpty) {
            _state = const ViewState.empty(message: 'No incoming ride requests');
          } else {
            // Unique collection by ride ID to prevent duplicate render
            final uniqueMap = <String, RideModel>{};
            for (final req in requests) {
              uniqueMap[req.id] = req;
            }
            final sortedList = uniqueMap.values.toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            _state = ViewState.success(sortedList);
          }
          notifyListeners();
        },
        onError: (error) {
          if (_isDisposed) return;
          if (_authController.sessionGeneration != captureSessionGen || !_isOnline) {
            return;
          }

          final errorMessage = error is FirestoreException
              ? error.message
              : 'Failed to load incoming ride requests.';

          _state = ViewState.error(errorMessage, error: error);
          notifyListeners();
        },
      );
    } catch (e) {
      if (_isDisposed) return;
      _state = ViewState.error(
        e is FirestoreException ? e.message : 'Could not start request listener.',
      );
      notifyListeners();
    }
  }

  /// Stops listening to incoming ride requests and resets state.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;

    if (!_isDisposed && !_state.isInitial) {
      _state = const ViewState.initial();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    _subscription = null;
    _authController.removeListener(_onAuthChanged);
    super.dispose();
  }
}

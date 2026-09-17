import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/driver_location.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import '../../services/location_provider.dart';
import '../../services/ride_service.dart';
import 'auth_controller.dart';
import 'view_state.dart';

/// Manages the state and lifecycle of driver location publishing.
///
/// Encapsulates permission checks, coordinate validation, ownership checks,
/// session generation safety, and ride status watching.
class DriverLocationController extends ChangeNotifier {
  final String rideId;
  final RideService _rideService;
  final LocationProvider _locationProvider;
  final AuthController _authController;

  ViewState<void> _state = const ViewState.initial();
  StreamSubscription<DriverLocation>? _locationSubscription;
  StreamSubscription<RideModel?>? _rideSubscription;
  bool _isDisposed = false;



  DriverLocationController({
    required this.rideId,
    RideService? rideService,
    LocationProvider? locationProvider,
    AuthController? authController,
  })  : _rideService = rideService ?? RideService(),
        _locationProvider =
            locationProvider ?? const GeolocatorLocationProvider(),
        _authController = authController ?? AuthController.instance {
    _init();
  }

  ViewState<void> get state => _state;

  void _init() {
    _authController.addListener(_onAuthChanged);
    if (rideId.trim().isNotEmpty) {
      _watchRideLifecycle();
    }
  }

  void _onAuthChanged() {
    final user = _authController.currentUser;
    if (user == null || user.role != UserRole.driver) {
      stopPublishing();
    }
  }

  void _watchRideLifecycle() {
    _rideSubscription = _rideService.watchRide(rideId).listen((ride) {
      if (_isDisposed) return;
      if (ride == null ||
          ride.status == RideStatus.completed ||
          ride.status == RideStatus.cancelled) {
        stopPublishing();
      }
    }, onError: (_) {
      if (!_isDisposed) stopPublishing();
    });
  }

  /// Attempts to start publishing the driver's location for an active ride.
  Future<void> startPublishing() async {
    if (_state.isLoading) return; // Prevent concurrent starts

    final trimmedRideId = rideId.trim();
    if (trimmedRideId.isEmpty) {
      _state = const ViewState.error('Invalid or empty ride ID.');
      notifyListeners();
      return;
    }

    _state = const ViewState.loading(message: 'Checking location permissions...');
    notifyListeners();

    try {
      final permission = await _locationProvider.requestPermission();

      if (_isDisposed) return; // Session safety

      if (permission == LocationPermissionState.denied ||
          permission == LocationPermissionState.permanentlyDenied) {
        _state = const ViewState.error(
            'Location permission is required to share your route.');
        notifyListeners();
        return;
      }

      if (permission == LocationPermissionState.locationServicesDisabled) {
        _state = const ViewState.error(
            'Please enable location services on your device.');
        notifyListeners();
        return;
      }

      // Role and Auth Ownership Validation
      final currentUser = _authController.currentUser;
      if (currentUser == null || !_authController.isAuthenticated) {
        _state = const ViewState.error('You must be logged in to share location.');
        notifyListeners();
        return;
      }

      if (currentUser.role != UserRole.driver) {
        _state = const ViewState.error(
            'Only authenticated driver accounts can publish location.');
        notifyListeners();
        return;
      }

      final driverId = currentUser.id;
      final sessionGen = _authController.sessionGeneration;


      _state = const ViewState.success(null);
      notifyListeners();

      _locationSubscription?.cancel();
      _locationSubscription = _locationProvider.getPositionStream().listen(
        (location) => _publishLocation(location, driverId, sessionGen),
        onError: (error) {
          if (_isDisposed) return;
          _state = const ViewState.error(
              'Failed to acquire location. Reconnecting...');
          notifyListeners();
        },
      );
    } catch (e) {
      if (_isDisposed) return;
      _state = const ViewState.error('Could not start location sharing.');
      notifyListeners();
    }
  }

  Future<void> _publishLocation(
      DriverLocation location, String driverId, int sessionGen) async {
    if (_isDisposed) return;

    // Safety checks: Session generation check & active driver UID check
    if (!_authController.isAuthenticated ||
        _authController.sessionGeneration != sessionGen ||
        _authController.currentUser?.id != driverId ||
        _authController.currentUser?.role != UserRole.driver) {
      stopPublishing();
      return;
    }

    // Coordinate validation
    if (!location.isValid) {
      return; // Skip invalid GPS points without crashing
    }

    try {
      await _rideService.updateDriverLocation(rideId, location, driverId);
      if (!_isDisposed && !_state.isSuccess) {
        _state = const ViewState.success(null);
        notifyListeners();
      }
    } catch (e) {
      if (_isDisposed) return;
      _state = const ViewState.error('Failed to update location.');
      notifyListeners();
    }
  }

  void stopPublishing() {
    _locationSubscription?.cancel();
    _locationSubscription = null;


    if (!_isDisposed && !_state.isInitial) {
      _state = const ViewState.initial();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authController.removeListener(_onAuthChanged);
    _locationSubscription?.cancel();
    _rideSubscription?.cancel();
    super.dispose();
  }
}

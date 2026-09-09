import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/driver_location.dart';
import '../../models/ride_model.dart';
import '../../services/location_provider.dart';
import '../../services/ride_service.dart';
import 'auth_controller.dart';
import 'view_state.dart';

/// Manages the state and lifecycle of driver location publishing.
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
        _locationProvider = locationProvider ?? const GeolocatorLocationProvider(),
        _authController = authController ?? AuthController.instance {
    _init();
  }

  ViewState<void> get state => _state;

  void _init() {
    _authController.addListener(_onAuthChanged);
    _watchRideLifecycle();
  }

  void _onAuthChanged() {
    if (_authController.currentUser == null) {
      stopPublishing();
    }
  }

  void _watchRideLifecycle() {
    _rideSubscription = _rideService.watchRide(rideId).listen((ride) {
      if (ride == null || 
          ride.status == RideStatus.completed || 
          ride.status == RideStatus.cancelled) {
        stopPublishing();
      }
    });
  }

  /// Attempts to start publishing the driver's location.
  Future<void> startPublishing() async {
    if (_state.isLoading) return; // Prevent concurrent starts

    _state = const ViewState.loading(message: 'Checking location permissions...');
    notifyListeners();

    try {
      final permission = await _locationProvider.requestPermission();
      
      if (_isDisposed) return; // Session safety

      if (permission == LocationPermissionState.denied || 
          permission == LocationPermissionState.permanentlyDenied) {
        _state = const ViewState.error('Location permission is required to share your route.');
        notifyListeners();
        return;
      }
      
      if (permission == LocationPermissionState.locationServicesDisabled) {
        _state = const ViewState.error('Please enable location services on your device.');
        notifyListeners();
        return;
      }

      // Check auth explicitly before streaming
      final driverId = _authController.currentUser?.id;
      if (driverId == null) {
        _state = const ViewState.error('You must be logged in to share location.');
        notifyListeners();
        return;
      }

      _state = const ViewState.success(null);
      notifyListeners();

      _locationSubscription?.cancel();
      _locationSubscription = _locationProvider.getPositionStream().listen(
        (location) => _publishLocation(location, driverId),
        onError: (error) {
          if (_isDisposed) return;
          _state = const ViewState.error('Failed to acquire location. Reconnecting...');
          notifyListeners();
        },
      );
    } catch (e) {
      if (_isDisposed) return;
      _state = const ViewState.error('Could not start location sharing.');
      notifyListeners();
    }
  }

  Future<void> _publishLocation(DriverLocation location, String driverId) async {
    if (_isDisposed) return;
    
    // Safety check: ensure user hasn't logged out since stream started
    if (_authController.currentUser?.id != driverId) {
      stopPublishing();
      return;
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
      // Note: We don't stop the stream on a single update failure to allow automatic recovery.
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

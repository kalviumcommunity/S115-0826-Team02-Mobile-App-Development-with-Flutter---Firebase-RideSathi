import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/ride_model.dart';
import '../../services/ride_service.dart';
import '../../services/firestore_exception.dart';
import 'auth_controller.dart';
import 'view_state.dart';

/// Controller for monitoring all requested rides in the system for dispatchers.
class DispatcherRequestedRidesController extends ChangeNotifier {
  final RideService _rideService;
  final AuthController _authController;

  StreamSubscription<List<RideModel>>? _subscription;
  ViewState<List<RideModel>> _state = const ViewState.initial();
  bool _isDisposed = false;
  int? _sessionGeneration;

  DispatcherRequestedRidesController({
    RideService? rideService,
    AuthController? authController,
  })  : _rideService = rideService ?? const RideService(),
        _authController = authController ?? AuthController.instance {
    _init();
  }

  ViewState<List<RideModel>> get state => _state;

  void _init() {
    _authController.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  void _onAuthChanged() {
    if (_isDisposed) return;
    
    if (!_authController.isAuthenticated || _authController.currentUser?.role != UserRole.dispatcher && _authController.currentUser?.role != UserRole.admin) {
      _stopListening();
      return;
    }

    if (_sessionGeneration != _authController.sessionGeneration) {
      _sessionGeneration = _authController.sessionGeneration;
      _startListening();
    }
  }

  void _startListening() {
    _stopListening();
    _setState(const ViewState.loading('Loading requested rides...'));

    final currentSession = _sessionGeneration;

    try {
      _subscription = _rideService.watchAllRequestedRides().listen(
        (rides) {
          if (_isDisposed || _sessionGeneration != currentSession) return;
          
          // Sort descending by created/updated time
          rides.sort((a, b) {
            final timeA = a.updatedAt ?? a.createdAt;
            final timeB = b.updatedAt ?? b.createdAt;
            return timeB.compareTo(timeA);
          });
          
          if (rides.isEmpty) {
            _setState(const ViewState.empty('No requested rides found.'));
          } else {
            _setState(ViewState.success(rides));
          }
        },
        onError: (error) {
          if (_isDisposed || _sessionGeneration != currentSession) return;
          _setState(ViewState.error('Failed to load requested rides', null, error));
        },
      );
    } catch (e) {
      if (_isDisposed || _sessionGeneration != currentSession) return;
      _setState(ViewState.error('Failed to initialize requested rides stream', null, e));
    }
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
    if (!_isDisposed) {
      _setState(const ViewState.initial());
    }
  }

  void _setState(ViewState<List<RideModel>> newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  void retry() {
    if (_authController.isAuthenticated) {
      _startListening();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authController.removeListener(_onAuthChanged);
    _stopListening();
    super.dispose();
  }
}

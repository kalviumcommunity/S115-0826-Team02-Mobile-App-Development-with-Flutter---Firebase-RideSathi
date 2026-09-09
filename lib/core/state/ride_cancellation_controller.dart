import 'package:flutter/foundation.dart';
import '../../services/ride_service.dart';
import 'auth_controller.dart';
import 'view_state.dart';

/// Manages the state and business logic for cancelling an active ride.
class RideCancellationController extends ChangeNotifier {
  final RideService _rideService;
  final AuthController _authController;

  ViewState<void> _state = const ViewState.initial();
  bool _isDisposed = false;

  RideCancellationController({
    RideService? rideService,
    AuthController? authController,
  })  : _rideService = rideService ?? RideService(),
        _authController = authController ?? AuthController.instance;

  /// The current state of the cancellation operation.
  ViewState<void> get state => _state;

  /// Attempts to cancel the ride with the given [rideId].
  /// 
  /// Updates [state] and notifies listeners accordingly.
  Future<void> cancelRide(String rideId) async {
    if (_state.isLoading || _isDisposed) return;

    if (rideId.trim().isEmpty) {
      _setState(const ViewState.error('Invalid ride ID.'));
      return;
    }

    final riderId = _authController.currentUser?.id;
    if (riderId == null) {
      _setState(const ViewState.error('You must be logged in to cancel a ride.'));
      return;
    }

    _setState(const ViewState.loading());

    try {
      await _rideService.cancelRide(rideId, riderId);
      
      if (_isDisposed) return;
      _setState(const ViewState.success(null));
      
    } catch (e) {
      if (_isDisposed) return;
      // We rely on the RideService/FirestoreException to provide user-friendly messages
      _setState(ViewState.error(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _setState(ViewState<void> newState) {
    if (!_isDisposed && _state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';
import '../../models/ride_model.dart';
import '../../models/ride_request_draft.dart';
import '../../services/ride_service.dart';
import '../../services/firestore_exception.dart';
import 'view_state.dart';
import 'auth_controller.dart';

/// Controller handling the state of a single ride request submission.
/// 
/// Protects against duplicate submissions and respects session generation.
class RideRequestController extends ChangeNotifier {
  final RideService _rideService;
  final AuthController _authController;
  
  ViewState<RideModel> _state = const ViewState.initial();
  bool _isDisposed = false;

  RideRequestController({
    RideService? rideService,
    AuthController? authController,
  })  : _rideService = rideService ?? RideService(),
        _authController = authController ?? AuthController.instance;

  /// Current async state of the ride request.
  ViewState<RideModel> get state => _state;

  /// Submits the ride request to Firestore.
  /// 
  /// Prevents duplicate submissions if already loading.
  Future<void> submitRequest(RideRequestDraft draft) async {
    if (_isDisposed) return;

    if (_state.isLoading) {
      return; // Deduplicate concurrent submissions
    }

    if (!draft.isComplete) {
      _setState(const ViewState.error('Missing pickup or destination.'));
      return;
    }

    final currentUser = _authController.currentUser;
    if (currentUser == null) {
      _setState(const ViewState.error('You must be logged in to request a ride.'));
      return;
    }

    final currentGeneration = _authController.sessionGeneration;
    final riderId = currentUser.id;

    _setState(const ViewState.loading());

    try {
      final ride = await _rideService.createRideRequest(draft, riderId);

      // Protect against stale session updates
      if (_isDisposed || _authController.sessionGeneration != currentGeneration) {
        return;
      }

      _setState(ViewState.success(ride));
    } on FirestoreException catch (e) {
      if (_isDisposed || _authController.sessionGeneration != currentGeneration) return;
      _setState(ViewState.error(e.message));
    } catch (e) {
      if (_isDisposed || _authController.sessionGeneration != currentGeneration) return;
      _setState(const ViewState.error('An unexpected error occurred while requesting your ride.'));
    }
  }

  /// Clears error or success state, returning to initial.
  void reset() {
    if (!_isDisposed && !_state.isLoading) {
      _setState(const ViewState.initial());
    }
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
    super.dispose();
  }
}

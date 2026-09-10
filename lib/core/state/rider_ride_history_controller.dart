import 'package:flutter/foundation.dart';
import '../../models/ride_model.dart';
import '../../services/ride_service.dart';
import '../../services/firestore_exception.dart';
import 'auth_controller.dart';
import 'view_state.dart';

/// State controller for managing the Rider Ride History UI lifecycle.
///
/// Ensures history requests are bound to the currently authenticated rider session.
/// Protects against duplicate loads and handles Firestore exceptions.
class RiderRideHistoryController extends ChangeNotifier {
  final RideService _rideService;
  final AuthController _authController;

  ViewState<List<RideModel>> _state = const ViewState.initial();
  bool _isDisposed = false;

  RiderRideHistoryController({
    RideService? rideService,
    AuthController? authController,
  })  : _rideService = rideService ?? RideService(),
        _authController = authController ?? AuthController.instance;

  ViewState<List<RideModel>> get state => _state;

  /// Fetches the rider's ride history from Firestore.
  /// 
  /// Uses a default [limit] of 20 to prevent unbounded queries.
  Future<void> loadHistory({int limit = 20}) async {
    if (_isDisposed || _state.isLoading) return;

    final currentUser = _authController.currentUser;
    if (currentUser == null) {
      _setState(const ViewState.error('User is not authenticated.'));
      return;
    }

    final currentGeneration = _authController.sessionGeneration;
    _setState(const ViewState.loading());

    try {
      final history = await _rideService.getRiderRideHistory(currentUser.id, limit: limit);

      // Protect against stale session updates if user logged out or changed
      if (_isDisposed || _authController.sessionGeneration != currentGeneration) {
        return;
      }

      _setState(ViewState.success(history));
    } on FirestoreException catch (e) {
      if (_isDisposed || _authController.sessionGeneration != currentGeneration) return;
      _setState(ViewState.error(e.message));
    } catch (e) {
      if (_isDisposed || _authController.sessionGeneration != currentGeneration) return;
      _setState(const ViewState.error('An unexpected error occurred while loading history.'));
    }
  }

  /// Clears the history state, useful on explicit logout or refresh logic.
  void clear() {
    if (!_isDisposed && !_state.isLoading) {
      _setState(const ViewState.initial());
    }
  }

  void _setState(ViewState<List<RideModel>> newState) {
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

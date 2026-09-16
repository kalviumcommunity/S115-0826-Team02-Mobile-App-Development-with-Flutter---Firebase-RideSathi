import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/candidate_evaluation.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_exception.dart';
import '../../services/nearest_driver_service.dart';
import '../../services/service_exception.dart';
import 'auth_controller.dart';
import 'view_state.dart';

/// Manages the real-time nearest driver ranking state for a specific ride.
///
/// Subscribes to [NearestDriverService] which delegates through to the candidate
/// stream established in PR 40. Handles session safety, ride-switch protection,
/// and lifecycle management.
class NearestDriverController extends ChangeNotifier {
  final NearestDriverService _nearestDriverService;
  final AuthController _authController;

  ViewState<List<CandidateEvaluation>> _state = const ViewState.initial();
  StreamSubscription<List<CandidateEvaluation>>? _subscription;
  bool _isDisposed = false;
  int _activeSessionGeneration = 0;
  String? _activeRideId;

  NearestDriverController({
    NearestDriverService? nearestDriverService,
    AuthController? authController,
  })  : _nearestDriverService = nearestDriverService ?? const NearestDriverService(),
        _authController = authController ?? AuthController.instance {
    _init();
  }

  /// Current UI view state containing the ranked, eligible candidate list.
  ViewState<List<CandidateEvaluation>> get state => _state;

  void _init() {
    _authController.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    final user = _authController.currentUser;
    final currentGen = _authController.sessionGeneration;
    if (user == null ||
        (user.role != UserRole.dispatcher && user.role != UserRole.admin) ||
        _activeSessionGeneration != currentGen) {
      stopListening();
    }
  }

  /// Starts listening to the nearest driver ranking for the given [ride].
  ///
  /// Cancels any existing subscription (ride-switch safety).
  void startListening(RideModel ride) {
    if (_isDisposed) return;

    final user = _authController.currentUser;
    if (user == null ||
        (user.role != UserRole.dispatcher && user.role != UserRole.admin)) {
      _state = const ViewState.error('Dispatcher authentication required.');
      notifyListeners();
      return;
    }

    // Duplicate request protection
    if (_activeRideId == ride.id && _subscription != null) return;

    _subscription?.cancel();
    _activeSessionGeneration = _authController.sessionGeneration;
    _activeRideId = ride.id;
    final captureSessionGen = _activeSessionGeneration;
    final captureRideId = ride.id;

    _state = const ViewState.loading(message: 'Calculating nearest drivers...');
    notifyListeners();

    try {
      _subscription = _nearestDriverService.watchRankedCandidates(ride).listen(
        (ranked) {
          if (_isDisposed) return;
          // Ride-switch + session guard
          if (_authController.sessionGeneration != captureSessionGen ||
              _activeRideId != captureRideId) {
            return;
          }

          final eligible = ranked.where((e) => e.isEligible).toList();

          if (eligible.isEmpty) {
            _state = const ViewState.empty(message: 'No eligible drivers available.');
          } else {
            _state = ViewState.success(ranked);
          }
          notifyListeners();
        },
        onError: (error) {
          if (_isDisposed) return;
          if (_authController.sessionGeneration != captureSessionGen ||
              _activeRideId != captureRideId) {
            return;
          }

          String errorMessage = 'Failed to load nearest drivers.';
          if (error is ServiceException) {
            errorMessage = error.message;
          } else if (error is FirestoreException) {
            errorMessage = error.message;
          }

          _state = ViewState.error(errorMessage, error: error);
          notifyListeners();
        },
      );
    } catch (e) {
      if (_isDisposed) return;
      _state = const ViewState.error('Failed to initialize nearest driver stream.');
      notifyListeners();
    }
  }

  /// Stops listening to the nearest driver stream.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _activeRideId = null;
    if (!_isDisposed && !_state.isInitial) {
      _state = const ViewState.initial();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authController.removeListener(_onAuthChanged);
    _subscription?.cancel();
    super.dispose();
  }
}

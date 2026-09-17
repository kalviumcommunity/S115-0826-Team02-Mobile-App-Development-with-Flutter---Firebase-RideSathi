import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/candidate_evaluation.dart';
import '../../models/matching_attempt_state.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import '../../services/fallback_matching_service.dart';
import '../../services/nearest_driver_service.dart';
import 'auth_controller.dart';
import 'view_state.dart';

/// Controller managing the fallback sequence and current candidate selection.
/// 
/// Integrates the real-time ranking from [NearestDriverService] and computes
/// the fallback transitions via [FallbackMatchingService].
class FallbackMatchingController extends ChangeNotifier {
  final NearestDriverService _nearestDriverService;
  final FallbackMatchingService _fallbackService;
  final AuthController _authController;

  ViewState<MatchingAttemptState> _state = const ViewState.initial();
  StreamSubscription<List<CandidateEvaluation>>? _subscription;
  
  bool _isDisposed = false;
  int _activeSessionGeneration = 0;
  String? _activeRideId;
  MatchingAttemptState _currentAttemptState = const MatchingAttemptState();

  FallbackMatchingController({
    NearestDriverService? nearestDriverService,
    FallbackMatchingService? fallbackService,
    AuthController? authController,
  })  : _nearestDriverService = nearestDriverService ?? NearestDriverService(),
        _fallbackService = fallbackService ?? FallbackMatchingService(),
        _authController = authController ?? AuthController.instance {
    _authController.addListener(_onAuthChanged);
  }

  /// The current state of the candidate selection/fallback attempt.
  ViewState<MatchingAttemptState> get state => _state;

  void _onAuthChanged() {
    if (_isDisposed) return;
    final user = _authController.currentUser;
    final currentGen = _authController.sessionGeneration;
    if (user == null ||
        (user.role != UserRole.dispatcher && user.role != UserRole.admin) ||
        _activeSessionGeneration != currentGen) {
      stopListening();
    }
  }

  /// Starts or updates the listening session for a specific [ride].
  void startListening(RideModel ride) {
    if (_isDisposed) return;

    final user = _authController.currentUser;
    if (user == null || (user.role != UserRole.dispatcher && user.role != UserRole.admin)) {
      _setState(const ViewState.error('Dispatcher authentication required.'));
      return;
    }

    // Terminal/Active Ride State Checks
    if (ride.status == RideStatus.timedOut) {
      stopListening();
      _currentAttemptState = _currentAttemptState.copyWith(status: MatchingAttemptStatus.timedOut);
      _setState(ViewState.success(_currentAttemptState));
      return;
    }

    if (ride.status != RideStatus.requested) {
      stopListening();
      _currentAttemptState = const MatchingAttemptState(status: MatchingAttemptStatus.idle);
      _setState(ViewState.success(_currentAttemptState));
      return;
    }

    // Duplicate request protection (if same ride, let the stream continue)
    if (_activeRideId == ride.id && _subscription != null) return;

    _subscription?.cancel();
    _activeSessionGeneration = _authController.sessionGeneration;
    _activeRideId = ride.id;
    _currentAttemptState = const MatchingAttemptState(status: MatchingAttemptStatus.searching);
    
    _setState(const ViewState.loading(message: 'Searching for candidates...'));

    final captureSessionGen = _activeSessionGeneration;
    final captureRideId = ride.id;

    _subscription = _nearestDriverService.watchRankedCandidates(ride).listen(
      (rankedCandidates) {
        if (_isDisposed) return;
        // Session and Ride-switch guard
        if (_authController.sessionGeneration != captureSessionGen || _activeRideId != captureRideId) {
          return;
        }

        _currentAttemptState = _fallbackService.computeNextState(rankedCandidates, _currentAttemptState);
        _setState(ViewState.success(_currentAttemptState));
      },
      onError: (error) {
        if (_isDisposed) return;
        if (_authController.sessionGeneration != captureSessionGen || _activeRideId != captureRideId) {
          return;
        }
        
        _currentAttemptState = _currentAttemptState.copyWith(
          status: MatchingAttemptStatus.error,
          errorMessage: error.toString(),
        );
        _setState(ViewState.error(error.toString()));
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _activeRideId = null;
  }

  void _setState(ViewState<MatchingAttemptState> newState) {
    if (!_isDisposed && _state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    stopListening();
    _authController.removeListener(_onAuthChanged);
    super.dispose();
  }
}

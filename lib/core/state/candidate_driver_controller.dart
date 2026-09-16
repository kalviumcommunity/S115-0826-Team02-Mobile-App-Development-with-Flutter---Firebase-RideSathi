import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/candidate_evaluation.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import '../../services/candidate_driver_service.dart';
import '../../services/firestore_exception.dart';
import 'auth_controller.dart';
import 'view_state.dart';

/// Manages the real-time candidate driver evaluation state for a specific ride.
///
/// Ensures session safety, role protection (dispatcher/admin), and ride-switch
/// safety (cancels previous subscriptions when a new ride is loaded).
class CandidateDriverController extends ChangeNotifier {
  final CandidateDriverService _candidateService;
  final AuthController _authController;

  ViewState<List<CandidateEvaluation>> _state = const ViewState.initial();
  StreamSubscription<List<CandidateEvaluation>>? _subscription;
  bool _isDisposed = false;
  int _activeSessionGeneration = 0;
  String? _activeRideId;

  CandidateDriverController({
    CandidateDriverService? candidateService,
    AuthController? authController,
  })  : _candidateService = candidateService ?? const CandidateDriverService(),
        _authController = authController ?? AuthController.instance {
    _init();
  }

  /// Current UI view state containing the list of evaluated candidates.
  ViewState<List<CandidateEvaluation>> get state => _state;

  void _init() {
    _authController.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    final user = _authController.currentUser;
    final currentGen = _authController.sessionGeneration;

    if (user == null || (user.role != UserRole.dispatcher && user.role != UserRole.admin) || _activeSessionGeneration != currentGen) {
      stopListening();
    }
  }

  /// Starts listening to candidate evaluations for the given [ride].
  ///
  /// Safe against duplicate requests and ride switching.
  void startListening(RideModel ride) {
    if (_isDisposed) return;

    final user = _authController.currentUser;
    if (user == null || (user.role != UserRole.dispatcher && user.role != UserRole.admin)) {
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

    _state = const ViewState.loading(message: 'Evaluating candidates...');
    notifyListeners();

    try {
      _subscription = _candidateService.watchCandidatesForRide(ride).listen(
        (evaluations) {
          if (_isDisposed) return;

          // Session generation and ride-switch guard
          if (_authController.sessionGeneration != captureSessionGen || _activeRideId != captureRideId) {
            return;
          }

          if (evaluations.isEmpty) {
            _state = const ViewState.empty(message: 'No candidates available for this ride.');
          } else {
            // Sort to ensure deterministic UI presentation
            // 1. Eligible first
            // 2. Verified first
            // 3. Name alphabetical
            final sorted = List<CandidateEvaluation>.from(evaluations)
              ..sort((a, b) {
                if (a.isEligible && !b.isEligible) return -1;
                if (!a.isEligible && b.isEligible) return 1;

                if (a.driver.isUnionVerified && !b.driver.isUnionVerified) return -1;
                if (!a.driver.isUnionVerified && b.driver.isUnionVerified) return 1;

                return a.driver.name.toLowerCase().compareTo(b.driver.name.toLowerCase());
              });
            _state = ViewState.success(sorted);
          }
          notifyListeners();
        },
        onError: (error) {
          if (_isDisposed) return;
          if (_authController.sessionGeneration != captureSessionGen || _activeRideId != captureRideId) {
            return;
          }

          final errorMessage = error is FirestoreException
              ? error.message
              : 'Failed to evaluate candidates.';

          _state = ViewState.error(errorMessage, error: error);
          notifyListeners();
        },
      );
    } catch (e) {
      if (_isDisposed) return;
      _state = const ViewState.error('Failed to initialize candidate evaluation stream.');
      notifyListeners();
    }
  }

  /// Stops listening to the candidate stream.
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

import 'package:flutter/foundation.dart';
import '../../services/firestore_exception.dart';
import '../../services/ride_service.dart';
import 'auth_controller.dart';
import 'view_state.dart';

/// State controller for managing Ride Feedback submission.
///
/// Ensures feedback is submitted by the currently authenticated user
/// and prevents concurrent duplicate submissions.
class RideFeedbackController extends ChangeNotifier {
  final RideService _rideService;
  final AuthController _authController;

  ViewState<void> _state = const ViewState.initial();
  bool _isDisposed = false;

  RideFeedbackController({
    RideService? rideService,
    AuthController? authController,
  })  : _rideService = rideService ?? RideService(),
        _authController = authController ?? AuthController.instance;

  ViewState<void> get state => _state;

  /// Submits the feedback to the backend.
  Future<bool> submitFeedback(String rideId, int rating, String? comment) async {
    if (_isDisposed || _state.isLoading) return false;

    final currentUser = _authController.currentUser;
    if (currentUser == null) {
      _setState(const ViewState.error('User is not authenticated.'));
      return false;
    }

    // Basic client-side validation
    if (rating < 1 || rating > 5) {
      _setState(const ViewState.error('Please select a rating between 1 and 5 stars.'));
      return false;
    }
    if (comment != null && comment.length > 500) {
      _setState(const ViewState.error('Comment must be less than 500 characters.'));
      return false;
    }

    final currentGeneration = _authController.sessionGeneration;
    _setState(const ViewState.loading());

    try {
      await _rideService.submitRideFeedback(
        rideId,
        currentUser.id,
        rating,
        comment: comment,
      );

      // Verify the session hasn't changed during the async wait
      if (_isDisposed || _authController.sessionGeneration != currentGeneration) {
        return false;
      }

      _setState(const ViewState.success(null));
      return true;
    } on FirestoreException catch (e) {
      if (_isDisposed || _authController.sessionGeneration != currentGeneration) return false;
      _setState(ViewState.error(e.message));
      return false;
    } catch (e) {
      if (_isDisposed || _authController.sessionGeneration != currentGeneration) return false;
      _setState(const ViewState.error('An unexpected error occurred while submitting feedback.'));
      return false;
    }
  }

  void reset() {
    if (!_isDisposed && !_state.isLoading) {
      _setState(const ViewState.initial());
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

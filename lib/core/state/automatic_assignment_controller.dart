import 'package:flutter/foundation.dart';
import '../../models/matching_attempt_state.dart';
import '../../services/ride_service.dart';
import 'fallback_matching_controller.dart';

/// Controller responsible for automatically assigning a ride to a candidate.
/// 
/// Listens to the [FallbackMatchingController] and initiates an atomic assignment
/// transaction via [RideService] when a candidate is selected or on fallback.
class AutomaticAssignmentController extends ChangeNotifier {
  final FallbackMatchingController fallbackController;
  final RideService rideService;
  
  bool _isDisposed = false;
  bool _isAssigning = false;
  String? _activeRideId;
  
  // Keep track of candidates we have attempted for the current ride to avoid infinite loops.
  final Set<String> _attemptedCandidateIds = {};

  AutomaticAssignmentController({
    required this.fallbackController,
    RideService? rideService,
  }) : rideService = rideService ?? RideService() {
    fallbackController.addListener(_onFallbackStateChanged);
  }

  void _onFallbackStateChanged() {
    if (_isDisposed || _isAssigning) return;

    final state = fallbackController.state;
    state.maybeWhen(
      success: (attemptState) {
        if (attemptState.status == MatchingAttemptStatus.candidateSelected ||
            attemptState.status == MatchingAttemptStatus.fallbackTransition) {
          final candidate = attemptState.currentCandidate;
          if (candidate != null && _activeRideId != null) {
            _attemptAssignment(candidate.driver.id);
          }
        }
      },
      orElse: () {},
    );
  }

  Future<void> _attemptAssignment(String driverId) async {
    if (_activeRideId == null || _attemptedCandidateIds.contains(driverId)) return;
    
    _isAssigning = true;
    _attemptedCandidateIds.add(driverId);
    
    try {
      await rideService.assignRide(_activeRideId!, driverId);
      // Success! The ride stream will now see status == accepted, 
      // which stops the FallbackMatchingController automatically.
      _isAssigning = false;
    } catch (e) {
      // Failed to assign (e.g. driver went offline during the transaction, 
      // or ride timed out, or ride cancelled).
      _isAssigning = false;
      
      // If it failed due to the driver, FallbackMatchingController's stream
      // should naturally evaluate the driver as ineligible on the next tick
      // and trigger a fallbackTransition on its own.
      // If it failed because the ride state changed (cancelled/timedOut),
      // the ride stream listener will catch it.
    }
  }

  /// Sets the active ride ID being monitored.
  void setRideId(String rideId) {
    if (_activeRideId != rideId) {
      _activeRideId = rideId;
      _attemptedCandidateIds.clear();
      _isAssigning = false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    fallbackController.removeListener(_onFallbackStateChanged);
    super.dispose();
  }
}

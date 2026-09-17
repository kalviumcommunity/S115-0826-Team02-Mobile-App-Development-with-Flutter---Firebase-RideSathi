import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/state/automatic_assignment_controller.dart';
import '../../core/state/fallback_matching_controller.dart';
import '../../models/candidate_evaluation.dart';
import '../../models/fallback_reason.dart';
import '../../models/ride_model.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../services/ride_service.dart';
import '../../models/matching_attempt_state.dart';

/// A minimal dispatcher screen for validating Candidate Driver Discovery and
/// Nearest Driver ranking (PR 40 + PR 41 validation surface).
///
/// Displays eligible ranked candidates and excluded drivers.
/// Contains NO assignment, auto-dispatch, ETA, or map logic.
class CandidateValidationScreen extends StatefulWidget {
  final RideModel ride;
  final bool isReassignment;
  final String? currentDriverId;

  const CandidateValidationScreen({
    super.key,
    required this.ride,
    this.isReassignment = false,
    this.currentDriverId,
  });

  @override
  State<CandidateValidationScreen> createState() =>
      _CandidateValidationScreenState();
}

class _CandidateValidationScreenState extends State<CandidateValidationScreen> {
  late final FallbackMatchingController _fallbackController;
  late final AutomaticAssignmentController _assignmentController;

  @override
  void initState() {
    super.initState();
    _fallbackController = FallbackMatchingController();
    _fallbackController.addListener(_onStateChanged);
    
    _assignmentController = AutomaticAssignmentController(fallbackController: _fallbackController);
    _assignmentController.setRideId(widget.ride.id);
    
    _fallbackController.startListening(widget.ride);
  }

  void _onStateChanged() => setState(() {});

  @override
  void dispose() {
    _fallbackController.removeListener(_onStateChanged);
    _assignmentController.dispose();
    _fallbackController.dispose();
    super.dispose();
  }

  String _formatDistance(double? km) {
    if (km == null) return '—';
    if (km < 1.0) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  Future<void> _assignDriver(String driverId) async {
    final service = RideService();
    try {
      if (widget.isReassignment) {
        await service.reassignRide(widget.ride.id, widget.currentDriverId!, driverId);
      } else {
        // Explicit manual assignment overrides automatic assignment.
        // We pause the auto-assigner just in case it's about to fire.
        _assignmentController.dispose();
        await service.assignRide(widget.ride.id, driverId);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully assigned to driver $driverId')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign driver: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _fallbackController.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matching Fallback & Candidates'),
      ),
      body: Column(
        children: [
          _buildRideInfo(context),
          const Divider(height: 1),
          Expanded(
            child: state.when(
              initial: () => const LoadingView(message: 'Initializing stream...'),
              loading: (msg) => LoadingView(message: msg),
              error: (msg, code, err) => ErrorView(
                message: msg,
                onRetry: () => _fallbackController.startListening(widget.ride),
              ),
              empty: (msg) => EmptyStateView(
                icon: Icons.search_off_rounded,
                title: msg ?? 'No candidates found',
              ),
              success: (attemptState) {
                final evaluations = attemptState.rankedCandidates;
                final eligible = evaluations.where((e) => e.isEligible).toList();
                final excluded = evaluations.where((e) => !e.isEligible).toList();
                
                final currentCandidateId = attemptState.currentCandidate?.driver.id;

                return RefreshIndicator(
                  onRefresh: () async {
                    _fallbackController.stopListening();
                    _fallbackController.startListening(widget.ride);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(AppConstants.spaceL),
                    children: [
                      if (attemptState.status == MatchingAttemptStatus.fallbackTransition)
                        _buildFallbackNotice(context, attemptState.lastFallbackReason),
                      if (attemptState.status == MatchingAttemptStatus.timedOut)
                        _buildTimedOutNotice(context),
                        
                      _buildSectionHeader(context, 'Eligible Candidates', eligible.length),
                      if (eligible.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppConstants.spaceM),
                          child: Text('No eligible candidates found. Waiting...'),
                        ),
                      ...eligible.asMap().entries.map((e) {
                        final isCurrent = e.value.driver.id == currentCandidateId;
                        final isNext = (!isCurrent && eligible.indexOf(e.value) == 1 && currentCandidateId != null) || 
                                       (currentCandidateId == null && e.key == 0);
                        
                        return _buildCandidateCard(
                          context,
                          e.value,
                          rank: e.key + 1,
                          isCurrentCandidate: isCurrent,
                          isNextCandidate: isNext,
                        );
                      }),
                      const SizedBox(height: AppConstants.spaceL),
                      _buildSectionHeader(context, 'Excluded Drivers', excluded.length),
                      if (excluded.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppConstants.spaceM),
                          child: Text('No drivers were excluded.'),
                        ),
                      ...excluded.map((e) => _buildCandidateCard(context, e)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackNotice(BuildContext context, FallbackReason? reason) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spaceL),
      padding: const EdgeInsets.all(AppConstants.spaceM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: AppConstants.spaceS),
          Expanded(
            child: Text(
              'Fallback triggered: ${_formatReason(reason)}',
              style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimedOutNotice(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spaceL),
      padding: const EdgeInsets.all(AppConstants.spaceM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: const Row(
        children: [
          Icon(Icons.timer_off_rounded),
          SizedBox(width: AppConstants.spaceS),
          Expanded(child: Text('Ride Request Timed Out.')),
        ],
      ),
    );
  }
  
  String _formatReason(FallbackReason? reason) {
    switch (reason) {
      case FallbackReason.wentOffline: return 'Driver went offline';
      case FallbackReason.activeOnAnotherRide: return 'Driver is active on another ride';
      case FallbackReason.lostLocation: return 'Driver lost location';
      case FallbackReason.noLongerEligible: return 'Driver is no longer eligible';
      case FallbackReason.disappeared: return 'Candidate disappeared from stream';
      case FallbackReason.rankChanged: return 'Another driver became closer';
      case FallbackReason.acceptedAnotherRide: return 'Driver accepted another ride';
      case FallbackReason.unknown:
      default: return 'Unknown reason';
    }
  }

  Widget _buildRideInfo(BuildContext context) {
    final pickup = widget.ride.pickup;
    final hasCoords = pickup.latitude != null && pickup.longitude != null;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceL),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 24),
          const SizedBox(width: AppConstants.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ride: ${widget.ride.id.substring(0, 8)}...',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Vehicle: ${widget.ride.vehicleType.name}'),
                Text('Pickup: ${pickup.displayName}'),
                if (hasCoords)
                  Text(
                    'Coords: ${pickup.latitude!.toStringAsFixed(4)}, ${pickup.longitude!.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  Text(
                    '⚠ Pickup has no coordinates — distances unavailable',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spaceM),
      child: Text(
        '$title ($count)',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildCandidateCard(
    BuildContext context,
    CandidateEvaluation eval, {
    int? rank,
    bool isCurrentCandidate = false,
    bool isNextCandidate = false,
  }) {
    final driver = eval.driver;
    final isEligible = eval.isEligible;

    return Card(
      color: isEligible
          ? (isCurrentCandidate ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.25) : null)
          : Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
      margin: const EdgeInsets.only(bottom: AppConstants.spaceM),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (rank != null)
                  Padding(
                    padding: const EdgeInsets.only(right: AppConstants.spaceM),
                    child: Text(
                      '#$rank',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isCurrentCandidate
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              driver.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    decoration: isEligible ? null : TextDecoration.lineThrough,
                                    color: isEligible
                                        ? null
                                        : Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          ),
                          if (isCurrentCandidate || isNextCandidate) ...[
                            const SizedBox(width: AppConstants.spaceS),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrentCandidate 
                                    ? Theme.of(context).colorScheme.primary 
                                    : Theme.of(context).colorScheme.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isCurrentCandidate ? 'Current Candidate' : 'Next Candidate',
                                style: TextStyle(
                                  color: isCurrentCandidate 
                                      ? Theme.of(context).colorScheme.onPrimary 
                                      : Theme.of(context).colorScheme.onSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text('Vehicle: ${driver.vehicleInfo ?? "Not specified"}'),
                    ],
                  ),
                ),
                if (driver.isUnionVerified)
                  const Icon(Icons.verified, color: Colors.blue, size: 20)
                else
                  const Icon(Icons.pending_actions, color: Colors.orange, size: 20),
              ],
            ),
            const Divider(),
            if (!isEligible) ...[
              Row(
                children: [
                  Icon(Icons.block, color: Theme.of(context).colorScheme.error, size: 16),
                  const SizedBox(width: AppConstants.spaceS),
                  Text(
                    'Excluded: ${eval.exclusionReason}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spaceS),
            ],
            Row(
              children: [
                Icon(
                  Icons.my_location_rounded,
                  color: eval.distanceKm != null ? Colors.blue : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: AppConstants.spaceS),
                Text(
                  _formatDistance(eval.distanceKm),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: AppConstants.spaceL),
                Icon(
                  driver.isOnline ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                  color: driver.isOnline ? Colors.green : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: AppConstants.spaceS),
                Text(driver.isOnline ? 'Online' : 'Offline'),
                const SizedBox(width: AppConstants.spaceL),
                Icon(
                  driver.activeRideId == null ? Icons.event_available : Icons.event_busy,
                  color: driver.activeRideId == null ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: AppConstants.spaceS),
                Text(driver.activeRideId == null ? 'Available' : 'Occupied'),
              ],
            ),
            if (isEligible) ...[
              const SizedBox(height: AppConstants.spaceM),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _assignDriver(driver.id),
                  icon: const Icon(Icons.assignment_ind),
                  label: Text(widget.isReassignment ? 'Reassign to ${driver.name}' : 'Manually Assign'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

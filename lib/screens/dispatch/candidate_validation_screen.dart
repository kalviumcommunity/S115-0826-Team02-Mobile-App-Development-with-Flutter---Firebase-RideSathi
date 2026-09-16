import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/state/nearest_driver_controller.dart';
import '../../models/candidate_evaluation.dart';
import '../../models/ride_model.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

/// A minimal dispatcher screen for validating Candidate Driver Discovery and
/// Nearest Driver ranking (PR 40 + PR 41 validation surface).
///
/// Displays eligible ranked candidates and excluded drivers.
/// Contains NO assignment, auto-dispatch, ETA, or map logic.
class CandidateValidationScreen extends StatefulWidget {
  final RideModel ride;

  const CandidateValidationScreen({
    super.key,
    required this.ride,
  });

  @override
  State<CandidateValidationScreen> createState() =>
      _CandidateValidationScreenState();
}

class _CandidateValidationScreenState extends State<CandidateValidationScreen> {
  late final NearestDriverController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NearestDriverController();
    _controller.addListener(_onStateChanged);
    _controller.startListening(widget.ride);
  }

  void _onStateChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  String _formatDistance(double? km) {
    if (km == null) return '—';
    if (km < 1.0) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearest Driver Matching'),
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
                onRetry: () => _controller.startListening(widget.ride),
              ),
              empty: (msg) => EmptyStateView(
                icon: Icons.search_off_rounded,
                message: msg,
              ),
              success: (evaluations) {
                final eligible = evaluations.where((e) => e.isEligible).toList();
                final excluded = evaluations.where((e) => !e.isEligible).toList();

                return RefreshIndicator(
                  onRefresh: () async {
                    _controller.stopListening();
                    _controller.startListening(widget.ride);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(AppConstants.spaceL),
                    children: [
                      _buildSectionHeader(context, 'Eligible Candidates', eligible.length),
                      if (eligible.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppConstants.spaceM),
                          child: Text('No eligible candidates found.'),
                        ),
                      ...eligible.asMap().entries.map((e) => _buildCandidateCard(
                            context,
                            e.value,
                            rank: e.key + 1,
                            isNearest: e.key == 0,
                          )),
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

  Widget _buildRideInfo(BuildContext context) {
    final pickup = widget.ride.pickup;
    final hasCoords = pickup.latitude != null && pickup.longitude != null;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceL),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
    bool isNearest = false,
  }) {
    final driver = eval.driver;
    final isEligible = eval.isEligible;

    return Card(
      color: isEligible
          ? (isNearest ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.25) : null)
          : Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
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
                            color: isNearest
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
                          if (isNearest) ...[
                            const SizedBox(width: AppConstants.spaceS),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Nearest',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
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
          ],
        ),
      ),
    );
  }
}

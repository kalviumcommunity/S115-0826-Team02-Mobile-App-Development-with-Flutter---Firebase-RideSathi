import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/ride_status_controller.dart';
import '../../models/ride_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_badge.dart';

class RideStatusScreen extends StatefulWidget {
  final String rideId;

  const RideStatusScreen({super.key, required this.rideId});

  @override
  State<RideStatusScreen> createState() => _RideStatusScreenState();
}

class _RideStatusScreenState extends State<RideStatusScreen> {
  late final RideStatusController _statusController;

  @override
  void initState() {
    super.initState();
    _statusController = RideStatusController(rideId: widget.rideId);
  }

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Status'),
        automaticallyImplyLeading: false, // Prevent simple back navigation without cancelling or intentionally returning Home
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _statusController,
          builder: (context, _) {
            final state = _statusController.state;

            if (state.isLoading || state.isInitial) {
              return const LoadingView(message: 'Loading ride details...');
            }

            if (state.isError) {
              return Padding(
                padding: const EdgeInsets.all(AppConstants.spaceXL),
                child: ErrorView(
                  message: state.message ?? 'Failed to load ride.',
                  retryLabel: 'Return Home',
                  onRetry: () {
                    AppNavigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.riderHome,
                      (route) => false,
                    );
                  },
                ),
              );
            }

            if (state.isSuccess && state.data != null) {
              return _buildRideStatusContent(context, state.data!);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildRideStatusContent(BuildContext context, RideModel ride) {
    final theme = Theme.of(context);

    // Determine user-friendly messaging based on status
    String statusMessage = '';
    String statusDescription = '';
    
    switch (ride.status) {
      case RideStatus.requested:
        statusMessage = 'Your ride request has been received.';
        statusDescription = 'We\'re waiting for the next step.';
        break;
      case RideStatus.accepted:
        statusMessage = 'A driver has accepted your ride!';
        statusDescription = 'They are on their way to your pickup location.';
        break;
      case RideStatus.arrived:
        statusMessage = 'Your driver has arrived!';
        statusDescription = 'Please meet them at the pickup location.';
        break;
      case RideStatus.inProgress:
        statusMessage = 'You are on your way!';
        statusDescription = 'Enjoy the ride to your destination.';
        break;
      case RideStatus.completed:
        statusMessage = 'You have reached your destination.';
        statusDescription = 'Thank you for riding with RideSathi.';
        break;
      case RideStatus.cancelled:
        statusMessage = 'This ride was cancelled.';
        statusDescription = 'You can request a new ride from the home screen.';
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spaceXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: statusMessage,
            subtitle: statusDescription,
          ),
          const SizedBox(height: AppConstants.spaceXL),
          
          Container(
            padding: const EdgeInsets.all(AppConstants.spaceM),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    StatusBadge(
                      status: ride.status.name.toUpperCase(),
                    ),
                  ],
                ),
                const Divider(height: AppConstants.spaceL),
                
                _buildLocationRow(context, 'Pickup', ride.pickup.displayName, Icons.my_location_rounded),
                const SizedBox(height: AppConstants.spaceM),
                _buildLocationRow(context, 'Destination', ride.destination.displayName, Icons.location_on_rounded),
              ],
            ),
          ),
          
          const Spacer(),
          
          CustomButton(
            label: 'Return Home',
            onPressed: () {
              AppNavigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.riderHome,
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: AppConstants.spaceS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

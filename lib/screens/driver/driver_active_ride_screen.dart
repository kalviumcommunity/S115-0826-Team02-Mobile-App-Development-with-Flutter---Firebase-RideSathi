import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/active_ride_controller.dart';
import '../../core/state/auth_controller.dart';
import '../../models/ride_model.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/location_display.dart';
import '../../widgets/status_badge.dart';

/// Driver-facing Active Ride screen for RideSathi.
///
/// Displays the driver's current accepted ride with full ride details.
/// Real-time updates handle rider cancellation and other status changes.
/// This screen is read-only: no status transitions occur here (PR 37).
class DriverActiveRideScreen extends StatefulWidget {
  /// Optional [AuthController] for dependency injection in tests.
  final AuthController? authController;

  /// Optional [ActiveRideController] for dependency injection in tests.
  final ActiveRideController? activeRideController;

  const DriverActiveRideScreen({
    super.key,
    this.authController,
    this.activeRideController,
  });

  @override
  State<DriverActiveRideScreen> createState() => _DriverActiveRideScreenState();
}

class _DriverActiveRideScreenState extends State<DriverActiveRideScreen> {
  late final AuthController _authController;
  late final ActiveRideController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _authController = widget.authController ?? AuthController.instance;

    if (widget.activeRideController != null) {
      _controller = widget.activeRideController!;
      _ownsController = false;
    } else {
      _controller = ActiveRideController(authController: _authController);
      _ownsController = true;
    }

    _controller.startListening();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} — $hour:$minute $period';
  }

  String _vehicleLabel(VehicleType type) {
    switch (type) {
      case VehicleType.autoRickshaw:
        return 'Auto Rickshaw';
      case VehicleType.cabSedan:
        return 'Cab — Sedan';
      case VehicleType.cabHatchback:
        return 'Cab — Hatchback';
      case VehicleType.cabSUV:
        return 'Cab — SUV';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppConstants.primaryAmber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_car_rounded,
                size: 20,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Active Ride',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        leading: BackButton(
          onPressed: () => AppNavigator.toDriverHome(context),
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final state = _controller.state;

          if (state.isInitial || state.isLoading) {
            return const LoadingView(message: 'Loading active ride...');
          }

          if (state.isError) {
            return ErrorView(
              message: state.message ?? 'Failed to load active ride.',
              onRetry: _controller.retry,
            );
          }

          if (state.isEmpty || state.data == null) {
            return EmptyStateView(
              icon: Icons.directions_car_outlined,
              title: 'No Active Ride',
              description:
                  'You do not have an active accepted ride at this moment.',
              actionLabel: 'Back to Home',
              actionIcon: Icons.home_rounded,
              onAction: () => AppNavigator.toDriverHome(context),
            );
          }

          final ride = state.data!;
          return _buildActiveRideContent(context, ride, theme, isDark);
        },
      ),
    );
  }

  Widget _buildActiveRideContent(
    BuildContext context,
    RideModel ride,
    ThemeData theme,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceXL,
        vertical: AppConstants.spaceL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.spaceXL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF064E3B), const Color(0xFF022C22)]
                    : [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusPill),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spaceM),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppConstants.spaceL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ride Accepted',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF065F46),
                        ),
                      ),
                      const SizedBox(height: 4),
                      StatusBadge(status: ride.status.name),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spaceXL),

          // Route Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.route_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Route',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spaceM),
                  const Divider(height: 1),
                  const SizedBox(height: AppConstants.spaceM),
                  LocationDisplay(
                    pickupAddress: ride.pickup.address.trim().isNotEmpty
                        ? ride.pickup.address
                        : 'Pickup address pending',
                    dropoffAddress: ride.destination.address.trim().isNotEmpty
                        ? ride.destination.address
                        : 'Destination pending',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spaceM),

          // Ride Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ride Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spaceM),
                  const Divider(height: 1),
                  const SizedBox(height: AppConstants.spaceM),
                  _detailRow(
                    context,
                    icon: Icons.electric_rickshaw_rounded,
                    label: 'Vehicle',
                    value: _vehicleLabel(ride.vehicleType),
                  ),
                  const SizedBox(height: AppConstants.spaceM),
                  _detailRow(
                    context,
                    icon: Icons.currency_rupee_rounded,
                    label: 'Estimated Fare',
                    value: '₹${ride.estimatedFare.toStringAsFixed(0)}',
                    valueColor: theme.colorScheme.primary,
                    bold: true,
                  ),
                  const SizedBox(height: AppConstants.spaceM),
                  _detailRow(
                    context,
                    icon: Icons.access_time_rounded,
                    label: 'Requested At',
                    value: _formatDateTime(ride.createdAt),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spaceXL),

          // Navigate back to home
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => AppNavigator.toDriverHome(context),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Back to Driver Home'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spaceXL),
        ],
      ),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool bold = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppConstants.spaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: valueColor ?? theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/active_ride_controller.dart';
import '../../core/state/auth_controller.dart';
import '../../core/state/driver_location_controller.dart';
import '../../core/state/ride_progress_controller.dart';
import '../../models/ride_model.dart';
import '../../services/location_provider.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/location_display.dart';
import '../../widgets/location_sharing_status_banner.dart';
import '../../widgets/status_badge.dart';

/// Driver-facing Active Ride screen for RideSathi.
///
/// Displays the driver's current operational ride with full details and
/// status-appropriate action buttons:
///
///   accepted  → [ Arrived at Pickup ]          location OFF
///   arrived   → [ Start Ride ]                 location ON
///   inProgress → [ Complete Ride ]             location ON
///   completed → (navigates back to Driver Home) location OFF
///
/// Location sharing is activated automatically when the ride reaches
/// [arrived] or [inProgress] using the existing [DriverLocationController].
/// It stops on completion, cancellation, logout, or disposal.
class DriverActiveRideScreen extends StatefulWidget {
  /// Optional [AuthController] for dependency injection in tests.
  final AuthController? authController;

  /// Optional [ActiveRideController] for dependency injection in tests.
  final ActiveRideController? activeRideController;

  /// Optional [RideProgressController] for dependency injection in tests.
  final RideProgressController? progressController;

  /// Optional [LocationProvider] for dependency injection in tests.
  final LocationProvider? locationProvider;

  const DriverActiveRideScreen({
    super.key,
    this.authController,
    this.activeRideController,
    this.progressController,
    this.locationProvider,
  });

  @override
  State<DriverActiveRideScreen> createState() => _DriverActiveRideScreenState();
}

class _DriverActiveRideScreenState extends State<DriverActiveRideScreen> {
  late final AuthController _authController;
  late final ActiveRideController _activeRideController;
  late final RideProgressController _progressController;
  bool _ownsActiveRideController = false;
  bool _ownsProgressController = false;

  /// Location controller, created lazily when an operational ride is first confirmed.
  DriverLocationController? _locationController;
  String? _locationRideId; // track which rideId the controller is for

  @override
  void initState() {
    super.initState();
    _authController = widget.authController ?? AuthController.instance;

    if (widget.activeRideController != null) {
      _activeRideController = widget.activeRideController!;
      _ownsActiveRideController = false;
    } else {
      _activeRideController =
          ActiveRideController(authController: _authController);
      _ownsActiveRideController = true;
    }

    _activeRideController.startListening();

    if (widget.progressController != null) {
      _progressController = widget.progressController!;
      _ownsProgressController = false;
    } else {
      _progressController = RideProgressController(
        authController: _authController,
        activeRideController: _activeRideController,
      );
      _ownsProgressController = true;
    }

    _progressController.addListener(_onProgressChanged);
    _activeRideController.addListener(_onRideStateChanged);
  }

  void _onProgressChanged() {
    final state = _progressController.state;
    if (state.isError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message ?? 'Action failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      _progressController.clearError();
    }
  }

  void _onRideStateChanged() {
    final activeRide = _activeRideController.activeRide;
    
    // Manage location sharing lifecycle based on ride status
    if (activeRide != null && 
        (activeRide.status == RideStatus.arrived || activeRide.status == RideStatus.inProgress)) {
      if (_locationController == null || _locationRideId != activeRide.id) {
        _locationController?.dispose();
        _locationRideId = activeRide.id;
        _locationController = DriverLocationController(
          rideId: activeRide.id,
          authController: _authController,
          locationProvider: widget.locationProvider,
        )..startPublishing();
        // Force rebuild to show banner
        if (mounted) setState(() {});
      }
    } else {
      // Not in an operational state, stop/dispose location sharing
      if (_locationController != null) {
        _locationController?.stopPublishing();
        _locationController?.dispose();
        _locationController = null;
        _locationRideId = null;
        if (mounted) setState(() {});
      }
    }

    // When ride completes or disappears, navigate back to Driver Home
    final isEmptyOrCompleted = _activeRideController.state.isEmpty ||
        (activeRide != null &&
            (activeRide.status == RideStatus.completed ||
                activeRide.status == RideStatus.cancelled));

    if (isEmptyOrCompleted && mounted) {
      final message = activeRide?.status == RideStatus.cancelled
          ? 'This ride was cancelled by the rider.'
          : activeRide?.status == RideStatus.completed
              ? 'Ride completed!'
              : null;

      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: activeRide?.status == RideStatus.completed
                ? Colors.green
                : Colors.orange,
          ),
        );
      }

      // Small delay for snackbar to show before navigating
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) AppNavigator.toDriverHome(context);
      });
    }
  }

  @override
  void dispose() {
    _locationController?.stopPublishing();
    _locationController?.dispose();
    _progressController.removeListener(_onProgressChanged);
    _activeRideController.removeListener(_onRideStateChanged);
    if (_ownsProgressController) _progressController.dispose();
    if (_ownsActiveRideController) _activeRideController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    const months = [
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
        animation: _activeRideController,
        builder: (context, _) {
          final state = _activeRideController.state;

          if (state.isInitial || state.isLoading) {
            return const LoadingView(message: 'Loading active ride...');
          }

          if (state.isError) {
            return ErrorView(
              message: state.message ?? 'Failed to load active ride.',
              onRetry: _activeRideController.retry,
            );
          }

          if (state.isEmpty || state.data == null) {
            return EmptyStateView(
              icon: Icons.directions_car_outlined,
              title: 'No Active Ride',
              description:
                  'You do not have an active ride at this moment.',
              actionLabel: 'Back to Home',
              actionIcon: Icons.home_rounded,
              onAction: () => AppNavigator.toDriverHome(context),
            );
          }

          final ride = state.data!;
          return _buildRideContent(context, ride, theme, isDark);
        },
      ),
    );
  }

  Widget _buildRideContent(
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
          _StatusBanner(ride: ride, isDark: isDark),

          const SizedBox(height: AppConstants.spaceXL),
          
          if (_locationController != null) ...[
            LocationSharingStatusBanner(controller: _locationController!),
            const SizedBox(height: AppConstants.spaceXL),
          ],

          // Route
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.route_rounded,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Route',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
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

          // Details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Ride Details',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spaceM),
                  const Divider(height: 1),
                  const SizedBox(height: AppConstants.spaceM),
                  _DetailRow(
                    icon: Icons.electric_rickshaw_rounded,
                    label: 'Vehicle',
                    value: _vehicleLabel(ride.vehicleType),
                  ),
                  const SizedBox(height: AppConstants.spaceM),
                  _DetailRow(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Estimated Fare',
                    value: '₹${ride.estimatedFare.toStringAsFixed(0)}',
                    valueColor: theme.colorScheme.primary,
                    bold: true,
                  ),
                  const SizedBox(height: AppConstants.spaceM),
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Requested At',
                    value: _formatDateTime(ride.createdAt),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spaceXL),

          // Action buttons driven by current status
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, _) {
              return _ActionArea(
                ride: ride,
                progressController: _progressController,
                onBack: () => AppNavigator.toDriverHome(context),
              );
            },
          ),

          const SizedBox(height: AppConstants.spaceXL),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status Banner
// ---------------------------------------------------------------------------

class _StatusBanner extends StatelessWidget {
  final RideModel ride;
  final bool isDark;

  const _StatusBanner({required this.ride, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bg1;
    Color bg2;
    Color iconColor;
    IconData icon;
    String label;

    switch (ride.status) {
      case RideStatus.accepted:
        bg1 = isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
        bg2 = isDark ? const Color(0xFF022C22) : const Color(0xFFA7F3D0);
        iconColor = Colors.green;
        icon = Icons.check_circle_rounded;
        label = 'Ride Accepted';
        break;
      case RideStatus.arrived:
        bg1 = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDEEEFF);
        bg2 = isDark ? const Color(0xFF0F2040) : const Color(0xFFBDD8FF);
        iconColor = Colors.blue;
        icon = Icons.location_on_rounded;
        label = 'You Have Arrived';
        break;
      case RideStatus.inProgress:
        bg1 = isDark ? const Color(0xFF3B2F05) : const Color(0xFFFFF8E1);
        bg2 = isDark ? const Color(0xFF1F1803) : const Color(0xFFFFECB3);
        iconColor = Colors.orange;
        icon = Icons.navigation_rounded;
        label = 'Ride In Progress';
        break;
      default:
        bg1 = isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surfaceContainerLow;
        bg2 = bg1;
        iconColor = theme.colorScheme.primary;
        icon = Icons.info_outline_rounded;
        label = ride.status.name;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spaceXL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bg1, bg2],
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
              color: iconColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(width: AppConstants.spaceL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                StatusBadge(status: ride.status.name),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action Area
// ---------------------------------------------------------------------------

class _ActionArea extends StatelessWidget {
  final RideModel ride;
  final RideProgressController progressController;
  final VoidCallback onBack;

  const _ActionArea({
    required this.ride,
    required this.progressController,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = progressController.state.isLoading;

    switch (ride.status) {
      case RideStatus.accepted:
        return _PrimaryActionButton(
          label: 'Arrived at Pickup',
          icon: Icons.location_on_rounded,
          color: Colors.blue,
          isLoading: isLoading,
          loadingLabel: 'Updating...',
          onPressed: () => progressController.markArrived(),
        );

      case RideStatus.arrived:
        return _PrimaryActionButton(
          label: 'Start Ride',
          icon: Icons.navigation_rounded,
          color: Colors.orange,
          isLoading: isLoading,
          loadingLabel: 'Starting ride...',
          onPressed: () => progressController.startRide(),
        );

      case RideStatus.inProgress:
        return _PrimaryActionButton(
          label: 'Complete Ride',
          icon: Icons.flag_rounded,
          color: Colors.green,
          isLoading: isLoading,
          loadingLabel: 'Completing...',
          onPressed: () => _confirmComplete(context),
        );

      default:
        // Completed / cancelled / unexpected — show back button only
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.home_rounded),
            label: const Text('Back to Driver Home'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
            ),
          ),
        );
    }
  }

  Future<void> _confirmComplete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Ride?'),
        content: const Text(
          'Are you sure you want to mark this ride as completed? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Complete Ride',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await progressController.completeRide();
    }
  }
}

// ---------------------------------------------------------------------------
// Reusable Primary Action Button
// ---------------------------------------------------------------------------

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final String loadingLabel;
  final VoidCallback? onPressed;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.loadingLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon),
        label: Text(
          isLoading ? loadingLabel : label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail Row
// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
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

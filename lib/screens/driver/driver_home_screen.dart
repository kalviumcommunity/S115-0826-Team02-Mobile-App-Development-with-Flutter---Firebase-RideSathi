import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/active_ride_controller.dart';
import '../../core/state/auth_controller.dart';
import '../../core/state/incoming_ride_requests_controller.dart';
import '../../core/state/ride_acceptance_controller.dart';
import '../../core/state/ride_rejection_controller.dart';
import '../../core/state/driver_availability_controller.dart';
import '../../core/theme/theme_controller.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/info_card.dart';
import '../../widgets/loading_view.dart';

import '../../widgets/ride_summary_card.dart';
import '../../widgets/union_badge.dart';

/// Landing and dashboard screen for authenticated Drivers in RideSathi.
///
/// Displays driver identity, vehicle details, availability status (Online/Offline),
/// incoming ride request queue, and supports clean logout with navigation stack clearing.
class DriverHomeScreen extends StatefulWidget {
  /// Optional [AuthController] for dependency injection in tests.
  final AuthController? authController;

  /// Optional [IncomingRideRequestsController] for dependency injection in tests.
  final IncomingRideRequestsController? requestsController;

  /// Optional [RideAcceptanceController] for dependency injection in tests.
  final RideAcceptanceController? acceptanceController;

  /// Optional [RideRejectionController] for dependency injection in tests.
  final RideRejectionController? rejectionController;

  /// Optional [DriverAvailabilityController] for dependency injection in tests.
  final DriverAvailabilityController? availabilityController;

  /// Optional [UserModel] for explicit user identity passing.
  final UserModel? user;

  const DriverHomeScreen({
    super.key,
    this.authController,
    this.requestsController,
    this.acceptanceController,
    this.rejectionController,
    this.availabilityController,
    this.user,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  late final AuthController _authController;
  late final IncomingRideRequestsController _requestsController;
  late final RideAcceptanceController _acceptanceController;
  late final RideRejectionController _rejectionController;
  late final ActiveRideController _activeRideController;
  late final DriverAvailabilityController _availabilityController;
  bool _isLoggingOut = false;
  bool _ownsRequestsController = false;
  bool _ownsAcceptanceController = false;
  bool _ownsRejectionController = false;

  @override
  void initState() {
    super.initState();
    _authController = widget.authController ?? AuthController.instance;
    
    if (widget.requestsController != null) {
      _requestsController = widget.requestsController!;
      _ownsRequestsController = false;
    } else {
      _requestsController = IncomingRideRequestsController(
        authController: _authController,
      );
      _ownsRequestsController = true;
    if (widget.acceptanceController != null) {
      _acceptanceController = widget.acceptanceController!;
      _ownsAcceptanceController = false;
    } else {
      _acceptanceController = RideAcceptanceController(
        authController: _authController,
        requestsController: _requestsController,
      );
      _ownsAcceptanceController = true;
    }

    if (widget.rejectionController != null) {
      _rejectionController = widget.rejectionController!;
      _ownsRejectionController = false;
    } else {
      _rejectionController = RideRejectionController(
        authController: _authController,
        requestsController: _requestsController,
      );
      _ownsRejectionController = true;
    }

    // ActiveRideController is always owned by this screen; used for the banner
    _activeRideController = ActiveRideController(authController: _authController)
      ..startListening();

    _acceptanceController.addListener(_onAcceptanceStateChanged);
    _rejectionController.addListener(_onRejectionStateChanged);

    _availabilityController = widget.availabilityController ??
        DriverAvailabilityController(authController: _authController);

    _availabilityController.addListener(_onAvailabilityStateChanged);
  }

  void _onRejectionStateChanged() {
    final state = _rejectionController.state;
    if (state.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message ?? 'Ride rejected.'),
        ),
      );
    } else if (state.isError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message ?? 'Failed to reject ride.'),
          backgroundColor: Colors.red,
        ),
      );
      _rejectionController.clearError();
    }
  }

  void _onAcceptanceStateChanged() {
    final state = _acceptanceController.state;
    if (state.isSuccess) {
      // Navigate to Active Ride screen after successful acceptance
      if (mounted) {
        AppNavigator.toDriverActiveRide(context);
      }
    } else if (state.isError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message ?? 'Failed to accept ride.'),
            backgroundColor: Colors.red,
          ),
        );
        _acceptanceController.clearError();
      }
    }
  }

  @override
  void dispose() {
    _acceptanceController.removeListener(_onAcceptanceStateChanged);
    _rejectionController.removeListener(_onRejectionStateChanged);
    if (_ownsAcceptanceController) {
      _acceptanceController.dispose();
    }
    if (_ownsRejectionController) {
      _rejectionController.dispose();
    }
    _availabilityController.removeListener(_onAvailabilityStateChanged);
    if (widget.availabilityController == null) {
      _availabilityController.dispose();
    }
    if (_ownsRequestsController) {
      _requestsController.dispose();
    }
    _activeRideController.dispose();
    super.dispose();
  }

  void _onAvailabilityStateChanged() {
    if (!mounted) return;
    
    // Sync the local requests controller with the backend-verified availability state
    _requestsController.setOnline(_availabilityController.isOnline);

    if (_availabilityController.state.isError) {
      final errorMessage = _availabilityController.errorMessage ??
          'Failed to update availability.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _availabilityController.toggleAvailability(),
          ),
        ),
      );
      _availabilityController.clearError();
    } else {
      setState(() {});
    }
  }

  Future<void> _handleToggleAvailability() async {
    await _availabilityController.toggleAvailability();
  }

  UserModel? get _currentUser => widget.user ?? _authController.currentUser;

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    _requestsController.setOnline(false);

    final success = await _authController.signOut();

    if (!mounted) return;
    setState(() => _isLoggingOut = false);

    if (success) {
      AppNavigator.logout(context);
    } else {
      final errorMessage = _authController.errorMessage ??
          'Unable to sign out. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _handleLogout,
          ),
        ),
      );
      _authController.clearError();
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dateTime.month - 1];
    final hour = dateTime.hour == 0 ? 12 : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$month ${dateTime.day}, ${dateTime.year} - $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = _currentUser;
    final driverName = user?.name.isNotEmpty == true ? user!.name : 'Driver';
    final vehicleInfo = user?.vehicleInfo?.isNotEmpty == true
        ? user!.vehicleInfo!
        : 'Vehicle details pending';
    final isVerified = user?.isUnionVerified ?? false;

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
              '${AppConstants.appName} Driver',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.themeModeNotifier,
            builder: (context, mode, _) {
              return IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                ),
                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onPressed: () => ThemeController.toggleTheme(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profile',
            onPressed: () => AppNavigator.toProfile(context),
          ),
          IconButton(
            icon: _isLoggingOut
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onSurface,
                      ),
                    ),
                  )
                : const Icon(Icons.logout_rounded),
            tooltip: 'Log Out',
            onPressed: _isLoggingOut ? null : _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceXL,
          vertical: AppConstants.spaceL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Welcome Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.spaceXL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [AppConstants.accentNavy, const Color(0xFF334155)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const UnionBadge(),
                  const SizedBox(height: 14),
                  Text(
                    'Welcome, $driverName',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user?.phoneNumber.isNotEmpty == true
                        ? 'Driver Console • ${user!.phoneNumber}'
                        : 'Union Fleet Operator & Driver Console',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spaceL),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spaceM,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryAmber.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusS),
                          border: Border.all(
                            color:
                                AppConstants.primaryAmber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.drive_eta_rounded,
                              size: 16,
                              color: AppConstants.primaryAmber,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Driver Role Active',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppConstants.spaceM),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spaceM,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.orange.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusS),
                          border: Border.all(
                            color: isVerified
                                ? Colors.green.withValues(alpha: 0.4)
                                : Colors.orange.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          isVerified ? 'Union Verified' : 'Pending Verification',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isVerified ? Colors.greenAccent : Colors.orangeAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Driver Availability Card (Functional)
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                side: BorderSide(
                  color: _availabilityController.isOnline
                      ? Colors.green.withValues(alpha: 0.5)
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spaceL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _availabilityController.isOnline
                                ? Colors.green.withValues(alpha: 0.15)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusM),
                          ),
                          child: Icon(
                            _availabilityController.isOnline
                                ? Icons.sensors_rounded
                                : Icons.sensors_off_rounded,
                            color: _availabilityController.isOnline ? Colors.green : Colors.grey,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppConstants.spaceM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Driver Availability',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _availabilityController.isOnline
                                    ? 'You are currently available for new rides.'
                                    : 'You are currently not available for new rides.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppConstants.spaceS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _availabilityController.isOnline
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusPill),
                            border: Border.all(
                              color: _availabilityController.isOnline ? Colors.green : Colors.grey,
                            ),
                          ),
                          child: Text(
                            _availabilityController.isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _availabilityController.isOnline ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spaceM),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _availabilityController.isUpdating
                            ? null
                            : _handleToggleAvailability,
                        style: FilledButton.styleFrom(
                          backgroundColor: _availabilityController.isOnline
                              ? Colors.red.shade700
                              : AppConstants.primaryAmber,
                          foregroundColor:
                              _availabilityController.isOnline ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: _availabilityController.isUpdating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                _availabilityController.isOnline
                                    ? Icons.power_settings_new_rounded
                                    : Icons.bolt_rounded,
                              ),
                        label: Text(
                          _availabilityController.isUpdating
                              ? 'Updating...'
                              : (_availabilityController.isOnline ? 'Go Offline' : 'Go Online'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            

            
            const SizedBox(height: AppConstants.spaceXL),

            // Active Ride Banner — shown when driver has an accepted ride
            AnimatedBuilder(
              animation: _activeRideController,
              builder: (context, _) {
                final activeRide = _activeRideController.activeRide;
                if (activeRide == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Ride',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppConstants.spaceM),
                    Card(
                      color: isDark
                          ? const Color(0xFF064E3B)
                          : const Color(0xFFECFDF5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusL),
                        side: const BorderSide(color: Colors.green, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spaceL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Ride Accepted',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.greenAccent
                                        : const Color(0xFF065F46),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.spaceM),
                            Text(
                              'Pickup: ${activeRide.pickup.address.trim().isNotEmpty ? activeRide.pickup.address : 'Pending'}',
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Drop: ${activeRide.destination.address.trim().isNotEmpty ? activeRide.destination.address : 'Pending'}',
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppConstants.spaceM),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    AppNavigator.toDriverActiveRide(context),
                                icon: const Icon(Icons.open_in_new_rounded,
                                    size: 18),
                                label: const Text('Open Active Ride'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppConstants.radiusM),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spaceXL),
                  ],
                );
              },
            ),

            // Incoming Ride Requests Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Incoming Ride Requests',
                  style: theme.textTheme.titleLarge,
                ),
                AnimatedBuilder(
                  animation: _requestsController,
                  builder: (context, _) {
                    final count = _requestsController.requestCount;
                    if (!_requestsController.isOnline || count == 0) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count Active',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spaceM),

            // Incoming Ride Requests List / Content
            AnimatedBuilder(
              animation: _requestsController,
              builder: (context, _) {
                if (!_requestsController.isOnline) {
                  return const EmptyStateView(
                    title: 'Driver is Offline',
                    message: 'Switch your availability to Online above to receive incoming ride requests.',
                    icon: Icons.wifi_off_rounded,
                  );
                }

                final state = _requestsController.state;

                if (state.isLoading) {
                  return const LoadingView(
                    message: 'Checking incoming requests...',
                  );
                }

                if (state.isError) {
                  return ErrorView(
                    message: state.message ?? 'Failed to load incoming requests.',
                    onRetry: () => _requestsController.startListening(),
                  );
                }

                if (state.isEmpty || state.data == null || state.data!.isEmpty) {
                  return const EmptyStateView(
                    title: 'No incoming ride requests',
                    message: 'You are online. Eligible ride requests assigned to you will appear here automatically.',
                    icon: Icons.inbox_rounded,
                  );
                }

                final requests = state.data!;

                return Column(
                  children: requests.map((ride) {
                    return RideSummaryCard(
                      pickupAddress: ride.pickup.address.trim().isNotEmpty
                          ? ride.pickup.address
                          : 'Pickup address pending',
                      dropoffAddress: ride.destination.address.trim().isNotEmpty
                          ? ride.destination.address
                          : 'Destination address pending',
                      status: ride.status.name,
                      dateTime: _formatDateTime(ride.createdAt),
                      fare: '₹${ride.estimatedFare.toStringAsFixed(0)}',
                      vehicleInfo: 'Vehicle: ${ride.vehicleType.name}',
                      onTap: () {
                        // Request detail preview / inspect action (PR 33 read-only)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Inspecting request #${ride.id}. Accept/Reject actions active in PR 34/35.',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      actionButton: AnimatedBuilder(
                        animation: Listenable.merge([_acceptanceController, _rejectionController]),
                        builder: (context, _) {
                          final isAccepting = _acceptanceController.state.isLoading;
                          final isRejecting = _rejectionController.state.isLoading;
                          final isBusy = isAccepting || isRejecting;

                          return Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: isBusy
                                      ? null
                                      : () => _rejectionController.rejectRide(ride.id),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: BorderSide(
                                      color: isBusy ? Colors.grey : Colors.red,
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                                    ),
                                  ),
                                  icon: isRejecting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                          ),
                                        )
                                      : const Icon(Icons.close_rounded),
                                  label: Text(
                                    isRejecting ? 'Rejecting...' : 'Reject',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppConstants.spaceM),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isBusy
                                      ? null
                                      : () => _acceptanceController.acceptRide(ride.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                                    ),
                                  ),
                                  icon: isAccepting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.check_circle_outline_rounded),
                                  label: Text(
                                    isAccepting ? 'Accepting...' : 'Accept Ride',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: AppConstants.spaceXL),

            // Registered Vehicle Details
            Text(
              'Vehicle & Union Status',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.spaceM),

            InfoCard(
              title: 'Registered Vehicle',
              description: vehicleInfo,
              icon: Icons.electric_rickshaw_rounded,
              iconColor: AppConstants.primaryAmber,
              badgeText: 'Active',
              badgeColor: Colors.blue,
            ),

            InfoCard(
              title: 'Union Verification Status',
              description: isVerified
                  ? 'Your union credentials and vehicle permit are fully verified.'
                  : 'Document review in progress by regional union administrators.',
              icon: isVerified
                  ? Icons.verified_user_rounded
                  : Icons.pending_actions_rounded,
              iconColor: isVerified ? Colors.green : Colors.orange,
              badgeText: isVerified ? 'Verified' : 'Pending',
              badgeColor: isVerified ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

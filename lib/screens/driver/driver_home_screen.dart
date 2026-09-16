import 'package:flutter/material.dart';
import 'package:ridesathi/core/constants/app_constants.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/driver_availability_controller.dart';
import 'package:ridesathi/core/theme/theme_controller.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/widgets/error_view.dart';
import 'package:ridesathi/widgets/info_card.dart';
import 'package:ridesathi/widgets/loading_view.dart';
import 'package:ridesathi/widgets/union_badge.dart';

/// Primary landing and operational dashboard screen for authenticated Drivers in RideSathi.
///
/// Displays driver identity, registered vehicle details, union verification status,
/// explicit online/offline availability control, future operational shells (requests, current ride),
/// and supports clean logout with navigation stack clearing.
class DriverHomeScreen extends StatefulWidget {
  /// Optional [AuthController] for dependency injection in tests.
  final AuthController? authController;

  /// Optional [DriverAvailabilityController] for dependency injection in tests.
  final DriverAvailabilityController? availabilityController;

  /// Optional [UserModel] for explicit user identity passing.
  final UserModel? user;

  const DriverHomeScreen({
    super.key,
    this.authController,
    this.availabilityController,
    this.user,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  late final AuthController _authController;
  late final DriverAvailabilityController _availabilityController;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _authController = widget.authController ?? AuthController.instance;
    _availabilityController = widget.availabilityController ??
        DriverAvailabilityController(authController: _authController);

    _availabilityController.addListener(_onAvailabilityStateChanged);
  }

  @override
  void dispose() {
    _availabilityController.removeListener(_onAvailabilityStateChanged);
    if (widget.availabilityController == null) {
      _availabilityController.dispose();
    }
    super.dispose();
  }

  void _onAvailabilityStateChanged() {
    if (!mounted) return;
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

  UserModel? get _currentUser => widget.user ?? _authController.currentUser;

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

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

  Future<void> _handleToggleAvailability() async {
    await _availabilityController.toggleAvailability();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Check auth loading state
    if (_authController.state.isLoading && widget.user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('${AppConstants.appName} Driver'),
        ),
        body: const LoadingView(
          message: 'Loading driver profile...',
        ),
      );
    }

    final user = _currentUser;

    // Missing profile or unauthenticated state
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('${AppConstants.appName} Driver'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Log Out',
              onPressed: _handleLogout,
            ),
          ],
        ),
        body: ErrorView(
          title: 'Driver Profile Not Found',
          message:
              'Unable to resolve authenticated driver information. Please log in again.',
          icon: Icons.account_circle_outlined,
          retryLabel: 'Log Out & Re-authenticate',
          onRetry: _handleLogout,
        ),
      );
    }

    // Role protection check
    if (user.role != UserRole.driver) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Restricted'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Log Out',
              onPressed: _handleLogout,
            ),
          ],
        ),
        body: ErrorView(
          title: 'Access Restricted',
          message:
              'This dashboard is reserved for authenticated driver accounts.',
          icon: Icons.gpp_maybe_rounded,
          retryLabel: 'Return to Rider Home',
          onRetry: () => AppNavigator.toRiderHome(context, user),
        ),
      );
    }

    final driverName = user.name.trim().isNotEmpty ? user.name : 'Driver';
    final vehicleInfo = user.vehicleInfo?.trim().isNotEmpty == true
        ? user.vehicleInfo!
        : 'Vehicle details not available';
    final hasVehicle = user.vehicleInfo?.trim().isNotEmpty == true;
    final isVerified = user.isUnionVerified;
    final isOnline = _availabilityController.isOnline;
    final isUpdatingAvailability = _availabilityController.isUpdating;

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
                tooltip:
                    isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
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
            // Driver Welcome / Identity Banner
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
                    user.phoneNumber.isNotEmpty
                        ? 'Driver Console • ${user.phoneNumber}'
                        : 'Union Fleet Operator & Driver Console',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spaceL),
                  Wrap(
                    spacing: AppConstants.spaceM,
                    runSpacing: AppConstants.spaceS,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spaceM,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppConstants.primaryAmber.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusS),
                          border: Border.all(
                            color: AppConstants.primaryAmber
                                .withValues(alpha: 0.4),
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
                          isVerified
                              ? 'Union Verified'
                              : 'Pending Verification',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isVerified
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spaceXL),

            // Registered Vehicle & Verification
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
              badgeText: hasVehicle ? 'Registered' : 'Not Set',
              badgeColor: hasVehicle ? Colors.blue : Colors.grey,
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
            const SizedBox(height: AppConstants.spaceXL),

            // Driver Operations Section
            Text(
              'Driver Operations',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.spaceM),

            // Driver Availability Card (Functional)
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                side: BorderSide(
                  color: isOnline
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
                            color: isOnline
                                ? Colors.green.withValues(alpha: 0.15)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusM),
                          ),
                          child: Icon(
                            isOnline
                                ? Icons.sensors_rounded
                                : Icons.sensors_off_rounded,
                            color: isOnline ? Colors.green : Colors.grey,
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
                                isOnline
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
                            color: isOnline
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusPill),
                            border: Border.all(
                              color: isOnline ? Colors.green : Colors.grey,
                            ),
                          ),
                          child: Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isOnline ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spaceM),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isUpdatingAvailability
                            ? null
                            : _handleToggleAvailability,
                        style: FilledButton.styleFrom(
                          backgroundColor: isOnline
                              ? Colors.red.shade700
                              : AppConstants.primaryAmber,
                          foregroundColor:
                              isOnline ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: isUpdatingAvailability
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
                                isOnline
                                    ? Icons.power_settings_new_rounded
                                    : Icons.bolt_rounded,
                              ),
                        label: Text(
                          isUpdatingAvailability
                              ? 'Updating...'
                              : (isOnline ? 'Go Offline' : 'Go Online'),
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
            const SizedBox(height: AppConstants.spaceM),

            const InfoCard(
              title: 'Incoming Ride Requests',
              description:
                  'No incoming ride requests. Queue will update automatically when active.',
              icon: Icons.hail_rounded,
              iconColor: Colors.teal,
              badgeText: 'No Requests',
              badgeColor: Colors.grey,
            ),

            const InfoCard(
              title: 'Current Ride',
              description: 'No active ride in progress.',
              icon: Icons.navigation_rounded,
              iconColor: Colors.indigo,
              badgeText: 'Inactive',
              badgeColor: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

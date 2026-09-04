import 'package:flutter/material.dart';
import 'package:ridesathi/core/constants/app_constants.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/theme/theme_controller.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/widgets/info_card.dart';
import 'package:ridesathi/widgets/union_badge.dart';

/// Landing and dashboard screen for authenticated Drivers in RideSathi.
///
/// Displays driver identity, vehicle details, union verification status,
/// and supports clean logout with navigation stack clearing.
class DriverHomeScreen extends StatefulWidget {
  /// Optional [AuthController] for dependency injection in tests.
  final AuthController? authController;

  /// Optional [UserModel] for explicit user identity passing.
  final UserModel? user;

  const DriverHomeScreen({super.key, this.authController, this.user});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  late final AuthController _authController;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _authController = widget.authController ?? AuthController.instance;
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
              badgeText: isVerified ? 'Verified' : 'Pending (PR 29)',
              badgeColor: isVerified ? Colors.green : Colors.orange,
            ),

            InfoCard(
              title: 'Trip Dispatch Console',
              description:
                  'Real-time passenger hailing and dispatch queue.',
              icon: Icons.dashboard_customize_rounded,
              iconColor: Colors.teal,
              badgeText: 'PR 29 Upcoming',
              badgeColor: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ridesathi/core/constants/app_constants.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/theme/theme_controller.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/widgets/custom_button.dart';
import 'package:ridesathi/widgets/empty_state_view.dart';
import 'package:ridesathi/widgets/section_header.dart';

/// Landing and dashboard screen for authenticated Riders in RideSathi.
///
/// PR 19 establishes the rider home shell with:
/// - Rider greeting using the authenticated domain profile
/// - Primary "Request a Ride" call-to-action
/// - Current ride / activity section with empty state
/// - Profile access from the app bar and bottom navigation
/// - Bottom navigation with Home and Profile destinations
///
/// This screen does NOT create rides, write to Firestore, or access ride
/// data directly. Those responsibilities belong to later PRs.
class RiderHomeScreen extends StatefulWidget {
  /// Optional [AuthController] for dependency injection in tests.
  final AuthController? authController;

  /// Optional [UserModel] for explicit user identity passing.
  final UserModel? user;

  const RiderHomeScreen({super.key, this.authController, this.user});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
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

  void _handleRequestRide() {
    AppNavigator.toRiderRequestRide(context);
  }

  void _handleProfile() {
    AppNavigator.toProfile(context);
  }

  void _handleHistory() {
    AppNavigator.toRiderHistory(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _currentUser;
    final riderName = user?.name.isNotEmpty == true ? user!.name : 'Rider';

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
                Icons.local_taxi_rounded,
                size: 20,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              '${AppConstants.appName} Rider',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.themeModeNotifier,
            builder: (context, mode, _) {
              final isDark = theme.brightness == Brightness.dark;
              return IconButton(
                icon: Icon(
                  isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
                tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                onPressed: ThemeController.toggleTheme,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_rounded),
            tooltip: 'Profile',
            onPressed: _handleProfile,
          ),
          IconButton(
            icon: _isLoggingOut
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: _isLoggingOut ? null : _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spaceXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hello, $riderName',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spaceXS),
              Text(
                "Where would you like to go?",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppConstants.spaceXL),
              Semantics(
                label: 'Request a Ride',
                button: true,
                child: CustomButton(
                  label: 'Request a Ride',
                  icon: Icons.directions_car_rounded,
                  onPressed: _handleRequestRide,
                ),
              ),
              const SizedBox(height: AppConstants.spaceXXL),
              const SectionHeader(
                title: 'Get Started',
                subtitle: 'Request a ride whenever you need one.',
              ),
              const SizedBox(height: AppConstants.spaceM),
              const EmptyStateView(
                icon: Icons.local_taxi_rounded,
                title: 'No active ride',
                description:
                    "You don't have an active ride. Tap 'Request a Ride' above to get going, "
                    "or view your past rides in History.",
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            _handleHistory();
          } else if (index == 2) {
            _handleProfile();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}




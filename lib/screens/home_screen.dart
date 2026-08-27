import 'package:flutter/material.dart';
import 'package:ridesathi/core/constants/app_constants.dart';
import 'package:ridesathi/core/theme/theme_controller.dart';
import 'package:ridesathi/services/auth_service.dart';
import 'package:ridesathi/services/firebase_service.dart';
import 'package:ridesathi/widgets/info_card.dart';
import 'package:ridesathi/widgets/union_badge.dart';

/// Foundation Home Dashboard Screen for RideSathi PR 01.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                Icons.local_taxi_rounded,
                size: 20,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              AppConstants.appName,
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
          if (FirebaseService.isInitialized)
            AuthService.currentUser != null
                ? IconButton(
                    icon: const Icon(Icons.logout_rounded),
                    tooltip: 'Log Out',
                    onPressed: () => _handleLogout(context),
                  )
                : IconButton(
                    icon: const Icon(Icons.login_rounded),
                    tooltip: 'Log In',
                    onPressed: () => Navigator.of(context)
                        .pushNamed(AppConstants.routeLogin),
                  ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Baseline Info',
            onPressed: () {
              _showBaselineInfoDialog(context);
            },
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
            // Union Welcome Banner
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
                  const Text(
                    'Welcome to RideSathi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Regional Cab and Auto-Rickshaw Union Mobile Application.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spaceL),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spaceM,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.secondaryTeal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                      border: Border.all(
                        color: AppConstants.secondaryTeal.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: AppConstants.secondaryTeal,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'PR 03 Theme Standardized',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spaceXL),

            // Foundation Status Section
            Text(
              'System Foundation Status',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.spaceM),

            InfoCard(
              title: 'Flutter Architecture Baseline',
              description: 'Modular directory structure established with separated screens, widgets, models, services, and theme.',
              icon: Icons.layers_rounded,
              iconColor: AppConstants.secondaryTeal,
              badgeText: AppConstants.statusBaselineReady,
              badgeColor: AppConstants.secondaryTeal,
            ),

            InfoCard(
              title: 'Firebase Integration Framework',
              description: FirebaseService.isInitialized
                  ? 'Firebase Core initialized successfully.'
                  : 'Firebase packages integrated (firebase_core, cloud_firestore, firebase_auth). Native credential files pending provision.',
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.deepOrange,
              badgeText: FirebaseService.isInitialized
                  ? 'Initialized'
                  : AppConstants.statusFirebasePending,
              badgeColor: FirebaseService.isInitialized
                  ? Colors.green
                  : Colors.orange,
            ),

            InfoCard(
              title: 'Static Analysis & Quality',
              description: 'Strict Dart lints enforced with zero analysis errors across all foundation packages.',
              icon: Icons.verified_rounded,
              iconColor: Colors.blue,
              badgeText: 'Clean Analysis',
              badgeColor: Colors.blue,
            ),

            const SizedBox(height: AppConstants.spaceXL),

            // Feature Roadmap Section
            Text(
              'Module Roadmap (Upcoming PRs)',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.spaceM),

            InfoCard(
              title: 'Rider Module',
              description: 'Ride booking, fare estimation, and driver matching.',
              icon: Icons.person_pin_circle_rounded,
              iconColor: Colors.purple,
              badgeText: 'Upcoming PR',
              badgeColor: Colors.grey,
            ),

            InfoCard(
              title: 'Driver Module',
              description: 'Union auto & cab driver dispatch console and trip acceptance.',
              icon: Icons.drive_eta_rounded,
              iconColor: Colors.amber,
              badgeText: 'Upcoming PR',
              badgeColor: Colors.grey,
            ),

            InfoCard(
              title: 'Dispatcher Console',
              description: 'Regional union fleet oversight and manual dispatch assistance.',
              icon: Icons.dashboard_customize_rounded,
              iconColor: Colors.teal,
              badgeText: 'Upcoming PR',
              badgeColor: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _handleLogout(BuildContext context) async {
    try {
      await AuthService.signOut();
    } on AuthException catch (_) {
      // Session termination failed; leave the user on the dashboard rather
      // than navigating away from a still-authenticated session.
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppConstants.routeLogin,
      (route) => false,
    );
  }

  void _showBaselineInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.nature_people_rounded, color: AppConstants.primaryAmber),
            SizedBox(width: 8),
            Text('RideSathi Baseline'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Application Name: RideSathi'),
            SizedBox(height: 4),
            Text('• Target Domain: Regional Cab & Auto Union'),
            SizedBox(height: 4),
            Text('• Branch: feat/pr-01-project-foundation'),
            SizedBox(height: 4),
            Text('• PR Scope: Audit baseline, clean project foundation setup.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

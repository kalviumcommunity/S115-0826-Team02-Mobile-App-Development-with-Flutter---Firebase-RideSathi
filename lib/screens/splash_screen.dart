import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ridesathi/core/constants/app_constants.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/services/auth_service.dart';
import 'package:ridesathi/services/firebase_service.dart';
import 'package:ridesathi/widgets/error_view.dart';
import 'package:ridesathi/widgets/union_badge.dart';

/// Represents the startup lifecycle phases of the splash screen.
enum SplashState {
  /// Initial state — animation playing, waiting for navigation timer.
  initializing,

  /// Firebase failed to initialize — error state displayed.
  error,
}

/// Splash screen that animates on launch and navigates to the appropriate
/// destination based on Firebase initialization and authentication state.
///
/// Navigation safety guarantees:
/// - Only one navigation action is ever executed ([_hasNavigated] guard).
/// - Timer is cancelled in [dispose] to prevent post-disposal callbacks.
/// - Navigation clears the entire back stack so splash cannot be returned to.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

/// Visible for testing — allows tests to inspect internal state.
class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  /// Guards against duplicate navigation calls.
  bool _hasNavigated = false;

  /// Current startup lifecycle state.
  SplashState _splashState = SplashState.initializing;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    _navigationTimer = Timer(const Duration(milliseconds: 2200), () {
      _navigateToDestination();
    });
  }

  /// Determines the correct destination and navigates, clearing the back stack.
  ///
  /// Guarded by [_hasNavigated] to ensure this executes at most once.
  void _navigateToDestination() {
    if (_hasNavigated || !mounted) return;

    // Firebase must be initialized before checking authentication state.
    if (!FirebaseService.isInitialized) {
      setState(() {
        _splashState = SplashState.error;
      });
      return;
    }

    _hasNavigated = true;

    // Wrap auth check in try-catch: if FirebaseAuth.instance is unavailable
    // (e.g., platform issue or test environment), treat as unauthenticated.
    bool isAuthenticated = false;
    try {
      isAuthenticated = AuthService.currentUser != null;
    } catch (_) {
      // Auth check failed — route to login as a safe fallback.
    }

    if (isAuthenticated) {
      AppNavigator.toHome(context);
    } else {
      AppNavigator.toLogin(context);
    }
  }

  /// Retries the startup flow after a Firebase initialization error.
  void _retryStartup() {
    if (!mounted) return;
    setState(() {
      _splashState = SplashState.initializing;
    });

    // Re-attempt navigation after a short delay to allow UI to update.
    _navigationTimer?.cancel();
    _navigationTimer = Timer(const Duration(milliseconds: 800), () {
      _navigateToDestination();
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Theme-aware background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        AppConstants.backgroundDark,
                        const Color(0xFF0F172A),
                      ]
                    : [
                        AppConstants.accentNavy,
                        const Color(0xFF334155),
                      ],
              ),
            ),
          ),
          // Main splash content
          SafeArea(
            child: Center(
              child: _splashState == SplashState.error
                  ? _buildErrorState()
                  : _buildBrandingContent(theme),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the main branding content shown during initialization.
  Widget _buildBrandingContent(ThemeData theme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceXL,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo icon
                Semantics(
                  label: '${AppConstants.appName} logo',
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryAmber,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppConstants.primaryAmber.withValues(alpha: 0.3),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_taxi_rounded,
                      size: 54,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spaceXL),
                // App name
                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppConstants.spaceS),
                // Tagline
                Text(
                  AppConstants.appTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppConstants.spaceXXL),
                // Union badge
                const UnionBadge(),
                const SizedBox(height: AppConstants.spaceXXL),
                // Loading indicator
                Semantics(
                  label: 'Loading application',
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppConstants.primaryAmber.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the error state when Firebase initialization has failed.
  Widget _buildErrorState() {
    return ErrorView(
      title: 'Unable to Start',
      message:
          'RideSathi could not connect to its services. '
          'Please check your internet connection and try again.',
      icon: Icons.cloud_off_rounded,
      retryLabel: 'Retry',
      onRetry: _retryStartup,
    );
  }
}

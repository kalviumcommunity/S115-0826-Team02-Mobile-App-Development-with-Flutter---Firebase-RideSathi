import 'package:flutter/material.dart';
import '../../core/state/auth_controller.dart';
import '../../models/user_model.dart';
import '../../screens/auth/driver_signup_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/driver/driver_active_ride_screen.dart';
import '../../screens/driver/driver_home_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/rider/location_search_screen.dart';
import '../../screens/rider/location_selection_screen.dart';
import '../../screens/rider/ride_review_boundary_screen.dart';
import '../../screens/rider/ride_status_screen.dart';
import '../../screens/rider/rider_home_screen.dart';
import '../../screens/rider/rider_ride_history_screen.dart';
import '../../screens/rider/ride_feedback_screen.dart';
import '../../screens/splash_screen.dart';
import '../../widgets/error_view.dart';
import '../state/location_selection_controller.dart';

/// Centralized route registry and generator for RideSathi.
///
/// Implements application-level route protection and cross-role redirection:
/// - Unauthenticated requests to protected screens are routed to [LoginScreen].
/// - Cross-role route requests (e.g. a Rider requesting `/driver/home`) are safely
///   redirected to the user's authentic role home.
class AppRoutes {
  // Core Routes
  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String driverSignup = '/driver-signup';

  // Role-Specific Authenticated Routes
  static const String riderHome = '/rider/home';
  static const String driverHome = '/driver/home';

  // Driver Workflow Routes
  static const String driverActiveRide = '/driver/active-ride';

  // Authenticated Profile Routes
  static const String profile = '/profile';
  static const String riderProfile = '/rider/profile';
  static const String driverProfile = '/driver/profile';

  // Rider Ride-Request Workflow
  static const String riderRequestRide = '/rider/request-ride';
  static const String riderLocationSearch = '/rider/location-search';
  static const String riderReviewRide = '/rider/review-ride';
  static const String riderStatus = '/rider/ride-status';
  static const String riderHistory = '/rider/history';
  static const String riderFeedback = '/rider/feedback';

  // Reserved Future Role Route
  static const String dispatcherHome = '/dispatcher/home';

  /// Generates application routes based on [RouteSettings] with route protection.
  static Route<dynamic> generateRoute(
    RouteSettings settings, {
    AuthController? authController,
  }) {
    final controller = authController ?? AuthController.instance;
    final userFromArgs =
        settings.arguments is UserModel ? settings.arguments as UserModel : null;
    final isAuthenticated = controller.isAuthenticated || userFromArgs != null;
    final userRole = userFromArgs?.role ?? controller.currentUser?.role;

    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => SplashScreen(authController: controller),
          settings: settings,
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => LoginScreen(authController: controller),
          settings: settings,
        );

      case signup:
        return MaterialPageRoute(
          builder: (_) => SignupScreen(authController: controller),
          settings: settings,
        );

      case driverSignup:
        return MaterialPageRoute(
          builder: (_) => DriverSignupScreen(authController: controller),
          settings: settings,
        );

      case riderHome:
        if (!isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => LoginScreen(authController: controller),
            settings: settings,
          );
        }
        if (userRole == UserRole.driver) {
          // Cross-role protection: Driver attempting Rider area
          return MaterialPageRoute(
            builder: (_) => DriverHomeScreen(
              authController: controller,
              user: userFromArgs,
            ),
            settings: settings,
          );
        }
        if (userRole == UserRole.rider) {
          return MaterialPageRoute(
            builder: (_) => RiderHomeScreen(
              authController: controller,
              user: userFromArgs,
            ),
            settings: settings,
          );
        }
        return _buildAccessErrorRoute(settings, 'Unsupported or unrecognized role.');

      case driverHome:
        if (!isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => LoginScreen(authController: controller),
            settings: settings,
          );
        }
        if (userRole == UserRole.rider) {
          // Cross-role protection: Rider attempting Driver area
          return MaterialPageRoute(
            builder: (_) => RiderHomeScreen(
              authController: controller,
              user: userFromArgs,
            ),
            settings: settings,
          );
        }
        if (userRole == UserRole.driver) {
          return MaterialPageRoute(
            builder: (_) => DriverHomeScreen(
              authController: controller,
              user: userFromArgs,
            ),
            settings: settings,
          );
        }
        return _buildAccessErrorRoute(settings, 'Unsupported or unrecognized role.');

      case driverActiveRide:
        if (!isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => LoginScreen(authController: controller),
            settings: settings,
          );
        }
        if (userRole == UserRole.rider) {
          // Cross-role protection: Rider attempting Driver Active Ride
          return MaterialPageRoute(
            builder: (_) => RiderHomeScreen(
              authController: controller,
              user: userFromArgs,
            ),
            settings: settings,
          );
        }
        if (userRole == UserRole.driver) {
          return MaterialPageRoute(
            builder: (_) => DriverActiveRideScreen(
              authController: controller,
            ),
            settings: settings,
          );
        }
        return _buildAccessErrorRoute(settings, 'Unsupported or unrecognized role.');

      case home:
        // Compatibility route: Resolves the authenticated user's designated home
        if (!isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => HomeScreen(authController: controller),
            settings: settings,
          );
        }
        if (userRole == UserRole.driver) {
          return MaterialPageRoute(
            builder: (_) => DriverHomeScreen(
              authController: controller,
              user: userFromArgs,
            ),
            settings: settings,
          );
        }
        if (userRole == UserRole.rider) {
          return MaterialPageRoute(
            builder: (_) => RiderHomeScreen(
              authController: controller,
              user: userFromArgs,
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => HomeScreen(authController: controller),
          settings: settings,
        );

      case profile:
        if (!isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => LoginScreen(authController: controller),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(authController: controller),
          settings: settings,
        );

      case riderProfile:
        if (!isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => LoginScreen(authController: controller),
            settings: settings,
          );
        }
        if (userRole == UserRole.driver) {
          // Cross-role protection: Driver attempting Rider profile area
          return MaterialPageRoute(
            builder: (_) => ProfileScreen(authController: controller),
            settings: const RouteSettings(name: driverProfile),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(authController: controller),
          settings: settings,
        );

      case driverProfile:
        if (!isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => LoginScreen(authController: controller),
            settings: settings,
          );
        }
        if (userRole == UserRole.rider) {
          // Cross-role protection: Rider attempting Driver profile area
          return MaterialPageRoute(
            builder: (_) => ProfileScreen(authController: controller),
            settings: const RouteSettings(name: riderProfile),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(authController: controller),
          settings: settings,
        );

      case riderRequestRide:
        if (!isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => LoginScreen(authController: controller),
            settings: settings,
          );
        }
        if (userRole == UserRole.driver) {
          // Cross-role protection: Driver attempting Rider request area
          return MaterialPageRoute(
            builder: (_) => DriverHomeScreen(
              authController: controller,
              user: userFromArgs,
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const LocationSelectionScreen(),
          settings: settings,
        );

      case riderLocationSearch:
        if (!isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => LoginScreen(authController: controller),
            settings: settings,
          );
        }
        final locationType = settings.arguments as String? ?? 'pickup';
        return MaterialPageRoute(
          builder: (_) => LocationSearchScreen(locationType: locationType),
          settings: settings,
        );

      case riderReviewRide:
        if (!isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => LoginScreen(authController: controller),
            settings: settings,
          );
        }
        final locController = settings.arguments as LocationSelectionController?;
        if (locController == null) {
          return _buildAccessErrorRoute(settings, 'Missing location selection state.');
        }
        return MaterialPageRoute(
          builder: (_) => RideReviewBoundaryScreen(controller: locController),
          settings: settings,
        );

      case riderStatus:
        if (!isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => LoginScreen(authController: controller),
            settings: settings,
          );
        }
        final rideId = settings.arguments as String?;
        if (rideId == null || rideId.trim().isEmpty) {
          return _buildAccessErrorRoute(settings, 'Missing ride ID.');
        }
        return MaterialPageRoute(
          builder: (_) => RideStatusScreen(rideId: rideId),
          settings: settings,
        );

      case riderHistory:
        if (!isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => LoginScreen(authController: controller),
            settings: settings,
          );
        }
        if (userRole == UserRole.driver) {
          // Cross-role protection: Driver attempting Rider history
          return MaterialPageRoute(
            builder: (_) => DriverHomeScreen(
              authController: controller,
              user: userFromArgs,
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const RiderRideHistoryScreen(),
          settings: settings,
        );

      case riderFeedback:
        if (!isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => LoginScreen(authController: controller),
            settings: settings,
          );
        }
        if (userRole == UserRole.driver) {
          return MaterialPageRoute(
            builder: (_) => DriverHomeScreen(
              authController: controller,
              user: userFromArgs,
            ),
            settings: settings,
          );
        }
        final feedbackArgs = settings.arguments as Map<String, dynamic>?;
        final feedbackRideId = feedbackArgs?['rideId'] as String?;
        if (feedbackRideId == null || feedbackRideId.trim().isEmpty) {
          return _buildAccessErrorRoute(settings, 'Missing ride ID for feedback.');
        }
        return MaterialPageRoute(
          builder: (_) => RideFeedbackScreen(rideId: feedbackRideId),
          settings: settings,
        );

      case dispatcherHome:
        return _buildAccessErrorRoute(
          settings,
          'Dispatcher console is reserved for upcoming roadmap milestones.',
        );


      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Page Not Found'),
            ),
            body: ErrorView(
              title: 'Page Not Found',
              message: 'The requested route "${settings.name}" does not exist.',
              icon: Icons.alt_route_rounded,
              retryLabel: 'Return to Login',
              onRetry: () => AppNavigator.toLogin(context),
            ),
          ),
          settings: settings,
        );
    }
  }

  static Route<dynamic> _buildAccessErrorRoute(RouteSettings settings, String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Access Restricted'),
        ),
        body: ErrorView(
          title: 'Access Restricted',
          message: message,
          icon: Icons.gpp_maybe_rounded,
          retryLabel: 'Return to Login',
          onRetry: () => AppNavigator.toLogin(context),
        ),
      ),
      settings: settings,
    );
  }
}

/// Focused navigation helper for consistent, predictable stack management and role-aware routing.
class AppNavigator {
  /// Pushes a named route onto the navigator stack.
  static Future<T?> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  /// Replaces the current route with a named route.
  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    return Navigator.of(context).pushReplacementNamed<T, TO>(
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  /// Pushes a named route and removes all previous routes until [predicate] returns true.
  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    BuildContext context,
    String routeName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamedAndRemoveUntil<T>(
      routeName,
      predicate,
      arguments: arguments,
    );
  }

  /// Navigates an authenticated user to their role-specific home destination,
  /// clearing the entire back stack.
  static Future<void> toAuthenticatedHome(
    BuildContext context, [
    UserModel? user,
  ]) {
    final role = user?.role ?? AuthController.instance.currentUser?.role;

    switch (role) {
      case UserRole.driver:
        return toDriverHome(context, user);
      case UserRole.rider:
      default:
        return toRiderHome(context, user);
    }
  }

  /// Navigates to the Rider Home screen, clearing the entire back stack.
  static Future<void> toRiderHome(BuildContext context, [UserModel? user]) {
    return pushNamedAndRemoveUntil(
      context,
      AppRoutes.riderHome,
      (route) => false,
      arguments: user,
    );
  }

  /// Navigates to the Driver Active Ride screen.
  static Future<void> toDriverActiveRide(BuildContext context) {
    return pushNamed(context, AppRoutes.driverActiveRide);
  }

  /// Navigates to the Driver Home screen, clearing the entire back stack.
  static Future<void> toDriverHome(BuildContext context, [UserModel? user]) {
    return pushNamedAndRemoveUntil(
      context,
      AppRoutes.driverHome,
      (route) => false,
      arguments: user,
    );
  }

  /// Navigates to the legacy/compatibility Home dashboard, clearing the entire back stack.
  static Future<void> toHome(BuildContext context) {
    return pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  /// Navigates to the Login screen, clearing the entire back stack.
  static Future<void> toLogin(BuildContext context) {
    return pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  /// Navigates from Login to Signup (or pushes Signup).
  static Future<void> toSignup(BuildContext context) {
    return pushReplacementNamed(context, AppRoutes.signup);
  }

  /// Navigates from Login to Driver Signup (or pushes Driver Signup).
  static Future<void> toDriverSignup(BuildContext context) {
    return pushReplacementNamed(context, AppRoutes.driverSignup);
  }

  /// Navigates to the user's Profile screen.
  static Future<void> toProfile(BuildContext context) {
    return pushNamed(context, AppRoutes.profile);
  }

  /// Navigates to the Rider Profile screen.
  static Future<void> toRiderProfile(BuildContext context) {
    return pushNamed(context, AppRoutes.riderProfile);
  }

  /// Navigates to the Driver Profile screen.
  static Future<void> toDriverProfile(BuildContext context) {
    return pushNamed(context, AppRoutes.driverProfile);
  }

  /// Navigates to the Rider ride-request flow (starts location selection).
  static Future<void> toRiderRequestRide(BuildContext context) {
    return pushNamed(context, AppRoutes.riderRequestRide);
  }

  /// Navigates to the Rider Ride History screen.
  static Future<void> toRiderHistory(BuildContext context) {
    return pushNamed(context, AppRoutes.riderHistory);
  }

  /// Logs out and resets the navigation stack to the Login screen.
  static Future<void> logout(BuildContext context) {
    return pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  /// Pops the topmost route off the navigator.
  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }

  /// Whether the navigator can pop.
  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }
}

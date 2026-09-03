import 'package:flutter/material.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/driver_signup_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/splash_screen.dart';
import '../../widgets/error_view.dart';

/// Centralized route registry and generator for RideSathi.
class AppRoutes {
  // Core Implemented Routes
  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String driverSignup = '/driver-signup';

  // Future Role-Specific Route Placeholders (for PR 06+ Rider/Driver/Dispatcher modules)
  static const String riderHome = '/rider/home';
  static const String driverHome = '/driver/home';
  static const String dispatcherHome = '/dispatcher/home';

  /// Generates application routes based on [RouteSettings].
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case signup:
        return MaterialPageRoute(
          builder: (_) => const SignupScreen(),
          settings: settings,
        );
      case driverSignup:
        return MaterialPageRoute(
          builder: (_) => const DriverSignupScreen(),
          settings: settings,
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
              retryLabel: 'Return to Home',
              onRetry: () => AppNavigator.toHome(context),
            ),
          ),
          settings: settings,
        );
    }
  }
}

/// Focused navigation helper for consistent, predictable stack management.
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

  /// Navigates to the Home dashboard, clearing the entire back stack.
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


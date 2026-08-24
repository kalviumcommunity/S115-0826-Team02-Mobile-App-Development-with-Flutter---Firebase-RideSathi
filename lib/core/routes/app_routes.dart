import 'package:flutter/material.dart';
import '../../screens/home_screen.dart';
import '../../screens/splash_screen.dart';
import '../constants/app_constants.dart';

/// Centralized route generator for RideSathi.
class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.routeSplash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case AppConstants.routeHome:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}

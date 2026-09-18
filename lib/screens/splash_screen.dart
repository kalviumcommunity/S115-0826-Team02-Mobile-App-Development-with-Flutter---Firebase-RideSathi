import 'package:flutter/material.dart';
import '../../core/state/auth_controller.dart';
import '../../core/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  final AuthController? authController;

  const SplashScreen({super.key, this.authController});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late AuthController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.authController ?? AuthController.instance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.addListener(_onAuthStateChanged);
      _controller.checkAuthStatus();
    });
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    
    if (!_controller.isAuthenticating) {
      _controller.removeListener(_onAuthStateChanged);
      if (_controller.isAuthenticated) {
        AppNavigator.toAuthenticatedHome(context, _controller.currentUser);
      } else {
        AppNavigator.toLogin(context);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_taxi_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

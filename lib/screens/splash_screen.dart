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
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    final controller = widget.authController ?? AuthController.instance;
    if (controller.isAuthenticated) {
      AppNavigator.toAuthenticatedHome(context, controller.currentUser);
    } else {
      AppNavigator.toLogin(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

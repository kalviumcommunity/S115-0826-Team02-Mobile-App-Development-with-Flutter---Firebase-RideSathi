import 'package:flutter/material.dart';
import '../../core/state/auth_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/custom_button.dart';

class SignupScreen extends StatelessWidget {
  final AuthController? authController;

  const SignupScreen({super.key, this.authController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rider Sign Up')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Rider Signup Form Placeholder'),
              const SizedBox(height: 20),
              CustomButton(
                label: 'Back to Login',
                onPressed: () => AppNavigator.toLogin(context),
                isLoading: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

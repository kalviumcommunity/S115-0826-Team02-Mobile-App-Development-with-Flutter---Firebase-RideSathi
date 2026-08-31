import 'package:flutter/material.dart';
import 'package:ridesathi/core/constants/app_constants.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/utils/validators.dart';
import 'package:ridesathi/services/auth_service.dart';
import 'package:ridesathi/services/firebase_service.dart';
import 'package:ridesathi/widgets/auth_text_field.dart';
import 'package:ridesathi/widgets/custom_button.dart';
import 'package:ridesathi/widgets/info_banner.dart';

/// Email/password registration screen for RideSathi.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_isLoading) return;
    setState(() => _errorMessage = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!FirebaseService.isInitialized) {
      setState(() {
        _errorMessage =
            'Firebase authentication is not available yet. Please complete Firebase setup before signing up.';
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      AppNavigator.toHome(context);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceXL,
            vertical: AppConstants.spaceXL,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_taxi_rounded,
                      size: 44,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spaceL),
                Text(
                  'Create Your Account',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppConstants.spaceXS),
                Text(
                  'Join the ${AppConstants.appName} network',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppConstants.spaceXL),
                if (!FirebaseService.isInitialized) ...[
                  const InfoBanner(
                    icon: Icons.info_outline_rounded,
                    color: Colors.orange,
                    message:
                        "Firebase isn't connected yet. Native configuration is pending — sign up will work once it's provisioned.",
                  ),
                  const SizedBox(height: AppConstants.spaceL),
                ],
                if (_errorMessage != null) ...[
                  InfoBanner(
                    icon: Icons.error_outline_rounded,
                    color: theme.colorScheme.error,
                    message: _errorMessage!,
                  ),
                  const SizedBox(height: AppConstants.spaceL),
                ],
                AuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: AppConstants.spaceL),
                AuthTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: Validators.password,
                ),
                const SizedBox(height: AppConstants.spaceL),
                AuthTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) => Validators.confirmPassword(
                    _passwordController.text,
                    value,
                  ),
                ),
                const SizedBox(height: AppConstants.spaceXL),
                CustomButton(
                  label: 'Sign Up',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _handleSignup,
                ),
                const SizedBox(height: AppConstants.spaceL),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (AppNavigator.canPop(context)) {
                                AppNavigator.pop(context);
                              } else {
                                AppNavigator.toLogin(context);
                              }
                            },
                      child: const Text('Log In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




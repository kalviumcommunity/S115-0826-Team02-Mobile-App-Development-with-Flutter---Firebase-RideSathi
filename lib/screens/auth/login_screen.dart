import 'package:flutter/material.dart';
import 'package:ridesathi/core/constants/app_constants.dart';
import 'package:ridesathi/core/utils/validators.dart';
import 'package:ridesathi/services/auth_service.dart';
import 'package:ridesathi/services/firebase_service.dart';
import 'package:ridesathi/widgets/auth_text_field.dart';
import 'package:ridesathi/widgets/custom_button.dart';
import 'package:ridesathi/widgets/info_banner.dart';

/// Email/password login screen for RideSathi.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    setState(() => _errorMessage = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!FirebaseService.isInitialized) {
      setState(() {
        _errorMessage =
            'Firebase authentication is not available yet. Please complete Firebase setup before signing in.';
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppConstants.routeHome);
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppConstants.primaryAmber,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_taxi_rounded,
                      size: 48,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppConstants.appName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Sign in to continue',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                if (!FirebaseService.isInitialized) ...[
                  InfoBanner(
                    icon: Icons.info_outline_rounded,
                    color: Colors.orange,
                    message:
                        "Firebase isn't connected yet. Native configuration is pending — sign in will work once it's provisioned.",
                  ),
                  const SizedBox(height: 20),
                ],
                if (_errorMessage != null) ...[
                  InfoBanner(
                    icon: Icons.error_outline_rounded,
                    color: theme.colorScheme.error,
                    message: _errorMessage!,
                  ),
                  const SizedBox(height: 16),
                ],
                AuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: Validators.password,
                ),
                const SizedBox(height: 28),
                CustomButton(
                  label: 'Log In',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _handleLogin,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context)
                              .pushReplacementNamed(AppConstants.routeSignup),
                      child: const Text('Sign Up'),
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

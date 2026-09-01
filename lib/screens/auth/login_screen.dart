import 'package:flutter/material.dart';
import 'package:ridesathi/core/constants/app_constants.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/utils/validators.dart';
import 'package:ridesathi/services/firebase_service.dart';
import 'package:ridesathi/widgets/auth_text_field.dart';
import 'package:ridesathi/widgets/custom_button.dart';
import 'package:ridesathi/widgets/info_banner.dart';

/// Email/password login screen for RideSathi.
///
/// Delegates authentication operations to [AuthController] and derives
/// loading/error state from [AuthState], eliminating local state duplication.
class LoginScreen extends StatefulWidget {
  /// Optional [AuthController] for dependency injection in tests.
  final AuthController? authController;

  const LoginScreen({super.key, this.authController});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AuthController _authController;

  /// Local error for pre-flight checks (e.g., Firebase not initialized).
  /// Auth operation errors are handled by AuthController.
  String? _localError;

  @override
  void initState() {
    super.initState();
    _authController = widget.authController ?? AuthController.instance;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Prevent duplicate submissions while authenticating.
    if (_authController.isAuthenticating) return;

    // Clear any previous errors before re-validating.
    _authController.clearError();
    setState(() => _localError = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!FirebaseService.isInitialized) {
      setState(() {
        _localError =
            'Firebase authentication is not available yet. Please complete Firebase setup before signing in.';
      });
      return;
    }

    final success = await _authController.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (success) {
      AppNavigator.toHome(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _authController,
          builder: (context, _) {
            final authState = _authController.state;
            final isLoading = authState.isAuthenticating;
            final errorMessage = _localError ?? authState.errorMessage;

            return SingleChildScrollView(
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
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppConstants.spaceXS),
                    Text(
                      'Sign in to continue',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppConstants.spaceXL),
                    if (!FirebaseService.isInitialized) ...[
                      const InfoBanner(
                        icon: Icons.info_outline_rounded,
                        color: Colors.orange,
                        message:
                            "Firebase isn't connected yet. Native configuration is pending — sign in will work once it's provisioned.",
                      ),
                      const SizedBox(height: AppConstants.spaceL),
                    ],
                    if (errorMessage != null) ...[
                      InfoBanner(
                        icon: Icons.error_outline_rounded,
                        color: theme.colorScheme.error,
                        message: errorMessage,
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
                      textInputAction: TextInputAction.done,
                      validator: Validators.password,
                    ),
                    const SizedBox(height: AppConstants.spaceXL),
                    CustomButton(
                      label: 'Log In',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _handleLogin,
                    ),
                    const SizedBox(height: AppConstants.spaceL),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => AppNavigator.toSignup(context),
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

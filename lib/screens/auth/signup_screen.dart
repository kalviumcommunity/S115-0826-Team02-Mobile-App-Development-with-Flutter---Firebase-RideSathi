import 'package:flutter/material.dart';
import 'package:ridesathi/core/constants/app_constants.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/utils/validators.dart';
import 'package:ridesathi/services/firebase_service.dart';
import 'package:ridesathi/widgets/auth_text_field.dart';
import 'package:ridesathi/widgets/custom_button.dart';
import 'package:ridesathi/widgets/info_banner.dart';

/// Email/password registration screen for RideSathi.
///
/// Delegates authentication operations to [AuthController] and derives
/// loading/error state from [AuthState], eliminating local state duplication.
class SignupScreen extends StatefulWidget {
  /// Optional [AuthController] for dependency injection in tests.
  final AuthController? authController;

  const SignupScreen({super.key, this.authController});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    // Prevent duplicate submissions while authenticating.
    if (_authController.isAuthenticating) return;

    // Clear any previous errors before re-validating.
    _authController.clearError();
    setState(() => _localError = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!FirebaseService.isInitialized) {
      setState(() {
        _localError =
            'Firebase authentication is not available yet. Please complete Firebase setup before signing up.';
      });
      return;
    }

    final success = await _authController.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text,
      phone: _phoneController.text,
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
                      'Create Rider Account',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppConstants.spaceXS),
                    Text(
                      'Register as a rider on the ${AppConstants.appName} network',
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
                    if (errorMessage != null) ...[
                      InfoBanner(
                        icon: Icons.error_outline_rounded,
                        color: theme.colorScheme.error,
                        message: errorMessage,
                      ),
                      const SizedBox(height: AppConstants.spaceL),
                    ],
                    AuthTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.name,
                      validator: Validators.name,
                    ),
                    const SizedBox(height: AppConstants.spaceL),
                    AuthTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: AppConstants.spaceL),
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
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _handleSignup,
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
                          onPressed: isLoading
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
            );
          },
        ),
      ),
    );
  }
}

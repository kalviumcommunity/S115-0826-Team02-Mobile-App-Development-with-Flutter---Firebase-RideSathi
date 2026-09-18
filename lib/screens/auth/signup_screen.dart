import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/auth_controller.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/info_banner.dart';
import '../../services/firebase_service.dart';

class SignupScreen extends StatefulWidget {
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
    if (_authController.isAuthenticating) return;
    
    _authController.clearError();
    setState(() => _localError = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _localError = 'Passwords do not match.';
      });
      return;
    }

    if (!FirebaseService.isInitialized) {
      setState(() {
        _localError = 'Firebase authentication is not available yet.';
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
      AppNavigator.toAuthenticatedHome(context, _authController.currentUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Rider Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _authController,
          builder: (context, _) {
            final authState = _authController.state;
            final isLoading = authState.isAuthenticating;
            final errorMessage = _localError ?? authState.errorMessage;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spaceXL),
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
                      'Register as a rider on the RideSathi network',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppConstants.spaceXL),

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
                      icon: Icons.person_outline,
                      validator: Validators.name,
                      
                    ),
                    const SizedBox(height: AppConstants.spaceM),
                    AuthTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                      
                    ),
                    const SizedBox(height: AppConstants.spaceM),
                    AuthTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      
                    ),
                    const SizedBox(height: AppConstants.spaceM),
                    AuthTextField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      validator: Validators.password,
                      
                    ),
                    const SizedBox(height: AppConstants.spaceM),
                    AuthTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      validator: (v) => Validators.confirmPassword(_passwordController.text, v),
                      
                      
                      
                    ),
                    const SizedBox(height: AppConstants.spaceXL),
                    CustomButton(
                      label: 'Create Account',
                      onPressed: _handleSignup,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: AppConstants.spaceM),
                    CustomButton(
                      label: 'Back to Login',
                      isSecondary: true,
                      onPressed: isLoading ? null : () => AppNavigator.pop(context),
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

import 'package:flutter/material.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/utils/validators.dart';
import 'package:ridesathi/services/firebase_service.dart';
import 'package:ridesathi/widgets/auth_text_field.dart';
import 'package:ridesathi/widgets/info_banner.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LoginScreen extends StatefulWidget {
  final AuthController? authController;
  const LoginScreen({super.key, this.authController});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthController _authController;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _authController = widget.authController ?? AuthController.instance;
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_authController.isAuthenticating) return;
    _authController.clearError();
    setState(() => _localError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!FirebaseService.isInitialized) {
      setState(() => _localError = 'Firebase authentication is not available yet.');
      return;
    }
    final success = await _authController.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (success) AppNavigator.toAuthenticatedHome(context, _authController.currentUser);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Full screen map background
          Positioned.fill(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(20.5937, 78.9629),
                initialZoom: 5.0,
                interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ridesathi.ridesathi',
                ),
              ],
            ),
          ),
          // Dark gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Color(0xEE000000)],
                  stops: [0.0, 0.5],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      children: [
                        SizedBox(height: size.height * 0.08),
                        // Logo
                        Container(
                          width: 72, height: 72,
                          decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                          child: const Icon(Icons.local_taxi_rounded, size: 40, color: Colors.black),
                        ),
                        const SizedBox(height: 16),
                        const Text('RideSathi', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                        const SizedBox(height: 6),
                        const Text('Your trusted ride companion', style: TextStyle(color: Colors.white70, fontSize: 15)),
                        const Spacer(),
                        // Login card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 0),
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                          decoration: const BoxDecoration(
                            color: Color(0xFF111827),
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                          ),
                          child: ListenableBuilder(
                            listenable: _authController,
                            builder: (context, _) {
                              final isLoading = _authController.isAuthenticating;
                              final errorMessage = _localError ?? _authController.errorMessage;
                              return Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Welcome back', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    const Text('Sign in to continue', style: TextStyle(color: Colors.white60, fontSize: 14)),
                                    const SizedBox(height: 24),
                                    if (!FirebaseService.isInitialized) ...[
                                      const InfoBanner(icon: Icons.info_outline_rounded, color: Colors.orange, message: "Firebase isn't connected yet. Sign in will work once provisioned."),
                                      const SizedBox(height: 16),
                                    ],
                                    if (errorMessage != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
                                        child: Row(children: [
                                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 13))),
                                        ]),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    // Email field
                                    Container(
                                      decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(14)),
                                      child: AuthTextField(
                                        controller: _emailController,
                                        label: 'Email address',
                                        icon: Icons.email_outlined,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: Validators.email,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Password field
                                    Container(
                                      decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(14)),
                                      child: AuthTextField(
                                        controller: _passwordController,
                                        label: 'Password',
                                        icon: Icons.lock_outline_rounded,
                                        isPassword: true,
                                        textInputAction: TextInputAction.done,
                                        validator: Validators.password,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: isLoading ? null : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFF59E0B),
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          elevation: 0,
                                        ),
                                        child: isLoading
                                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                                            : const Text('Sign In', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      const Text("Don't have an account? ", style: TextStyle(color: Colors.white60)),
                                      GestureDetector(
                                        onTap: isLoading ? null : () => _showSignupOptions(context),
                                        child: const Text('Sign Up', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                                      ),
                                    ]),
                                    SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignupOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Join RideSathi', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Choose how you want to join', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 24),
            _signupOptionTile(ctx, Icons.person_rounded, 'Ride as Passenger', 'Book rides instantly', Colors.blue, () { Navigator.pop(ctx); AppNavigator.toSignup(context); }),
            const SizedBox(height: 12),
            _signupOptionTile(ctx, Icons.directions_car_rounded, 'Drive & Earn', 'Become a RideSathi driver', const Color(0xFFF59E0B), () { Navigator.pop(ctx); AppNavigator.toDriverSignup(context); }),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget _signupOptionTile(BuildContext ctx, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 26)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
            Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ])),
          const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
        ]),
      ),
    );
  }
}

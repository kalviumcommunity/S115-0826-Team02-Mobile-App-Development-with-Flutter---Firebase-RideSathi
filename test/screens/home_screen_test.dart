import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridesathi/core/constants/app_constants.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/auth_state.dart';
import 'package:ridesathi/core/theme/app_theme.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/screens/home_screen.dart';
import 'package:ridesathi/services/auth_service.dart';
import 'package:ridesathi/services/firebase_service.dart';

/// Fake AuthService that simulates sign-out success or failure.
class FakeAuthService extends AuthService {
  final bool shouldFail;
  final String failureMessage;

  const FakeAuthService({
    this.shouldFail = false,
    this.failureMessage = 'Network error during sign out',
  });

  @override
  Future<void> userSignOut() async {
    if (shouldFail) {
      throw AuthException(failureMessage);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late AuthController controller;

  final dummyUser = UserModel(
    id: 'u1',
    name: 'Test Driver',
    phoneNumber: '+919999888877',
    role: UserRole.driver,
    createdAt: DateTime(2026, 1, 1),
  );

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }

  setUp(() {
    AuthController.resetInstance();
    FirebaseService.isInitializedOverride = true;
  });

  tearDown(() {
    AuthController.resetInstance();
    FirebaseService.isInitializedOverride = false;
  });

  group('HomeScreen — Rendering', () {
    testWidgets('renders app name and foundation content', (tester) async {
      controller = AuthController(
        initialState: AuthState.authenticated(dummyUser),
      );

      await tester.pumpWidget(
        wrap(HomeScreen(authController: controller)),
      );

      expect(find.text(AppConstants.appName), findsWidgets);
      expect(find.text('Welcome to RideSathi'), findsOneWidget);
      expect(find.text('System Foundation Status'), findsOneWidget);
    });
  });

  group('HomeScreen — Logout with AuthController', () {
    testWidgets('successful logout navigates to login', (tester) async {
      final fakeAuth = const FakeAuthService(shouldFail: false);
      controller = AuthController(
        authService: fakeAuth,
        initialState: AuthState.authenticated(dummyUser),
      );

      await tester.pumpWidget(
        wrap(HomeScreen(authController: controller)),
      );

      // Tap the logout button.
      await tester.tap(find.byTooltip('Log Out'));
      await tester.pumpAndSettle();

      // Should have navigated to login.
      expect(find.text('Sign in to continue'), findsOneWidget);
    });

    testWidgets('failed logout shows SnackBar with error and retry',
        (tester) async {
      final fakeAuth = const FakeAuthService(
        shouldFail: true,
        failureMessage: 'Network error during sign out',
      );
      controller = AuthController(
        authService: fakeAuth,
        initialState: AuthState.authenticated(dummyUser),
      );

      await tester.pumpWidget(
        wrap(HomeScreen(authController: controller)),
      );

      // Tap the logout button.
      await tester.tap(find.byTooltip('Log Out'));
      await tester.pumpAndSettle();

      // Should show SnackBar with error message.
      expect(find.text('Network error during sign out'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Should still be on the home screen.
      expect(find.text('Welcome to RideSathi'), findsOneWidget);
    });

    testWidgets('shows login button when user is not authenticated',
        (tester) async {
      controller = AuthController(
        initialState: const AuthState.unauthenticated(),
      );

      await tester.pumpWidget(
        wrap(HomeScreen(authController: controller)),
      );

      // Login button should be visible, not logout.
      expect(find.byTooltip('Log In'), findsOneWidget);
      expect(find.byTooltip('Log Out'), findsNothing);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/auth_state.dart';
import 'package:ridesathi/screens/auth/login_screen.dart';
import 'package:ridesathi/services/firebase_service.dart';

// These tests exercise client-side validation, the "Firebase not configured"
// fallback path, and AuthController state integration. They never reach
// AuthService.signIn because FirebaseService.isInitialized is false by default
// in the test environment — so no real or emulated Firebase project is required.
void main() {
  late AuthController controller;

  Widget wrap(Widget child) {
    return MaterialApp(
      home: child,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }

  setUp(() {
    AuthController.resetInstance();
    FirebaseService.isInitializedOverride = false;
    controller = AuthController();
  });

  tearDown(() {
    AuthController.resetInstance();
    FirebaseService.isInitializedOverride = false;
  });

  group('LoginScreen — Form Validation', () {
    testWidgets('shows validation errors when submitting empty fields',
        (tester) async {
      await tester.pumpWidget(
        wrap(LoginScreen(authController: controller)),
      );

      await tester.tap(find.text('Log In'));
      await tester.pump();

      expect(find.text('Email is required.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);
    });

    testWidgets(
        'shows a friendly message instead of crashing when Firebase is not configured',
        (tester) async {
      await tester.pumpWidget(
        wrap(LoginScreen(authController: controller)),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'rider@ridesathi.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Log In'));
      await tester.pump();

      expect(
        find.text(
          'Firebase authentication is not available yet. Please complete Firebase setup before signing in.',
        ),
        findsOneWidget,
      );
    });
  });

  group('LoginScreen — Navigation', () {
    testWidgets('navigates to the signup screen', (tester) async {
      await tester.pumpWidget(
        wrap(LoginScreen(authController: controller)),
      );

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Create Your Account'), findsOneWidget);
    });
  });

  group('LoginScreen — AuthController Integration', () {
    testWidgets('shows loading state from AuthController', (tester) async {
      // Pre-set the controller to authenticating state.
      controller.updateState(const AuthState.authenticating());

      await tester.pumpWidget(
        wrap(LoginScreen(authController: controller)),
      );

      // CustomButton should show loading spinner when authenticating.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message from AuthController', (tester) async {
      controller.updateState(
        const AuthState.error('Incorrect email or password.'),
      );

      await tester.pumpWidget(
        wrap(LoginScreen(authController: controller)),
      );

      expect(find.text('Incorrect email or password.'), findsOneWidget);
    });

    testWidgets('clears error when user submits again', (tester) async {
      controller.updateState(
        const AuthState.error('Previous error'),
      );

      await tester.pumpWidget(
        wrap(LoginScreen(authController: controller)),
      );

      expect(find.text('Previous error'), findsOneWidget);

      // Tap submit to trigger re-validation (will fail at form validation,
      // but should clear the auth error first).
      await tester.tap(find.text('Log In'));
      await tester.pump();

      // The auth error should be cleared, but form validation errors appear.
      expect(find.text('Previous error'), findsNothing);
      expect(find.text('Email is required.'), findsOneWidget);
    });

    testWidgets('disables navigation controls during authentication',
        (tester) async {
      controller.updateState(const AuthState.authenticating());

      await tester.pumpWidget(
        wrap(LoginScreen(authController: controller)),
      );

      // Sign Up TextButton should be disabled during loading.
      final signUpButton = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Sign Up'),
          matching: find.byType(TextButton),
        ),
      );
      expect(signUpButton.onPressed, isNull);
    });
  });
}

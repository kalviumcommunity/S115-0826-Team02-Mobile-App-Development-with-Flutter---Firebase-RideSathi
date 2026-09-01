import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/auth_state.dart';
import 'package:ridesathi/screens/auth/signup_screen.dart';
import 'package:ridesathi/services/firebase_service.dart';

// These tests exercise client-side validation, the "Firebase not configured"
// fallback path, and AuthController state integration — see
// login_screen_test.dart for why no real or emulated Firebase project is required.
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

  group('SignupScreen — Form Validation', () {
    testWidgets('shows validation errors when submitting empty fields',
        (tester) async {
      await tester.pumpWidget(
        wrap(SignupScreen(authController: controller)),
      );

      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      expect(find.text('Email is required.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);
      expect(find.text('Please confirm your password.'), findsOneWidget);
    });

    testWidgets('shows an error when passwords do not match', (tester) async {
      await tester.pumpWidget(
        wrap(SignupScreen(authController: controller)),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'rider@ridesathi.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'different456',
      );
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets(
        'shows a friendly message instead of crashing when Firebase is not configured',
        (tester) async {
      await tester.pumpWidget(
        wrap(SignupScreen(authController: controller)),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'rider@ridesathi.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      expect(
        find.text(
          'Firebase authentication is not available yet. Please complete Firebase setup before signing up.',
        ),
        findsOneWidget,
      );
    });
  });

  group('SignupScreen — Navigation', () {
    testWidgets('navigates back to the login screen', (tester) async {
      await tester.pumpWidget(
        wrap(SignupScreen(authController: controller)),
      );

      await tester.ensureVisible(find.text('Log In'));
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to continue'), findsOneWidget);
    });
  });

  group('SignupScreen — AuthController Integration', () {
    testWidgets('shows loading state from AuthController', (tester) async {
      controller.updateState(const AuthState.authenticating());

      await tester.pumpWidget(
        wrap(SignupScreen(authController: controller)),
      );

      // The button should show loading spinner.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message from AuthController', (tester) async {
      controller.updateState(
        const AuthState.error('An account already exists with this email.'),
      );

      await tester.pumpWidget(
        wrap(SignupScreen(authController: controller)),
      );

      expect(
        find.text('An account already exists with this email.'),
        findsOneWidget,
      );
    });

    testWidgets('clears error when user submits again', (tester) async {
      controller.updateState(
        const AuthState.error('Previous signup error'),
      );

      await tester.pumpWidget(
        wrap(SignupScreen(authController: controller)),
      );

      expect(find.text('Previous signup error'), findsOneWidget);

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // The auth error should be cleared, form validation errors appear.
      expect(find.text('Previous signup error'), findsNothing);
      expect(find.text('Email is required.'), findsOneWidget);
    });

    testWidgets('disables navigation controls during authentication',
        (tester) async {
      controller.updateState(const AuthState.authenticating());

      await tester.pumpWidget(
        wrap(SignupScreen(authController: controller)),
      );

      // Log In TextButton should be disabled during loading.
      final loginButton = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Log In'),
          matching: find.byType(TextButton),
        ),
      );
      expect(loginButton.onPressed, isNull);
    });
  });
}

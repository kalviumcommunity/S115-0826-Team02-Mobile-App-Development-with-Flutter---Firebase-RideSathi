import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/screens/auth/login_screen.dart';

// These tests exercise client-side validation and the "Firebase not
// configured" fallback path only. They never reach AuthService.signIn,
// because FirebaseService.isInitialized is false by default in the test
// environment (main() is not run, so Firebase.initializeApp() never
// executes) — so no real or emulated Firebase project is required.
void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: child,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }

  testWidgets('shows validation errors when submitting empty fields',
      (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));

    await tester.tap(find.text('Log In'));
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
  });

  testWidgets(
      'shows a friendly message instead of crashing when Firebase is not configured',
      (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));

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

  testWidgets('navigates to the signup screen', (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.text('Create Your Account'), findsOneWidget);
  });
}

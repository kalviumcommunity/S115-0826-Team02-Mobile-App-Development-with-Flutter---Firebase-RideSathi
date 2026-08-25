import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/screens/auth/signup_screen.dart';

// These tests exercise client-side validation and the "Firebase not
// configured" fallback path only — see login_screen_test.dart for why no
// real or emulated Firebase project is required.
void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: child,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }

  testWidgets('shows validation errors when submitting empty fields',
      (tester) async {
    await tester.pumpWidget(wrap(const SignupScreen()));

    await tester.tap(find.text('Sign Up'));
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
    expect(find.text('Please confirm your password.'), findsOneWidget);
  });

  testWidgets('shows an error when passwords do not match', (tester) async {
    await tester.pumpWidget(wrap(const SignupScreen()));

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
    await tester.pumpWidget(wrap(const SignupScreen()));

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

  testWidgets('navigates back to the login screen', (tester) async {
    await tester.pumpWidget(wrap(const SignupScreen()));

    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to continue'), findsOneWidget);
  });
}

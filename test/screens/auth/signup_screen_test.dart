import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/auth_state.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/screens/auth/signup_screen.dart';
import 'package:ridesathi/services/auth_service.dart';
import 'package:ridesathi/services/firebase_service.dart';
import 'package:ridesathi/services/user_profile_service.dart';

class _FakeAuthService extends AuthService {
  const _FakeAuthService();

  @override
  Future<UserModel?> userSignUp({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    return UserModel(
      id: 'rider-mock-uid',
      name: name ?? '',
      phoneNumber: phone ?? '',
      email: email,
      role: UserRole.rider,
      isUnionVerified: false,
      createdAt: DateTime.now(),
    );
  }
}

class _FakeUserProfileService extends UserProfileService {
  UserModel? savedProfile;

  @override
  Future<void> createRiderProfile(UserModel user) async {
    savedProfile = user;
  }
}

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

  group('SignupScreen — Rider Branding & Layout', () {
    testWidgets('renders rider-specific headings and taxi icon', (tester) async {
      await tester.pumpWidget(
        wrap(SignupScreen(authController: controller)),
      );

      expect(find.text('Create Rider Account'), findsOneWidget);
      expect(
        find.text('Register as a rider on the RideSathi network'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.local_taxi_rounded), findsOneWidget);
    });

    testWidgets('renders all required rider input fields', (tester) async {
      await tester.pumpWidget(
        wrap(SignupScreen(authController: controller)),
      );

      expect(find.widgetWithText(TextFormField, 'Full Name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Phone Number'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Confirm Password'), findsOneWidget);
    });
  });

  group('SignupScreen — Form Validation', () {
    testWidgets('shows validation errors when submitting empty fields',
        (tester) async {
      await tester.pumpWidget(
        wrap(SignupScreen(authController: controller)),
      );

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      expect(find.text('Full name is required.'), findsOneWidget);
      expect(find.text('Phone number is required.'), findsOneWidget);
      expect(find.text('Email is required.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);
      expect(find.text('Please confirm your password.'), findsOneWidget);
    });

    testWidgets('shows errors for invalid name and phone inputs', (tester) async {
      await tester.pumpWidget(
        wrap(SignupScreen(authController: controller)),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'A');
      await tester.enterText(find.byType(TextFormField).at(1), '12345');
      await tester.enterText(find.byType(TextFormField).at(2), 'not-an-email');
      await tester.enterText(find.byType(TextFormField).at(3), '123');
      await tester.enterText(find.byType(TextFormField).at(4), '123');

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      expect(find.text('Name must be at least 2 characters.'), findsOneWidget);
      expect(find.text('Enter a valid phone number.'), findsOneWidget);
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters.'), findsOneWidget);
    });

    testWidgets('shows an error when passwords do not match', (tester) async {
      await tester.pumpWidget(
        wrap(SignupScreen(authController: controller)),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Aarav Sharma');
      await tester.enterText(find.byType(TextFormField).at(1), '+919876543210');
      await tester.enterText(find.byType(TextFormField).at(2), 'rider@ridesathi.com');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');
      await tester.enterText(find.byType(TextFormField).at(4), 'different456');

      await tester.ensureVisible(find.text('Sign Up'));
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

      await tester.enterText(find.byType(TextFormField).at(0), 'Aarav Sharma');
      await tester.enterText(find.byType(TextFormField).at(1), '+919876543210');
      await tester.enterText(find.byType(TextFormField).at(2), 'rider@ridesathi.com');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');
      await tester.enterText(find.byType(TextFormField).at(4), 'password123');

      await tester.ensureVisible(find.text('Sign Up'));
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

  group('SignupScreen — Successful Rider Registration', () {
    testWidgets('submits valid rider data and navigates to home on success',
        (tester) async {
      FirebaseService.isInitializedOverride = true;
      final fakeAuth = const _FakeAuthService();
      final fakeProfile = _FakeUserProfileService();
      final customController = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      await tester.pumpWidget(
        wrap(SignupScreen(authController: customController)),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Deepak Verma');
      await tester.enterText(find.byType(TextFormField).at(1), '9876543210');
      await tester.enterText(find.byType(TextFormField).at(2), 'deepak@ridesathi.com');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');
      await tester.enterText(find.byType(TextFormField).at(4), 'password123');

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(fakeProfile.savedProfile, isNotNull);
      expect(fakeProfile.savedProfile!.name, equals('Deepak Verma'));
      expect(fakeProfile.savedProfile!.phoneNumber, equals('9876543210'));
      expect(fakeProfile.savedProfile!.role, equals(UserRole.rider));
      // Navigates to home screen
      expect(find.text('Welcome to RideSathi'), findsOneWidget);
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
      expect(find.text('Full name is required.'), findsOneWidget);
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

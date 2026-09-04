import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/auth_state.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/screens/auth/login_screen.dart';
import 'package:ridesathi/services/auth_service.dart';
import 'package:ridesathi/services/firebase_service.dart';
import 'package:ridesathi/services/user_profile_service.dart';

class _FakeAuthService extends AuthService {
  final UserModel? userToReturn;
  const _FakeAuthService({this.userToReturn});

  @override
  Future<UserModel?> userSignIn({
    required String email,
    required String password,
  }) async {
    return userToReturn ??
        UserModel(
          id: 'test-uid',
          name: 'Test Rider',
          phoneNumber: '9876543210',
          email: email,
          role: UserRole.rider,
          createdAt: DateTime.now(),
        );
  }
}

class _FakeUserProfileService extends UserProfileService {
  final UserModel? profileToReturn;
  const _FakeUserProfileService({this.profileToReturn});

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    return profileToReturn;
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
    testWidgets('navigates to the signup screen via bottom sheet', (tester) async {
      await tester.pumpWidget(
        wrap(LoginScreen(authController: controller)),
      );

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Choose Account Type'), findsOneWidget);

      await tester.tap(find.text('Register as Rider'));
      await tester.pumpAndSettle();

      expect(find.text('Create Rider Account'), findsOneWidget);
    });

    testWidgets('navigates to the driver signup screen via bottom sheet', (tester) async {
      await tester.pumpWidget(
        wrap(LoginScreen(authController: controller)),
      );

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Choose Account Type'), findsOneWidget);

      await tester.tap(find.text('Register as Driver'));
      await tester.pumpAndSettle();

      expect(find.text('Create Driver Account'), findsOneWidget);
    });
  });

  group('LoginScreen — Successful Login', () {
    testWidgets('submits valid credentials, resolves profile, and navigates to home',
        (tester) async {
      FirebaseService.isInitializedOverride = true;
      final rider = UserModel(
        id: 'rider-abc',
        name: 'Rider Ramesh',
        phoneNumber: '9876543210',
        email: 'rider@ridesathi.com',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      final customController = AuthController(
        authService: _FakeAuthService(userToReturn: rider),
        userProfileService: _FakeUserProfileService(profileToReturn: rider),
      );

      await tester.pumpWidget(
        wrap(LoginScreen(authController: customController)),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'rider@ridesathi.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(customController.isAuthenticated, isTrue);
      expect(customController.currentUser!.name, equals('Rider Ramesh'));
      expect(find.text('RideSathi Rider'), findsOneWidget);
      expect(find.text('Welcome, Rider Ramesh'), findsOneWidget);
    });

    testWidgets('submits driver credentials, resolves driver profile, and navigates to home',
        (tester) async {
      FirebaseService.isInitializedOverride = true;
      final driver = UserModel(
        id: 'driver-xyz',
        name: 'Driver Dharmendra',
        phoneNumber: '9876543210',
        email: 'driver@ridesathi.com',
        role: UserRole.driver,
        vehicleInfo: 'Auto KA-01-1234',
        createdAt: DateTime.now(),
      );

      final customController = AuthController(
        authService: _FakeAuthService(userToReturn: driver),
        userProfileService: _FakeUserProfileService(profileToReturn: driver),
      );

      await tester.pumpWidget(
        wrap(LoginScreen(authController: customController)),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'driver@ridesathi.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(customController.isAuthenticated, isTrue);
      expect(customController.currentUser!.role, equals(UserRole.driver));
      expect(customController.currentUser!.vehicleInfo, equals('Auto KA-01-1234'));
      expect(find.text('RideSathi Driver'), findsOneWidget);
      expect(find.text('Welcome, Driver Dharmendra'), findsOneWidget);
    });

    testWidgets('shows error when profile is missing in Firestore',
        (tester) async {
      FirebaseService.isInitializedOverride = true;
      final orphan = UserModel(
        id: 'orphan-123',
        name: 'Orphan User',
        phoneNumber: '9876543210',
        email: 'orphan@ridesathi.com',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      final customController = AuthController(
        authService: _FakeAuthService(userToReturn: orphan),
        userProfileService: const _FakeUserProfileService(profileToReturn: null),
      );

      await tester.pumpWidget(
        wrap(LoginScreen(authController: customController)),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'orphan@ridesathi.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(customController.isAuthenticated, isFalse);
      expect(
        find.text('User profile not found. Please contact support or register again.'),
        findsOneWidget,
      );
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

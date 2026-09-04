import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/auth_state.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/screens/rider/rider_home_screen.dart';
import 'package:ridesathi/services/auth_service.dart';
import 'package:ridesathi/services/firebase_service.dart';

class _FakeAuthService extends AuthService {
  final bool shouldFailSignOut;
  final Completer<void>? signOutCompleter;
  const _FakeAuthService({this.shouldFailSignOut = false, this.signOutCompleter});

  @override
  Future<void> userSignOut() async {
    if (signOutCompleter != null) {
      await signOutCompleter!.future;
    }
    if (shouldFailSignOut) {
      throw const AuthException('Sign out failed due to network.');
    }
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

  final dummyRider = UserModel(
    id: 'rider-1',
    name: 'Anita Roy',
    phoneNumber: '+919876543210',
    email: 'anita@rider.com',
    role: UserRole.rider,
    createdAt: DateTime.now(),
  );

  setUp(() {
    AuthController.resetInstance();
    FirebaseService.isInitializedOverride = true;
    controller = AuthController(
      authService: const _FakeAuthService(),
      initialState: AuthState.authenticated(dummyRider),
    );
  });

  tearDown(() {
    AuthController.resetInstance();
    FirebaseService.isInitializedOverride = false;
  });

  group('RiderHomeScreen — Layout and Rider Identity', () {
    testWidgets('renders rider branding, welcome text, and active role', (tester) async {
      await tester.pumpWidget(
        wrap(RiderHomeScreen(authController: controller)),
      );

      expect(find.text('RideSathi Rider'), findsOneWidget);
      expect(find.text('Welcome, Anita Roy'), findsOneWidget);
      expect(find.text('Connected as Rider • +919876543210'), findsOneWidget);
      expect(find.text('Rider Role Active'), findsOneWidget);
      expect(find.text('Book a Ride'), findsOneWidget);
      expect(find.text('Fair Union Pricing'), findsOneWidget);
    });

    testWidgets('fallback to Rider when name is empty', (tester) async {
      final anonRider = UserModel(
        id: 'rider-2',
        name: '',
        phoneNumber: '',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      final anonController = AuthController(
        initialState: AuthState.authenticated(anonRider),
      );

      await tester.pumpWidget(
        wrap(RiderHomeScreen(authController: anonController)),
      );

      expect(find.text('Welcome, Rider'), findsOneWidget);
    });
  });

  group('RiderHomeScreen — Logout Workflow', () {
    testWidgets('successful logout clears stack and navigates to LoginScreen', (tester) async {
      await tester.pumpWidget(
        wrap(RiderHomeScreen(authController: controller)),
      );

      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pumpAndSettle();

      expect(controller.isAuthenticated, isFalse);
      expect(find.text('Sign in to continue'), findsOneWidget);
    });

    testWidgets('failed logout shows SnackBar error', (tester) async {
      final failingController = AuthController(
        authService: const _FakeAuthService(shouldFailSignOut: true),
        initialState: AuthState.authenticated(dummyRider),
      );

      await tester.pumpWidget(
        wrap(RiderHomeScreen(authController: failingController)),
      );

      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pump();

      expect(find.text('Sign out failed due to network.'), findsOneWidget);
    });

    testWidgets('shows loading indicator and disables logout button during logout', (tester) async {
      final completer = Completer<void>();
      final slowController = AuthController(
        authService: _FakeAuthService(signOutCompleter: completer),
        initialState: AuthState.authenticated(dummyRider),
      );

      await tester.pumpWidget(
        wrap(RiderHomeScreen(authController: slowController)),
      );

      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Tap logout
      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pump();

      // Spinner appears in place of icon
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsNothing);

      // Complete sign-out
      completer.complete();
      await tester.pumpAndSettle();

      expect(slowController.isAuthenticated, isFalse);
      expect(find.text('Sign in to continue'), findsOneWidget);
    });

    testWidgets('rapid repeated taps on logout do not crash or produce duplicate navigation', (tester) async {
      final completer = Completer<void>();
      final slowController = AuthController(
        authService: _FakeAuthService(signOutCompleter: completer),
        initialState: AuthState.authenticated(dummyRider),
      );

      await tester.pumpWidget(
        wrap(RiderHomeScreen(authController: slowController)),
      );

      // Tap multiple times rapidly
      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pump();
      await tester.tap(find.byType(IconButton).last, warnIfMissed: false);
      await tester.pump();

      completer.complete();
      await tester.pumpAndSettle();

      expect(slowController.isAuthenticated, isFalse);
      expect(find.text('Sign in to continue'), findsOneWidget);
    });
  });
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/auth_state.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/screens/driver/driver_home_screen.dart';
import 'package:ridesathi/services/auth_service.dart';
import 'package:ridesathi/services/firebase_service.dart';

class _FakeAuthService extends AuthService {
  final bool shouldFailSignOut;
  final Completer<void>? signOutCompleter;
  const _FakeAuthService(
      {this.shouldFailSignOut = false, this.signOutCompleter});

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

  final dummyDriver = UserModel(
    id: 'driver-1',
    name: 'Vikram Singh',
    phoneNumber: '+919988776655',
    email: 'vikram@driver.com',
    role: UserRole.driver,
    vehicleInfo: 'Auto DL-01-AB-1234',
    isUnionVerified: false,
    createdAt: DateTime.now(),
  );

  setUp(() {
    AuthController.resetInstance();
    FirebaseService.isInitializedOverride = true;
    controller = AuthController(
      authService: const _FakeAuthService(),
      initialState: AuthState.authenticated(dummyDriver),
    );
  });

  tearDown(() {
    AuthController.resetInstance();
    FirebaseService.isInitializedOverride = false;
  });

  group('DriverHomeScreen — Layout, Driver Identity & Verification State', () {
    testWidgets(
        'renders driver branding, vehicle info, and pending verification badge',
        (tester) async {
      await tester.pumpWidget(
        wrap(DriverHomeScreen(authController: controller)),
      );

      expect(find.text('RideSathi Driver'), findsOneWidget);
      expect(find.text('Welcome, Vikram Singh'), findsOneWidget);
      expect(find.text('Driver Console • +919988776655'), findsOneWidget);
      expect(find.text('Driver Role Active'), findsOneWidget);
      expect(find.text('Pending Verification'), findsOneWidget);
      expect(find.text('Auto DL-01-AB-1234'), findsOneWidget);
      expect(find.text('Registered Vehicle'), findsOneWidget);
      expect(find.text('Union Verification Status'), findsOneWidget);
      expect(find.text('Driver Availability'), findsOneWidget);
      expect(find.text('Incoming Ride Requests'), findsOneWidget);
      expect(find.text('Current Ride'), findsOneWidget);
    });

    testWidgets(
        'renders verified badge and message when driver is union verified',
        (tester) async {
      final verifiedDriver = UserModel(
        id: 'driver-2',
        name: 'Harpreet Singh',
        phoneNumber: '+919999000011',
        role: UserRole.driver,
        vehicleInfo: 'Cab KA-02-CD-5678',
        isUnionVerified: true,
        createdAt: DateTime.now(),
      );

      final verifiedController = AuthController(
        initialState: AuthState.authenticated(verifiedDriver),
      );

      await tester.pumpWidget(
        wrap(DriverHomeScreen(authController: verifiedController)),
      );

      expect(find.text('Union Verified'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(
          find.text(
              'Your union credentials and vehicle permit are fully verified.'),
          findsOneWidget);
      expect(find.text('Cab KA-02-CD-5678'), findsOneWidget);
      expect(
          find.text(
              'Your union credentials and vehicle permit are fully verified.'),
          findsOneWidget);
    });

    testWidgets(
        'renders fallback text when vehicle information is missing or empty',
        (tester) async {
      final noVehicleDriver = UserModel(
        id: 'driver-3',
        name: 'Amit Kumar',
        phoneNumber: '+919876543210',
        role: UserRole.driver,
        vehicleInfo: '',
        isUnionVerified: false,
        createdAt: DateTime.now(),
      );

      final noVehicleController = AuthController(
        initialState: AuthState.authenticated(noVehicleDriver),
      );

      await tester.pumpWidget(
        wrap(DriverHomeScreen(authController: noVehicleController)),
      );

      expect(find.text('Vehicle details not available'), findsOneWidget);
      expect(find.text('Not Set'), findsOneWidget);
    });
  });

  group('DriverHomeScreen — Loading and Error States', () {
    testWidgets('renders loading view when auth controller state is loading',
        (tester) async {
      final loadingController = AuthController(
        initialState: const AuthState.loading(),
      );

      await tester.pumpWidget(
        wrap(DriverHomeScreen(authController: loadingController)),
      );

      expect(find.text('Loading driver profile...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error view when user profile is null', (tester) async {
      final unauthController = AuthController(
        initialState: const AuthState.unauthenticated(),
      );

      await tester.pumpWidget(
        wrap(DriverHomeScreen(authController: unauthController)),
      );

      expect(find.text('Driver Profile Not Found'), findsOneWidget);
      expect(
          find.text(
              'Unable to resolve authenticated driver information. Please log in again.'),
          findsOneWidget);
    });

    testWidgets('renders access restricted error when user is a Rider',
        (tester) async {
      final riderUser = UserModel(
        id: 'rider-1',
        name: 'Rahul Rider',
        phoneNumber: '+919111122223',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      final riderController = AuthController(
        initialState: AuthState.authenticated(riderUser),
      );

      await tester.pumpWidget(
        wrap(DriverHomeScreen(authController: riderController)),
      );

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(
          find.text(
              'This dashboard is reserved for authenticated driver accounts.'),
          findsOneWidget);
    });

    testWidgets(
        'renders fallback text when vehicle information is missing or empty',
        (tester) async {
      final noVehicleDriver = UserModel(
        id: 'driver-3',
        name: 'Amit Kumar',
        phoneNumber: '+919876543210',
        role: UserRole.driver,
        vehicleInfo: '',
        isUnionVerified: false,
        createdAt: DateTime.now(),
      );

      final noVehicleController = AuthController(
        initialState: AuthState.authenticated(noVehicleDriver),
      );

      await tester.pumpWidget(
        wrap(DriverHomeScreen(authController: noVehicleController)),
      );

      expect(find.text('Vehicle details not available'), findsOneWidget);
      expect(find.text('Not Set'), findsOneWidget);
    });
  });

  group('DriverHomeScreen — Session Isolation & Verification State Safety',
      () {
    testWidgets(
        'verified Driver A logout and unverified Driver B login preserves strict session isolation',
        (tester) async {
      final driverA = UserModel(
        id: 'driver-A',
        name: 'Driver Alpha',
        phoneNumber: '+919000000001',
        role: UserRole.driver,
        vehicleInfo: 'Auto KA-01-A-1111',
        isUnionVerified: true,
        createdAt: DateTime.now(),
      );

      final driverB = UserModel(
        id: 'driver-B',
        name: 'Driver Bravo',
        phoneNumber: '+919000000002',
        role: UserRole.driver,
        vehicleInfo: 'Cab KA-02-B-2222',
        isUnionVerified: false,
        createdAt: DateTime.now(),
      );

      final authCtrl = AuthController(
        initialState: AuthState.authenticated(driverA),
      );

      await tester.pumpWidget(
        wrap(DriverHomeScreen(authController: authCtrl)),
      );

      expect(find.text('Welcome, Driver Alpha'), findsOneWidget);
      expect(find.text('Union Verified'), findsOneWidget);

      // Sign out Driver A
      await authCtrl.signOut();
      await tester.pumpAndSettle();

      // Sign in Driver B
      authCtrl.restoreSession(driverB);
      await tester.pumpWidget(
        wrap(DriverHomeScreen(authController: authCtrl)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome, Driver Bravo'), findsOneWidget);
      expect(find.text('Pending Verification'), findsOneWidget);

      expect(find.text('Welcome, Driver Alpha'), findsNothing);
      expect(find.text('Union Verified'), findsNothing);
    });
  });

  group('DriverHomeScreen — Navigation and Logout Workflow', () {
    testWidgets('navigates to Profile screen when profile icon is tapped',
        (tester) async {
      await tester.pumpWidget(
        wrap(DriverHomeScreen(authController: controller)),
      );

      final profileButton = find.byIcon(Icons.person_outline_rounded);
      expect(profileButton, findsOneWidget);

      await tester.tap(profileButton);
      await tester.pumpAndSettle();

      expect(find.text('User Profile'), findsOneWidget);
    });

    testWidgets(
        'successful logout clears stack and navigates to LoginScreen',
        (tester) async {
      await tester.pumpWidget(
        wrap(DriverHomeScreen(authController: controller)),
      );

      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pumpAndSettle();

      expect(controller.isAuthenticated, isFalse);
      expect(find.text('Sign in to continue'), findsOneWidget);
    });

    testWidgets('failed logout shows SnackBar error', (tester) async {
      final failingController = AuthController(
        authService: const _FakeAuthService(shouldFailSignOut: true),
        initialState: AuthState.authenticated(dummyDriver),
      );

      await tester.pumpWidget(
        wrap(DriverHomeScreen(authController: failingController)),
      );

      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pump();

      expect(find.text('Sign out failed due to network.'), findsOneWidget);
    });

    testWidgets(
        'shows loading indicator and disables logout button during logout',
        (tester) async {
      final completer = Completer<void>();
      final slowController = AuthController(
        authService: _FakeAuthService(signOutCompleter: completer),
        initialState: AuthState.authenticated(dummyDriver),
      );

      await tester.pumpWidget(
        wrap(DriverHomeScreen(authController: slowController)),
      );

      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsNothing);

      completer.complete();
      await tester.pumpAndSettle();

      expect(slowController.isAuthenticated, isFalse);
      expect(find.text('Sign in to continue'), findsOneWidget);
    });

    testWidgets(
        'rapid repeated taps on logout do not crash or produce duplicate navigation',
        (tester) async {
      final completer = Completer<void>();
      final slowController = AuthController(
        authService: _FakeAuthService(signOutCompleter: completer),
        initialState: AuthState.authenticated(dummyDriver),
      );

      await tester.pumpWidget(
        wrap(DriverHomeScreen(authController: slowController)),
      );

      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pump();
      await tester.tap(find.byType(IconButton).last, warnIfMissed: false);
      await tester.pump();
    });
  });
}

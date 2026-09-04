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
  const _FakeAuthService({this.shouldFailSignOut = false});

  @override
  Future<void> userSignOut() async {
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

  group('DriverHomeScreen — Layout and Driver Identity', () {
    testWidgets('renders driver branding, vehicle info, and verification badge', (tester) async {
      await tester.pumpWidget(
        wrap(DriverHomeScreen(authController: controller)),
      );

      expect(find.text('RideSathi Driver'), findsOneWidget);
      expect(find.text('Welcome, Vikram Singh'), findsOneWidget);
      expect(find.text('Driver Console • +919988776655'), findsOneWidget);
      expect(find.text('Driver Role Active'), findsOneWidget);
      expect(find.text('Pending Verification'), findsOneWidget);
      expect(find.text('Auto DL-01-AB-1234'), findsOneWidget);
      expect(find.text('Trip Dispatch Console'), findsOneWidget);
    });

    testWidgets('renders verified badge when driver is union verified', (tester) async {
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
      expect(find.text('Cab KA-02-CD-5678'), findsOneWidget);
    });
  });

  group('DriverHomeScreen — Logout Workflow', () {
    testWidgets('successful logout clears stack and navigates to LoginScreen', (tester) async {
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
  });
}

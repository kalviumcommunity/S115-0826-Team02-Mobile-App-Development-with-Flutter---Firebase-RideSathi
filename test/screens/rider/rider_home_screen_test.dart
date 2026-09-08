import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/auth_state.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/screens/profile/profile_screen.dart';
import 'package:ridesathi/screens/rider/rider_home_screen.dart';
import 'package:ridesathi/screens/rider/ride_request_placeholder_screen.dart';
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

  Widget wrap(Widget child, {AuthController? authController}) {
    return MaterialApp(
      home: child,
      onGenerateRoute: (settings) => AppRoutes.generateRoute(
        settings,
        authController: authController,
      ),
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

  group('RiderHomeScreen \u2014 Layout and Rider Identity', () {
    testWidgets('renders rider branding and greeting with rider name', (tester) async {
      await tester.pumpWidget(
        wrap(RiderHomeScreen(authController: controller), authController: controller),
      );

      expect(find.text('RideSathi Rider'), findsOneWidget);
      expect(find.text('Hello, Anita Roy'), findsOneWidget);
      expect(find.text('Where would you like to go?'), findsOneWidget);
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
        wrap(RiderHomeScreen(authController: anonController), authController: anonController),
      );

      expect(find.text('Hello, Rider'), findsOneWidget);
    });
  });

  group('RiderHomeScreen \u2014 Request a Ride CTA', () {
    testWidgets('Request a Ride CTA is visible', (tester) async {
      await tester.pumpWidget(
        wrap(RiderHomeScreen(authController: controller), authController: controller),
      );
      expect(find.text('Request a Ride'), findsOneWidget);
    });

    testWidgets('Request a Ride CTA navigates to placeholder screen', (tester) async {
      await tester.pumpWidget(
        wrap(RiderHomeScreen(authController: controller), authController: controller),
      );
      await tester.tap(find.text('Request a Ride'));
      await tester.pumpAndSettle();
      expect(find.byType(RideRequestPlaceholderScreen), findsOneWidget);
    });
  });

  group('RiderHomeScreen \u2014 Profile Access', () {
    testWidgets('profile action is visible in app bar', (tester) async {
      await tester.pumpWidget(
        wrap(RiderHomeScreen(authController: controller), authController: controller),
      );
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('profile action navigates to ProfileScreen', (tester) async {
      await tester.pumpWidget(
        wrap(RiderHomeScreen(authController: controller), authController: controller),
      );
      await tester.tap(find.byIcon(Icons.person_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });

  group('RiderHomeScreen \u2014 Current Ride Section', () {
    testWidgets('empty current ride state is displayed when no active ride', (tester) async {
      await tester.pumpWidget(
        wrap(RiderHomeScreen(authController: controller), authController: controller),
      );
      expect(find.text('No active ride'), findsOneWidget);
      expect(find.text('Current Ride'), findsOneWidget);
    });

    testWidgets('active ride UI is not falsely displayed', (tester) async {
      await tester.pumpWidget(
        wrap(RiderHomeScreen(authController: controller), authController: controller),
      );
      expect(find.text('No active ride'), findsOneWidget);
    });
  });

  group('RiderHomeScreen \u2014 Bottom Navigation', () {
    testWidgets('bottom navigation selects Home correctly', (tester) async {
      await tester.pumpWidget(
        wrap(RiderHomeScreen(authController: controller), authController: controller),
      );
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Profile'), findsWidgets);
    });

    testWidgets('bottom navigation can reach Profile', (tester) async {
      await tester.pumpWidget(
        wrap(RiderHomeScreen(authController: controller), authController: controller),
      );
      final profileDest = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profile'),
      );
      await tester.tap(profileDest);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });

  group('RiderHomeScreen \u2014 Logout Workflow', () {
    testWidgets('successful logout clears stack and navigates to LoginScreen', (tester) async {
      await tester.pumpWidget(
        wrap(RiderHomeScreen(authController: controller), authController: controller),
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
        wrap(RiderHomeScreen(authController: failingController), authController: failingController),
      );
      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pump();
      expect(find.text('Sign out failed due to network.'), findsOneWidget);
    });

    testWidgets('shows loading indicator during logout', (tester) async {
      final completer = Completer<void>();
      final slowController = AuthController(
        authService: _FakeAuthService(signOutCompleter: completer),
        initialState: AuthState.authenticated(dummyRider),
      );
      await tester.pumpWidget(
        wrap(RiderHomeScreen(authController: slowController), authController: slowController),
      );
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.byIcon(Icons.logout_rounded), findsNothing);
      completer.complete();
      await tester.pumpAndSettle();
      expect(slowController.isAuthenticated, isFalse);
      expect(find.text('Sign in to continue'), findsOneWidget);
    });
  });

  group('RiderHomeScreen \u2014 Theming', () {
    testWidgets('dark theme renders without exceptions', (tester) async {
      await tester.pumpWidget(
        wrap(
          Theme(
            data: ThemeData.dark(useMaterial3: true),
            child: RiderHomeScreen(authController: controller),
          ),
          authController: controller,
        ),
      );
      expect(find.text('Hello, Anita Roy'), findsOneWidget);
      expect(find.text('Request a Ride'), findsOneWidget);
      expect(find.text('No active ride'), findsOneWidget);
    });
  });

  group('RiderHomeScreen \u2014 Responsive Layout', () {
    testWidgets('narrow-screen layout does not overflow', (tester) async {
      tester.view.physicalSize = const Size(428, 926);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        wrap(RiderHomeScreen(authController: controller), authController: controller),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Hello, Anita Roy'), findsOneWidget);
    });
  });
}





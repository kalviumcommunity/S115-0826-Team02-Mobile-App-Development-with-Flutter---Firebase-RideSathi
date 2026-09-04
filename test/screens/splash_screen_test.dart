import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridesathi/core/constants/app_constants.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/auth_state.dart';
import 'package:ridesathi/core/theme/app_theme.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/screens/splash_screen.dart';
import 'package:ridesathi/services/auth_service.dart';
import 'package:ridesathi/services/firebase_service.dart';
import 'package:ridesathi/services/firestore_exception.dart';
import 'package:ridesathi/services/user_profile_service.dart';
import 'package:ridesathi/widgets/error_view.dart';
import 'package:ridesathi/widgets/union_badge.dart';

class FakeSplashAuthService extends AuthService {
  final UserModel? mockUser;
  const FakeSplashAuthService({this.mockUser});

  @override
  UserModel? get currentAuthUser => mockUser;
}

class FakeSplashUserProfileService extends UserProfileService {
  bool shouldFail;
  UserModel? profileToReturn;

  FakeSplashUserProfileService({this.shouldFail = false, this.profileToReturn});

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    if (shouldFail) {
      throw const FirestoreException('Network error during session restoration');
    }
    return profileToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  /// Wraps the SplashScreen in a MaterialApp with the real route generator.
  Widget buildSplashApp({ThemeData? theme, AuthController? authController}) {
    if (authController != null) {
      return MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: SplashScreen(authController: authController),
        onGenerateRoute: AppRoutes.generateRoute,
      );
    }
    return MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }

  setUp(() {
    // Reset Firebase and Auth state before each test.
    FirebaseService.isInitializedOverride = false;
    AuthController.resetInstance();
  });

  tearDown(() {
    // Ensure clean state after each test.
    FirebaseService.isInitializedOverride = false;
    AuthController.resetInstance();
  });

  group('SplashScreen — Branding & Rendering', () {
    testWidgets('renders app name and tagline', (WidgetTester tester) async {
      await tester.pumpWidget(buildSplashApp());

      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text(AppConstants.appTagline), findsOneWidget);
    });

    testWidgets('renders UnionBadge', (WidgetTester tester) async {
      await tester.pumpWidget(buildSplashApp());

      expect(find.byType(UnionBadge), findsOneWidget);
    });

    testWidgets('renders loading indicator during initialization',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildSplashApp());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders taxi icon', (WidgetTester tester) async {
      await tester.pumpWidget(buildSplashApp());

      expect(find.byIcon(Icons.local_taxi_rounded), findsOneWidget);
    });
  });

  group('SplashScreen — Unauthenticated Startup', () {
    testWidgets(
        'navigates to login when Firebase is initialized and no user is logged in',
        (WidgetTester tester) async {
      // Simulate successful Firebase initialization with no logged-in user.
      FirebaseService.isInitializedOverride = true;

      await tester.pumpWidget(buildSplashApp());

      // Verify splash is shown initially.
      expect(find.byType(SplashScreen), findsOneWidget);

      // Advance past the 2200ms navigation timer.
      await tester.pump(const Duration(milliseconds: 2500));
      // Pump a few more frames to let the route transition complete.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Should have navigated away from splash to login.
      // Login screen shows "Sign in to continue".
      expect(find.text('Sign in to continue'), findsOneWidget);
    });
  });

  group('SplashScreen — Authenticated Startup', () {
    // Note: Testing authenticated startup with a real User object requires
    // Firebase Auth to be initialized, which is not available in unit tests.
    // The navigation logic is verified by the unauthenticated test above
    // (proving the if/else branch works) and by the navigation guard tests.
    // Full authenticated flow is covered in the manual test plan.

    testWidgets('navigates away from splash when Firebase is initialized',
        (WidgetTester tester) async {
      FirebaseService.isInitializedOverride = true;

      await tester.pumpWidget(buildSplashApp());

      // Advance past timer and let route transition complete.
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Should have left the splash screen (to login since no user).
      expect(find.byType(SplashScreen), findsNothing);
    });
  });

  group('SplashScreen — Timer/Lifecycle Safety', () {
    testWidgets('disposing before timer fires does not throw',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildSplashApp());

      // Verify splash is present.
      expect(find.byType(SplashScreen), findsOneWidget);

      // Immediately replace the widget tree (which disposes the splash)
      // before the 2200ms timer fires — this should not throw.
      await tester.pumpWidget(const SizedBox());

      // Advance time past where the timer would have fired.
      await tester.pump(const Duration(milliseconds: 3000));

      // If we reach here without an exception, the test passes.
      // The timer was cancelled in dispose() and did not attempt
      // navigation on a disposed widget.
    });

    testWidgets('animation controller disposes cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildSplashApp());

      // Pump a few animation frames.
      await tester.pump(const Duration(milliseconds: 500));

      // Replace the widget tree — dispose should be clean.
      await tester.pumpWidget(const SizedBox());

      // Advance time past the timer.
      await tester.pump(const Duration(milliseconds: 3000));

      // No exception means the animation controller and timer
      // were properly disposed.
    });
  });

  group('SplashScreen — Navigation Guard', () {
    testWidgets(
        'splash navigates exactly once via stack-clearing navigation',
        (WidgetTester tester) async {
      FirebaseService.isInitializedOverride = true;

      await tester.pumpWidget(buildSplashApp());

      // Advance past the timer.
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // After navigating, splash should be gone and login should be present.
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('Sign in to continue'), findsOneWidget);

      // The back stack should be cleared — canPop should be false.
      final loginContext = tester.element(find.text('Sign in to continue'));
      expect(Navigator.of(loginContext).canPop(), isFalse);
    });
  });

  group('SplashScreen — Error State', () {
    testWidgets(
        'shows error UI when Firebase is not initialized after timer fires',
        (WidgetTester tester) async {
      // Firebase NOT initialized (default state).
      await tester.pumpWidget(buildSplashApp());

      // Advance past the 2200ms navigation timer.
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();

      // Error state should be shown with ErrorView.
      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Unable to Start'), findsOneWidget);
      expect(
        find.textContaining('could not connect'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button re-checks Firebase state',
        (WidgetTester tester) async {
      // Start with Firebase NOT initialized.
      await tester.pumpWidget(buildSplashApp());

      // Advance past timer to trigger error state.
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();

      expect(find.byType(ErrorView), findsOneWidget);

      // Now simulate Firebase becoming available.
      FirebaseService.isInitializedOverride = true;

      // Tap retry.
      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Advance past the retry delay (800ms).
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Should have navigated to login (since no user in test env).
      expect(find.text('Sign in to continue'), findsOneWidget);
    });
  });

  group('SplashScreen — Theme Support', () {
    testWidgets('renders correctly in light theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildSplashApp(theme: AppTheme.lightTheme));

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders correctly in dark theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.generateRoute,
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('SplashScreen — AuthController Session Restoration', () {
    testWidgets('navigates to /rider/home when rider user is authenticated with valid profile',
        (WidgetTester tester) async {
      FirebaseService.isInitializedOverride = true;
      final dummyUser = UserModel(
        id: 'rider-splash-1',
        name: 'Splash Rider',
        phoneNumber: '9876543210',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );
      final controller = AuthController(
        initialState: AuthState.authenticated(dummyUser),
      );

      await tester.pumpWidget(buildSplashApp(authController: controller));

      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('RideSathi Rider'), findsOneWidget);
      expect(find.text('Welcome, Splash Rider'), findsOneWidget);
    });

    testWidgets('navigates to /driver/home when driver user is authenticated with valid profile',
        (WidgetTester tester) async {
      FirebaseService.isInitializedOverride = true;
      final dummyDriver = UserModel(
        id: 'driver-splash-1',
        name: 'Driver Splash',
        phoneNumber: '9876543210',
        role: UserRole.driver,
        vehicleInfo: 'Auto DL-01-AB-1234',
        createdAt: DateTime.now(),
      );
      final controller = AuthController(
        initialState: AuthState.authenticated(dummyDriver),
      );

      await tester.pumpWidget(buildSplashApp(authController: controller));

      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('RideSathi Driver'), findsOneWidget);
      expect(find.text('Welcome, Driver Splash'), findsOneWidget);
    });

    testWidgets('navigates to /login when user is unauthenticated',
        (WidgetTester tester) async {
      FirebaseService.isInitializedOverride = true;
      final controller = AuthController(
        initialState: const AuthState.unauthenticated(),
      );

      await tester.pumpWidget(buildSplashApp(authController: controller));

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('Sign in to continue'), findsOneWidget);
    });

    testWidgets('shows ErrorView when session restoration fails with error',
        (WidgetTester tester) async {
      FirebaseService.isInitializedOverride = true;
      final controller = AuthController(
        initialState: const AuthState.error(
          'User session active, but profile could not be found.',
        ),
      );

      await tester.pumpWidget(buildSplashApp(authController: controller));

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();

      expect(find.byType(ErrorView), findsOneWidget);
      expect(
        find.text('User session active, but profile could not be found.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('waits for restoration to complete even if timer fires first',
        (WidgetTester tester) async {
      FirebaseService.isInitializedOverride = true;
      final controller = AuthController(
        initialState: const AuthState.authenticating(),
      );

      await tester.pumpWidget(buildSplashApp(authController: controller));

      // Advance past timer (2200ms) while still authenticating
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();

      // Should still be on SplashScreen because restoration has not reached definitive state
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Now restoration completes to unauthenticated
      controller.updateState(const AuthState.unauthenticated());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Navigates to login
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('Sign in to continue'), findsOneWidget);
    });

    testWidgets('retry on splash error initiates retry and navigates on recovery',
        (WidgetTester tester) async {
      FirebaseService.isInitializedOverride = true;

      final dummyUser = UserModel(
        id: 'recovered-driver-1',
        name: 'Recovered Driver',
        phoneNumber: '9876543210',
        role: UserRole.driver,
        vehicleInfo: 'Auto DL-01',
        createdAt: DateTime.now(),
      );

      final fakeAuth = FakeSplashAuthService(mockUser: dummyUser);
      final fakeProfile = FakeSplashUserProfileService(
        shouldFail: true,
      );

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
        initialState: const AuthState.error(
          'Network error during session restoration',
        ),
      );

      await tester.pumpWidget(buildSplashApp(authController: controller));
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();

      expect(find.byType(ErrorView), findsOneWidget);
      expect(
        find.text('Network error during session restoration'),
        findsOneWidget,
      );

      // Now service recovers
      fakeProfile.shouldFail = false;
      fakeProfile.profileToReturn = dummyUser;

      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Advance retry timer (800ms) + let async navigation complete
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('RideSathi Driver'), findsOneWidget);
      expect(find.text('Welcome, Recovered Driver'), findsOneWidget);
    });
  });
}

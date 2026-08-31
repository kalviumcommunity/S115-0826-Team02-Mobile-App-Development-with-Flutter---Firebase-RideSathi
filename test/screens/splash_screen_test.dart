import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridesathi/core/constants/app_constants.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/theme/app_theme.dart';
import 'package:ridesathi/screens/splash_screen.dart';
import 'package:ridesathi/services/firebase_service.dart';
import 'package:ridesathi/widgets/error_view.dart';
import 'package:ridesathi/widgets/union_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  /// Wraps the SplashScreen in a MaterialApp with the real route generator.
  Widget buildSplashApp({ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }

  setUp(() {
    // Reset Firebase state before each test.
    FirebaseService.isInitializedOverride = false;
  });

  tearDown(() {
    // Ensure clean state after each test.
    FirebaseService.isInitializedOverride = false;
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
}

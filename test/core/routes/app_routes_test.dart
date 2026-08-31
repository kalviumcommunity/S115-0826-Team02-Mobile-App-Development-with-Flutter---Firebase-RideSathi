import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/theme/app_theme.dart';
import 'package:ridesathi/screens/auth/login_screen.dart';
import 'package:ridesathi/screens/auth/signup_screen.dart';
import 'package:ridesathi/screens/home_screen.dart';
import 'package:ridesathi/screens/splash_screen.dart';
import 'package:ridesathi/widgets/error_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AppRoutes Constants', () {
    test('defines correct path strings for all routes', () {
      expect(AppRoutes.splash, '/');
      expect(AppRoutes.home, '/home');
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.signup, '/signup');
      expect(AppRoutes.riderHome, '/rider/home');
      expect(AppRoutes.driverHome, '/driver/home');
      expect(AppRoutes.dispatcherHome, '/dispatcher/home');
    });
  });

  group('AppRoutes.generateRoute', () {
    Widget buildTestApp(String initialRoute) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        initialRoute: initialRoute,
        onGenerateRoute: AppRoutes.generateRoute,
      );
    }

    testWidgets('generates SplashScreen for routeSplash',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(AppRoutes.splash));
      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pumpAndSettle();
    });

    testWidgets('generates HomeScreen for routeHome',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(AppRoutes.home));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('generates LoginScreen for routeLogin',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(AppRoutes.login));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('generates SignupScreen for routeSignup',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(AppRoutes.signup));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);
    });

    testWidgets('generates ErrorView for unknown routes',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp('/invalid-route-name'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Page Not Found'), findsAtLeastNWidgets(1));
      expect(
        find.text('The requested route "/invalid-route-name" does not exist.'),
        findsOneWidget,
      );
      expect(find.text('Return to Home'), findsOneWidget);
    });

    testWidgets(
        'tapping Return to Home on unknown route navigates to HomeScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp('/invalid-route-name'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsOneWidget);

      await tester.tap(find.text('Return to Home'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('AppNavigator Helpers', () {
    Widget buildNavApp(String initialRoute) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        initialRoute: initialRoute,
        onGenerateRoute: AppRoutes.generateRoute,
      );
    }

    testWidgets('toHome navigates to HomeScreen and clears stack',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildNavApp(AppRoutes.login));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      final BuildContext context = tester.element(find.byType(LoginScreen));
      AppNavigator.toHome(context);
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(AppNavigator.canPop(tester.element(find.byType(HomeScreen))), isFalse);
    });

    testWidgets('toLogin navigates to LoginScreen and clears stack',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildNavApp(AppRoutes.home));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      final BuildContext context = tester.element(find.byType(HomeScreen));
      AppNavigator.toLogin(context);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(AppNavigator.canPop(tester.element(find.byType(LoginScreen))), isFalse);
    });

    testWidgets('toSignup navigates to SignupScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildNavApp(AppRoutes.login));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      final BuildContext context = tester.element(find.byType(LoginScreen));
      AppNavigator.toSignup(context);
      await tester.pumpAndSettle();

      expect(find.byType(SignupScreen), findsOneWidget);
    });

    testWidgets('logout resets stack to LoginScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildNavApp(AppRoutes.home));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      final BuildContext context = tester.element(find.byType(HomeScreen));
      AppNavigator.logout(context);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(AppNavigator.canPop(tester.element(find.byType(LoginScreen))), isFalse);
    });

    testWidgets('pop and canPop operate correctly on pushed route',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildNavApp(AppRoutes.home));
      await tester.pumpAndSettle();

      final BuildContext homeCtx = tester.element(find.byType(HomeScreen));
      AppNavigator.pushNamed(homeCtx, AppRoutes.login);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(AppNavigator.canPop(tester.element(find.byType(LoginScreen))), isTrue);

      AppNavigator.pop(tester.element(find.byType(LoginScreen)));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}

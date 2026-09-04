import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/auth_state.dart';
import 'package:ridesathi/core/theme/app_theme.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/screens/auth/driver_signup_screen.dart';
import 'package:ridesathi/screens/auth/login_screen.dart';
import 'package:ridesathi/screens/auth/signup_screen.dart';
import 'package:ridesathi/screens/driver/driver_home_screen.dart';
import 'package:ridesathi/screens/rider/rider_home_screen.dart';
import 'package:ridesathi/screens/splash_screen.dart';
import 'package:ridesathi/widgets/error_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final dummyRider = UserModel(
    id: 'rider-1',
    name: 'Rider Ramesh',
    phoneNumber: '+919876543210',
    email: 'rider@example.com',
    role: UserRole.rider,
    createdAt: DateTime.now(),
  );

  final dummyDriver = UserModel(
    id: 'driver-1',
    name: 'Driver Dharmendra',
    phoneNumber: '+919988776655',
    email: 'driver@example.com',
    role: UserRole.driver,
    vehicleInfo: 'Auto DL-01-AB-1234',
    isUnionVerified: false,
    createdAt: DateTime.now(),
  );

  setUp(() {
    AuthController.resetInstance();
  });

  tearDown(() {
    AuthController.resetInstance();
  });

  group('AppRoutes Constants', () {
    test('defines correct path strings for all routes', () {
      expect(AppRoutes.splash, '/');
      expect(AppRoutes.home, '/home');
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.signup, '/signup');
      expect(AppRoutes.driverSignup, '/driver-signup');
      expect(AppRoutes.riderHome, '/rider/home');
      expect(AppRoutes.driverHome, '/driver/home');
      expect(AppRoutes.dispatcherHome, '/dispatcher/home');
    });
  });

  group('AppRoutes.generateRoute & Route Protection', () {
    Widget buildTestApp(String initialRoute, {AuthController? authController}) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        initialRoute: initialRoute,
        onGenerateRoute: (settings) => AppRoutes.generateRoute(
          settings,
          authController: authController,
        ),
      );
    }

    testWidgets('generates SplashScreen for routeSplash', (tester) async {
      await tester.pumpWidget(buildTestApp(AppRoutes.splash));
      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('generates LoginScreen for routeLogin', (tester) async {
      await tester.pumpWidget(buildTestApp(AppRoutes.login));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('generates SignupScreen for routeSignup', (tester) async {
      await tester.pumpWidget(buildTestApp(AppRoutes.signup));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);
    });

    testWidgets('generates DriverSignupScreen for routeDriverSignup', (tester) async {
      await tester.pumpWidget(buildTestApp(AppRoutes.driverSignup));
      await tester.pumpAndSettle();
      expect(find.byType(DriverSignupScreen), findsOneWidget);
    });

    testWidgets('unauthenticated access to riderHome redirects to LoginScreen', (tester) async {
      final unauthController = AuthController(initialState: const AuthState.unauthenticated());
      await tester.pumpWidget(buildTestApp(AppRoutes.riderHome, authController: unauthController));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('unauthenticated access to driverHome redirects to LoginScreen', (tester) async {
      final unauthController = AuthController(initialState: const AuthState.unauthenticated());
      await tester.pumpWidget(buildTestApp(AppRoutes.driverHome, authController: unauthController));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('authenticated rider gets RiderHomeScreen on riderHome', (tester) async {
      final riderController = AuthController(initialState: AuthState.authenticated(dummyRider));
      await tester.pumpWidget(buildTestApp(AppRoutes.riderHome, authController: riderController));
      await tester.pumpAndSettle();
      expect(find.byType(RiderHomeScreen), findsOneWidget);
    });

    testWidgets('authenticated driver gets DriverHomeScreen on driverHome', (tester) async {
      final driverController = AuthController(initialState: AuthState.authenticated(dummyDriver));
      await tester.pumpWidget(buildTestApp(AppRoutes.driverHome, authController: driverController));
      await tester.pumpAndSettle();
      expect(find.byType(DriverHomeScreen), findsOneWidget);
    });

    testWidgets('cross-role protection: driver attempting riderHome is redirected to DriverHomeScreen', (tester) async {
      final driverController = AuthController(initialState: AuthState.authenticated(dummyDriver));
      await tester.pumpWidget(buildTestApp(AppRoutes.riderHome, authController: driverController));
      await tester.pumpAndSettle();
      expect(find.byType(DriverHomeScreen), findsOneWidget);
      expect(find.byType(RiderHomeScreen), findsNothing);
    });

    testWidgets('cross-role protection: rider attempting driverHome is redirected to RiderHomeScreen', (tester) async {
      final riderController = AuthController(initialState: AuthState.authenticated(dummyRider));
      await tester.pumpWidget(buildTestApp(AppRoutes.driverHome, authController: riderController));
      await tester.pumpAndSettle();
      expect(find.byType(RiderHomeScreen), findsOneWidget);
      expect(find.byType(DriverHomeScreen), findsNothing);
    });

    testWidgets('compatibility /home redirects driver to DriverHomeScreen', (tester) async {
      final driverController = AuthController(initialState: AuthState.authenticated(dummyDriver));
      await tester.pumpWidget(buildTestApp(AppRoutes.home, authController: driverController));
      await tester.pumpAndSettle();
      expect(find.byType(DriverHomeScreen), findsOneWidget);
    });

    testWidgets('compatibility /home redirects rider to RiderHomeScreen', (tester) async {
      final riderController = AuthController(initialState: AuthState.authenticated(dummyRider));
      await tester.pumpWidget(buildTestApp(AppRoutes.home, authController: riderController));
      await tester.pumpAndSettle();
      expect(find.byType(RiderHomeScreen), findsOneWidget);
    });

    testWidgets('reserved dispatcherHome displays access restriction error view', (tester) async {
      await tester.pumpWidget(buildTestApp(AppRoutes.dispatcherHome));
      await tester.pumpAndSettle();
      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Access Restricted'), findsAtLeastNWidgets(1));
    });

    testWidgets('generates ErrorView for unknown routes', (tester) async {
      await tester.pumpWidget(buildTestApp('/invalid-route-name'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Page Not Found'), findsAtLeastNWidgets(1));
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

    testWidgets('toRiderHome navigates to RiderHomeScreen and clears stack', (tester) async {
      final riderController = AuthController.instance;
      riderController.updateState(AuthState.authenticated(dummyRider));

      await tester.pumpWidget(buildNavApp(AppRoutes.login));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      final BuildContext context = tester.element(find.byType(LoginScreen));
      AppNavigator.toRiderHome(context);
      await tester.pumpAndSettle();

      expect(find.byType(RiderHomeScreen), findsOneWidget);
      expect(AppNavigator.canPop(tester.element(find.byType(RiderHomeScreen))), isFalse);
    });

    testWidgets('toDriverHome navigates to DriverHomeScreen and clears stack', (tester) async {
      final driverController = AuthController.instance;
      driverController.updateState(AuthState.authenticated(dummyDriver));

      await tester.pumpWidget(buildNavApp(AppRoutes.login));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      final BuildContext context = tester.element(find.byType(LoginScreen));
      AppNavigator.toDriverHome(context);
      await tester.pumpAndSettle();

      expect(find.byType(DriverHomeScreen), findsOneWidget);
      expect(AppNavigator.canPop(tester.element(find.byType(DriverHomeScreen))), isFalse);
    });

    testWidgets('toAuthenticatedHome routes driver to driverHome', (tester) async {
      final driverController = AuthController.instance;
      driverController.updateState(AuthState.authenticated(dummyDriver));

      await tester.pumpWidget(buildNavApp(AppRoutes.login));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(LoginScreen));
      AppNavigator.toAuthenticatedHome(context, dummyDriver);
      await tester.pumpAndSettle();

      expect(find.byType(DriverHomeScreen), findsOneWidget);
    });

    testWidgets('toAuthenticatedHome routes rider to riderHome', (tester) async {
      final riderController = AuthController.instance;
      riderController.updateState(AuthState.authenticated(dummyRider));

      await tester.pumpWidget(buildNavApp(AppRoutes.login));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(LoginScreen));
      AppNavigator.toAuthenticatedHome(context, dummyRider);
      await tester.pumpAndSettle();

      expect(find.byType(RiderHomeScreen), findsOneWidget);
    });

    testWidgets('logout resets stack to LoginScreen', (tester) async {
      await tester.pumpWidget(buildNavApp(AppRoutes.login));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(LoginScreen));
      AppNavigator.logout(context);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(AppNavigator.canPop(tester.element(find.byType(LoginScreen))), isFalse);
    });
  });
}

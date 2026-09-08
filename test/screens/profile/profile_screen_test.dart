import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/auth_state.dart';
import 'package:ridesathi/core/state/profile_controller.dart';
import 'package:ridesathi/core/theme/app_theme.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/screens/profile/profile_screen.dart';
import 'package:ridesathi/services/auth_service.dart';
import 'package:ridesathi/services/firestore_exception.dart';
import 'package:ridesathi/services/user_profile_service.dart';
import 'package:ridesathi/widgets/auth_text_field.dart';
import 'package:ridesathi/widgets/confirmation_dialog.dart';
import 'package:ridesathi/widgets/custom_button.dart';
import 'package:ridesathi/widgets/info_banner.dart';

class _FakeAuthService extends AuthService {
  UserModel? user;
  final StreamController<UserModel?> _stream = StreamController.broadcast();

  _FakeAuthService({this.user});

  @override
  UserModel? get currentAuthUser => user;

  @override
  Stream<UserModel?> get onAuthStateChanged => _stream.stream;

  @override
  Future<void> userSignOut() async {
    user = null;
    _stream.add(null);
  }
}


class _FakeUserProfileService extends UserProfileService {
  final Map<String, UserModel> storage = {};
  bool shouldThrow = false;
  FirestoreException? errorToThrow;
  Completer<UserModel>? updateCompleter;
  int updateCallCount = 0;

  @override
  Future<UserModel?> getUserProfile(String uid) async => storage[uid];

  @override
  Future<UserModel> updateProfile({
    required String uid,
    required Map<String, dynamic> updates,
  }) async {
    updateCallCount++;
    if (updateCompleter != null) {
      return updateCompleter!.future;
    }
    if (shouldThrow) {
      throw errorToThrow ??
          const FirestoreException(
            'Failed to update profile',
            code: 'unavailable',
          );
    }
    final existing = storage[uid]!;
    final updated = existing.copyWith(
      name: updates['name'] as String? ?? existing.name,
      phoneNumber: updates['phoneNumber'] as String? ?? existing.phoneNumber,
      vehicleInfo: updates.containsKey('vehicleInfo')
          ? updates['vehicleInfo'] as String?
          : existing.vehicleInfo,
      updatedAt: DateTime.now(),
    );
    storage[uid] = updated;
    return updated;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final testRider = UserModel(
    id: 'rider-test-uid',
    name: 'Priya Sharma',
    phoneNumber: '+919876543210',
    email: 'priya@ridesathi.com',
    role: UserRole.rider,
    isUnionVerified: false,
    createdAt: DateTime.parse('2026-02-15T08:30:00Z'),
  );

  final testDriver = UserModel(
    id: 'driver-test-uid',
    name: 'Vikram Singh',
    phoneNumber: '+919811223344',
    email: 'vikram@ridesathi.com',
    role: UserRole.driver,
    vehicleInfo: 'Auto DL-01-XY-9999',
    isUnionVerified: true,
    createdAt: DateTime.parse('2026-01-10T12:00:00Z'),
  );

  Widget createProfileTestApp({
    required AuthController authController,
    ProfileController? profileController,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: ProfileScreen(
        authController: authController,
        profileController: profileController,
      ),
    );
  }

  group('ProfileScreen — Rider View', () {
    late _FakeAuthService fakeAuth;
    late _FakeUserProfileService fakeProfileService;
    late AuthController authController;

    setUp(() {
      fakeAuth = _FakeAuthService(user: testRider);
      fakeProfileService = _FakeUserProfileService();
      fakeProfileService.storage[testRider.id] = testRider;

      authController = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfileService,
        initialState: AuthState.authenticated(testRider),
      );
    });

    tearDown(() {
      authController.dispose();
      AuthController.resetInstance();
    });

    testWidgets('renders rider identity, editable fields, and immutable fields', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createProfileTestApp(authController: authController));
      await tester.pumpAndSettle();

      // Header identity
      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Priya Sharma'), findsNWidgets(2)); // Avatar card header & Full Name text field
      expect(find.text('priya@ridesathi.com'), findsNWidgets(2)); // Avatar card & email field
      expect(find.text('Rider'), findsNWidgets(2)); // Badge & Account details

      // Editable fields
      expect(find.widgetWithText(AuthTextField, 'Full Name'), findsOneWidget);
      expect(find.widgetWithText(AuthTextField, 'Phone Number'), findsOneWidget);

      // Driver vehicle info must NOT be rendered for rider
      expect(find.text('Driver & Vehicle Information'), findsNothing);
      expect(find.text('Vehicle Information'), findsNothing);

      // Account details
      expect(find.text('Account Details'), findsOneWidget);
      expect(find.text('Member Since'), findsOneWidget);
      expect(find.text('2026-02-15'), findsOneWidget);

      // Save button starts disabled when not dirty
      final saveBtn = tester.widget<CustomButton>(find.widgetWithText(CustomButton, 'Save Changes'));
      expect(saveBtn.onPressed, isNull);
    });

    testWidgets('modifying field enables Save and Discard buttons, discarding resets fields', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createProfileTestApp(authController: authController));
      await tester.pumpAndSettle();

      // Enter a new name
      await tester.enterText(
        find.widgetWithText(AuthTextField, 'Full Name'),
        'Priya S. Verma',
      );
      await tester.pumpAndSettle();

      // Save Changes button is now enabled
      var saveBtn = tester.widget<CustomButton>(find.widgetWithText(CustomButton, 'Save Changes'));
      expect(saveBtn.onPressed, isNotNull);

      // Discard button is now visible and enabled
      expect(find.widgetWithText(CustomButton, 'Discard Changes'), findsOneWidget);

      // Tap Discard Changes
      await tester.tap(find.widgetWithText(CustomButton, 'Discard Changes'));
      await tester.pumpAndSettle();

      // Values restored
      expect(find.text('Priya Sharma'), findsNWidgets(2));
      expect(find.text('Priya S. Verma'), findsNothing);

      // Save button is disabled again
      saveBtn = tester.widget<CustomButton>(find.widgetWithText(CustomButton, 'Save Changes'));
      expect(saveBtn.onPressed, isNull);
      expect(find.widgetWithText(CustomButton, 'Discard Changes'), findsNothing);
    });

    testWidgets('successful save persists changes and synchronizes auth state', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createProfileTestApp(authController: authController));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(AuthTextField, 'Full Name'),
        'Priya Updated',
      );
      await tester.enterText(
        find.widgetWithText(AuthTextField, 'Phone Number'),
        '+919999900000',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(CustomButton, 'Save Changes'));
      await tester.pumpAndSettle();

      // SnackBar verification
      expect(find.text('Profile updated successfully.'), findsOneWidget);

      // AuthController synchronized
      expect(authController.currentUser?.name, equals('Priya Updated'));
      expect(authController.currentUser?.phoneNumber, equals('+919999900000'));
      expect(fakeProfileService.updateCallCount, equals(1));
    });

    testWidgets('field validation prevents save on invalid name or phone', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createProfileTestApp(authController: authController));
      await tester.pumpAndSettle();

      // Clear name
      await tester.enterText(find.widgetWithText(AuthTextField, 'Full Name'), '');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(CustomButton, 'Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Full name is required.'), findsOneWidget);
      expect(fakeProfileService.updateCallCount, equals(0));

      // Enter invalid phone
      await tester.enterText(find.widgetWithText(AuthTextField, 'Full Name'), 'Valid Name');
      await tester.enterText(find.widgetWithText(AuthTextField, 'Phone Number'), 'bad');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(CustomButton, 'Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid phone number.'), findsOneWidget);
      expect(fakeProfileService.updateCallCount, equals(0));
    });

    testWidgets('displays error banner when save fails in service', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeProfileService.shouldThrow = true;
      fakeProfileService.errorToThrow = const FirestoreException(
        'Unable to reach server. Check your connection.',
        code: 'unavailable',
      );

      await tester.pumpWidget(createProfileTestApp(authController: authController));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(AuthTextField, 'Full Name'), 'Priya Fails');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(CustomButton, 'Save Changes'));
      await tester.pumpAndSettle();

      expect(find.byType(InfoBanner), findsOneWidget);
      expect(find.text('Unable to reach server. Check your connection.'), findsOneWidget);
    });
  });


  group('ProfileScreen — Driver View', () {
    late _FakeAuthService fakeAuth;
    late _FakeUserProfileService fakeProfileService;
    late AuthController authController;

    setUp(() {
      fakeAuth = _FakeAuthService(user: testDriver);
      fakeProfileService = _FakeUserProfileService();
      fakeProfileService.storage[testDriver.id] = testDriver;

      authController = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfileService,
        initialState: AuthState.authenticated(testDriver),
      );
    });

    tearDown(() {
      authController.dispose();
      AuthController.resetInstance();
    });

    testWidgets('renders driver badge, union verification status, and vehicle info field', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createProfileTestApp(authController: authController));
      await tester.pumpAndSettle();

      expect(find.text('Driver'), findsNWidgets(2)); // Badge & Account details
      expect(find.text('Union Verified'), findsOneWidget);
      expect(find.text('Driver & Vehicle Information'), findsOneWidget);
      expect(find.widgetWithText(AuthTextField, 'Vehicle Information'), findsOneWidget);

      // Verify union notice explaining client-side immutability
      expect(
        find.textContaining('Union verification is managed by union administrators'),
        findsOneWidget,
      );
    });

    testWidgets('driver can edit vehicleInfo and save successfully', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createProfileTestApp(authController: authController));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(AuthTextField, 'Vehicle Information'),
        'Auto KA-03-ZZ-1111',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(CustomButton, 'Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Profile updated successfully.'), findsOneWidget);
      expect(authController.currentUser?.vehicleInfo, equals('Auto KA-03-ZZ-1111'));
      expect(fakeProfileService.storage[testDriver.id]?.vehicleInfo, equals('Auto KA-03-ZZ-1111'));
    });

    testWidgets('driver vehicleInfo validation rejects empty or too short input', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createProfileTestApp(authController: authController));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(AuthTextField, 'Vehicle Information'),
        '',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(CustomButton, 'Save Changes'));
      await tester.pumpAndSettle();


      expect(find.text('Vehicle info is required.'), findsOneWidget);
      expect(fakeProfileService.updateCallCount, equals(0));
    });
  });

  group('ProfileScreen — PopScope & Unsaved Changes Guard', () {
    late _FakeAuthService fakeAuth;
    late _FakeUserProfileService fakeProfileService;
    late AuthController authController;

    setUp(() {
      fakeAuth = _FakeAuthService(user: testRider);
      fakeProfileService = _FakeUserProfileService();
      fakeProfileService.storage[testRider.id] = testRider;

      authController = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfileService,
        initialState: AuthState.authenticated(testRider),
      );
    });

    tearDown(() {
      authController.dispose();
      AuthController.resetInstance();
    });

    testWidgets('shows ConfirmationDialog on back navigation with unsaved changes and handles cancel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(authController: authController),
                ),
              ),
              child: const Text('Open Profile'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open profile screen
      await tester.tap(find.text('Open Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);

      // Make dirty changes
      await tester.enterText(find.widgetWithText(AuthTextField, 'Full Name'), 'Modified Name');
      await tester.pumpAndSettle();

      // Trigger back navigation via system or back button
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      // ConfirmationDialog should appear
      expect(find.byType(ConfirmationDialog), findsOneWidget);
      expect(find.text('Discard Changes?'), findsOneWidget);

      // Tap 'Keep Editing' (cancel)
      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();

      // Still on ProfileScreen
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.byType(ConfirmationDialog), findsNothing);
    });

    testWidgets('discarding unsaved changes in dialog allows pop and reverts edits', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(authController: authController),
                ),
              ),
              child: const Text('Open Profile'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open profile screen
      await tester.tap(find.text('Open Profile'));
      await tester.pumpAndSettle();

      // Modify name
      await tester.enterText(find.widgetWithText(AuthTextField, 'Full Name'), 'Modified Name');
      await tester.pumpAndSettle();

      // Trigger back
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmationDialog), findsOneWidget);

      // Tap 'Discard'
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      // ProfileScreen is popped, back on root
      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.text('Open Profile'), findsOneWidget);
    });
  });
}

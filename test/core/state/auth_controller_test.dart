import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/auth_state.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/services/auth_service.dart';
import 'package:ridesathi/services/firebase_service.dart';
import 'package:ridesathi/services/firestore_exception.dart';
import 'package:ridesathi/services/user_profile_service.dart';

/// Fake implementation of [AuthService] for deterministic controller unit tests.
class FakeAuthService extends AuthService {
  final bool shouldFail;
  final String failureMessage;
  final UserModel? userToReturn;
  final UserModel? mockCurrentAuthUser;

  const FakeAuthService({
    this.shouldFail = false,
    this.failureMessage = 'Operation failed',
    this.userToReturn,
    this.mockCurrentAuthUser,
  });

  @override
  UserModel? get currentAuthUser => mockCurrentAuthUser;

  @override
  Future<UserModel?> userSignUp({
    required String email,
    required String password,
    String? name,
    String? phone,
    UserRole role = UserRole.rider,
    String? vehicleInfo,
  }) async {
    if (shouldFail) {
      throw AuthException(failureMessage);
    }
    return userToReturn ??
        UserModel(
          id: 'test-user-id',
          name: name ?? 'New User',
          phoneNumber: phone ?? '9876543210',
          email: email,
          role: role,
          vehicleInfo: vehicleInfo,
          isUnionVerified: false,
          createdAt: DateTime.now(),
        );
  }

  @override
  Future<UserModel?> userSignIn({
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      throw AuthException(failureMessage);
    }
    return userToReturn ??
        UserModel(
          id: 'test-user-id',
          name: 'Existing User',
          phoneNumber: '9876543210',
          email: email,
          role: UserRole.rider,
          isUnionVerified: false,
          createdAt: DateTime.now(),
        );
  }

  @override
  Future<void> userSignOut() async {
    if (shouldFail) {
      throw AuthException(failureMessage);
    }
  }
}

/// Fake implementation of [UserProfileService] for controller tests.
class FakeTestUserProfileService extends UserProfileService {
  final bool shouldFail;
  final String failureMessage;
  final Map<String, UserModel> _profiles = {};
  UserModel? savedProfile;

  FakeTestUserProfileService({
    this.shouldFail = false,
    this.failureMessage = 'Firestore error',
  });

  void setProfile(String uid, UserModel profile) {
    _profiles[uid] = profile;
    savedProfile = profile;
  }

  @override
  Future<void> createRiderProfile(UserModel user) async {
    if (shouldFail) {
      throw FirestoreException(failureMessage);
    }
    savedProfile = user;
    _profiles[user.id] = user;
  }

  @override
  Future<void> createDriverProfile(UserModel user) async {
    if (shouldFail) {
      throw FirestoreException(failureMessage);
    }
    savedProfile = user;
    _profiles[user.id] = user;
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    if (shouldFail) {
      throw FirestoreException(failureMessage);
    }
    return _profiles[uid] ?? savedProfile;
  }
}

void main() {
  setUp(() {
    AuthController.resetInstance();
    FirebaseService.isInitializedOverride = false;
  });

  tearDown(() {
    AuthController.resetInstance();
    FirebaseService.isInitializedOverride = false;
  });

  group('AuthController — Initialization and State Inspection', () {
    test('initializes with default AuthState.initial', () {
      final controller = AuthController();

      expect(controller.state.status, equals(AuthStatus.initial));
      expect(controller.isAuthenticated, isFalse);
      expect(controller.isAuthenticating, isFalse);
      expect(controller.currentUser, isNull);
      expect(controller.errorMessage, isNull);
    });

    test('accepts custom initial state', () {
      const customInitial = AuthState.unauthenticated();
      final controller = AuthController(initialState: customInitial);

      expect(controller.state, equals(customInitial));
      expect(controller.state.isUnauthenticated, isTrue);
    });

    test('singleton instance returns the same shared object', () {
      final instance1 = AuthController.instance;
      final instance2 = AuthController.instance;

      expect(identical(instance1, instance2), isTrue);
    });
  });

  group('AuthController — State Transitions & Notifications', () {
    test('updateState updates state and notifies listeners', () {
      final controller = AuthController();
      int notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      final dummyUser = UserModel(
        id: 'u1',
        name: 'Anita Devi',
        phoneNumber: '+919811122233',
        role: UserRole.rider,
        createdAt: DateTime(2026, 1, 1),
      );

      controller.updateState(AuthState.authenticated(dummyUser));

      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser, equals(dummyUser));
      expect(notificationCount, equals(1));
    });

    test('clearError removes active error message and notifies listeners', () {
      final controller = AuthController(
        initialState: const AuthState.error('Network timeout'),
      );
      int notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      expect(controller.errorMessage, equals('Network timeout'));

      controller.clearError();

      expect(controller.errorMessage, isNull);
      expect(controller.state.isError, isTrue);
      expect(notificationCount, equals(1));
    });
  });

  group('AuthController — Service Operations', () {
    test('checkAuthStatus sets unauthenticated when Firebase is not initialized', () async {
      FirebaseService.isInitializedOverride = false;
      final controller = AuthController();

      await controller.checkAuthStatus();

      expect(controller.state.isUnauthenticated, isTrue);
      expect(controller.isAuthenticated, isFalse);
    });

    test('checkAuthStatus resolves domain profile when session exists', () async {
      FirebaseService.isInitializedOverride = true;
      final persistedUser = UserModel(
        id: 'persisted-uid',
        name: 'Persistent Driver',
        phoneNumber: '+919876543210',
        email: 'driver@ridesathi.com',
        role: UserRole.driver,
        vehicleInfo: 'Auto DL-01',
        createdAt: DateTime.now(),
      );

      final fakeAuth = FakeAuthService(mockCurrentAuthUser: persistedUser);
      final fakeProfile = FakeTestUserProfileService()..setProfile('persisted-uid', persistedUser);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      await controller.checkAuthStatus();

      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser, isNotNull);
      expect(controller.currentUser!.name, equals('Persistent Driver'));
      expect(controller.currentUser!.role, equals(UserRole.driver));
      expect(controller.currentUser!.vehicleInfo, equals('Auto DL-01'));
    });

    test('checkAuthStatus reports error when authenticated user profile is missing in Firestore', () async {
      FirebaseService.isInitializedOverride = true;
      final authUser = UserModel(
        id: 'orphan-uid',
        name: 'Orphan User',
        phoneNumber: '+919876543210',
        email: 'orphan@ridesathi.com',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      final fakeAuth = FakeAuthService(mockCurrentAuthUser: authUser);
      final fakeProfile = FakeTestUserProfileService(); // No profile stored

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      await controller.checkAuthStatus();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.state.isError, isTrue);
      expect(
        controller.errorMessage,
        equals('User session active, but profile could not be found.'),
      );
    });

    test('signIn authenticates and resolves rider domain profile from Firestore', () async {
      final riderProfile = UserModel(
        id: 'rider-123',
        name: 'Rider Ramesh',
        phoneNumber: '+919123456789',
        email: 'rider@example.com',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      final fakeAuth = FakeAuthService(userToReturn: riderProfile);
      final fakeProfile = FakeTestUserProfileService()..setProfile('rider-123', riderProfile);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      final success = await controller.signIn(
        email: 'rider@example.com',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser, isNotNull);
      expect(controller.currentUser!.name, equals('Rider Ramesh'));
      expect(controller.currentUser!.role, equals(UserRole.rider));
    });

    test('signIn authenticates and resolves driver domain profile with vehicleInfo', () async {
      final driverProfile = UserModel(
        id: 'driver-456',
        name: 'Driver Dharmendra',
        phoneNumber: '+919876543210',
        email: 'driver@example.com',
        role: UserRole.driver,
        vehicleInfo: 'Auto DL-01-AB-1234',
        isUnionVerified: false,
        createdAt: DateTime.now(),
      );

      final fakeAuth = FakeAuthService(userToReturn: driverProfile);
      final fakeProfile = FakeTestUserProfileService()..setProfile('driver-456', driverProfile);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      final success = await controller.signIn(
        email: 'driver@example.com',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser, isNotNull);
      expect(controller.currentUser!.name, equals('Driver Dharmendra'));
      expect(controller.currentUser!.role, equals(UserRole.driver));
      expect(controller.currentUser!.vehicleInfo, equals('Auto DL-01-AB-1234'));
      expect(controller.currentUser!.isUnionVerified, isFalse);
    });

    test('signIn fails with clear error when profile document is missing in Firestore', () async {
      final authUser = UserModel(
        id: 'missing-doc-uid',
        name: 'No Profile User',
        phoneNumber: '+919876543210',
        email: 'noprofile@example.com',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      final fakeAuth = FakeAuthService(userToReturn: authUser);
      final fakeProfile = FakeTestUserProfileService(); // Profile will return null

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      final success = await controller.signIn(
        email: 'noprofile@example.com',
        password: 'password123',
      );

      expect(success, isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.state.isError, isTrue);
      expect(
        controller.errorMessage,
        equals('User profile not found. Please contact support or register again.'),
      );
    });

    test('signIn fails when profile has corrupted data / invalid role', () async {
      final authUser = UserModel(
        id: 'corrupt-uid',
        name: 'Corrupt User',
        phoneNumber: '+919876543210',
        email: 'corrupt@example.com',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      final fakeAuth = FakeAuthService(userToReturn: authUser);
      final fakeProfile = FakeTestUserProfileService(
        shouldFail: true,
        failureMessage: 'User profile data is corrupted or contains an invalid role.',
      );

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      final success = await controller.signIn(
        email: 'corrupt@example.com',
        password: 'password123',
      );

      expect(success, isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.state.isError, isTrue);
      expect(
        controller.errorMessage,
        equals('User profile data is corrupted or contains an invalid role.'),
      );
    });

    test('signIn handles AuthException during sign in', () async {
      final fakeAuth = const FakeAuthService(
        shouldFail: true,
        failureMessage: 'Incorrect email or password.',
      );
      final fakeProfile = FakeTestUserProfileService();

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      final success = await controller.signIn(
        email: 'wrong@example.com',
        password: 'wrongpassword',
      );

      expect(success, isFalse);
      expect(controller.state.isError, isTrue);
      expect(
        controller.errorMessage,
        equals('Incorrect email or password.'),
      );
    });

    test('signUp creates auth user and persists rider profile in Firestore', () async {
      final fakeAuth = const FakeAuthService(shouldFail: false);
      final fakeProfile = FakeTestUserProfileService(shouldFail: false);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      final success = await controller.signUp(
        email: 'rider@example.com',
        password: 'password123',
        name: 'Kavita Roy',
        phone: '+919876543210',
      );

      expect(success, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser, isNotNull);
      expect(controller.currentUser!.name, equals('Kavita Roy'));
      expect(controller.currentUser!.phoneNumber, equals('+919876543210'));
      expect(controller.currentUser!.role, equals(UserRole.rider));
      expect(fakeProfile.savedProfile, isNotNull);
      expect(fakeProfile.savedProfile!.name, equals('Kavita Roy'));
      expect(fakeProfile.savedProfile!.phoneNumber, equals('+919876543210'));
    });

    test('signUpDriver creates auth user and persists driver profile in Firestore', () async {
      final fakeAuth = const FakeAuthService(shouldFail: false);
      final fakeProfile = FakeTestUserProfileService(shouldFail: false);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      final success = await controller.signUpDriver(
        email: 'driver@example.com',
        password: 'password123',
        name: 'Rahul Driver',
        phone: '+919999988888',
        vehicleInfo: 'Auto KA-01',
      );

      expect(success, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser, isNotNull);
      expect(controller.currentUser!.name, equals('Rahul Driver'));
      expect(controller.currentUser!.role, equals(UserRole.driver));
      expect(fakeProfile.savedProfile, isNotNull);
      expect(fakeProfile.savedProfile!.role, equals(UserRole.driver));
      expect(fakeProfile.savedProfile!.vehicleInfo, equals('Auto KA-01'));
    });

    test('signUp handles AuthException during registration', () async {
      final fakeAuth = const FakeAuthService(
        shouldFail: true,
        failureMessage: 'An account already exists with this email.',
      );
      final fakeProfile = FakeTestUserProfileService();

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      final success = await controller.signUp(
        email: 'existing@example.com',
        password: 'password123',
      );

      expect(success, isFalse);
      expect(controller.state.isError, isTrue);
      expect(
        controller.errorMessage,
        equals('An account already exists with this email.'),
      );
      expect(fakeProfile.savedProfile, isNull);
    });

    test('signUp handles FirestoreException when profile creation fails', () async {
      final fakeAuth = const FakeAuthService(shouldFail: false);
      final fakeProfile = FakeTestUserProfileService(
        shouldFail: true,
        failureMessage: 'Service is temporarily unavailable. Please try again later.',
      );

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      final success = await controller.signUp(
        email: 'new@example.com',
        password: 'password123',
        name: 'Test Rider',
      );

      expect(success, isFalse);
      expect(controller.state.isError, isTrue);
      expect(
        controller.errorMessage,
        equals('Service is temporarily unavailable. Please try again later.'),
      );
    });

    test('signOut sets unauthenticated state on success', () async {
      final fakeAuth = const FakeAuthService(shouldFail: false);
      final dummyUser = UserModel(
        id: 'u1',
        name: 'Driver Singh',
        phoneNumber: '+919999888877',
        role: UserRole.driver,
        createdAt: DateTime(2026, 1, 1),
      );

      final controller = AuthController(
        authService: fakeAuth,
        initialState: AuthState.authenticated(dummyUser),
      );

      final result = await controller.signOut();

      expect(result, isTrue);
      expect(controller.state.isUnauthenticated, isTrue);
      expect(controller.currentUser, isNull);
    });

    test('signOut captures AuthException and transitions to error state', () async {
      final fakeAuth = const FakeAuthService(
        shouldFail: true,
        failureMessage: 'Network error during sign out',
      );
      final dummyUser = UserModel(
        id: 'u1',
        name: 'Driver Singh',
        phoneNumber: '+919999888877',
        role: UserRole.driver,
        createdAt: DateTime(2026, 1, 1),
      );

      final controller = AuthController(
        authService: fakeAuth,
        initialState: AuthState.authenticated(dummyUser),
      );

      final result = await controller.signOut();

      expect(result, isFalse);
      expect(controller.state.isError, isTrue);
      expect(controller.errorMessage, equals('Network error during sign out'));
      // Previous user is preserved in error state
      expect(controller.currentUser, equals(dummyUser));
    });
  });

  group('AuthController — Lifecycle & Disposal', () {
    test('dispose cleans up safely without throwing exceptions', () {
      final controller = AuthController(listenToAuthChanges: true);

      expect(() => controller.dispose(), returnsNormally);
    });
  });
}

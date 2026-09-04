import 'dart:async';
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
  final StreamController<UserModel?>? streamController;

  const FakeAuthService({
    this.shouldFail = false,
    this.failureMessage = 'Operation failed',
    this.userToReturn,
    this.mockCurrentAuthUser,
    this.streamController,
  });

  @override
  UserModel? get currentAuthUser => mockCurrentAuthUser;

  @override
  Stream<UserModel?> get onAuthStateChanged =>
      streamController?.stream ?? const Stream.empty();

  void emitAuthState(UserModel? user) {
    streamController?.add(user);
  }

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
  int getUserProfileCallCount = 0;
  Completer<UserModel?>? profileCompleter;

  FakeTestUserProfileService({
    this.shouldFail = false,
    this.failureMessage = 'Firestore error',
    this.profileCompleter,
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
    getUserProfileCallCount++;
    if (profileCompleter != null) {
      return profileCompleter!.future;
    }
    if (shouldFail) {
      throw FirestoreException(failureMessage);
    }
    return _profiles[uid] ?? savedProfile;
  }
}

/// Fake implementation of [AuthService] tracking sign out calls for PR 17 tests.
class SignOutTrackingAuthService extends FakeAuthService {
  int signOutCallCount = 0;
  Completer<void>? signOutCompleter;
  final bool shouldFailSignOut;
  final bool shouldThrowGenericException;

  SignOutTrackingAuthService({
    this.shouldFailSignOut = false,
    this.shouldThrowGenericException = false,
    this.signOutCompleter,
    super.streamController,
    super.mockCurrentAuthUser,
  });

  @override
  Future<void> userSignOut() async {
    signOutCallCount++;
    if (signOutCompleter != null) {
      await signOutCompleter!.future;
    }
    if (shouldFailSignOut) {
      throw const AuthException('Network error during sign out.');
    }
    if (shouldThrowGenericException) {
      throw Exception('Unexpected system failure.');
    }
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

    test('post-disposal stream event does not update state or throw', () async {
      final streamController = StreamController<UserModel?>.broadcast();
      final fakeAuth = FakeAuthService(streamController: streamController);
      final fakeProfile = FakeTestUserProfileService();
      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
        listenToAuthChanges: true,
      );

      controller.dispose();

      final dummyUser = UserModel(
        id: 'u-post-dispose',
        name: 'Ghost User',
        phoneNumber: '1234567890',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      expect(() => fakeAuth.emitAuthState(dummyUser), returnsNormally);
      await pumpEventQueue();

      expect(controller.isAuthenticated, isFalse);
      streamController.close();
    });
  });

  group('AuthController — Session Restoration & Persistence Lifecycle', () {
    test('restores persisted rider session with full profile', () async {
      FirebaseService.isInitializedOverride = true;
      final rider = UserModel(
        id: 'persisted-rider-id',
        name: 'Aarav Sharma',
        phoneNumber: '+919876543210',
        email: 'aarav@ridesathi.com',
        role: UserRole.rider,
        createdAt: DateTime(2026, 1, 1),
      );

      final fakeAuth = FakeAuthService(mockCurrentAuthUser: rider);
      final fakeProfile = FakeTestUserProfileService()..setProfile('persisted-rider-id', rider);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      await controller.checkAuthStatus();

      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser, isNotNull);
      expect(controller.currentUser!.id, equals('persisted-rider-id'));
      expect(controller.currentUser!.name, equals('Aarav Sharma'));
      expect(controller.currentUser!.role, equals(UserRole.rider));
      expect(controller.currentUser!.phoneNumber, equals('+919876543210'));
    });

    test('restores persisted driver session with vehicleInfo and verification state', () async {
      FirebaseService.isInitializedOverride = true;
      final driver = UserModel(
        id: 'persisted-driver-id',
        name: 'Gopal Auto Driver',
        phoneNumber: '+919888877777',
        email: 'gopal@ridesathi.com',
        role: UserRole.driver,
        vehicleInfo: 'Auto KA-05-CD-5678',
        isUnionVerified: true,
        createdAt: DateTime(2026, 1, 1),
      );

      final fakeAuth = FakeAuthService(mockCurrentAuthUser: driver);
      final fakeProfile = FakeTestUserProfileService()..setProfile('persisted-driver-id', driver);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      await controller.checkAuthStatus();

      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser, isNotNull);
      expect(controller.currentUser!.role, equals(UserRole.driver));
      expect(controller.currentUser!.vehicleInfo, equals('Auto KA-05-CD-5678'));
      expect(controller.currentUser!.isUnionVerified, isTrue);
    });

    test('transitions through authenticating state during restoration', () async {
      FirebaseService.isInitializedOverride = true;
      final rider = UserModel(
        id: 'rider-trans-id',
        name: 'Transition Test Rider',
        phoneNumber: '+919876543210',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      final fakeAuth = FakeAuthService(mockCurrentAuthUser: rider);
      final fakeProfile = FakeTestUserProfileService()..setProfile('rider-trans-id', rider);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      final recordedStatuses = <AuthStatus>[];
      controller.addListener(() {
        recordedStatuses.add(controller.state.status);
      });

      await controller.checkAuthStatus();

      expect(recordedStatuses, contains(AuthStatus.authenticating));
      expect(recordedStatuses.last, equals(AuthStatus.authenticated));
      expect(controller.isAuthenticated, isTrue);
    });

    test('sets unauthenticated state when no persisted user exists', () async {
      FirebaseService.isInitializedOverride = true;
      final fakeAuth = FakeAuthService(mockCurrentAuthUser: null);
      final fakeProfile = FakeTestUserProfileService();

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      await controller.checkAuthStatus();

      expect(controller.state.isUnauthenticated, isTrue);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentUser, isNull);
    });

    test('missing profile in Firestore transitions to error and rejects authentication', () async {
      FirebaseService.isInitializedOverride = true;
      final authUser = UserModel(
        id: 'orphan-user-uid',
        name: 'Orphan Rider',
        phoneNumber: '9999999999',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      final fakeAuth = FakeAuthService(mockCurrentAuthUser: authUser);
      final fakeProfile = FakeTestUserProfileService(); // Empty profile store

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
      expect(controller.currentUser, isNull);
    });

    test('corrupted profile or invalid role transitions to error and rejects privileged session', () async {
      FirebaseService.isInitializedOverride = true;
      final authUser = UserModel(
        id: 'corrupted-user-uid',
        name: 'Corrupted User',
        phoneNumber: '9999999999',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      final fakeAuth = FakeAuthService(mockCurrentAuthUser: authUser);
      final fakeProfile = FakeTestUserProfileService(
        shouldFail: true,
        failureMessage: 'User profile data is corrupted or contains an invalid role.',
      );

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      await controller.checkAuthStatus();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.state.isError, isTrue);
      expect(
        controller.errorMessage,
        equals('User profile data is corrupted or contains an invalid role.'),
      );
      expect(controller.currentUser, isNull);
    });

    test('network failure during restoration transitions to error state and preserves unauthenticated', () async {
      FirebaseService.isInitializedOverride = true;
      final authUser = UserModel(
        id: 'network-fail-uid',
        name: 'Offline User',
        phoneNumber: '9999999999',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      final fakeAuth = FakeAuthService(mockCurrentAuthUser: authUser);
      final fakeProfile = FakeTestUserProfileService(
        shouldFail: true,
        failureMessage: 'Network error. Check your connection and try again.',
      );

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      await controller.checkAuthStatus();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.state.isError, isTrue);
      expect(
        controller.errorMessage,
        equals('Network error. Check your connection and try again.'),
      );
      expect(controller.currentUser, isNull);
    });

    test('retryRestoration clears prior error and restores session on subsequent attempt', () async {
      FirebaseService.isInitializedOverride = true;
      final rider = UserModel(
        id: 'retry-user-id',
        name: 'Recovered Rider',
        phoneNumber: '9999911111',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      final fakeAuth = FakeAuthService(mockCurrentAuthUser: rider);
      // First attempt fails with Firestore network exception
      final fakeProfile = FakeTestUserProfileService(
        shouldFail: true,
        failureMessage: 'Network error. Check your connection and try again.',
      );

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      await controller.checkAuthStatus();
      expect(controller.state.isError, isTrue);

      // Now service recovers and profile is set
      final recoveredProfile = FakeTestUserProfileService()..setProfile('retry-user-id', rider);
      final recoveredController = AuthController(
        authService: fakeAuth,
        userProfileService: recoveredProfile,
        initialState: controller.state,
      );

      await recoveredController.retryRestoration();

      expect(recoveredController.isAuthenticated, isTrue);
      expect(recoveredController.errorMessage, isNull);
      expect(recoveredController.currentUser!.name, equals('Recovered Rider'));
    });

    test('concurrent checkAuthStatus calls are deduplicated into single profile resolution', () async {
      FirebaseService.isInitializedOverride = true;
      final rider = UserModel(
        id: 'dedup-rider-id',
        name: 'Dedup Rider',
        phoneNumber: '9999900000',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      final fakeAuth = FakeAuthService(mockCurrentAuthUser: rider);
      final fakeProfile = FakeTestUserProfileService()..setProfile('dedup-rider-id', rider);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      // Launch multiple checkAuthStatus calls concurrently
      await Future.wait([
        controller.checkAuthStatus(),
        controller.checkAuthStatus(),
        controller.checkAuthStatus(),
      ]);

      expect(controller.isAuthenticated, isTrue);
      // Profile service was queried only once due to active restoration deduplication
      expect(fakeProfile.getUserProfileCallCount, equals(1));
    });
  });

  group('AuthController — Auth Stream Synchronization', () {
    test('auth state changed event resolves domain profile', () async {
      final rider = UserModel(
        id: 'stream-rider-id',
        name: 'Stream Rider',
        phoneNumber: '9876500000',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      final streamController = StreamController<UserModel?>.broadcast();
      final fakeAuth = FakeAuthService(streamController: streamController);
      final fakeProfile = FakeTestUserProfileService()..setProfile('stream-rider-id', rider);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
        listenToAuthChanges: true,
      );

      fakeAuth.emitAuthState(rider);
      await pumpEventQueue();

      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser, isNotNull);
      expect(controller.currentUser!.name, equals('Stream Rider'));
      streamController.close();
    });

    test('stream event with missing profile emits error, never authenticated', () async {
      final orphan = UserModel(
        id: 'stream-orphan-id',
        name: 'Stream Orphan',
        phoneNumber: '9876500001',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      final streamController = StreamController<UserModel?>.broadcast();
      final fakeAuth = FakeAuthService(streamController: streamController);
      final fakeProfile = FakeTestUserProfileService(); // Missing profile

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
        listenToAuthChanges: true,
      );

      fakeAuth.emitAuthState(orphan);
      await pumpEventQueue();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.state.isError, isTrue);
      expect(
        controller.errorMessage,
        equals('User session active, but profile could not be found.'),
      );
      streamController.close();
    });

    test('stream event with null user clears authenticated state', () async {
      final rider = UserModel(
        id: 'stream-logout-id',
        name: 'Rider Logging Out',
        phoneNumber: '9876500002',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      final streamController = StreamController<UserModel?>.broadcast();
      final fakeAuth = FakeAuthService(streamController: streamController);
      final fakeProfile = FakeTestUserProfileService()..setProfile('stream-logout-id', rider);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
        listenToAuthChanges: true,
      );

      fakeAuth.emitAuthState(rider);
      await pumpEventQueue();
      expect(controller.isAuthenticated, isTrue);

      fakeAuth.emitAuthState(null);
      await pumpEventQueue();

      expect(controller.state.isUnauthenticated, isTrue);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentUser, isNull);
      streamController.close();
    });

    test('repeated stream events for identical authenticated user do not re-fetch profile', () async {
      final rider = UserModel(
        id: 'repeated-rider-id',
        name: 'Repeated Rider',
        phoneNumber: '9876500003',
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );

      final streamController = StreamController<UserModel?>.broadcast();
      final fakeAuth = FakeAuthService(streamController: streamController);
      final fakeProfile = FakeTestUserProfileService()..setProfile('repeated-rider-id', rider);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
        listenToAuthChanges: true,
      );

      fakeAuth.emitAuthState(rider);
      await pumpEventQueue();
      expect(controller.isAuthenticated, isTrue);
      expect(fakeProfile.getUserProfileCallCount, equals(1));

      // Emit identical user again
      fakeAuth.emitAuthState(rider);
      await pumpEventQueue();

      // Should not re-fetch profile
      expect(controller.isAuthenticated, isTrue);
      expect(fakeProfile.getUserProfileCallCount, equals(1));
      streamController.close();
    });
  });

  group('AuthController — Sign-Out & Fresh Re-login Domain State', () {
    test('sign-out clears domain profile, cached role, and vehicleInfo', () async {
      final driver = UserModel(
        id: 'signout-driver-id',
        name: 'Driver Harish',
        phoneNumber: '9988776655',
        role: UserRole.driver,
        vehicleInfo: 'Auto KA-01-XX-9999',
        isUnionVerified: true,
        createdAt: DateTime.now(),
      );

      final fakeAuth = FakeAuthService(mockCurrentAuthUser: driver);
      final fakeProfile = FakeTestUserProfileService()..setProfile('signout-driver-id', driver);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
        initialState: AuthState.authenticated(driver),
      );

      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser!.vehicleInfo, equals('Auto KA-01-XX-9999'));

      final success = await controller.signOut();

      expect(success, isTrue);
      expect(controller.state.isUnauthenticated, isTrue);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentUser, isNull);
    });

    test('re-login after sign-out fetches fresh profile from Firestore, not stale in-memory data', () async {
      final initialDriver = UserModel(
        id: 'relogin-driver-id',
        name: 'Driver Original',
        phoneNumber: '9876543210',
        email: 'relogin@ridesathi.com',
        role: UserRole.driver,
        vehicleInfo: 'Auto DL-01-1111',
        createdAt: DateTime.now(),
      );

      final fakeAuth = FakeAuthService();
      final fakeProfile = FakeTestUserProfileService()..setProfile('relogin-driver-id', initialDriver);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      // First sign in
      final login1 = await controller.signIn(
        email: 'relogin@ridesathi.com',
        password: 'password123',
      );
      expect(login1, isTrue);
      expect(controller.currentUser!.name, equals('Driver Original'));
      expect(controller.currentUser!.vehicleInfo, equals('Auto DL-01-1111'));

      // Sign out
      await controller.signOut();
      expect(controller.currentUser, isNull);

      // External Firestore profile update occurs (e.g. driver updated vehicle or name)
      final updatedDriver = UserModel(
        id: 'relogin-driver-id',
        name: 'Driver Updated Name',
        phoneNumber: '9876543210',
        email: 'relogin@ridesathi.com',
        role: UserRole.driver,
        vehicleInfo: 'Electric Auto DL-01-2222',
        createdAt: DateTime.now(),
      );
      fakeProfile.setProfile('relogin-driver-id', updatedDriver);

      // Second sign in
      final login2 = await controller.signIn(
        email: 'relogin@ridesathi.com',
        password: 'password123',
      );
      expect(login2, isTrue);
      expect(controller.currentUser!.name, equals('Driver Updated Name'));
      expect(controller.currentUser!.vehicleInfo, equals('Electric Auto DL-01-2222'));
    });
  });

  group('AuthController — PR 17 Hardened Logout & Session Teardown', () {
    final testRider = UserModel(
      id: 'pr17-rider-id',
      name: 'Rider Teardown',
      phoneNumber: '9876543210',
      email: 'rider.teardown@ridesathi.com',
      role: UserRole.rider,
      createdAt: DateTime.now(),
    );

    final testDriver = UserModel(
      id: 'pr17-driver-id',
      name: 'Driver Teardown',
      phoneNumber: '9988776655',
      email: 'driver.teardown@ridesathi.com',
      role: UserRole.driver,
      vehicleInfo: 'Auto KA-05-1234',
      isUnionVerified: true,
      createdAt: DateTime.now(),
    );

    test('successful signOut clears all user, role, and domain state', () async {
      final fakeAuth = SignOutTrackingAuthService(mockCurrentAuthUser: testDriver);
      final fakeProfile = FakeTestUserProfileService()..setProfile(testDriver.id, testDriver);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
        initialState: AuthState.authenticated(testDriver),
      );

      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser, isNotNull);

      final result = await controller.signOut();

      expect(result, isTrue);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.state.isUnauthenticated, isTrue);
      expect(controller.currentUser, isNull);
      expect(controller.errorMessage, isNull);
      expect(fakeAuth.signOutCallCount, equals(1));
    });

    test('concurrent signOut invocations are deduplicated to a single operation', () async {
      final completer = Completer<void>();
      final fakeAuth = SignOutTrackingAuthService(
        mockCurrentAuthUser: testRider,
        signOutCompleter: completer,
      );
      final fakeProfile = FakeTestUserProfileService()..setProfile(testRider.id, testRider);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
        initialState: AuthState.authenticated(testRider),
      );

      // Start two concurrent sign-out calls
      final future1 = controller.signOut();
      final future2 = controller.signOut();

      expect(fakeAuth.signOutCallCount, equals(1));

      completer.complete();
      final results = await Future.wait([future1, future2]);

      expect(results[0], isTrue);
      expect(results[1], isTrue);
      expect(fakeAuth.signOutCallCount, equals(1));
      expect(controller.isAuthenticated, isFalse);
      expect(controller.state.isUnauthenticated, isTrue);
    });

    test('profile restoration in flight is cancelled and cannot re-authenticate after signOut', () async {
      final profileCompleter = Completer<UserModel?>();
      final fakeAuth = SignOutTrackingAuthService(mockCurrentAuthUser: testDriver);
      final fakeProfile = FakeTestUserProfileService(profileCompleter: profileCompleter);

      FirebaseService.isInitializedOverride = true;
      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      // Trigger restoration (which stalls on profile fetch)
      final restorationFuture = controller.checkAuthStatus();
      await pumpEventQueue();

      expect(controller.state.isAuthenticating, isTrue);
      expect(fakeProfile.getUserProfileCallCount, equals(1));

      // User signs out while Firestore profile request is in-flight
      final signOutFuture = controller.signOut();
      await signOutFuture;

      expect(controller.state.isUnauthenticated, isTrue);
      expect(controller.currentUser, isNull);

      // Firestore profile request now completes with the old driver profile
      profileCompleter.complete(testDriver);
      await restorationFuture;
      await pumpEventQueue();

      // Crucial assertion: State must NOT revert to authenticated!
      expect(controller.state.isUnauthenticated, isTrue);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentUser, isNull);
    });

    test('onAuthStateChanged null event clears session and avoids redundant notifications', () async {
      final streamController = StreamController<UserModel?>.broadcast();
      final fakeAuth = SignOutTrackingAuthService(
        streamController: streamController,
        mockCurrentAuthUser: testRider,
      );
      final fakeProfile = FakeTestUserProfileService()..setProfile(testRider.id, testRider);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
        initialState: AuthState.authenticated(testRider),
        listenToAuthChanges: true,
      );

      int notificationCount = 0;
      controller.addListener(() => notificationCount++);

      // Sign out directly through controller
      await controller.signOut();
      expect(controller.state.isUnauthenticated, isTrue);
      final notificationsAfterSignOut = notificationCount;

      // Stream emits null subsequently (standard Firebase Auth behavior on sign-out)
      streamController.add(null);
      await pumpEventQueue();

      // State remains unauthenticated, and duplicate notification is suppressed
      expect(controller.state.isUnauthenticated, isTrue);
      expect(notificationCount, equals(notificationsAfterSignOut));

      await streamController.close();
    });

    test('external sign-out via stream invalidates in-flight restoration', () async {
      final profileCompleter = Completer<UserModel?>();
      final streamController = StreamController<UserModel?>.broadcast();
      final fakeAuth = SignOutTrackingAuthService(
        streamController: streamController,
      );
      final fakeProfile = FakeTestUserProfileService(profileCompleter: profileCompleter);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
        listenToAuthChanges: true,
      );

      // Stream emits user (restoration starts)
      streamController.add(testRider);
      await pumpEventQueue();
      expect(fakeProfile.getUserProfileCallCount, equals(1));

      // External sign-out occurs before profile fetch finishes
      streamController.add(null);
      await pumpEventQueue();
      expect(controller.state.isUnauthenticated, isTrue);

      // In-flight profile completes
      profileCompleter.complete(testRider);
      await pumpEventQueue();

      // Stale restoration must NOT re-authenticate
      expect(controller.state.isUnauthenticated, isTrue);
      expect(controller.currentUser, isNull);

      await streamController.close();
    });

    test('signOut failure via AuthException sets error state and preserves previous user for retry', () async {
      final fakeAuth = SignOutTrackingAuthService(
        mockCurrentAuthUser: testDriver,
        shouldFailSignOut: true,
      );
      final fakeProfile = FakeTestUserProfileService()..setProfile(testDriver.id, testDriver);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
        initialState: AuthState.authenticated(testDriver),
      );

      final success = await controller.signOut();

      expect(success, isFalse);
      expect(controller.state.isError, isTrue);
      expect(controller.errorMessage, equals('Network error during sign out.'));
      // Previous user is preserved in error state so UI can display context and allow retry
      expect(controller.currentUser, equals(testDriver));
    });

    test('signOut failure via generic exception sets user-friendly error message and preserves user', () async {
      final fakeAuth = SignOutTrackingAuthService(
        mockCurrentAuthUser: testRider,
        shouldThrowGenericException: true,
      );
      final fakeProfile = FakeTestUserProfileService()..setProfile(testRider.id, testRider);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
        initialState: AuthState.authenticated(testRider),
      );

      final success = await controller.signOut();

      expect(success, isFalse);
      expect(controller.state.isError, isTrue);
      expect(controller.errorMessage, equals('Failed to sign out. Please try again.'));
      expect(controller.currentUser, equals(testRider));
    });

    test('calling dispose during in-flight signOut safely suppresses notifications and throws no error', () async {
      final completer = Completer<void>();
      final fakeAuth = SignOutTrackingAuthService(
        mockCurrentAuthUser: testRider,
        signOutCompleter: completer,
      );
      final fakeProfile = FakeTestUserProfileService()..setProfile(testRider.id, testRider);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
        initialState: AuthState.authenticated(testRider),
      );

      bool notifiedAfterDisposal = false;
      controller.addListener(() {
        notifiedAfterDisposal = true;
      });

      final signOutFuture = controller.signOut();
      controller.dispose();

      completer.complete();
      final result = await signOutFuture;

      expect(result, isTrue);
      expect(notifiedAfterDisposal, isFalse);
    });

    test('signOut on already disposed controller returns false immediately', () async {
      final fakeAuth = SignOutTrackingAuthService();
      final controller = AuthController(authService: fakeAuth);
      controller.dispose();

      final result = await controller.signOut();

      expect(result, isFalse);
      expect(fakeAuth.signOutCallCount, equals(0));
    });

    test('re-login after signOut restores fresh authenticated session for rider', () async {
      final fakeAuth = FakeAuthService();
      final fakeProfile = FakeTestUserProfileService()..setProfile(testRider.id, testRider);

      final controller = AuthController(
        authService: fakeAuth,
        userProfileService: fakeProfile,
      );

      // 1. Initial login
      final loggedIn = await controller.signIn(
        email: testRider.email!,
        password: 'password123',
      );
      expect(loggedIn, isTrue);
      expect(controller.currentUser!.name, equals('Rider Teardown'));
      expect(controller.currentUser!.role, equals(UserRole.rider));

      // 2. Sign out
      final signedOut = await controller.signOut();
      expect(signedOut, isTrue);
      expect(controller.currentUser, isNull);
      expect(controller.state.isUnauthenticated, isTrue);

      // 3. Profile update in Firestore
      final updatedRider = UserModel(
        id: testRider.id,
        name: 'Rider Fresh Name',
        phoneNumber: '9111222333',
        email: testRider.email,
        role: UserRole.rider,
        createdAt: DateTime.now(),
      );
      fakeProfile.setProfile(testRider.id, updatedRider);

      // 4. Re-login
      final reLoggedIn = await controller.signIn(
        email: testRider.email!,
        password: 'password123',
      );
      expect(reLoggedIn, isTrue);
      expect(controller.currentUser!.name, equals('Rider Fresh Name'));
      expect(controller.currentUser!.phoneNumber, equals('9111222333'));
      expect(controller.currentUser!.role, equals(UserRole.rider));
    });
  });
}

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/services/auth_service.dart';
import 'package:ridesathi/services/service_exception.dart';

/// Test double subclassing [AuthService] to verify contract compliance
/// and controller integration without contacting a live Firebase network.
class TestAuthService extends AuthService {
  UserModel? mockUser;
  final StreamController<UserModel?> _streamController =
      StreamController<UserModel?>.broadcast();
  bool shouldThrow = false;
  AuthException? exceptionToThrow;

  TestAuthService({this.mockUser});

  @override
  UserModel? get currentAuthUser => mockUser;

  @override
  Stream<UserModel?> get onAuthStateChanged => _streamController.stream;

  void emitAuthState(UserModel? user) {
    mockUser = user;
    _streamController.add(user);
  }

  @override
  Future<UserModel?> userSignIn({
    required String email,
    required String password,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ??
          const AuthException('Incorrect email or password.', code: 'wrong-password');
    }
    mockUser = UserModel(
      id: 'test-user-123',
      name: 'Test Rider',
      phoneNumber: '+919876543210',
      email: email,
      role: UserRole.rider,
      isUnionVerified: false,
      createdAt: DateTime.now(),
    );
    _streamController.add(mockUser);
    return mockUser;
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
    if (shouldThrow) {
      throw exceptionToThrow ??
          const AuthException('An account already exists with this email.',
              code: 'email-already-in-use');
    }
    mockUser = UserModel(
      id: 'test-user-new',
      name: name ?? 'New User',
      phoneNumber: phone ?? '',
      email: email,
      role: role,
      isUnionVerified: false,
      vehicleInfo: vehicleInfo,
      createdAt: DateTime.now(),
    );
    _streamController.add(mockUser);
    return mockUser;
  }

  @override
  Future<void> userSignOut() async {
    if (shouldThrow) {
      throw exceptionToThrow ??
          const AuthException('Network error. Check your connection and try again.',
              code: 'network-request-failed');
    }
    mockUser = null;
    _streamController.add(null);
  }

  void dispose() {
    _streamController.close();
  }
}

void main() {
  group('AuthException — Error Code Mapping & Properties', () {
    test('preserves error code and message', () {
      final exception = AuthException.from(
        FirebaseAuthException(code: 'wrong-password'),
      );
      expect(exception.message, equals('Incorrect email or password.'));
      expect(exception.code, equals('wrong-password'));
      expect(exception, isA<ServiceException>());
    });

    test('maps user-not-found to a friendly message', () {
      final exception =
          AuthException.from(FirebaseAuthException(code: 'user-not-found'));
      expect(exception.message, equals('No account found with this email.'));
      expect(exception.code, equals('user-not-found'));
    });

    test('maps invalid-credential to incorrect password message', () {
      final exception =
          AuthException.from(FirebaseAuthException(code: 'invalid-credential'));
      expect(exception.message, equals('Incorrect email or password.'));
    });

    test('maps user-disabled to contact support message', () {
      final exception =
          AuthException.from(FirebaseAuthException(code: 'user-disabled'));
      expect(exception.message,
          equals('This account has been disabled. Contact support for help.'));
    });

    test('maps email-already-in-use to friendly message', () {
      final exception = AuthException.from(
        FirebaseAuthException(code: 'email-already-in-use'),
      );
      expect(exception.message,
          equals('An account already exists with this email.'));
    });

    test('maps weak-password to friendly message', () {
      final exception =
          AuthException.from(FirebaseAuthException(code: 'weak-password'));
      expect(exception.message,
          equals('Password is too weak. Use at least 6 characters.'));
    });

    test('maps invalid-email to friendly message', () {
      final exception =
          AuthException.from(FirebaseAuthException(code: 'invalid-email'));
      expect(exception.message, equals('Please enter a valid email address.'));
    });

    test('maps operation-not-allowed to friendly message', () {
      final exception =
          AuthException.from(FirebaseAuthException(code: 'operation-not-allowed'));
      expect(exception.message,
          equals('Email/password sign-in is not enabled. Contact support.'));
    });

    test('maps network-request-failed to friendly message', () {
      final exception = AuthException.from(
        FirebaseAuthException(code: 'network-request-failed'),
      );
      expect(exception.message,
          equals('Network error. Check your connection and try again.'));
    });

    test('maps too-many-requests to friendly message', () {
      final exception = AuthException.from(
        FirebaseAuthException(code: 'too-many-requests'),
      );
      expect(exception.message,
          equals('Too many attempts. Please wait a moment and try again.'));
    });

    test('maps channel-error to enter email and password message', () {
      final exception =
          AuthException.from(FirebaseAuthException(code: 'channel-error'));
      expect(exception.message,
          equals('Please enter both email and password.'));
    });

    test('maps quota-exceeded to service busy message', () {
      final exception =
          AuthException.from(FirebaseAuthException(code: 'quota-exceeded'));
      expect(exception.message,
          equals('Service temporarily busy. Please try again in a few moments.'));
    });

    test('maps user-token-expired to session expired message', () {
      final exception =
          AuthException.from(FirebaseAuthException(code: 'user-token-expired'));
      expect(exception.message,
          equals('Your session has expired. Please log in again.'));
    });

    test('maps unmapped Firebase code to generic auth failure', () {
      final exception = AuthException.from(
        FirebaseAuthException(code: 'unknown-code'),
      );
      expect(exception.message, equals('Authentication failed. Please try again.'));
      expect(exception.code, equals('unknown-code'));
    });

    test('maps non-Firebase exception to friendly fallback', () {
      final exception = AuthException.from(Exception('Random disk error'));
      expect(
        exception.message,
        equals('Something went wrong. Please check your connection and try again.'),
      );
      expect(exception.code, isNull);
    });
  });

  group('AuthService — Test Double & Contract Verification', () {
    late TestAuthService authService;

    setUp(() {
      authService = TestAuthService();
    });

    tearDown(() {
      authService.dispose();
    });

    test('defaults to null current user when unauthenticated', () {
      expect(authService.currentAuthUser, isNull);
    });

    test('userSignIn returns valid UserModel and emits auth change', () async {
      final user = await authService.userSignIn(
        email: 'rider@ridesathi.com',
        password: 'password123',
      );

      expect(user, isNotNull);
      expect(user!.email, equals('rider@ridesathi.com'));
      expect(user.role, equals(UserRole.rider));
      expect(authService.currentAuthUser, equals(user));
    });

    test('userSignIn throws AuthException on failure', () async {
      authService.shouldThrow = true;

      expect(
        () => authService.userSignIn(
          email: 'invalid@ridesathi.com',
          password: 'wrong',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('userSignUp returns newly created UserModel and updates state', () async {
      final user = await authService.userSignUp(
        email: 'newuser@ridesathi.com',
        password: 'securePassword!',
        name: 'New Rider',
        phone: '+919999988888',
      );

      expect(user, isNotNull);
      expect(user!.name, equals('New Rider'));
      expect(user.phoneNumber, equals('+919999988888'));
      expect(user.role, equals(UserRole.rider));
      expect(authService.currentAuthUser, equals(user));
    });

    test('userSignUp with driver role returns valid UserModel and updates state', () async {
      final user = await authService.userSignUp(
        email: 'driver@ridesathi.com',
        password: 'securePassword!',
        name: 'New Driver',
        phone: '+919999988889',
        role: UserRole.driver,
        vehicleInfo: 'Auto DL-01',
      );

      expect(user, isNotNull);
      expect(user!.name, equals('New Driver'));
      expect(user.role, equals(UserRole.driver));
      expect(user.vehicleInfo, equals('Auto DL-01'));
      expect(authService.currentAuthUser, equals(user));
    });

    test('userSignUp throws AuthException on duplicate email', () async {
      authService.shouldThrow = true;

      expect(
        () => authService.userSignUp(
          email: 'existing@ridesathi.com',
          password: 'password123',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('userSignOut clears session and current user', () async {
      await authService.userSignIn(
        email: 'user@ridesathi.com',
        password: 'password123',
      );
      expect(authService.currentAuthUser, isNotNull);

      await authService.userSignOut();
      expect(authService.currentAuthUser, isNull);
    });

    test('onAuthStateChanged stream emits user transitions', () async {
      final emittedUsers = <UserModel?>[];
      final subscription = authService.onAuthStateChanged.listen(emittedUsers.add);

      final user1 = UserModel(
        id: 'u1',
        name: 'User One',
        phoneNumber: '111',
        role: UserRole.rider,
        isUnionVerified: false,
        createdAt: DateTime.now(),
      );

      authService.emitAuthState(user1);
      authService.emitAuthState(null);

      await pumpEventQueue();

      expect(emittedUsers, hasLength(2));
      expect(emittedUsers[0]?.name, equals('User One'));
      expect(emittedUsers[1], isNull);

      await subscription.cancel();
    });
  });
}

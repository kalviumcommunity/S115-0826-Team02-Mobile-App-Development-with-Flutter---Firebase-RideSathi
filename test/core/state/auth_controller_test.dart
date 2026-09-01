import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/core/state/auth_state.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/services/auth_service.dart';
import 'package:ridesathi/services/firebase_service.dart';

/// Fake implementation of [AuthService] for deterministic controller unit tests.
class FakeAuthService extends AuthService {
  final bool shouldFail;
  final String failureMessage;

  const FakeAuthService({
    this.shouldFail = false,
    this.failureMessage = 'Operation failed',
  });

  @override
  Future<void> userSignOut() async {
    if (shouldFail) {
      throw AuthException(failureMessage);
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

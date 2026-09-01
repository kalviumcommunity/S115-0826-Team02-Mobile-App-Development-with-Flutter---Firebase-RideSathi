import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/state/auth_state.dart';
import 'package:ridesathi/models/user_model.dart';

void main() {
  final sampleUser = UserModel(
    id: 'usr_001',
    name: 'Rajesh Sharma',
    phoneNumber: '+919876543210',
    email: 'rajesh@example.com',
    role: UserRole.driver,
    createdAt: DateTime(2026, 1, 1),
  );

  group('AuthState — Construction & Factory States', () {
    test('AuthState.initial sets initial status', () {
      const state = AuthState.initial();

      expect(state.status, equals(AuthStatus.initial));
      expect(state.isInitial, isTrue);
      expect(state.isAuthenticating, isFalse);
      expect(state.isAuthenticated, isFalse);
      expect(state.isUnauthenticated, isFalse);
      expect(state.isError, isFalse);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
    });

    test('AuthState.authenticating sets authenticating status and retains previous user', () {
      final state = AuthState.authenticating(previousUser: sampleUser);

      expect(state.status, equals(AuthStatus.authenticating));
      expect(state.isAuthenticating, isTrue);
      expect(state.user, equals(sampleUser));
    });

    test('AuthState.authenticated sets authenticated status with valid user', () {
      final state = AuthState.authenticated(sampleUser);

      expect(state.status, equals(AuthStatus.authenticated));
      expect(state.isAuthenticated, isTrue);
      expect(state.user, equals(sampleUser));
      expect(state.errorMessage, isNull);
    });

    test('AuthState.unauthenticated sets unauthenticated status with null user', () {
      const state = AuthState.unauthenticated();

      expect(state.status, equals(AuthStatus.unauthenticated));
      expect(state.isUnauthenticated, isTrue);
      expect(state.user, isNull);
    });

    test('AuthState.error sets error status with message and optional user', () {
      final state = AuthState.error('Invalid credentials', previousUser: sampleUser);

      expect(state.status, equals(AuthStatus.error));
      expect(state.isError, isTrue);
      expect(state.errorMessage, equals('Invalid credentials'));
      expect(state.user, equals(sampleUser));
    });
  });

  group('AuthState — copyWith & Immutability', () {
    test('copyWith updates specified fields correctly', () {
      const initial = AuthState.initial();
      final updated = initial.copyWith(
        status: AuthStatus.authenticated,
        user: sampleUser,
      );

      expect(updated.status, equals(AuthStatus.authenticated));
      expect(updated.user, equals(sampleUser));
      expect(updated.errorMessage, isNull);
    });

    test('copyWith clears user and error when flags are set', () {
      final errorState = AuthState.error('Wrong password', previousUser: sampleUser);

      final cleared = errorState.copyWith(
        clearUser: true,
        clearError: true,
      );

      expect(cleared.user, isNull);
      expect(cleared.errorMessage, isNull);
      expect(cleared.status, equals(AuthStatus.error));
    });
  });

  group('AuthState — Equality and toString', () {
    test('equal states match and have identical hashCodes', () {
      final state1 = AuthState.authenticated(sampleUser);
      final state2 = AuthState.authenticated(sampleUser);
      const state3 = AuthState.unauthenticated();

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
      expect(state1, isNot(equals(state3)));
    });

    test('toString includes status and user details', () {
      final state = AuthState.authenticated(sampleUser);
      expect(state.toString(), contains('AuthStatus.authenticated'));
      expect(state.toString(), contains('Rajesh Sharma'));
    });
  });
}

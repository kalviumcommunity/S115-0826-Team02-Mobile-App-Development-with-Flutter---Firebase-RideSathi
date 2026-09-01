import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';

/// Represents the status of user authentication.
enum AuthStatus {
  /// Initial uninitialized/unknown authentication state.
  initial,

  /// An authentication operation is in progress (signing in, signing up, checking session).
  authenticating,

  /// User is successfully authenticated.
  authenticated,

  /// User is not authenticated.
  unauthenticated,

  /// An authentication operation failed.
  error,
}

/// Immutable snapshot of the application's authentication state.
@immutable
class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState._({
    required this.status,
    this.user,
    this.errorMessage,
  });

  /// Initial state before authentication check.
  const AuthState.initial() : this._(status: AuthStatus.initial);

  /// Authenticating state during sign in, sign up, or auth status verification.
  const AuthState.authenticating({UserModel? previousUser})
      : this._(
          status: AuthStatus.authenticating,
          user: previousUser,
        );

  /// Authenticated state with active [user].
  const AuthState.authenticated(UserModel user)
      : this._(
          status: AuthStatus.authenticated,
          user: user,
        );

  /// Unauthenticated state (guest / signed out).
  const AuthState.unauthenticated()
      : this._(status: AuthStatus.unauthenticated);

  /// Error state when authentication fails.
  const AuthState.error(String errorMessage, {UserModel? previousUser})
      : this._(
          status: AuthStatus.error,
          errorMessage: errorMessage,
          user: previousUser,
        );

  // Convenience Status Predicates
  bool get isInitial => status == AuthStatus.initial;
  bool get isAuthenticating => status == AuthStatus.authenticating;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isError => status == AuthStatus.error;

  /// Creates a copy of this [AuthState] with the given fields replaced.
  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState._(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.status == status &&
        other.user == user &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(status, user, errorMessage);

  @override
  String toString() =>
      'AuthState(status: $status, user: ${user?.name ?? user?.id}, error: $errorMessage)';
}

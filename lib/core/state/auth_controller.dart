import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../services/firestore_exception.dart';
import '../../services/user_profile_service.dart';
import 'auth_state.dart';

/// Observable controller managing application authentication session state.
///
/// Coordinates actions through [AuthService] and [UserProfileService], listens to session changes,
/// and notifies UI listeners with immutable [AuthState] snapshots.
class AuthController extends ChangeNotifier {
  final AuthService _authService;
  final UserProfileService _userProfileService;
  StreamSubscription<UserModel?>? _authSubscription;

  AuthState _state;

  /// Global singleton instance for app-wide sharing where appropriate.
  static AuthController? _instance;
  static AuthController get instance => _instance ??= AuthController();

  AuthController({
    AuthService? authService,
    UserProfileService? userProfileService,
    AuthState initialState = const AuthState.initial(),
    bool listenToAuthChanges = false,
  })  : _authService = authService ?? const AuthService(),
        _userProfileService = userProfileService ?? const UserProfileService(),
        _state = initialState {
    if (listenToAuthChanges) {
      _subscribeToAuthChanges();
    }
  }

  /// Current immutable authentication state.
  AuthState get state => _state;

  /// Whether a user is currently authenticated.
  bool get isAuthenticated => _state.isAuthenticated;

  /// Whether an authentication request is in progress.
  bool get isAuthenticating => _state.isAuthenticating;

  /// The current authenticated user model, if any.
  UserModel? get currentUser => _state.user;

  /// The current error message, if any.
  String? get errorMessage => _state.errorMessage;

  void _setState(AuthState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  /// Subscribes to real-time auth changes from [AuthService].
  void _subscribeToAuthChanges() {
    try {
      _authSubscription?.cancel();
      _authSubscription = _authService.onAuthStateChanged.listen((UserModel? user) {
        if (user != null) {
          _setState(AuthState.authenticated(user));
        } else {
          _setState(const AuthState.unauthenticated());
        }
      });
    } catch (_) {
      // Firebase not initialized in current test or platform environment.
    }
  }

  /// Synchronizes authentication state with current [AuthService] session.
  Future<void> checkAuthStatus() async {
    if (!FirebaseService.isInitialized) {
      _setState(const AuthState.unauthenticated());
      return;
    }

    try {
      final user = _authService.currentAuthUser;
      if (user != null) {
        _setState(AuthState.authenticated(user));
      } else {
        _setState(const AuthState.unauthenticated());
      }
    } catch (e) {
      _setState(const AuthState.unauthenticated());
    }
  }

  /// Signs in a user with email and password.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setState(AuthState.authenticating(previousUser: _state.user));
    try {
      final user = await _authService.userSignIn(
        email: email,
        password: password,
      );
      if (user != null) {
        _setState(AuthState.authenticated(user));
        return true;
      } else {
        _setState(const AuthState.error('Failed to authenticate user.'));
        return false;
      }
    } on AuthException catch (e) {
      _setState(AuthState.error(e.message));
      return false;
    } catch (e) {
      _setState(const AuthState.error(
        'An unexpected error occurred. Please try again.',
      ));
      return false;
    }
  }

  /// Registers a new user with email and password, then creates their rider profile document in Firestore.
  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    _setState(AuthState.authenticating(previousUser: _state.user));
    try {
      final user = await _authService.userSignUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      if (user != null) {
        try {
          await _userProfileService.createRiderProfile(user);
        } catch (e) {
          final errorMsg = e is FirestoreException
              ? e.message
              : 'Account created, but failed to save rider profile.';
          _setState(AuthState.error(errorMsg));
          return false;
        }
        _setState(AuthState.authenticated(user));
        return true;
      } else {
        _setState(const AuthState.error('Failed to create account.'));
        return false;
      }
    } on AuthException catch (e) {
      _setState(AuthState.error(e.message));
      return false;
    } on FirestoreException catch (e) {
      _setState(AuthState.error(e.message));
      return false;
    } catch (e) {
      _setState(const AuthState.error(
        'An unexpected error occurred. Please try again.',
      ));
      return false;
    }
  }

  /// Signs out the currently authenticated user.
  Future<bool> signOut() async {
    try {
      await _authService.userSignOut();
      _setState(const AuthState.unauthenticated());
      return true;
    } on AuthException catch (e) {
      _setState(AuthState.error(e.message, previousUser: _state.user));
      return false;
    } catch (e) {
      _setState(AuthState.error(
        'Failed to sign out. Please try again.',
        previousUser: _state.user,
      ));
      return false;
    }
  }

  /// Clears any active error message without altering other state fields.
  void clearError() {
    if (_state.errorMessage != null) {
      _setState(_state.copyWith(clearError: true));
    }
  }

  /// Directly updates internal state (useful in tests and isolated state simulations).
  @visibleForTesting
  void updateState(AuthState newState) {
    _setState(newState);
  }

  /// Resets the global singleton instance (useful between test runs).
  @visibleForTesting
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

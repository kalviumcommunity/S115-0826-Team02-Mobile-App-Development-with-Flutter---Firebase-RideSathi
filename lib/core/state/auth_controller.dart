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
  bool _isDisposed = false;
  Future<void>? _activeRestoration;
  Future<bool>? _activeSignOut;
  String? _restoringUid;
  int _sessionGeneration = 0;

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
    if (_isDisposed) return;
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  /// Subscribes to real-time auth changes from [AuthService].
  void _subscribeToAuthChanges() {
    try {
      _authSubscription?.cancel();
      _authSubscription = _authService.onAuthStateChanged.listen((UserModel? authUser) async {
        if (_isDisposed) return;

        if (authUser == null) {
          _sessionGeneration++;
          _restoringUid = null;
          _activeRestoration = null;
          _setState(const AuthState.unauthenticated());
          return;
        }

        // Avoid duplicate resolution if already authenticated with this exact user
        if (_state.isAuthenticated && _state.user?.id == authUser.id) {
          return;
        }

        // Avoid duplicate concurrent resolution if an interactive login or check is in progress
        if (_restoringUid == authUser.id) {
          return;
        }

        _restoringUid = authUser.id;
        final currentGen = _sessionGeneration;
        try {
          await _restoreDomainProfile(authUser.id, currentGen);
        } finally {
          if (_restoringUid == authUser.id) {
            _restoringUid = null;
          }
        }
      });
    } catch (_) {
      // Firebase not initialized in current test or platform environment.
    }
  }

  /// Resolves the user's Firestore domain profile document and updates state accordingly.
  Future<UserModel?> _restoreDomainProfile(String uid, [int? expectedGeneration]) async {
    final gen = expectedGeneration ?? _sessionGeneration;
    try {
      final profile = await _userProfileService.getUserProfile(uid);
      if (_isDisposed || _sessionGeneration != gen || _restoringUid != uid) {
        return null;
      }
      if (profile != null) {
        _setState(AuthState.authenticated(profile));
        return profile;
      } else {
        _setState(const AuthState.error(
          'User session active, but profile could not be found.',
        ));
        return null;
      }
    } on FirestoreException catch (e) {
      if (_isDisposed || _sessionGeneration != gen || _restoringUid != uid) {
        return null;
      }
      _setState(AuthState.error(e.message));
      return null;
    } catch (_) {
      if (_isDisposed || _sessionGeneration != gen || _restoringUid != uid) {
        return null;
      }
      _setState(const AuthState.error(
        'Failed to load user profile. Please try again.',
      ));
      return null;
    }
  }

  /// Synchronizes authentication state with current [AuthService] session and resolves domain profile.
  ///
  /// Deduplicated and idempotent: concurrent invocations return the same active [Future].
  Future<void> checkAuthStatus() async {
    if (_activeRestoration != null) {
      return _activeRestoration!;
    }

    final future = _performCheckAuthStatus();
    _activeRestoration = future;
    try {
      await future;
    } finally {
      _activeRestoration = null;
    }
  }

  Future<void> _performCheckAuthStatus() async {
    if (!FirebaseService.isInitialized) {
      if (FirebaseService.initializationError != null) {
        _setState(const AuthState.error(
          'RideSathi could not connect to its services. Please check your internet connection and try again.',
        ));
      } else {
        _setState(const AuthState.unauthenticated());
      }
      return;
    }

    _setState(AuthState.authenticating(previousUser: _state.user));

    try {
      final authUser = _authService.currentAuthUser;
      if (authUser != null) {
        _restoringUid = authUser.id;
        final currentGen = _sessionGeneration;
        try {
          await _restoreDomainProfile(authUser.id, currentGen);
        } finally {
          if (_restoringUid == authUser.id) {
            _restoringUid = null;
          }
        }
      } else {
        _setState(const AuthState.unauthenticated());
      }
    } catch (_) {
      _setState(const AuthState.unauthenticated());
    }
  }

  /// Retries session restoration after an error.
  Future<void> retryRestoration() async {
    clearError();
    await checkAuthStatus();
  }

  /// Signs in a user with email and password and resolves their Firestore domain profile.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setState(AuthState.authenticating(previousUser: _state.user));
    final currentGen = ++_sessionGeneration;
    try {
      final authUser = await _authService.userSignIn(
        email: email,
        password: password,
      );
      if (authUser == null) {
        if (_sessionGeneration != currentGen) return false;
        _setState(const AuthState.error('Failed to authenticate user.'));
        return false;
      }

      _restoringUid = authUser.id;
      try {
        final profile = await _userProfileService.getUserProfile(authUser.id);
        if (_isDisposed || _sessionGeneration != currentGen) return false;
        if (profile == null) {
          _setState(const AuthState.error(
            'User profile not found. Please contact support or register again.',
          ));
          return false;
        }
        _setState(AuthState.authenticated(profile));
        return true;
      } on FirestoreException catch (e) {
        if (_isDisposed || _sessionGeneration != currentGen) return false;
        _setState(AuthState.error(e.message));
        return false;
      } catch (e) {
        if (_isDisposed || _sessionGeneration != currentGen) return false;
        _setState(const AuthState.error(
          'Failed to load user profile. Please try again.',
        ));
        return false;
      } finally {
        if (_restoringUid == authUser.id) {
          _restoringUid = null;
        }
      }
    } on AuthException catch (e) {
      if (_isDisposed || _sessionGeneration != currentGen) return false;
      _setState(AuthState.error(e.message));
      return false;
    } on FirestoreException catch (e) {
      if (_isDisposed || _sessionGeneration != currentGen) return false;
      _setState(AuthState.error(e.message));
      return false;
    } catch (e) {
      if (_isDisposed || _sessionGeneration != currentGen) return false;
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
    final currentGen = ++_sessionGeneration;
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
          if (_isDisposed || _sessionGeneration != currentGen) return false;
          final errorMsg = e is FirestoreException
              ? e.message
              : 'Account created, but failed to save rider profile.';
          _setState(AuthState.error(errorMsg));
          return false;
        }
        if (_isDisposed || _sessionGeneration != currentGen) return false;
        _setState(AuthState.authenticated(user));
        return true;
      } else {
        if (_isDisposed || _sessionGeneration != currentGen) return false;
        _setState(const AuthState.error('Failed to create account.'));
        return false;
      }
    } on AuthException catch (e) {
      if (_isDisposed || _sessionGeneration != currentGen) return false;
      _setState(AuthState.error(e.message));
      return false;
    } on FirestoreException catch (e) {
      if (_isDisposed || _sessionGeneration != currentGen) return false;
      _setState(AuthState.error(e.message));
      return false;
    } catch (e) {
      if (_isDisposed || _sessionGeneration != currentGen) return false;
      _setState(const AuthState.error(
        'An unexpected error occurred. Please try again.',
      ));
      return false;
    }
  }

  /// Registers a new driver with email and password, then creates their driver profile document in Firestore.
  Future<bool> signUpDriver({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String vehicleInfo,
  }) async {
    _setState(AuthState.authenticating(previousUser: _state.user));
    final currentGen = ++_sessionGeneration;
    try {
      final user = await _authService.userSignUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: UserRole.driver,
        vehicleInfo: vehicleInfo,
      );
      if (user != null) {
        try {
          await _userProfileService.createDriverProfile(user);
        } catch (e) {
          if (_isDisposed || _sessionGeneration != currentGen) return false;
          final errorMsg = e is FirestoreException
              ? e.message
              : 'Account created, but failed to save driver profile.';
          _setState(AuthState.error(errorMsg));
          return false;
        }
        if (_isDisposed || _sessionGeneration != currentGen) return false;
        _setState(AuthState.authenticated(user));
        return true;
      } else {
        if (_isDisposed || _sessionGeneration != currentGen) return false;
        _setState(const AuthState.error('Failed to create account.'));
        return false;
      }
    } on AuthException catch (e) {
      if (_isDisposed || _sessionGeneration != currentGen) return false;
      _setState(AuthState.error(e.message));
      return false;
    } on FirestoreException catch (e) {
      if (_isDisposed || _sessionGeneration != currentGen) return false;
      _setState(AuthState.error(e.message));
      return false;
    } catch (e) {
      if (_isDisposed || _sessionGeneration != currentGen) return false;
      _setState(const AuthState.error(
        'An unexpected error occurred. Please try again.',
      ));
      return false;
    }
  }

  /// Signs out the currently authenticated user.
  ///
  /// Deduplicated and idempotent: concurrent invocations return the same active [Future].
  /// Cancels in-flight profile restoration, invalidates pending callbacks,
  /// clears domain session state, and delegates to [AuthService.userSignOut].
  Future<bool> signOut() async {
    if (_isDisposed) return false;
    if (_activeSignOut != null) {
      return _activeSignOut!;
    }

    final future = _performSignOut();
    _activeSignOut = future;
    try {
      return await future;
    } finally {
      _activeSignOut = null;
    }
  }

  Future<bool> _performSignOut() async {
    _sessionGeneration++;
    _restoringUid = null;
    _activeRestoration = null;
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
    _isDisposed = true;
    _sessionGeneration++;
    _authSubscription?.cancel();
    _authSubscription = null;
    _activeRestoration = null;
    _activeSignOut = null;
    _restoringUid = null;
    super.dispose();
  }
}

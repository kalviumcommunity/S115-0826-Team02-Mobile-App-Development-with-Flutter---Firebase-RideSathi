import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import '../../services/driver_availability_service.dart';
import '../../services/firestore_exception.dart';
import 'auth_controller.dart';
import 'view_state.dart';

/// Controller managing driver online/offline availability state.
///
/// Encapsulates availability persistence, ownership validation, duplicate request
/// prevention, and safe synchronization with [AuthController] session generation.
class DriverAvailabilityController extends ChangeNotifier {
  final AuthController _authController;
  final DriverAvailabilityService _availabilityService;

  ViewState<bool> _state;
  bool _isUpdating = false;
  bool _isDisposed = false;

  DriverAvailabilityController({
    AuthController? authController,
    DriverAvailabilityService? availabilityService,
    bool? initialOnline,
  })  : _authController = authController ?? AuthController.instance,
        _availabilityService =
            availabilityService ?? const DriverAvailabilityService(),
        _state = ViewState.success(
          initialOnline ??
              authController?.currentUser?.isOnline ??
              false,
        ) {
    final user = _authController.currentUser;
    if (user != null && user.role == UserRole.driver && initialOnline == null) {
      _state = ViewState.success(user.isOnline);
    }
  }

  /// Current availability view state (`true` = Online, `false` = Offline).
  ViewState<bool> get state => _state;

  /// Whether the driver is currently online.
  bool get isOnline => _state.data ?? false;

  /// Whether an availability update operation is in-flight.
  bool get isUpdating => _isUpdating;

  /// Whether an availability fetch operation is in-flight.
  bool get isLoading => _state.isLoading && !_isUpdating;

  /// Active error message, if any.
  String? get errorMessage => _state.isError ? _state.message : null;

  /// Fetches the latest availability state from Firestore.
  Future<bool> fetchAvailability() async {
    final activeUser = _authController.currentUser;
    if (activeUser == null || !_authController.isAuthenticated) {
      _state = const ViewState.error('No authenticated user session found.');
      notifyListeners();
      return false;
    }

    if (activeUser.role != UserRole.driver) {
      _state = const ViewState.error(
        'Only driver accounts can access availability features.',
      );
      notifyListeners();
      return false;
    }

    final sessionGen = _authController.sessionGeneration;
    _state = ViewState.loading(previousData: isOnline);
    notifyListeners();

    try {
      final online = await _availabilityService.getAvailability(activeUser.id);
      if (_isDisposed ||
          !_authController.isAuthenticated ||
          _authController.sessionGeneration != sessionGen) {
        return false;
      }

      _authController.updateCurrentUser(
        activeUser.copyWith(isOnline: online),
        expectedGeneration: sessionGen,
      );

      _state = ViewState.success(online);
      notifyListeners();
      return online;
    } on FirestoreException catch (e) {
      if (!_isDisposed) {
        _state = ViewState.error(
          e.message,
          code: e.code,
          previousData: isOnline,
        );
        notifyListeners();
      }
      return isOnline;
    } catch (_) {
      if (!_isDisposed) {
        _state = ViewState.error(
          'Failed to load availability state.',
          previousData: isOnline,
        );
        notifyListeners();
      }
      return isOnline;
    }
  }

  /// Sets driver availability to Online (`isOnline = true`).
  Future<bool> setOnline() => _updateAvailability(true);

  /// Sets driver availability to Offline (`isOnline = false`).
  Future<bool> setOffline() => _updateAvailability(false);

  /// Toggles current availability state.
  Future<bool> toggleAvailability() => _updateAvailability(!isOnline);

  Future<bool> _updateAvailability(bool targetOnline) async {
    if (_isUpdating || _isDisposed) return isOnline;

    final activeUser = _authController.currentUser;
    if (activeUser == null || !_authController.isAuthenticated) {
      _state = const ViewState.error(
        'You must be signed in to change availability.',
        code: 'unauthenticated',
      );
      notifyListeners();
      return isOnline;
    }

    if (activeUser.role != UserRole.driver) {
      _state = const ViewState.error(
        'Only driver accounts can update availability.',
      );
      notifyListeners();
      return isOnline;
    }

    final sessionGen = _authController.sessionGeneration;
    final driverId = activeUser.id;

    _isUpdating = true;
    _state = ViewState.loading(previousData: isOnline);
    notifyListeners();

    try {
      final successOnline = await _availabilityService.setAvailability(
        driverId: driverId,
        isOnline: targetOnline,
      );

      if (_isDisposed) return isOnline;

      // Session guard: check if logout or session change occurred during write
      if (!_authController.isAuthenticated ||
          _authController.sessionGeneration != sessionGen ||
          _authController.currentUser?.id != driverId) {
        _isUpdating = false;
        return isOnline;
      }

      _authController.updateCurrentUser(
        activeUser.copyWith(isOnline: successOnline),
        expectedGeneration: sessionGen,
      );

      _state = ViewState.success(
        successOnline,
        message: successOnline ? 'You are now Online.' : 'You are now Offline.',
      );
      return successOnline;
    } on FirestoreException catch (e) {
      if (_isDisposed) return isOnline;
      _state = ViewState.error(
        e.message,
        code: e.code,
        previousData: isOnline,
      );
      return isOnline;
    } catch (_) {
      if (_isDisposed) return isOnline;
      _state = ViewState.error(
        'Failed to update availability status. Please try again.',
        previousData: isOnline,
      );
      return isOnline;
    } finally {
      _isUpdating = false;
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  /// Clears any active error state without altering current availability data.
  void clearError() {
    if (_state.isError) {
      _state = ViewState.success(isOnline);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import '../../services/firestore_exception.dart';
import '../../services/user_profile_service.dart';
import '../utils/validators.dart';
import 'auth_controller.dart';
import 'view_state.dart';

/// Controller managing authenticated profile inspection, editing, and persistence.
///
/// Encapsulates profile form validation, dirty tracking, Firestore persistence,
/// and safe synchronization with [AuthController] session generation.
class ProfileController extends ChangeNotifier {
  final AuthController _authController;
  final UserProfileService _userProfileService;

  ViewState<UserModel> _state;
  UserModel? _originalUser;
  bool _isSaving = false;
  bool _isDisposed = false;

  String _name = '';
  String _phoneNumber = '';
  String? _vehicleInfo;

  ProfileController({
    AuthController? authController,
    UserProfileService? userProfileService,
    UserModel? initialUser,
  })  : _authController = authController ?? AuthController.instance,
        _userProfileService = userProfileService ??
            authController?.userProfileService ??
            const UserProfileService(),
        _state = initialUser != null
            ? ViewState.success(initialUser)
            : (authController?.currentUser != null
                ? ViewState.success(authController!.currentUser!)
                : const ViewState.initial()) {
    final user = initialUser ?? _authController.currentUser;
    if (user != null) {
      initialize(user);
    }
  }

  /// Current profile view state.
  ViewState<UserModel> get state => _state;

  /// The resolved user model, if any.
  UserModel? get currentUser => _state.data ?? _originalUser;

  /// Current editable form field values.
  String get name => _name;
  String get phoneNumber => _phoneNumber;
  String? get vehicleInfo => _vehicleInfo;

  /// Whether a profile save operation is in-flight.
  bool get isSaving => _isSaving;

  /// Whether a profile fetch is in-flight.
  bool get isLoading => _state.isLoading && !_isSaving;

  /// Active error message, if in error state.
  String? get errorMessage => _state.isError ? _state.message : null;

  /// Active success message, if present.
  String? get successMessage => _state.isSuccess ? _state.message : null;

  /// Whether any editable field has been modified compared to the source user profile.
  bool get isDirty {
    if (_originalUser == null) return false;
    final nameChanged = _name.trim() != _originalUser!.name.trim();
    final phoneChanged =
        _phoneNumber.trim() != _originalUser!.phoneNumber.trim();
    final vehicleChanged = _originalUser!.role == UserRole.driver &&
        (_vehicleInfo?.trim() ?? '') !=
            (_originalUser!.vehicleInfo?.trim() ?? '');
    return nameChanged || phoneChanged || vehicleChanged;
  }

  /// Initializes the controller with a baseline user model.
  void initialize(UserModel user) {
    _originalUser = user;
    _name = user.name;
    _phoneNumber = user.phoneNumber;
    _vehicleInfo = user.vehicleInfo;
    _state = ViewState.success(user);
    notifyListeners();
  }

  /// Updates the name field and notifies listeners.
  void setName(String value) {
    if (_name != value) {
      _name = value;
      notifyListeners();
    }
  }

  /// Updates the phone number field and notifies listeners.
  void setPhoneNumber(String value) {
    if (_phoneNumber != value) {
      _phoneNumber = value;
      notifyListeners();
    }
  }

  /// Updates the vehicle info field and notifies listeners.
  void setVehicleInfo(String? value) {
    if (_vehicleInfo != value) {
      _vehicleInfo = value;
      notifyListeners();
    }
  }

  /// Reverts editable fields back to the source user profile values.
  void resetForm() {
    if (_originalUser != null) {
      _name = _originalUser!.name;
      _phoneNumber = _originalUser!.phoneNumber;
      _vehicleInfo = _originalUser!.vehicleInfo;
      clearError();
      notifyListeners();
    }
  }

  /// Clears any active error message without discarding entered field changes.
  void clearError() {
    if (_state.isError) {
      _state = _originalUser != null
          ? ViewState.success(_originalUser!)
          : const ViewState.initial();
      notifyListeners();
    }
  }

  /// Refreshes the user profile from Firestore and syncs state.
  Future<UserModel?> refreshProfile() async {
    final activeUser = _authController.currentUser ?? _originalUser;
    if (activeUser == null) {
      _state = const ViewState.error('No authenticated user session found.');
      notifyListeners();
      return null;
    }

    final sessionGen = _authController.sessionGeneration;
    _state = ViewState.loading(previousData: _originalUser);
    notifyListeners();

    try {
      final fresh = await _userProfileService.getUserProfile(activeUser.id);
      if (_isDisposed ||
          !_authController.isAuthenticated ||
          _authController.sessionGeneration != sessionGen) {
        return null;
      }

      if (fresh != null) {
        _authController.updateCurrentUser(fresh, expectedGeneration: sessionGen);
        initialize(fresh);
        return fresh;
      } else {
        _state = const ViewState.error('Profile could not be found.');
        notifyListeners();
        return null;
      }
    } on FirestoreException catch (e) {
      if (!_isDisposed) {
        _state = ViewState.error(
          e.message,
          code: e.code,
          previousData: _originalUser,
        );
        notifyListeners();
      }
      return null;
    } catch (_) {
      if (!_isDisposed) {
        _state = ViewState.error(
          'Failed to load user profile. Please try again.',
          previousData: _originalUser,
        );
        notifyListeners();
      }
      return null;
    }
  }

  /// Validates inputs and persists modified permitted fields to Firestore.
  ///
  /// Synchronizes the updated profile with [AuthController] upon success,
  /// strictly preserving immutable identity and role fields.
  Future<bool> saveProfile() async {
    if (_isSaving || _isDisposed) return false;

    final activeUser = _authController.currentUser;
    if (activeUser == null || !_authController.isAuthenticated) {
      _state = const ViewState.error(
        'You must be signed in to update your profile.',
        code: 'unauthenticated',
      );
      notifyListeners();
      return false;
    }

    // Input Validation
    final nameError = Validators.name(_name);
    if (nameError != null) {
      _state = ViewState.error(nameError, previousData: _originalUser);
      notifyListeners();
      return false;
    }

    final phoneError = Validators.phone(_phoneNumber);
    if (phoneError != null) {
      _state = ViewState.error(phoneError, previousData: _originalUser);
      notifyListeners();
      return false;
    }

    if (activeUser.role == UserRole.driver) {
      final vehicleError = Validators.vehicleInfo(_vehicleInfo);
      if (vehicleError != null) {
        _state = ViewState.error(vehicleError, previousData: _originalUser);
        notifyListeners();
        return false;
      }
    }

    // If nothing changed, succeed immediately without network write
    if (!isDirty) {
      _state = ViewState.success(_originalUser ?? activeUser);
      notifyListeners();
      return true;
    }

    final sessionGen = _authController.sessionGeneration;
    final uid = activeUser.id;

    _isSaving = true;
    _state = ViewState.loading(previousData: _originalUser);
    notifyListeners();

    try {
      final updates = <String, dynamic>{
        'name': _name.trim(),
        'phoneNumber': _phoneNumber.trim(),
      };
      if (activeUser.role == UserRole.driver) {
        updates['vehicleInfo'] = _vehicleInfo?.trim() ?? '';
      }

      final updatedProfile = await _userProfileService.updateProfile(
        uid: uid,
        updates: updates,
      );

      if (_isDisposed) return false;

      // Session guard: if user logged out or session generation changed during save, abort
      if (!_authController.isAuthenticated ||
          _authController.sessionGeneration != sessionGen ||
          _authController.currentUser?.id != uid) {
        _isSaving = false;
        return false;
      }

      final synced = _authController.updateCurrentUser(
        updatedProfile,
        expectedGeneration: sessionGen,
      );

      if (!synced) {
        _isSaving = false;
        return false;
      }

      _originalUser = updatedProfile;
      _name = updatedProfile.name;
      _phoneNumber = updatedProfile.phoneNumber;
      _vehicleInfo = updatedProfile.vehicleInfo;
      _state = ViewState.success(
        updatedProfile,
        message: 'Profile updated successfully.',
      );
      return true;
    } on FirestoreException catch (e) {
      if (_isDisposed) return false;
      _state = ViewState.error(
        e.message,
        code: e.code,
        previousData: _originalUser,
      );
      return false;
    } catch (e) {
      if (_isDisposed) return false;
      _state = ViewState.error(
        'Failed to update profile. Please try again.',
        previousData: _originalUser,
      );
      return false;
    } finally {
      _isSaving = false;
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

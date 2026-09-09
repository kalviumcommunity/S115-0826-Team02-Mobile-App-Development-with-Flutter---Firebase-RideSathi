import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import '../../services/user_profile_service.dart';
import 'view_state.dart';

/// Manages the state for fetching and displaying assigned driver information.
class DriverInformationController extends ChangeNotifier {
  final UserProfileService _profileService;
  
  ViewState<UserModel> _state = const ViewState.initial();
  String? _currentDriverId;

  DriverInformationController({
    UserProfileService? profileService,
  }) : _profileService = profileService ?? const UserProfileService();

  ViewState<UserModel> get state => _state;

  /// Loads the driver profile for the given [driverId].
  /// 
  /// If [driverId] is null or empty, the state transitions to initial (unassigned).
  /// Prevents duplicate concurrent loads for the same driver.
  Future<void> loadDriver(String? driverId) async {
    final trimmedId = driverId?.trim();

    if (trimmedId == null || trimmedId.isEmpty) {
      if (_currentDriverId != null || !_state.isInitial) {
        _currentDriverId = null;
        _state = const ViewState.initial();
        notifyListeners();
      }
      return;
    }

    if (trimmedId == _currentDriverId && (_state.isSuccess || _state.isLoading)) {
      // Already loading or successfully loaded this exact driver.
      return;
    }

    _currentDriverId = trimmedId;
    _state = const ViewState.loading(message: 'Loading driver details...');
    notifyListeners();

    try {
      final profile = await _profileService.getUserProfile(trimmedId);

      // Session safety: Check if we are still loading the same driver
      if (_currentDriverId != trimmedId) return;

      if (profile == null) {
        _state = const ViewState.error('Driver information is currently unavailable.');
        notifyListeners();
        return;
      }

      // Domain role validation: Ensure the fetched profile is actually a driver.
      if (profile.role != UserRole.driver) {
        _state = const ViewState.error('Driver information is currently unavailable.');
        notifyListeners();
        return;
      }

      _state = ViewState.success(profile);
      notifyListeners();
    } catch (e) {
      if (_currentDriverId != trimmedId) return;
      
      _state = const ViewState.error('Driver information is currently unavailable.');
      notifyListeners();
    }
  }

  /// Retries loading the current driver if an error occurred.
  void retry() {
    if (_currentDriverId != null) {
      final idToLoad = _currentDriverId;
      _currentDriverId = null; // force reload bypass
      loadDriver(idToLoad);
    }
  }
}

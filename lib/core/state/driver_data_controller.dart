import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/driver_operational_data.dart';
import '../../models/user_model.dart';
import '../../services/driver_data_service.dart';
import '../../services/firestore_exception.dart';
import 'auth_controller.dart';
import 'view_state.dart';

/// Manages the real-time operational driver data stream for dispatchers.
///
/// Ensures the stream is only active when an authenticated dispatcher is logged in.
/// Provides safe lifecycle management, duplicate subscription protection,
/// and session safety.
class DriverDataController extends ChangeNotifier {
  final DriverDataService _driverDataService;
  final AuthController _authController;

  ViewState<List<DriverOperationalData>> _state = const ViewState.initial();
  StreamSubscription<List<DriverOperationalData>>? _subscription;
  bool _isDisposed = false;
  int _activeSessionGeneration = 0;

  DriverDataController({
    DriverDataService? driverDataService,
    AuthController? authController,
  })  : _driverDataService = driverDataService ?? DriverDataService(),
        _authController = authController ?? AuthController.instance {
    _init();
  }

  /// Current UI view state containing the list of online drivers.
  ViewState<List<DriverOperationalData>> get state => _state;

  void _init() {
    _authController.addListener(_onAuthChanged);
    _onAuthChanged(); // trigger immediately
  }

  void _onAuthChanged() {
    final user = _authController.currentUser;
    final currentGen = _authController.sessionGeneration;

    // Only dispatchers (or admins) should see this data.
    // For now, allow dispatchers. If role is not authorized, stop listening.
    if (user == null || (user.role != UserRole.dispatcher && user.role != UserRole.admin) || _activeSessionGeneration != currentGen) {
      stopListening();
    } else if (_subscription == null) {
      startListening();
    }
  }

  /// Starts listening to real-time driver data.
  void startListening() {
    if (_isDisposed) return;

    final user = _authController.currentUser;
    if (user == null || (user.role != UserRole.dispatcher && user.role != UserRole.admin)) {
      _state = const ViewState.error('Dispatcher authentication required.');
      notifyListeners();
      return;
    }

    _subscription?.cancel();
    _activeSessionGeneration = _authController.sessionGeneration;
    final captureSessionGen = _activeSessionGeneration;

    _state = const ViewState.loading(message: 'Loading real-time driver data...');
    notifyListeners();

    try {
      _subscription = _driverDataService.watchOnlineDriversData().listen(
        (drivers) {
          if (_isDisposed) return;

          // Session generation guard
          if (_authController.sessionGeneration != captureSessionGen) {
            return;
          }

          if (drivers.isEmpty) {
            _state = const ViewState.empty(message: 'No drivers are currently online.');
          } else {
            // Sort drivers by verification status and then name for stable UI
            final sortedDrivers = List<DriverOperationalData>.from(drivers)
              ..sort((a, b) {
                if (a.isUnionVerified && !b.isUnionVerified) return -1;
                if (!a.isUnionVerified && b.isUnionVerified) return 1;
                return a.name.toLowerCase().compareTo(b.name.toLowerCase());
              });
            _state = ViewState.success(sortedDrivers);
          }
          notifyListeners();
        },
        onError: (error) {
          if (_isDisposed) return;
          if (_authController.sessionGeneration != captureSessionGen) {
            return;
          }

          final errorMessage = error is FirestoreException
              ? error.message
              : 'Failed to load driver data.';

          _state = ViewState.error(errorMessage, error: error);
          notifyListeners();
        },
      );
    } catch (e) {
      if (_isDisposed) return;
      _state = const ViewState.error('Failed to initialize driver data stream.');
      notifyListeners();
    }
  }

  /// Stops listening to the driver data stream.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    if (!_isDisposed && !_state.isInitial) {
      _state = const ViewState.initial();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authController.removeListener(_onAuthChanged);
    _subscription?.cancel();
    super.dispose();
  }
}

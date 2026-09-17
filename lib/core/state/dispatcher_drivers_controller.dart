import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/driver_operational_data.dart';
import '../../models/user_model.dart';
import '../../services/driver_data_service.dart';
import 'auth_controller.dart';
import 'view_state.dart';

enum DriverFilter {
  all,
  online,
  offline,
  available,
  onActiveRide,
  unionVerified,
  pendingVerification,
}

/// Controller for monitoring and filtering all drivers for dispatchers.
/// 
/// Note: The underlying `DriverDataService` currently only watches *online* drivers 
/// in PR 39. To show *all* drivers, we may need a slightly different query or 
/// we adapt `DriverDataService` to stream all drivers.
/// Wait, `DriverDataService.watchOnlineDriversData()` was specific to PR 39/40 dispatch candidates.
/// Let's use `DriverDataService.watchAllDriversData()` if we build it, or for now we'll 
/// just implement the local filter and search logic on whatever stream we can get.
class DispatcherDriversController extends ChangeNotifier {
  final DriverDataService _driverDataService;
  final AuthController _authController;

  StreamSubscription<List<DriverOperationalData>>? _subscription;
  ViewState<List<DriverOperationalData>> _state = const ViewState.initial();
  
  List<DriverOperationalData> _allDrivers = [];
  
  bool _isDisposed = false;
  int? _sessionGeneration;

  // Local UI State
  DriverFilter _currentFilter = DriverFilter.all;
  String _searchQuery = '';

  DispatcherDriversController({
    DriverDataService? driverDataService,
    AuthController? authController,
  })  : _driverDataService = driverDataService ?? DriverDataService(),
        _authController = authController ?? AuthController.instance {
    _init();
  }

  ViewState<List<DriverOperationalData>> get state => _state;
  DriverFilter get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;

  void setFilter(DriverFilter filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      _applyFilters();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFilters();
    }
  }

  void _init() {
    _authController.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  void _onAuthChanged() {
    if (_isDisposed) return;
    
    if (!_authController.isAuthenticated || _authController.currentUser?.role != UserRole.dispatcher && _authController.currentUser?.role != UserRole.admin) {
      _stopListening();
      return;
    }

    if (_sessionGeneration != _authController.sessionGeneration) {
      _sessionGeneration = _authController.sessionGeneration;
      _startListening();
    }
  }

  void _startListening() {
    _stopListening();
    _setState(const ViewState.loading(message: 'Loading drivers...'));

    final currentSession = _sessionGeneration;

    try {
      // NOTE: We need DriverDataService to expose watchAllDriversData() for the dispatcher.
      // If it only exposes watchOnlineDriversData(), we'll use that for now and modify DriverDataService later.
      _subscription = _driverDataService.watchAllDriversData().listen(
        (drivers) {
          if (_isDisposed || _sessionGeneration != currentSession) return;
          _allDrivers = drivers;
          _applyFilters();
        },
        onError: (error) {
          if (_isDisposed || _sessionGeneration != currentSession) return;
          _setState(ViewState.error('Failed to load drivers', error: error));
        },
      );
    } catch (e) {
      if (_isDisposed || _sessionGeneration != currentSession) return;
      _setState(ViewState.error('Failed to initialize drivers stream', error: e));
    }
  }

  void _applyFilters() {
    if (_isDisposed) return;
    
    var filtered = _allDrivers;

    // Apply Filter
    switch (_currentFilter) {
      case DriverFilter.online:
        filtered = filtered.where((d) => d.isOnline).toList();
        break;
      case DriverFilter.offline:
        filtered = filtered.where((d) => !d.isOnline).toList();
        break;
      case DriverFilter.available:
        filtered = filtered.where((d) => d.isOnline && d.activeRideId == null).toList();
        break;
      case DriverFilter.onActiveRide:
        filtered = filtered.where((d) => d.activeRideId != null).toList();
        break;
      case DriverFilter.unionVerified:
        filtered = filtered.where((d) => d.isUnionVerified).toList();
        break;
      case DriverFilter.pendingVerification:
        filtered = filtered.where((d) => !d.isUnionVerified).toList();
        break;
      case DriverFilter.all:

    }

    // Apply Search
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((d) {
        final nameMatch = d.name.toLowerCase().contains(query);
        final phoneMatch = d.phoneNumber.contains(query);
        final vehicleMatch = d.vehicleInfo?.toLowerCase().contains(query) ?? false;
        return nameMatch || phoneMatch || vehicleMatch;
      }).toList();
    }

    if (filtered.isEmpty) {
      if (_allDrivers.isEmpty) {
        _setState(const ViewState.empty(message: 'No drivers found.'));
      } else {
        _setState(const ViewState.empty(message: 'No drivers match your filters.'));
      }
    } else {
      _setState(ViewState.success(filtered));
    }
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
    if (!_isDisposed) {
      _setState(const ViewState.initial());
      _allDrivers = [];
    }
  }

  void _setState(ViewState<List<DriverOperationalData>> newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  void retry() {
    if (_authController.isAuthenticated) {
      _startListening();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authController.removeListener(_onAuthChanged);
    _stopListening();
    super.dispose();
  }
}

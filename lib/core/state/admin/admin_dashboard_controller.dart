import 'dart:async';
import 'package:flutter/material.dart';
import '../view_state.dart';
import '../../../models/ride_model.dart';
import '../../../models/user_model.dart';
import '../../../services/admin_service.dart';

/// Real-time dashboard controller providing live platform health metrics.
class AdminDashboardController extends ChangeNotifier {
  final AdminService _service;

  ViewState<Map<String, int>> _counts = const ViewState.initial();
  ViewState<List<RideModel>> _pendingRides = const ViewState.initial();
  ViewState<List<RideModel>> _activeRides = const ViewState.initial();
  ViewState<List<UserModel>> _onlineDrivers = const ViewState.initial();

  StreamSubscription? _pendingSub;
  StreamSubscription? _activeSub;
  StreamSubscription? _driversSub;

  ViewState<Map<String, int>> get counts => _counts;
  ViewState<List<RideModel>> get pendingRides => _pendingRides;
  ViewState<List<RideModel>> get activeRides => _activeRides;
  ViewState<List<UserModel>> get onlineDrivers => _onlineDrivers;

  AdminDashboardController({AdminService? service})
      : _service = service ?? AdminService() {
    _init();
  }

  void _init() {
    _loadCounts();
    _subscribePending();
    _subscribeActive();
    _subscribeDrivers();
  }

  Future<void> _loadCounts() async {
    _counts = const ViewState.loading();
    notifyListeners();
    try {
      final data = await _service.getDashboardCounts();
      _counts = ViewState.success(data);
    } catch (e) {
      _counts = ViewState.error(e.toString());
    }
    notifyListeners();
  }

  void _subscribePending() {
    _pendingRides = const ViewState.loading();
    _pendingSub = _service.watchPendingRides().listen(
      (rides) {
        _pendingRides = ViewState.success(rides);
        notifyListeners();
        _loadCounts(); // Refresh counts when rides change
      },
      onError: (e) {
        _pendingRides = ViewState.error(e.toString());
        notifyListeners();
      },
    );
  }

  void _subscribeActive() {
    _activeRides = const ViewState.loading();
    _activeSub = _service.watchActiveRides().listen(
      (rides) {
        _activeRides = ViewState.success(rides);
        notifyListeners();
      },
      onError: (e) {
        _activeRides = ViewState.error(e.toString());
        notifyListeners();
      },
    );
  }

  void _subscribeDrivers() {
    _driversSub = _service.watchAllDrivers().listen(
      (drivers) {
        _onlineDrivers = ViewState.success(drivers.where((d) => d.isOnline).toList());
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  Future<void> refresh() => _loadCounts();

  @override
  void dispose() {
    _pendingSub?.cancel();
    _activeSub?.cancel();
    _driversSub?.cancel();
    super.dispose();
  }
}

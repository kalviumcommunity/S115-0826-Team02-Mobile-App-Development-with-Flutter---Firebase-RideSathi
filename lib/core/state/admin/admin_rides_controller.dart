import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../view_state.dart';
import '../../../models/ride_model.dart';
import '../../../services/admin_service.dart';

/// Controller for paginated ride management with filter/search.
class AdminRidesController extends ChangeNotifier {
  final AdminService _service;

  ViewState<List<RideModel>> _rides = const ViewState.initial();
  RideStatus? _activeFilter;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  static const int _pageSize = 20;

  ViewState<List<RideModel>> get rides => _rides;
  RideStatus? get activeFilter => _activeFilter;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  AdminRidesController({AdminService? service})
      : _service = service ?? AdminService() {
    load();
  }

  Future<void> load({RideStatus? status}) async {
    _activeFilter = status;
    _lastDoc = null;
    _hasMore = true;
    _rides = const ViewState.loading();
    notifyListeners();
    try {
      final results = await _service.getRidesPaginated(status: status, limit: _pageSize);
      _rides = ViewState.success(results);
      _hasMore = results.length == _pageSize;
    } catch (e) {
      _rides = ViewState.error(e.toString());
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final more = await _service.getRidesPaginated(
        status: _activeFilter,
        limit: _pageSize,
        startAfter: _lastDoc,
      );
      final current = _rides.data ?? [];
      _rides = ViewState.success([...current, ...more]);
      _hasMore = more.length == _pageSize;
    } catch (_) {}
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> cancelRide(String rideId, String adminId, String reason) async {
    try {
      await _service.adminCancelRide(rideId: rideId, adminId: adminId, reason: reason);
      await load(status: _activeFilter);
    } catch (e) {
      _rides = ViewState.error(e.toString());
      notifyListeners();
      rethrow;
    }
  }

  Future<void> assignDriver(String rideId, String driverId, String adminId) async {
    await _service.adminAssignDriver(rideId: rideId, driverId: driverId, adminId: adminId);
    await load(status: _activeFilter);
  }

  Future<void> reassignDriver(String rideId, String newDriverId, String adminId, {String? reason}) async {
    await _service.adminReassignDriver(rideId: rideId, newDriverId: newDriverId, adminId: adminId, reason: reason);
    await load(status: _activeFilter);
  }
}

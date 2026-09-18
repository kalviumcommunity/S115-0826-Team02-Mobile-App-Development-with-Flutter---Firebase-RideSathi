import 'dart:async';
import 'package:flutter/material.dart';
import '../view_state.dart';
import '../../../models/user_model.dart';
import '../../../services/admin_service.dart';

/// Controller for managing driver list with real-time updates and admin actions.
class AdminDriversController extends ChangeNotifier {
  final AdminService _service;

  ViewState<List<UserModel>> _drivers = const ViewState.initial();
  StreamSubscription? _sub;
  String _searchQuery = '';
  bool? _onlineFilter;

  ViewState<List<UserModel>> get drivers => _drivers;
  String get searchQuery => _searchQuery;
  bool? get onlineFilter => _onlineFilter;

  List<UserModel> get filteredDrivers {
    final all = _drivers.data ?? [];
    return all.where((d) {
      final matchesSearch = _searchQuery.isEmpty ||
          d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.phoneNumber.contains(_searchQuery) ||
          (d.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesOnline = _onlineFilter == null || d.isOnline == _onlineFilter;
      return matchesSearch && matchesOnline;
    }).toList();
  }

  AdminDriversController({AdminService? service})
      : _service = service ?? AdminService() {
    _subscribe();
  }

  void _subscribe() {
    _drivers = const ViewState.loading();
    _sub = _service.watchAllDrivers().listen(
      (drivers) {
        _drivers = ViewState.success(drivers);
        notifyListeners();
      },
      onError: (e) {
        _drivers = ViewState.error(e.toString());
        notifyListeners();
      },
    );
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setOnlineFilter(bool? value) {
    _onlineFilter = value;
    notifyListeners();
  }

  Future<void> verifyDriver(String driverId, String adminId) async {
    await _service.verifyDriver(driverId: driverId, adminId: adminId);
  }

  Future<void> rejectDriver(String driverId, String adminId, {String? reason}) async {
    await _service.rejectDriverVerification(driverId: driverId, adminId: adminId, reason: reason);
  }

  Future<void> suspendDriver(String driverId, String adminId, String reason) async {
    await _service.suspendUser(userId: driverId, adminId: adminId, reason: reason, isDriver: true);
  }

  Future<void> reactivateDriver(String driverId, String adminId) async {
    await _service.reactivateUser(userId: driverId, adminId: adminId, isDriver: true);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../view_state.dart';
import '../../../models/user_model.dart';
import '../../../services/admin_service.dart';

/// Controller for managing rider list.
class AdminRidersController extends ChangeNotifier {
  final AdminService _service;
  ViewState<List<UserModel>> _riders = const ViewState.initial();
  StreamSubscription? _sub;
  String _searchQuery = '';

  ViewState<List<UserModel>> get riders => _riders;
  String get searchQuery => _searchQuery;

  List<UserModel> get filteredRiders {
    final all = _riders.data ?? [];
    if (_searchQuery.isEmpty) return all;
    return all.where((r) =>
      r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      r.phoneNumber.contains(_searchQuery) ||
      (r.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  AdminRidersController({AdminService? service})
      : _service = service ?? AdminService() {
    _subscribe();
  }

  void _subscribe() {
    _riders = const ViewState.loading();
    _sub = _service.watchAllRiders().listen(
      (riders) { _riders = ViewState.success(riders); notifyListeners(); },
      onError: (e) { _riders = ViewState.error(e.toString()); notifyListeners(); },
    );
  }

  void setSearch(String query) { _searchQuery = query; notifyListeners(); }

  Future<void> suspendRider(String riderId, String adminId, String reason) async {
    await _service.suspendUser(userId: riderId, adminId: adminId, reason: reason, isDriver: false);
  }

  Future<void> reactivateRider(String riderId, String adminId) async {
    await _service.reactivateUser(userId: riderId, adminId: adminId, isDriver: false);
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}

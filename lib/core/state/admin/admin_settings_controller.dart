import 'package:flutter/material.dart';
import '../view_state.dart';
import '../../../models/system_settings.dart';
import '../../../services/admin_service.dart';

/// Controller for reading and updating system-wide settings.
class AdminSettingsController extends ChangeNotifier {
  final AdminService _service;
  ViewState<SystemSettings> _settings = const ViewState.initial();
  bool _isSaving = false;

  ViewState<SystemSettings> get settings => _settings;
  bool get isSaving => _isSaving;

  AdminSettingsController({AdminService? service})
      : _service = service ?? AdminService() {
    load();
  }

  Future<void> load() async {
    _settings = const ViewState.loading();
    notifyListeners();
    try {
      final s = await _service.getSystemSettings();
      _settings = ViewState.success(s);
    } catch (e) {
      _settings = ViewState.error(e.toString());
    }
    notifyListeners();
  }

  Future<bool> updateSetting({
    required String adminId,
    required String key,
    required dynamic value,
  }) async {
    final current = _settings.data;
    if (current == null) return false;
    _isSaving = true;
    notifyListeners();
    try {
      final dynamic prev;
      final SystemSettings updated;
      switch (key) {
        case 'rideRequestTimeoutSeconds':
          prev = current.rideRequestTimeoutSeconds;
          updated = current.copyWith(rideRequestTimeoutSeconds: value as int);
        case 'matchingRadiusKm':
          prev = current.matchingRadiusKm;
          updated = current.copyWith(matchingRadiusKm: value as double);
        case 'maxCandidateCount':
          prev = current.maxCandidateCount;
          updated = current.copyWith(maxCandidateCount: value as int);
        case 'cancellationWindowSeconds':
          prev = current.cancellationWindowSeconds;
          updated = current.copyWith(cancellationWindowSeconds: value as int);
        default:
          _isSaving = false;
          notifyListeners();
          return false;
      }
      await _service.updateSystemSettings(
        settings: updated,
        adminId: adminId,
        changedKey: key,
        previousValue: prev,
        newValue: value,
      );
      _settings = ViewState.success(updated);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      rethrow;
    }
  }
}

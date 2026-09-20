import 'package:flutter/material.dart';
import '../view_state.dart';
import '../../../models/admin_audit_log.dart';
import '../../../services/admin_service.dart';

/// Controller for paginated audit log viewing.
class AdminAuditController extends ChangeNotifier {
  final AdminService _service;
  ViewState<List<AdminAuditLog>> _logs = const ViewState.initial();
  final bool _isLoadingMore = false;
  bool _hasMore = true;

  ViewState<List<AdminAuditLog>> get logs => _logs;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  AdminAuditController({AdminService? service})
      : _service = service ?? AdminService() {
    load();
  }

  Future<void> load() async {
    _logs = const ViewState.loading();
    _hasMore = true;
    notifyListeners();
    try {
      final results = await _service.getAuditLogs(limit: 30);
      _logs = ViewState.success(results);
      _hasMore = results.length == 30;
    } catch (e) {
      _logs = ViewState.error(e.toString());
    }
    notifyListeners();
  }
}

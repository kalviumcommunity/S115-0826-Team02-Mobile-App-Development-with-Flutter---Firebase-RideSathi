import 'package:flutter/foundation.dart';
import '../models/operational_analytics.dart';
import '../../services/operational_analytics_service.dart';
import '../../services/firestore_exception.dart';
import 'auth_controller.dart';
import 'view_state.dart';

enum AnalyticsTimeRange {
  today,
  last7Days,
  last30Days,
}

class OperationalAnalyticsController extends ChangeNotifier {
  final OperationalAnalyticsService _service;
  final AuthController _authController;

  ViewState<OperationalAnalytics> _state = const ViewState.initial();
  bool _isDisposed = false;

  AnalyticsTimeRange _currentRange = AnalyticsTimeRange.today;

  OperationalAnalyticsController({
    OperationalAnalyticsService? service,
    AuthController? authController,
  })  : _service = service ?? OperationalAnalyticsService(),
        _authController = authController ?? AuthController.instance;

  ViewState<OperationalAnalytics> get state => _state;
  AnalyticsTimeRange get currentRange => _currentRange;

  Future<void> loadAnalytics({bool refresh = false}) async {
    if (_isDisposed) return;
    if (!refresh && _state.isLoading) return;

    final currentGeneration = _authController.sessionGeneration;
    _setState(const ViewState.loading());

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (_currentRange) {
      case AnalyticsTimeRange.today:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case AnalyticsTimeRange.last7Days:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case AnalyticsTimeRange.last30Days:
        startDate = now.subtract(const Duration(days: 30));
        break;
    }

    try {
      final analytics = await _service.getAnalytics(
        startDate: startDate,
        endDate: endDate,
      );

      if (_isDisposed || _authController.sessionGeneration != currentGeneration) {
        return;
      }

      _setState(ViewState.success(analytics));
    } on FirestoreException catch (e) {
      if (_isDisposed || _authController.sessionGeneration != currentGeneration) return;
      _setState(ViewState.error(e.message));
    } catch (e) {
      if (_isDisposed || _authController.sessionGeneration != currentGeneration) return;
      _setState(const ViewState.error('An unexpected error occurred while loading analytics.'));
    }
  }

  void setTimeRange(AnalyticsTimeRange range) {
    if (_currentRange != range) {
      _currentRange = range;
      loadAnalytics(refresh: true);
    }
  }

  void _setState(ViewState<OperationalAnalytics> newState) {
    if (!_isDisposed && _state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ride_model.dart';
import '../../services/ride_service.dart';
import '../../services/firestore_exception.dart';
import 'auth_controller.dart';
import 'view_state.dart';

class DriverRideHistoryController extends ChangeNotifier {
  final RideService _rideService;
  final AuthController _authController;

  ViewState<List<RideModel>> _state = const ViewState.initial();
  bool _isDisposed = false;
  
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  final List<RideModel> _rides = [];
  bool _isLoadingMore = false;
  RideStatus? _currentStatusFilter;

  DriverRideHistoryController({
    RideService? rideService,
    AuthController? authController,
  })  : _rideService = rideService ?? RideService(),
        _authController = authController ?? AuthController.instance;

  ViewState<List<RideModel>> get state => _state;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  RideStatus? get currentStatusFilter => _currentStatusFilter;

  Future<void> loadHistory({bool refresh = false, RideStatus? status}) async {
    if (_isDisposed) return;
    
    if (status != _currentStatusFilter) {
      _currentStatusFilter = status;
      refresh = true;
    }

    if (refresh) {
      _hasMore = true;
      _lastDoc = null;
      _rides.clear();
      _setState(const ViewState.loading());
    } else {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
      notifyListeners();
    }

    final currentUser = _authController.currentUser;
    if (currentUser == null) {
      _setState(const ViewState.error('User is not authenticated.'));
      return;
    }

    final currentGeneration = _authController.sessionGeneration;

    try {
      final page = await _rideService.getDriverRideHistory(
        currentUser.id,
        limit: 20,
        startAfter: _lastDoc,
        status: _currentStatusFilter,
      );

      if (_isDisposed || _authController.sessionGeneration != currentGeneration) {
        return;
      }

      if (page.rides.isEmpty) {
        _hasMore = false;
      } else {
        _rides.addAll(page.rides);
        _lastDoc = page.lastDocument;
        _hasMore = page.rides.length == 20; 
      }

      _isLoadingMore = false;
      _setState(ViewState.success(List.unmodifiable(_rides)));
    } on FirestoreException catch (e) {
      if (_isDisposed || _authController.sessionGeneration != currentGeneration) return;
      _isLoadingMore = false;
      _setState(ViewState.error(e.message));
    } catch (e) {
      if (_isDisposed || _authController.sessionGeneration != currentGeneration) return;
      _isLoadingMore = false;
      _setState(const ViewState.error('An unexpected error occurred while loading history.'));
    }
  }

  void setFilter(RideStatus? status) {
    if (_currentStatusFilter != status) {
      loadHistory(refresh: true, status: status);
    }
  }

  void clear() {
    if (!_isDisposed) {
      _rides.clear();
      _lastDoc = null;
      _hasMore = true;
      _isLoadingMore = false;
      _currentStatusFilter = null;
      _setState(const ViewState.initial());
    }
  }

  void _setState(ViewState<List<RideModel>> newState) {
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

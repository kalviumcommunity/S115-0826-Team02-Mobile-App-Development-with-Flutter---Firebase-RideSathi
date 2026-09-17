import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ride_model.dart';
import '../../services/ride_service.dart';
import '../../services/firestore_exception.dart';
import 'auth_controller.dart';
import 'view_state.dart';

class DispatcherHistoryController extends ChangeNotifier {
  final RideService _rideService;
  final AuthController _authController;

  ViewState<List<RideModel>> _state = const ViewState.initial();
  bool _isDisposed = false;
  
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  final List<RideModel> _rides = [];
  bool _isLoadingMore = false;
  
  // Filters
  RideStatus? _statusFilter;
  String? _driverIdFilter;
  String? _riderIdFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Local Search (Applies over the fetched pages)
  String _searchQuery = '';
  List<RideModel> _filteredRides = [];

  DispatcherHistoryController({
    RideService? rideService,
    AuthController? authController,
  })  : _rideService = rideService ?? RideService(),
        _authController = authController ?? AuthController.instance;

  ViewState<List<RideModel>> get state => _state;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  
  RideStatus? get statusFilter => _statusFilter;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get searchQuery => _searchQuery;

  Future<void> loadHistory({bool refresh = false}) async {
    if (_isDisposed) return;
    
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

    final currentGeneration = _authController.sessionGeneration;

    try {
      final page = await _rideService.getDispatcherRideHistory(
        limit: 20,
        startAfter: _lastDoc,
        status: _statusFilter,
        driverId: _driverIdFilter,
        riderId: _riderIdFilter,
        startDate: _startDate,
        endDate: _endDate,
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
      _applyLocalSearch();
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

  void setFilters({
    RideStatus? status,
    String? driverId,
    String? riderId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _statusFilter = status;
    _driverIdFilter = driverId;
    _riderIdFilter = riderId;
    _startDate = startDate;
    _endDate = endDate;
    loadHistory(refresh: true);
  }
  
  void clearFilters() {
    _statusFilter = null;
    _driverIdFilter = null;
    _riderIdFilter = null;
    _startDate = null;
    _endDate = null;
    _searchQuery = '';
    loadHistory(refresh: true);
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyLocalSearch();
    }
  }

  void _applyLocalSearch() {
    if (_searchQuery.trim().isEmpty) {
      _filteredRides = List.unmodifiable(_rides);
    } else {
      final q = _searchQuery.trim().toLowerCase();
      _filteredRides = _rides.where((ride) {
        final pickupMatch = ride.pickup.displayName.toLowerCase().contains(q);
        final destMatch = ride.destination.displayName.toLowerCase().contains(q);
        final idMatch = ride.id.toLowerCase().contains(q);
        return pickupMatch || destMatch || idMatch;
      }).toList();
    }
    _setState(ViewState.success(List.unmodifiable(_filteredRides)));
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

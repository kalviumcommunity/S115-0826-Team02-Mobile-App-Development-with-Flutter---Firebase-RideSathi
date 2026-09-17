import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import 'auth_controller.dart';
import 'view_state.dart';

/// Controller for monitoring all active rides in the system for dispatchers.
class DispatcherActiveRidesController extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final AuthController _authController;

  StreamSubscription<List<RideModel>>? _subscription;
  ViewState<List<RideModel>> _state = const ViewState.initial();
  bool _isDisposed = false;
  int? _sessionGeneration;

  DispatcherActiveRidesController({
    FirebaseFirestore? firestore,
    AuthController? authController,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authController = authController ?? AuthController.instance {
    _init();
  }

  ViewState<List<RideModel>> get state => _state;

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
    _setState(const ViewState.loading(message: 'Loading active rides...'));

    final currentSession = _sessionGeneration;

    try {
      final activeStatuses = [
        RideStatus.accepted.name,
        RideStatus.arrived.name,
        RideStatus.inProgress.name,
      ];

      final stream = _firestore
          .collection('rides')
          .where('status', whereIn: activeStatuses)
          // We can't efficiently sort by updatedAt and filter by status without a composite index.
          // Since PR constraints say "do not invent indexes without verifying", we'll sort client-side.
          .snapshots()
          .map((snapshot) {
        final rides = snapshot.docs
            .map((doc) {
              try {
                return RideModel.fromMap(doc.data());
              } catch (e) {
                return null;
              }
            })
            .whereType<RideModel>()
            .toList();

        // Sort descending by updated/created time
        rides.sort((a, b) {
          final timeA = a.updatedAt ?? a.createdAt ?? DateTime.now();
          final timeB = b.updatedAt ?? b.createdAt ?? DateTime.now();
          return timeB.compareTo(timeA);
        });

        return rides;
      });

      _subscription = stream.listen(
        (rides) {
          if (_isDisposed || _sessionGeneration != currentSession) return;
          if (rides.isEmpty) {
            _setState(const ViewState.empty(message: 'No active rides found.'));
          } else {
            _setState(ViewState.success(rides));
          }
        },
        onError: (error) {
          if (_isDisposed || _sessionGeneration != currentSession) return;
          _setState(ViewState.error('Failed to load active rides', error: error));
        },
      );
    } catch (e) {
      if (_isDisposed || _sessionGeneration != currentSession) return;
      _setState(ViewState.error('Failed to initialize active rides stream', error: e));
    }
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
    if (!_isDisposed) {
      _setState(const ViewState.initial());
    }
  }

  void _setState(ViewState<List<RideModel>> newState) {
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

import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/active_ride_controller.dart';
import '../../core/state/auth_controller.dart';
import '../../core/state/incoming_ride_requests_controller.dart';
import '../../core/state/ride_acceptance_controller.dart';
import '../../core/state/ride_rejection_controller.dart';
import '../../core/state/driver_availability_controller.dart';
import '../../core/theme/theme_controller.dart';

import '../../models/user_model.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/real_location_service.dart';

/// Landing and dashboard screen for authenticated Drivers in RideSathi.
///
/// Displays driver identity, vehicle details, availability status (Online/Offline),
/// incoming ride request queue, and supports clean logout with navigation stack clearing.
class DriverHomeScreen extends StatefulWidget {
  /// Optional [AuthController] for dependency injection in tests.
  final AuthController? authController;

  /// Optional [IncomingRideRequestsController] for dependency injection in tests.
  final IncomingRideRequestsController? requestsController;

  /// Optional [RideAcceptanceController] for dependency injection in tests.
  final RideAcceptanceController? acceptanceController;

  /// Optional [RideRejectionController] for dependency injection in tests.
  final RideRejectionController? rejectionController;

  /// Optional [DriverAvailabilityController] for dependency injection in tests.
  final DriverAvailabilityController? availabilityController;

  /// Optional [UserModel] for explicit user identity passing.
  final UserModel? user;

  const DriverHomeScreen({
    super.key,
    this.authController,
    this.requestsController,
    this.acceptanceController,
    this.rejectionController,
    this.availabilityController,
    this.user,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  late final AuthController _authController;
  late final IncomingRideRequestsController _requestsController;
  late final RideAcceptanceController _acceptanceController;
  late final RideRejectionController _rejectionController;
  late final ActiveRideController _activeRideController;
  late final DriverAvailabilityController _availabilityController;
  bool _isLoggingOut = false;
  bool _ownsRequestsController = false;
  bool _ownsAcceptanceController = false;
  bool _ownsRejectionController = false;

  
  final MapController _mapController = MapController();
  final RealLocationService _locationService = RealLocationService();
  LatLng _mapCenter = const LatLng(28.6139, 77.2090);
  bool _isMapInitialized = false;


  @override
  void initState() {
    super.initState();
    _authController = widget.authController ?? AuthController.instance;
    
    if (widget.requestsController != null) {
      _requestsController = widget.requestsController!;
      _ownsRequestsController = false;
    } else {
      _requestsController = IncomingRideRequestsController(
        authController: _authController,
      );
      _ownsRequestsController = true;
    }
    if (widget.acceptanceController != null) {
      _acceptanceController = widget.acceptanceController!;
      _ownsAcceptanceController = false;
    } else {
      _acceptanceController = RideAcceptanceController(
        authController: _authController,
        requestsController: _requestsController,
      );
      _ownsAcceptanceController = true;
    }

    if (widget.rejectionController != null) {
      _rejectionController = widget.rejectionController!;
      _ownsRejectionController = false;
    } else {
      _rejectionController = RideRejectionController(
        authController: _authController,
        requestsController: _requestsController,
      );
      _ownsRejectionController = true;
    }

    // ActiveRideController is always owned by this screen; used for the banner
    _activeRideController = ActiveRideController(authController: _authController)
      ..startListening();

    _acceptanceController.addListener(_onAcceptanceStateChanged);
    _rejectionController.addListener(_onRejectionStateChanged);

    _availabilityController = widget.availabilityController ??
        DriverAvailabilityController(authController: _authController);

    _availabilityController.addListener(_onAvailabilityStateChanged);
    _initLocation();
  }

  
  Future<void> _initLocation() async {
    try {
      final loc = await _locationService.getCurrentLocation();
      if (!mounted) return;
      final ll = LatLng(loc.latitude ?? 28.6139, loc.longitude ?? 77.2090);
      setState(() { _mapCenter = ll; _isMapInitialized = true; });
      _mapController.move(ll, 15.0);
    } catch (_) {
      if (mounted) setState(() => _isMapInitialized = true);
    }
  }


  void _onRejectionStateChanged() {
    final state = _rejectionController.state;
    if (state.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message ?? 'Ride rejected.'),
        ),
      );
    } else if (state.isError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message ?? 'Failed to reject ride.'),
          backgroundColor: Colors.red,
        ),
      );
      _rejectionController.clearError();
    }
  }

  void _onAcceptanceStateChanged() {
    final state = _acceptanceController.state;
    if (state.isSuccess) {
      // Navigate to Active Ride screen after successful acceptance
      if (mounted) {
        AppNavigator.toDriverActiveRide(context);
      }
    } else if (state.isError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message ?? 'Failed to accept ride.'),
            backgroundColor: Colors.red,
          ),
        );
        _acceptanceController.clearError();
      }
    }
  }

  @override
  void dispose() {
    _acceptanceController.removeListener(_onAcceptanceStateChanged);
    _rejectionController.removeListener(_onRejectionStateChanged);
    if (_ownsAcceptanceController) {
      _acceptanceController.dispose();
    }
    if (_ownsRejectionController) {
      _rejectionController.dispose();
    }
    _availabilityController.removeListener(_onAvailabilityStateChanged);
    if (widget.availabilityController == null) {
      _availabilityController.dispose();
    }
    if (_ownsRequestsController) {
      _requestsController.dispose();
    }
    _activeRideController.dispose();
    super.dispose();
  }

  void _onAvailabilityStateChanged() {
    if (!mounted) return;
    
    // Sync the local requests controller with the backend-verified availability state
    _requestsController.setOnline(_availabilityController.isOnline);

    if (_availabilityController.state.isError) {
      final errorMessage = _availabilityController.errorMessage ??
          'Failed to update availability.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _availabilityController.toggleAvailability(),
          ),
        ),
      );
      _availabilityController.clearError();
    } else {
      setState(() {});
    }
  }

  Future<void> _handleToggleAvailability() async {
    await _availabilityController.toggleAvailability();
  }

  UserModel? get _currentUser => widget.user ?? _authController.currentUser;

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    _requestsController.setOnline(false);

    final success = await _authController.signOut();

    if (!mounted) return;
    setState(() => _isLoggingOut = false);

    if (success) {
      AppNavigator.logout(context);
    } else {
      final errorMessage = _authController.errorMessage ??
          'Unable to sign out. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _handleLogout,
          ),
        ),
      );
      _authController.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _authController,
      builder: (context, _) {
        final authState = _authController.state;
        
        if (authState.isAuthenticating) {
          return const Scaffold(
            body: Center(child: LoadingView(message: 'Loading driver profile...')),
          );
        }

        final user = _currentUser;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('RideSathi Driver')),
            body: ErrorView(
              message: 'Unable to resolve authenticated driver information. Please log in again.',
              onRetry: _handleLogout,
            ),
          );
        }

        if (user.role != UserRole.driver) {
          return Scaffold(
            appBar: AppBar(title: const Text('Access Restricted')),
            body: ErrorView(
              message: 'You must be registered as a driver to access the driver console.',
              onRetry: _handleLogout,
            ),
          );
        }

        final isVerified = user.isUnionVerified;

        return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${AppConstants.appName} Driver',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (isVerified)
              Text(
                'Union Verified',
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.green),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: ThemeController.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => AppNavigator.toProfile(context),
          ),
          IconButton(
            icon: _isLoggingOut
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.logout),
            onPressed: _isLoggingOut ? null : _handleLogout,
          ),
        ],
      ),
      body: SizedBox.expand(
        child: Stack(
        children: [
          
          Positioned.fill(
            child: !_isMapInitialized
                ? Container(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE8EAF0), child: const Center(child: CircularProgressIndicator()))
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(initialCenter: _mapCenter, initialZoom: 15.0),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.ridesathi.ridesathi',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _mapCenter,
                            width: 60, height: 60,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), shape: BoxShape.circle)),
                                Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.3), shape: BoxShape.circle)),
                                Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Prominent Availability Toggle Header overlay
                Container(
                  margin: const EdgeInsets.all(AppConstants.spaceM),
                  padding: const EdgeInsets.all(AppConstants.spaceL),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _availabilityController.isOnline ? 'Online & Ready' : 'Offline',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _availabilityController.isOnline ? Colors.green : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _availabilityController.isOnline,
                        onChanged: _availabilityController.isUpdating
                            ? null
                            : (val) => _handleToggleAvailability(),
                        activeThumbColor: Colors.green,
                        activeTrackColor: Colors.green.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: AnimatedBuilder(
                    animation: _requestsController,
                    builder: (context, _) {
                      if (!_requestsController.isOnline) {
                        return const SizedBox.shrink(); // Show full map when offline
                      }

                      final state = _requestsController.state;
                      
                      if (state.isEmpty || state.data == null || state.data!.isEmpty) {
                        return const SizedBox.shrink(); // Show full map when waiting for requests
                      }

                      final requests = state.data!;
                      
                      // Show requests in a horizontal scrollable list or bottom sheet
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 300,
                          margin: const EdgeInsets.only(bottom: AppConstants.spaceM),
                          child: PageView.builder(
                            itemCount: requests.length,
                            controller: PageController(viewportFraction: 0.9),
                            itemBuilder: (context, index) {
                              final ride = requests[index];
                              return Card(
                                elevation: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                shadowColor: Colors.black26,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primaryContainer,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '₹${ride.estimatedFare.toStringAsFixed(0)}',
                                              style: theme.textTheme.titleLarge?.copyWith(
                                                color: theme.colorScheme.onPrimaryContainer,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'New Request',
                                            style: theme.textTheme.labelMedium?.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          const Icon(Icons.my_location, size: 20, color: Colors.blue),
                                          const SizedBox(width: 12),
                                          Expanded(child: Text(ride.pickup.address.isEmpty ? 'Pending' : ride.pickup.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                                        ],
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(left: 9),
                                        child: SizedBox(height: 16, child: VerticalDivider(width: 2, color: Colors.grey)),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 20, color: Colors.red),
                                          const SizedBox(width: 12),
                                          Expanded(child: Text(ride.destination.address.isEmpty ? 'Pending' : ride.destination.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                                        ],
                                      ),
                                      const Spacer(),
                                      // Countdown timer bar
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 1.0, end: 0.0),
                                        duration: const Duration(seconds: 15),
                                        builder: (context, value, child) {
                                          return Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text('Accept in s', style: TextStyle(color: value < 0.3 ? Colors.red : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              LinearProgressIndicator(
                                                value: value,
                                                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                                valueColor: AlwaysStoppedAnimation(value < 0.3 ? Colors.red : const Color(0xFFF59E0B)),
                                                borderRadius: BorderRadius.circular(4),
                                                minHeight: 4,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      AnimatedBuilder(
                                        animation: Listenable.merge([_acceptanceController, _rejectionController]),
                                        builder: (context, _) {
                                          final isAccepting = _acceptanceController.state.isLoading;
                                          final isRejecting = _rejectionController.state.isLoading;
                                          final isBusy = isAccepting || isRejecting;

                                          return Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: isBusy ? null : () => _rejectionController.rejectRide(ride.id),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                    side: const BorderSide(color: Colors.red),
                                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                  ),
                                                  child: isRejecting 
                                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                                      : const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: isBusy ? null : () => _acceptanceController.acceptRide(ride.id),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.black,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                  ),
                                                  child: isAccepting
                                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                      : const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
      },
    );
  }
}

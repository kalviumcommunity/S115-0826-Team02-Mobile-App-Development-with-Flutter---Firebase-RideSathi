import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/state/auth_controller.dart';
import '../../core/state/dispatcher_active_rides_controller.dart';
import '../../core/state/dispatcher_drivers_controller.dart';
import '../../core/state/dispatcher_requested_rides_controller.dart';
import '../../models/user_model.dart';
import '../../models/ride_model.dart';
import '../../models/driver_operational_data.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_badge.dart';
import '../../core/routes/app_routes.dart';
import 'dispatcher_history_screen.dart';
import 'dispatcher_analytics_screen.dart';

class DispatcherHomeScreen extends StatefulWidget {
  final AuthController authController;
  final UserModel? user;

  const DispatcherHomeScreen({
    super.key,
    required this.authController,
    this.user,
  });

  @override
  State<DispatcherHomeScreen> createState() => _DispatcherHomeScreenState();
}

class _DispatcherHomeScreenState extends State<DispatcherHomeScreen> {
  int _currentIndex = 0;
  
  late final DispatcherRequestedRidesController _requestedRidesController;
  late final DispatcherActiveRidesController _activeRidesController;
  late final DispatcherDriversController _driversController;

  @override
  void initState() {
    super.initState();
    _requestedRidesController = DispatcherRequestedRidesController();
    _activeRidesController = DispatcherActiveRidesController();
    _driversController = DispatcherDriversController();

    _requestedRidesController.addListener(_onStateChanged);
    _activeRidesController.addListener(_onStateChanged);
    _driversController.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _requestedRidesController.removeListener(_onStateChanged);
    _activeRidesController.removeListener(_onStateChanged);
    _driversController.removeListener(_onStateChanged);
    
    _requestedRidesController.dispose();
    _activeRidesController.dispose();
    _driversController.dispose();
    super.dispose();
  }

  void _logout() async {
    await widget.authController.signOut();
    if (mounted) {
      AppNavigator.toLogin(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatcher Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildRequestedRidesTab(),
          _buildActiveRidesTab(),
          _buildDriversTab(),
          const DispatcherHistoryScreen(),
          const DispatcherAnalyticsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_rounded),
            label: 'Requested',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_rounded),
            label: 'Active',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_rounded),
            label: 'Drivers',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_rounded),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: Requested Rides
  // ==========================================
  Widget _buildRequestedRidesTab() {
    return _requestedRidesController.state.when(
      initial: () => const LoadingView(message: 'Initializing...'),
      loading: (msg) => LoadingView(message: msg),
      error: (msg, code, err) => ErrorView(
        message: msg,
        onRetry: _requestedRidesController.retry,
      ),
      empty: (msg) => EmptyStateView(
        icon: Icons.search_off_rounded,
        message: msg,
      ),
      success: (rides) {
        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.spaceM),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final ride = rides[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppConstants.spaceM),
              child: ListTile(
                title: Text('Ride: ${ride.id.substring(0, 8)}...'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pickup: ${ride.pickup.displayName}'),
                    Text('Destination: ${ride.destination.displayName}'),
                    const SizedBox(height: AppConstants.spaceS),
                    Text('Created: ${ride.createdAt?.toLocal().toString().split('.').first ?? "Unknown"}'),
                  ],
                ),
                trailing: StatusBadge(status: ride.status),
                onTap: () {
                  AppNavigator.pushNamed(
                    context, 
                    AppRoutes.dispatcherCandidates,
                    arguments: ride,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // TAB 2: Active Rides
  // ==========================================
  Widget _buildActiveRidesTab() {
    return _activeRidesController.state.when(
      initial: () => const LoadingView(message: 'Initializing...'),
      loading: (msg) => LoadingView(message: msg),
      error: (msg, code, err) => ErrorView(
        message: msg,
        onRetry: _activeRidesController.retry,
      ),
      empty: (msg) => EmptyStateView(
        icon: Icons.check_circle_outline_rounded,
        message: msg,
      ),
      success: (rides) {
        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.spaceM),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final ride = rides[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppConstants.spaceM),
              child: ListTile(
                title: Text('Driver: ${ride.driverId ?? "Unknown"}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pickup: ${ride.pickup.displayName}'),
                    Text('Destination: ${ride.destination.displayName}'),
                    Text('Updated: ${ride.updatedAt?.toLocal().toString().split('.').first ?? "Unknown"}'),
                  ],
                ),
                trailing: StatusBadge(status: ride.status),
                onTap: () {
                  // We will implement DispatcherRideDetailScreen later and route to it.
                  // For now, it's a placeholder.
                  _showActiveRideDetails(ride);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showActiveRideDetails(RideModel ride) {
    // A simple dialog for now, can be extracted to a full screen if needed.
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Active Ride Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ride ID: ${ride.id}'),
                Text('Status: ${ride.status.name}'),
                const Divider(),
                Text('Pickup: ${ride.pickup.displayName}'),
                Text('Destination: ${ride.destination.displayName}'),
                const Divider(),
                Text('Rider ID: ${ride.riderId}'),
                Text('Driver ID: ${ride.driverId ?? "None"}'),
                Text('Vehicle Type: ${ride.vehicleType.name}'),
                Text('Fare: ${ride.estimatedFare}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                AppNavigator.pushNamed(
                  context,
                  AppRoutes.dispatcherCandidates,
                  arguments: {
                    'ride': ride,
                    'isReassignment': true,
                    'currentDriverId': ride.driverId,
                  },
                );
              },
              child: const Text('Reassign Driver'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // TAB 3: Drivers Management
  // ==========================================
  Widget _buildDriversTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.spaceM),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by name, phone, or vehicle...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
            ),
            onChanged: (value) => _driversController.setSearchQuery(value),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
          child: Row(
            children: DriverFilter.values.map((filter) {
              final isSelected = _driversController.currentFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: AppConstants.spaceS),
                child: FilterChip(
                  label: Text(_formatDriverFilter(filter)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) _driversController.setFilter(filter);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(),
        Expanded(
          child: _driversController.state.when(
            initial: () => const LoadingView(message: 'Initializing...'),
            loading: (msg) => LoadingView(message: msg),
            error: (msg, code, err) => ErrorView(
              message: msg,
              onRetry: _driversController.retry,
            ),
            empty: (msg) => EmptyStateView(
              icon: Icons.group_off_rounded,
              message: msg,
            ),
            success: (drivers) {
              return ListView.builder(
                padding: const EdgeInsets.all(AppConstants.spaceM),
                itemCount: drivers.length,
                itemBuilder: (context, index) {
                  final driver = drivers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppConstants.spaceM),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: driver.isOnline ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                        child: Icon(
                          driver.isOnline ? Icons.person : Icons.person_off,
                          color: driver.isOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                      title: Text(driver.name),
                      subtitle: Text(driver.vehicleInfo ?? 'Unknown vehicle'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (driver.activeRideId != null)
                            const Text('On Active Ride', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold))
                          else if (driver.isOnline)
                            const Text('Available', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold))
                          else
                            const Text('Offline', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                          
                          if (driver.isUnionVerified)
                            const Icon(Icons.verified, size: 16, color: Colors.blue)
                        ],
                      ),
                      onTap: () => _showDriverDetails(driver),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDriverDetails(DriverOperationalData driver) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(driver.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Phone: ${driver.phoneNumber}'),
                Text('Vehicle: ${driver.vehicleInfo ?? "None"}'),
                Text('Union Verified: ${driver.isUnionVerified ? "Yes" : "No"}'),
                const Divider(),
                Text('Status: ${driver.isOnline ? "Online" : "Offline"}'),
                Text('Active Ride ID: ${driver.activeRideId ?? "None"}'),
                Text('Last Updated: ${driver.availabilityUpdatedAt?.toLocal().toString().split('.').first ?? "Unknown"}'),
                const Divider(),
                if (driver.location != null) ...[
                  Text('Location: ${driver.location!.latitude.toStringAsFixed(4)}, ${driver.location!.longitude.toStringAsFixed(4)}'),
                  Text('Location Timestamp: ${driver.location!.timestamp.toLocal().toString().split('.').first}'),
                ] else ...[
                  const Text('Location: Not available'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatDriverFilter(DriverFilter filter) {
    switch (filter) {
      case DriverFilter.all: return 'All';
      case DriverFilter.online: return 'Online';
      case DriverFilter.offline: return 'Offline';
      case DriverFilter.available: return 'Available';
      case DriverFilter.onActiveRide: return 'On Ride';
      case DriverFilter.unionVerified: return 'Verified';
      case DriverFilter.pendingVerification: return 'Pending';
    }
  }
}

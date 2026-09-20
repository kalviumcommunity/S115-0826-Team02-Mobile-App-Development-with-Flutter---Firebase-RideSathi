import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/ride_status_controller.dart';
import '../../core/state/ride_cancellation_controller.dart';
import '../../models/ride_model.dart';
import '../../widgets/driver_information_view.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../services/route_service.dart';

class RideStatusScreen extends StatefulWidget {
  final String rideId;
  const RideStatusScreen({super.key, required this.rideId});
  @override
  State<RideStatusScreen> createState() => _RideStatusScreenState();
}

class _RideStatusScreenState extends State<RideStatusScreen> {
  late final RideStatusController _statusController;
  late final RideCancellationController _cancellationController;
  
  final MapController _mapController = MapController();
  final RouteService _routeService = RouteService();
  RouteResult? _routeResult;
  bool _isRouting = false;
  String? _lastLoadedRideId;

  @override
  void initState() {
    super.initState();
    _statusController = RideStatusController(rideId: widget.rideId);
    _statusController.addListener(_onStatusChange);
    _cancellationController = RideCancellationController();
  }

  void _onStatusChange() {
    final state = _statusController.state;
    if (state.isSuccess && state.data != null) {
      final ride = state.data!;
      if (_lastLoadedRideId != ride.id) {
        _lastLoadedRideId = ride.id;
        _calculateRouteAndFit(ride);
      }
    }
  }

  Future<void> _calculateRouteAndFit(RideModel ride) async {
    if (ride.pickup.latitude == null || ride.destination.latitude == null) return;
    
    setState(() => _isRouting = true);
    
    try {
      final origin = LatLng(ride.pickup.latitude!, ride.pickup.longitude!);
      final dest = LatLng(ride.destination.latitude!, ride.destination.longitude!);
      
      final result = await _routeService.getRoute(origin: origin, destination: dest);
      
      if (!mounted) return;
      setState(() {
        _routeResult = result;
        _isRouting = false;
      });
      _fitBounds(origin, dest);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRouting = false);
      _fitBounds(LatLng(ride.pickup.latitude!, ride.pickup.longitude!), LatLng(ride.destination.latitude!, ride.destination.longitude!));
    }
  }

  void _fitBounds(LatLng p1, LatLng p2) {
    List<LatLng> boundsPoints = [p1, p2];
    if (_routeResult != null && _routeResult!.points.isNotEmpty) {
      boundsPoints = _routeResult!.points;
    }
    
    final bounds = LatLngBounds.fromPoints(boundsPoints);
    _mapController.fitCamera(CameraFit.bounds(
      bounds: bounds,
      padding: const EdgeInsets.only(top: 80.0, left: 60.0, right: 60.0, bottom: 420.0),
    ));
  }

  @override
  void dispose() {
    _statusController.removeListener(_onStatusChange);
    _statusController.dispose();
    _cancellationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: ListenableBuilder(
        listenable: _statusController,
        builder: (context, _) {
          final state = _statusController.state;

          if (state.isLoading || state.isInitial) {
            return Stack(children: [
              _buildMapBackground(null, isDark),
              const Center(child: CircularProgressIndicator()),
            ]);
          }

          if (state.isError) {
            return Stack(children: [
              _buildMapBackground(null, isDark),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.message ?? 'Failed to load ride.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: () => AppNavigator.pushNamedAndRemoveUntil(context, AppRoutes.riderHome, (_) => false), child: const Text('Return Home')),
                  ]),
                ),
              ),
            ]);
          }

          if (state.isSuccess && state.data != null) {
            return _buildContent(context, state.data!, isDark);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMapBackground(RideModel? ride, bool isDark) {
    // Use pickup location if available
    LatLng center = const LatLng(28.6139, 77.2090);
    if (ride?.pickup.latitude != null && ride?.pickup.longitude != null) {
      center = LatLng(ride!.pickup.latitude!, ride.pickup.longitude!);
    }

    return Positioned.fill(
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: center, initialZoom: 14.0, interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag)),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.ridesathi.ridesathi'),
          if (_routeResult != null && _routeResult!.points.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline<Object>(
                  points: _routeResult!.points,
                  color: Colors.black,
                  strokeWidth: 5.0,
                  strokeJoin: StrokeJoin.round,
                  strokeCap: StrokeCap.round,
                ),
              ],
            ),
          if (ride != null) MarkerLayer(markers: [
            if (ride.pickup.latitude != null)
              Marker(point: LatLng(ride.pickup.latitude!, ride.pickup.longitude!), width: 36, height: 36,
                child: Stack(alignment: Alignment.center, children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), shape: BoxShape.circle)),
                  Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                ]),
              ),
            if (ride.destination.latitude != null)
              Marker(point: LatLng(ride.destination.latitude!, ride.destination.longitude!), width: 36, height: 36,
                child: const Icon(Icons.location_on, color: Colors.red, size: 36)),
          ]),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, RideModel ride, bool isDark) {
    final (statusMessage, statusIcon, statusColor) = _getStatusInfo(ride.status);
    final isTerminal = [RideStatus.completed, RideStatus.cancelled, RideStatus.timedOut, RideStatus.rejected].contains(ride.status);
    final isError = [RideStatus.cancelled, RideStatus.timedOut, RideStatus.rejected].contains(ride.status);

    return Stack(
      children: [
        // Map background
        _buildMapBackground(ride, isDark),

        // Gradient overlay at bottom
        Positioned(
          left: 0, right: 0, bottom: 0,
          height: MediaQuery.of(context).size.height * 0.55,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, isDark ? const Color(0xF0111827) : const Color(0xF0FFFFFF)],
                stops: const [0.0, 0.35],
              ),
            ),
          ),
        ),

        // Safe area content
        SafeArea(
          child: Column(
            children: [
              // Top status pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xE0111827) : Colors.white.withValues(alpha: 0.93),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12)],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (ride.status == RideStatus.requested)
                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 10),
                    Text(statusMessage, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: statusColor)),
                  ]),
                ),
              ),

              const Spacer(),

              // Bottom panel
              Container(
                margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, -4))],
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Handle
                  Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),

                  // Route display
                  _routeRow(Icons.my_location_rounded, Colors.blue, ride.pickup.displayName, ride.pickup.address, isDark),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Container(width: 2, height: 20, color: isDark ? Colors.white24 : Colors.black12),
                  ),
                  _routeRow(Icons.location_on_rounded, Colors.red, ride.destination.displayName, ride.destination.address, isDark),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Progress steps
                  if (!isError) _buildProgressSteps(ride.status),

                  // Driver info
                  if (ride.driverId != null && !isError) ...[
                    const SizedBox(height: 16),
                    DriverInformationView(driverId: ride.driverId),
                  ],

                  const SizedBox(height: 20),

                  // Cancellation error
                  ListenableBuilder(
                    listenable: _cancellationController,
                    builder: (ctx, _) {
                      if (_cancellationController.state.isError) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_cancellationController.state.message ?? 'Cancellation failed.', style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Action buttons
                  ListenableBuilder(
                    listenable: _cancellationController,
                    builder: (ctx, _) {
                      final isCancelling = _cancellationController.state.isLoading;
                      return Column(children: [
                        if (!isTerminal)
                          SizedBox(width: double.infinity, height: 52,
                            child: OutlinedButton(
                              onPressed: isCancelling ? null : () => _handleCancel(context),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              child: isCancelling ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)) : const Text('Cancel Ride', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ),
                        if (ride.status == RideStatus.completed && ride.feedback == null) ...[
                          const SizedBox(height: 10),
                          SizedBox(width: double.infinity, height: 52,
                            child: ElevatedButton(
                              onPressed: () => AppNavigator.pushNamed(context, AppRoutes.riderFeedback, arguments: {'rideId': ride.id}),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              child: const Text('Rate Your Ride ★', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ),
                        ],
                        if (isTerminal) ...[
                          const SizedBox(height: 10),
                          SizedBox(width: double.infinity, height: 52,
                            child: ElevatedButton(
                              onPressed: () => AppNavigator.pushNamedAndRemoveUntil(context, AppRoutes.riderHome, (_) => false),
                              style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.white : Colors.black, foregroundColor: isDark ? Colors.black : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              child: const Text('Return to Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ),
                        ],
                      ]);
                    },
                  ),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _routeRow(IconData icon, Color color, String title, String? subtitle, bool isDark) {
    return Row(crossAxisAlignment: subtitle != null && subtitle.isNotEmpty && subtitle != title ? CrossAxisAlignment.start : CrossAxisAlignment.center, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (subtitle != null && subtitle.isNotEmpty && subtitle != title)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildProgressSteps(RideStatus status) {
    final steps = ['Requested', 'Assigned', 'Arrived', 'In Progress', 'Done'];
    final currentIndex = [RideStatus.requested, RideStatus.accepted, RideStatus.arrived, RideStatus.inProgress, RideStatus.completed].indexOf(status);

    return Row(
      children: steps.asMap().entries.map((e) {
        final done = e.key <= currentIndex;
        final active = e.key == currentIndex;
        return Expanded(
          child: Column(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: done ? Colors.green : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: done ? Colors.green : Colors.grey.shade400, width: 2),
              ),
              child: done ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
            ),
            const SizedBox(height: 4),
            Text(e.value, style: TextStyle(fontSize: 9, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? Colors.green : Colors.grey), textAlign: TextAlign.center),
          ]),
        );
      }).toList(),
    );
  }

  (String, IconData, Color) _getStatusInfo(RideStatus status) {
    return switch (status) {
      RideStatus.requested => ('Finding your driver...', Icons.radar, Colors.blue),
      RideStatus.accepted => ('Driver Assigned', Icons.check_circle, Colors.green),
      RideStatus.arrived => ('Driver has arrived!', Icons.directions_car, Colors.green),
      RideStatus.inProgress => ('On the way', Icons.navigation, Colors.blue),
      RideStatus.completed => ('Ride Completed', Icons.check_circle, Colors.green),
      RideStatus.cancelled => ('Ride Cancelled', Icons.cancel, Colors.red),
      RideStatus.timedOut => ('No Drivers Found', Icons.timer_off, Colors.orange),
      RideStatus.rejected => ('Request Declined', Icons.cancel, Colors.red),
    };
  }

  void _handleCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: 'Cancel Ride',
        message: 'Are you sure you want to cancel this ride request?',
        confirmLabel: 'Cancel Ride',
        cancelLabel: 'Keep Ride',
        isDestructive: true,
        onConfirm: () => _cancellationController.cancelRide(widget.rideId),
      ),
    );
  }
}

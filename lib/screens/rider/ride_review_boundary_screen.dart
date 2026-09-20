import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/location_selection_controller.dart';
import '../../core/state/ride_request_controller.dart';
import '../../models/ride_request_draft.dart';
import '../../services/route_service.dart';
import '../../services/fare_service.dart';

class RideReviewBoundaryScreen extends StatefulWidget {
  final LocationSelectionController controller;

  const RideReviewBoundaryScreen({
    super.key,
    required this.controller,
  });

  @override
  State<RideReviewBoundaryScreen> createState() => _RideReviewBoundaryScreenState();
}

class _RideReviewBoundaryScreenState extends State<RideReviewBoundaryScreen> {
  late final LocationSelectionController _locationController;
  late final RideRequestController _requestController;
  final RouteService _routeService = RouteService();
  final FareService _fareService = FareService();
  
  final MapController _mapController = MapController();
  RouteResult? _routeResult;
  bool _isRouting = true;
  String? _routeError;
  
  @override
  void initState() {
    super.initState();
    _locationController = widget.controller;
    _requestController = RideRequestController();
    _requestController.addListener(_onRequestStateChange);
    
    // Fit bounds after map builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitBounds();
      _calculateRoute();
    });
  }

  Future<void> _calculateRoute() async {
    final draft = widget.controller.draft;
    if (draft.pickup?.latitude == null || draft.destination?.latitude == null) {
      setState(() { _isRouting = false; });
      return;
    }
    
    setState(() { _isRouting = true; _routeError = null; });
    
    try {
      final p1 = LatLng(draft.pickup!.latitude!, draft.pickup!.longitude!);
      final p2 = LatLng(draft.destination!.latitude!, draft.destination!.longitude!);
      
      final result = await _routeService.getRoute(origin: p1, destination: p2);
      
      if (!mounted) return;
      
      final calculatedFare = _fareService.calculateFare(
        distanceMeters: result.distanceMeters,
        durationSeconds: result.durationSeconds,
      );

      _locationController.setRouteInfo(
        fare: calculatedFare,
        distanceMeters: result.distanceMeters,
        durationSeconds: result.durationSeconds,
      );

      setState(() {
        _routeResult = result;
        _isRouting = false;
      });
      _fitBounds();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _routeError = e.toString();
        _isRouting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_routeError!)));
    }
  }

  void _fitBounds() {
    final draft = widget.controller.draft;
    if (draft.pickup?.latitude != null && draft.destination?.latitude != null) {
      final p1 = LatLng(draft.pickup!.latitude!, draft.pickup!.longitude!);
      final p2 = LatLng(draft.destination!.latitude!, draft.destination!.longitude!);
      
      List<LatLng> boundsPoints = [p1, p2];
      if (_routeResult != null && _routeResult!.points.isNotEmpty) {
        boundsPoints = _routeResult!.points;
      }

      final bounds = LatLngBounds.fromPoints(boundsPoints);
      _mapController.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60.0),
      ));
    }
  }

  void _onRequestStateChange() {
    final state = _requestController.state;
    if (state.isSuccess) {
      widget.controller.clear();
      AppNavigator.pushNamedAndRemoveUntil(
        context, 
        AppRoutes.riderStatus,
        (route) => false,
        arguments: state.data!.id,
      );
    } else if (state.isError && state.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message!), behavior: SnackBarBehavior.floating),
      );
      _requestController.reset();
    }
  }

  @override
  void dispose() {
    _requestController.removeListener(_onRequestStateChange);
    _requestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final draft = widget.controller.draft;

    if (!draft.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) => AppNavigator.pop(context));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final p1 = LatLng(draft.pickup!.latitude!, draft.pickup!.longitude!);
    final p2 = LatLng(draft.destination!.latitude!, draft.destination!.longitude!);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: isDark ? Colors.black54 : Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]),
            child: const Icon(Icons.arrow_back),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Map
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: p1, initialZoom: 13.0),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ridesathi.ridesathi',
                ),
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
                MarkerLayer(
                  markers: [
                    Marker(
                      point: p1,
                      width: 36, height: 36,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: Center(child: Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                      ),
                    ),
                    Marker(
                      point: p2,
                      width: 36, height: 36,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Loading Overlay
          if (_isRouting)
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary)),
                      const SizedBox(width: 12),
                      const Text('Finding fastest route...', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Sheet
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, -4))],
              ),
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  
                  // Locations Display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                              Expanded(child: Container(width: 2, color: theme.colorScheme.outlineVariant, margin: const EdgeInsets.symmetric(vertical: 4))),
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(draft.pickup!.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(draft.pickup!.address, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 16),
                                Text(draft.destination!.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(draft.destination!.address, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  // Ride Type (Placeholder for future options)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                      borderRadius: BorderRadius.circular(16),
                      color: isDark ? const Color(0xFF332714) : const Color(0xFFFFFBEB),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_taxi_rounded, size: 40, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('RideSathi Standard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('Nearby drivers', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                        if (_isRouting)
                          const Text('Calculating fare...', style: TextStyle(color: Colors.grey, fontSize: 13))
                        else if (_routeResult != null && draft.estimatedFare != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${draft.estimatedFare!.round()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text('${(_routeResult!.durationSeconds / 60).round()} min • ${(_routeResult!.distanceMeters / 1000).toStringAsFixed(1)} km', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          )
                        else
                          const Text('Fare unavailable', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Request Button
                  ListenableBuilder(
                    listenable: _requestController,
                    builder: (context, _) {
                      final isLoading = _requestController.state.isLoading;
                      return SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => _requestController.submitRequest(draft),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Text('Confirm Ride', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/location_selection_controller.dart';
import '../../models/location_model.dart';
import '../../services/real_location_service.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});
  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final LocationSelectionController _controller = LocationSelectionController();
  final RealLocationService _locationService = RealLocationService();
  final MapController _mapController = MapController();

  LatLng _mapCenter = const LatLng(28.6139, 77.2090);
  String? _validationError;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _initLocation();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() => setState(() => _validationError = null);

  Future<void> _initLocation() async {
    try {
      final loc = await _locationService.getCurrentLocation();
      if (!mounted) return;
      final ll = LatLng(loc.latitude ?? 28.6139, loc.longitude ?? 77.2090);
      setState(() { _mapCenter = ll; _isInitialized = true; });
      _mapController.move(ll, 15.0);
      // Auto-fill pickup with current location
      if (_controller.draft.pickup == null) {
        _controller.setPickup(loc);
      }
    } catch (_) {
      if (mounted) setState(() => _isInitialized = true);
    }
  }

  Future<void> _openSearch(bool isPickup) async {
    try {
      final result = await AppNavigator.pushNamed<LocationModel>(
        context,
        AppRoutes.riderLocationSearch,
        arguments: isPickup ? 'pickup' : 'destination',
      );
      if (result != null) {
        if (isPickup) {
          _controller.setPickup(result);
        } else {
          _controller.setDestination(result);
        }
        if (result.latitude != null && result.longitude != null) {
          final ll = LatLng(result.latitude!, result.longitude!);
          setState(() => _mapCenter = ll);
          _mapController.move(ll, 15.0);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening search: $e')));
    }
  }

  void _onContinue() {
    final error = _controller.validate();
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }
    AppNavigator.pushNamed(context, AppRoutes.riderReviewRide, arguments: _controller);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final draft = _controller.draft;
    final hasPickup = draft.pickup != null;
    final hasDest = draft.destination != null;

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
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Full-screen map
            Positioned.fill(
              child: !_isInitialized
                ? Container(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE8EAF0), child: const Center(child: CircularProgressIndicator()))
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(initialCenter: _mapCenter, initialZoom: 14.0),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.ridesathi.ridesathi',
                      ),
                      MarkerLayer(
                        markers: [
                          if (hasPickup && draft.pickup!.latitude != null)
                            Marker(
                              point: LatLng(draft.pickup!.latitude!, draft.pickup!.longitude!),
                              width: 36, height: 36,
                              child: Container(
                                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), shape: BoxShape.circle),
                                child: Center(child: Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                              ),
                            ),
                          if (hasDest && draft.destination!.latitude != null)
                            Marker(
                              point: LatLng(draft.destination!.latitude!, draft.destination!.longitude!),
                              width: 36, height: 36,
                              child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),

          // Bottom panel with search fields
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, -4))],
              ),
              padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).padding.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text('Plan your ride', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Set your pickup and destination', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 20),
                  
                  // Route indicator + fields
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        // Dot line indicator
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 4)])),
                            Expanded(child: Container(width: 2, color: theme.colorScheme.outlineVariant, margin: const EdgeInsets.symmetric(vertical: 4))),
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 4)])),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            children: [
                              // Pickup field
                              Material(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  onTap: () => _openSearch(true),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: hasPickup ? Border.all(color: Colors.blue.withValues(alpha: 0.5), width: 1.5) : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: hasPickup
                                              ? Text(draft.pickup!.displayName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)
                                              : Text('Pickup location', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                        ),
                                        if (hasPickup)
                                          Icon(Icons.edit_location_alt_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Destination field
                              Material(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  onTap: () => _openSearch(false),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: hasDest ? Border.all(color: Colors.red.withValues(alpha: 0.5), width: 1.5) : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: hasDest
                                              ? Text(draft.destination!.displayName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)
                                              : Text('Where to?', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                        ),
                                        if (hasDest)
                                          Icon(Icons.edit_location_alt_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (_validationError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Icon(Icons.warning_rounded, color: theme.colorScheme.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_validationError!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer))),
                      ]),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: hasDest && hasPickup ? _onContinue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        hasDest && hasPickup ? 'Continue' : 'Select locations to continue',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

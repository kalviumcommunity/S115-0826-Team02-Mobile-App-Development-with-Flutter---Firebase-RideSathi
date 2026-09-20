import 'package:flutter/material.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/state/auth_controller.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/services/real_location_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridesathi/core/theme/theme_controller.dart';

class RiderHomeScreen extends StatefulWidget {
  final AuthController? authController;
  final UserModel? user;
  const RiderHomeScreen({super.key, this.authController, this.user});
  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  late final AuthController _authController;
  final RealLocationService _locationService = RealLocationService();
  final MapController _mapController = MapController();
  bool _isLoggingOut = false;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _authController = widget.authController ?? AuthController.instance;
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final loc = await _locationService.getCurrentLocation();
      if (mounted) {
        setState(() => _currentLocation = LatLng(loc.latitude ?? 18.5204, loc.longitude ?? 73.8567));
        // The map will automatically center on initialCenter when it renders
      }
    } catch (e) {
      if (mounted) {
        setState(() => _currentLocation = const LatLng(18.5204, 73.8567));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permission denied or GPS failed. Defaulting to fallback.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  UserModel? get _currentUser => widget.user ?? _authController.currentUser;

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    final success = await _authController.signOut();
    if (!mounted) return;
    setState(() => _isLoggingOut = false);
    if (success) { AppNavigator.logout(context); return; }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_authController.errorMessage ?? 'Sign out failed'), behavior: SnackBarBehavior.floating));
    _authController.clearError();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _currentUser;
    final firstName = (user?.name.isNotEmpty == true ? user!.name.split(' ').first : 'Rider');
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // ── Full-screen map ───────────────────────────────────────
            Positioned.fill(
              child: _currentLocation == null
                  ? Container(color: isDark ? const Color(0xFF0D1117) : const Color(0xFFE8EDF5))
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(initialCenter: _currentLocation!, initialZoom: 15.0),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.ridesathi.ridesathi',
                        ),
                        if (_currentLocation != null)
                          MarkerLayer(markers: [
                            Marker(
                              point: _currentLocation!,
                              width: 48, height: 48,
                              child: Stack(alignment: Alignment.center, children: [
                                Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.18), shape: BoxShape.circle)),
                                Container(width: 16, height: 16, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5), boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.5), blurRadius: 8)])),
                              ]),
                            ),
                          ]),
                      ],
                    ),
            ),

            // ── Top bar (floating) ────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  // Menu / avatar
                  GestureDetector(
                    onTap: () => AppNavigator.toProfile(context),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10)],
                      ),
                      child: const Icon(Icons.person_outline_rounded, size: 22),
                    ),
                  ),
                  const Spacer(),
                  // Brand pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10)],
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.local_taxi_rounded, size: 16, color: Color(0xFFF59E0B)),
                      SizedBox(width: 6),
                      Text('RideSathi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ]),
                  ),
                  const Spacer(),
                  // Theme Toggle
                  GestureDetector(
                    onTap: ThemeController.toggleTheme,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10)],
                      ),
                      child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Logout
                  GestureDetector(
                    onTap: _isLoggingOut ? null : _handleLogout,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10)],
                      ),
                      child: _isLoggingOut
                          ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.logout_rounded, size: 22),
                    ),
                  ),
                ]),
              ),
            ),

            // ── My Location button (floating right) ───────────────────
            Positioned(
              right: 16,
              bottom: 240,
              child: GestureDetector(
                onTap: () {
                  if (_currentLocation != null) _mapController.move(_currentLocation!, 15.0);
                },
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 12)],
                  ),
                  child: const Icon(Icons.my_location_rounded, color: Color(0xFFF59E0B), size: 22),
                ),
              ),
            ),

            // ── Bottom "Where to?" sheet ──────────────────────────────
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, -4))],
                ),
                padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 20),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Handle
                  Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Text('$greeting, $firstName', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('Where to?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
                  const SizedBox(height: 16),

                  // Search bar — primary CTA
                  GestureDetector(
                    onTap: () => AppNavigator.toRiderRequestRide(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.search_rounded, color: Color(0xFFF59E0B), size: 22),
                        const SizedBox(width: 12),
                        Text('Search destination', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 16, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick action buttons
                  Row(children: [
                    Expanded(child: _quickAction(context, Icons.history_rounded, 'Recent', isDark, () => AppNavigator.toRiderHistory(context))),
                    const SizedBox(width: 12),
                    Expanded(child: _quickAction(context, Icons.local_taxi_rounded, 'Ride Now', isDark, () => AppNavigator.toRiderRequestRide(context))),
                    const SizedBox(width: 12),
                    Expanded(child: _quickAction(context, Icons.local_fire_department_rounded, 'Hot Places', isDark, () => AppNavigator.toRiderHotPlaces(context))),
                  ]),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(BuildContext ctx, IconData icon, String label, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 22, color: isDark ? Colors.white70 : Colors.black54),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
        ]),
      ),
    );
  }
}

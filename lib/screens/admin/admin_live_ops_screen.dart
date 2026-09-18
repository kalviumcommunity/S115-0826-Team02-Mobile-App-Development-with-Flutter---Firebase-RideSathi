import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/ride_model.dart';
import '../../services/admin_service.dart';
import 'admin_ride_detail_screen.dart';

/// Real-time live operations view — shows all active + pending rides.
class AdminLiveOpsScreen extends StatefulWidget {
  const AdminLiveOpsScreen({super.key});
  @override
  State<AdminLiveOpsScreen> createState() => _AdminLiveOpsScreenState();
}

class _AdminLiveOpsScreenState extends State<AdminLiveOpsScreen> {
  final AdminService _service = AdminService();
  StreamSubscription? _activeSub;
  StreamSubscription? _pendingSub;
  List<RideModel> _active = [];
  List<RideModel> _pending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _activeSub = _service.watchActiveRides().listen((r) => setState(() { _active = r; _loading = false; }));
    _pendingSub = _service.watchPendingRides().listen((r) => setState(() { _pending = r; _loading = false; }));
  }

  @override
  void dispose() { _activeSub?.cancel(); _pendingSub?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final theme = Theme.of(context);

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Active rides
      Row(children: [
        Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('ACTIVE RIDES (${_active.length})', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ]),
      const SizedBox(height: 8),
      if (_active.isEmpty) const _EmptyOps(message: 'No active rides', icon: Icons.check_circle_rounded),
      ..._active.map((r) => _LiveRideCard(ride: r, isActive: true,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminRideDetailScreen(rideId: r.id))))),
      const SizedBox(height: 24),

      // Pending rides
      Row(children: [
        Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('PENDING REQUESTS (${_pending.length})', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ]),
      const SizedBox(height: 8),
      if (_pending.isEmpty) const _EmptyOps(message: 'No pending requests', icon: Icons.done_all_rounded),
      ..._pending.map((r) => _LiveRideCard(ride: r, isActive: false,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminRideDetailScreen(rideId: r.id))))),
    ]);
  }
}

class _LiveRideCard extends StatelessWidget {
  final RideModel ride;
  final bool isActive;
  final VoidCallback onTap;
  const _LiveRideCard({required this.ride, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isActive ? Colors.green : Colors.orange;
    final age = ride.createdAt != null ? DateTime.now().difference(ride.createdAt!) : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(ride.pickup.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Text(ride.status.name, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
          ]),
          Text('→ ${ride.destination.displayName}', style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.person_outline, size: 13, color: Colors.grey),
            const SizedBox(width: 4),
            Text(ride.riderId.substring(0, 8), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            if (ride.driverId != null) ...[
              const SizedBox(width: 12),
              const Icon(Icons.drive_eta_outlined, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(ride.driverId!.substring(0, 8), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ] else ...[
              const SizedBox(width: 12),
              const Text('No driver', style: TextStyle(fontSize: 11, color: Colors.orange)),
            ],
            const Spacer(),
            if (age != null) Text(_fmtAge(age), style: TextStyle(fontSize: 11, color: age.inMinutes > 10 ? Colors.red : Colors.grey)),
          ]),
          if (age != null && age.inMinutes > 15 && !isActive)
            Padding(padding: const EdgeInsets.only(top: 6), child: Row(children: [
              const Icon(Icons.warning_rounded, color: Colors.red, size: 14),
              const SizedBox(width: 4),
              const Text('Long wait — consider manual assignment', style: TextStyle(color: Colors.red, fontSize: 11)),
            ])),
        ]),
      ),
    );
  }

  String _fmtAge(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds}s ago';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    return '${d.inHours}h ${d.inMinutes % 60}m ago';
  }
}

class _EmptyOps extends StatelessWidget {
  final String message;
  final IconData icon;
  const _EmptyOps({required this.message, required this.icon});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 18, color: Colors.grey),
      const SizedBox(width: 8),
      Text(message, style: const TextStyle(color: Colors.grey)),
    ]),
  );
}

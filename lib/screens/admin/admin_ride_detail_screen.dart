import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/state/auth_controller.dart';
import '../../models/ride_model.dart';
import '../../services/admin_service.dart';

/// Full ride detail screen for admins — lifecycle, actions, info.
class AdminRideDetailScreen extends StatefulWidget {
  final String rideId;
  const AdminRideDetailScreen({super.key, required this.rideId});
  @override
  State<AdminRideDetailScreen> createState() => _AdminRideDetailScreenState();
}

class _AdminRideDetailScreenState extends State<AdminRideDetailScreen> {
  final AdminService _admin = AdminService();
  RideModel? _ride;
  bool _loading = true;
  String? _error;
  bool _isActing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final snap = await FirebaseFirestore.instance.collection('rides').doc(widget.rideId).get();
      if (snap.exists) {
        setState(() { _ride = RideModel.fromMap(snap.data()!, snap.id); _loading = false; });
      } else {
        setState(() { _error = 'Ride not found.'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String get _adminId => AuthController.instance.currentUser?.id ?? '';

  Future<void> _cancelRide() async {
    final reason = await _showReasonDialog('Cancel Ride', ['Driver unavailable', 'Customer request', 'Operational issue', 'Other']);
    if (reason == null) return;
    setState(() => _isActing = true);
    try {
      await _admin.adminCancelRide(rideId: widget.rideId, adminId: _adminId, reason: reason);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride cancelled.'), backgroundColor: Colors.green));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _isActing = false);
  }

  Future<void> _assignDriver() async {
    final drivers = await _admin.searchUsersByName('', role: 'driver');
    final eligible = drivers.where((d) => d.isOnline && !d.isSuspended).toList();
    if (!mounted) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _DriverPickerSheet(drivers: eligible),
    );
    if (selected == null) return;
    setState(() => _isActing = true);
    try {
      await _admin.adminAssignDriver(rideId: widget.rideId, driverId: selected, adminId: _adminId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Driver assigned.'), backgroundColor: Colors.green));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _isActing = false);
  }

  Future<String?> _showReasonDialog(String title, List<String> options) async {
    String selected = options.first;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((o) => ListTile(
              dense: true,
              leading: Icon(selected == o ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected == o ? const Color(0xFFF59E0B) : Colors.grey),
              title: Text(o),
              onTap: () => set(() => selected = o),
            )).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, selected), child: const Text('Confirm')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('Ride Detail — ${widget.rideId.substring(0, 8)}...'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _error != null ? Center(child: Text(_error!))
        : _ride == null ? const SizedBox.shrink()
        : _buildContent(isDark),
    );
  }

  Widget _buildContent(bool isDark) {
    final ride = _ride!;
    final isTerminal = {RideStatus.completed, RideStatus.cancelled, RideStatus.timedOut}.contains(ride.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Status banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _statusColor(ride.status).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _statusColor(ride.status).withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            Icon(_statusIcon(ride.status), color: _statusColor(ride.status), size: 36),
            const SizedBox(height: 8),
            Text(ride.status.name.toUpperCase(), style: TextStyle(color: _statusColor(ride.status), fontWeight: FontWeight.bold, fontSize: 18)),
          ]),
        ),
        const SizedBox(height: 16),

        // Info card
        _InfoCard(isDark: isDark, children: [
          _InfoRow('Ride ID', ride.id),
          _InfoRow('Rider ID', ride.riderId),
          _InfoRow('Driver ID', ride.driverId ?? 'Unassigned'),
          _InfoRow('Vehicle', ride.vehicleType.name),
          _InfoRow('Fare', '₹${ride.estimatedFare.toStringAsFixed(0)}'),
          _InfoRow('Created', ride.createdAt?.toString() ?? '—'),
          _InfoRow('Updated', ride.updatedAt?.toString() ?? '—'),
        ]),
        const SizedBox(height: 12),

        // Route
        _InfoCard(isDark: isDark, children: [
          _InfoRow('Pickup', ride.pickup.displayName),
          _InfoRow('Destination', ride.destination.displayName),
        ]),
        const SizedBox(height: 12),

        // Progress timeline
        _buildTimeline(ride.status),
        const SizedBox(height: 12),

        // Feedback
        if (ride.feedback != null) ...[
          _InfoCard(isDark: isDark, children: [
            _InfoRow('Rating', '${ride.feedback!.rating} ★'),
            if (ride.feedback!.comment != null) _InfoRow('Comment', ride.feedback!.comment!),
          ]),
          const SizedBox(height: 12),
        ],

        // Admin actions
        if (!isTerminal) ...[
          Text('Admin Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_isActing) const Center(child: CircularProgressIndicator()),
          if (!_isActing) ...[
            if (ride.driverId == null || ride.status == RideStatus.requested)
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Assign Driver'),
                onPressed: _assignDriver,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              icon: const Icon(Icons.cancel_rounded, color: Colors.red),
              label: const Text('Cancel Ride', style: TextStyle(color: Colors.red)),
              onPressed: _cancelRide,
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )),
          ],
        ],
      ]),
    );
  }

  Widget _buildTimeline(RideStatus current) {
    final steps = [RideStatus.requested, RideStatus.accepted, RideStatus.arrived, RideStatus.inProgress, RideStatus.completed];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: steps.asMap().entries.map((e) {
          final done = steps.indexOf(current) >= e.key;
          final active = steps.indexOf(current) == e.key;
          return Expanded(child: Row(children: [
            Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 24, height: 24, decoration: BoxDecoration(
                color: done ? Colors.green : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: done ? Colors.green : Colors.grey.shade400, width: 2),
              ), child: done ? const Icon(Icons.check, size: 12, color: Colors.white) : null),
              const SizedBox(height: 4),
              Text(e.value.name, style: TextStyle(fontSize: 9, color: active ? Colors.green : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center),
            ]),
            if (e.key < steps.length - 1) Expanded(child: Container(height: 2, color: done && steps.indexOf(current) > e.key ? Colors.green : Colors.grey.shade300)),
          ]));
        }).toList(),
      ),
    );
  }

  Color _statusColor(RideStatus s) => switch (s) {
    RideStatus.requested => Colors.orange,
    RideStatus.accepted => Colors.blue,
    RideStatus.arrived => Colors.indigo,
    RideStatus.inProgress => Colors.green,
    RideStatus.completed => Colors.teal,
    _ => Colors.red,
  };

  IconData _statusIcon(RideStatus s) => switch (s) {
    RideStatus.requested => Icons.access_time_rounded,
    RideStatus.accepted => Icons.check_circle_rounded,
    RideStatus.arrived => Icons.directions_car_rounded,
    RideStatus.inProgress => Icons.navigation_rounded,
    RideStatus.completed => Icons.done_all_rounded,
    _ => Icons.cancel_rounded,
  };
}

class _InfoCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const _InfoCard({required this.isDark, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Column(children: children),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  );
}

class _DriverPickerSheet extends StatelessWidget {
  final List<dynamic> drivers;
  const _DriverPickerSheet({required this.drivers});
  @override
  Widget build(BuildContext context) {
    if (drivers.isEmpty) {
      return const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No eligible online drivers available.')));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 16),
      const Text('Select Driver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 8),
      ...drivers.map((d) => ListTile(
        leading: const Icon(Icons.person_rounded),
        title: Text(d.name),
        subtitle: Text(d.phoneNumber),
        trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)), child: const Text('Online', style: TextStyle(color: Colors.green, fontSize: 11))),
        onTap: () => Navigator.of(context).pop(d.id),
      )),
      const SizedBox(height: 16),
    ]);
  }
}

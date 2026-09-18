import 'package:flutter/material.dart';
import '../../core/state/admin/admin_rides_controller.dart';
import '../../models/ride_model.dart';
import 'admin_ride_detail_screen.dart';

class AdminRidesScreen extends StatefulWidget {
  const AdminRidesScreen({super.key});
  @override
  State<AdminRidesScreen> createState() => _AdminRidesScreenState();
}

class _AdminRidesScreenState extends State<AdminRidesScreen> {
  late final AdminRidesController _ctrl;
  RideStatus? _filter;
  final _scroll = ScrollController();

  static const _filters = [null, RideStatus.requested, RideStatus.accepted, RideStatus.inProgress, RideStatus.completed, RideStatus.cancelled, RideStatus.timedOut];

  @override
  void initState() {
    super.initState();
    _ctrl = AdminRidesController();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _ctrl.loadMore();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Filter bar
        Container(
          height: 48,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), children: [
            ..._filters.map((s) {
              final label = s == null ? 'All' : s.name;
              final sel = _filter == s;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () { setState(() => _filter = s); _ctrl.load(status: s); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFF59E0B) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(label, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal, color: sel ? Colors.black : null)),
                  ),
                ),
              );
            }),
          ]),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: _ctrl,
            builder: (context, _) {
              if (_ctrl.rides.isLoading) return const Center(child: CircularProgressIndicator());
              if (_ctrl.rides.isError) return Center(child: Text(_ctrl.rides.message ?? 'Error'));
              final rides = _ctrl.rides.data ?? [];
              if (rides.isEmpty) return const Center(child: Text('No rides found.'));
              return ListView.separated(
                controller: _scroll,
                itemCount: rides.length + (_ctrl.isLoadingMore ? 1 : 0),
                padding: const EdgeInsets.all(12),
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) {
                  if (i >= rides.length) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                  return _RideTile(ride: rides[i], onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminRideDetailScreen(rideId: rides[i].id))));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RideTile extends StatelessWidget {
  final RideModel ride;
  final VoidCallback onTap;
  const _RideTile({required this.ride, required this.onTap});

  static const _statusColors = {
    'requested': Colors.orange,
    'accepted': Colors.blue,
    'arrived': Colors.indigo,
    'inProgress': Colors.green,
    'completed': Colors.teal,
    'cancelled': Colors.red,
    'timedOut': Colors.grey,
    'rejected': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _statusColors[ride.status.name] ?? Colors.grey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.route_rounded, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ride.pickup.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('→ ${ride.destination.displayName}', style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(ride.createdAt != null ? _fmt(ride.createdAt!) : '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Text(ride.status.name, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
            const SizedBox(height: 4),
            Text('₹${ride.estimatedFare.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
        ]),
      ),
    );
  }

  String _fmt(DateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';
import '../../core/state/admin/admin_dashboard_controller.dart';
import '../../models/ride_model.dart';

/// Real-time operational dashboard — the first screen an admin sees.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AdminDashboardController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AdminDashboardController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        final theme = Theme.of(context);
        final counts = _ctrl.counts.data ?? {};
        final pendingRides = _ctrl.pendingRides.data ?? [];
        final activeRides = _ctrl.activeRides.data ?? [];

        return RefreshIndicator(
          onRefresh: _ctrl.refresh,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Platform health cards ─────────────────────────────
                    Text('Platform Health', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    _buildMetricGrid(counts, theme),
                    const SizedBox(height: 24),

                    // ── Alerts ─────────────────────────────────────────────
                    if (_ctrl.pendingRides.isSuccess && pendingRides.isNotEmpty) ...[
                      _AlertBanner(
                        icon: Icons.warning_amber_rounded,
                        color: Colors.orange,
                        text: '${pendingRides.length} ride(s) waiting for a driver',
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (counts['onlineDrivers'] == 0 && counts['pendingRides'] != null && counts['pendingRides']! > 0) ...[
                      _AlertBanner(
                        icon: Icons.no_accounts,
                        color: Colors.red,
                        text: 'No drivers online — ${counts['pendingRides']} pending ride(s) cannot be served!',
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Active Rides ────────────────────────────────────────
                    if (activeRides.isNotEmpty) ...[
                      Text('Active Rides (${activeRides.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...activeRides.take(5).map((r) => _RideCard(ride: r)),
                      const SizedBox(height: 16),
                    ],

                    // ── Pending Rides ──────────────────────────────────────
                    if (pendingRides.isNotEmpty) ...[
                      Text('Pending Requests (${pendingRides.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...pendingRides.take(5).map((r) => _RideCard(ride: r)),
                    ],

                    if (activeRides.isEmpty && pendingRides.isEmpty && _ctrl.activeRides.isSuccess)
                      _EmptyDashboard(),

                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricGrid(Map<String, int> counts, ThemeData theme) {
    final metrics = [
      _Metric('Riders', counts['totalRiders'], Icons.person_rounded, Colors.blue),
      _Metric('Drivers', counts['totalDrivers'], Icons.drive_eta_rounded, Colors.purple),
      _Metric('Online', counts['onlineDrivers'], Icons.wifi_rounded, Colors.green),
      _Metric('Pending', counts['pendingRides'], Icons.access_time_rounded, Colors.orange),
      _Metric('Active', counts['activeRides'], Icons.navigation_rounded, Colors.blue),
      _Metric('Done', counts['completedRides'], Icons.check_circle_rounded, Colors.teal),
      _Metric('Cancelled', counts['cancelledRides'], Icons.cancel_rounded, Colors.red),
      _Metric('Offline', counts['offlineDrivers'], Icons.wifi_off_rounded, Colors.grey),
    ];

    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: metrics.map((m) => _MetricCard(metric: m, isLoading: _ctrl.counts.isLoading)).toList(),
    );
  }
}

class _Metric {
  final String label;
  final int? value;
  final IconData icon;
  final Color color;
  const _Metric(this.label, this.value, this.icon, this.color);
}

class _MetricCard extends StatelessWidget {
  final _Metric metric;
  final bool isLoading;
  const _MetricCard({required this.metric, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(children: [
          Icon(metric.icon, color: metric.color, size: 16),
          const SizedBox(width: 6),
          Text(metric.label, style: TextStyle(fontSize: 12, color: metric.color, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        if (isLoading)
          Container(height: 24, width: 40, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))
        else
          Text('${metric.value ?? 0}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _AlertBanner({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }
}

class _RideCard extends StatelessWidget {
  final RideModel ride;
  const _RideCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(ride.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ride.pickup.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('→ ${ride.destination.displayName}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
          child: Text(ride.status.name, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Color _statusColor(RideStatus s) => switch (s) {
    RideStatus.requested => Colors.orange,
    RideStatus.accepted => Colors.blue,
    RideStatus.arrived => Colors.indigo,
    RideStatus.inProgress => Colors.green,
    RideStatus.completed => Colors.teal,
    RideStatus.cancelled => Colors.red,
    RideStatus.timedOut => Colors.grey,
    RideStatus.rejected => Colors.red,
  };
}

class _EmptyDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text('All clear!', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('No pending or active rides at the moment.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/state/operational_analytics_controller.dart';
import '../../models/operational_analytics.dart';

/// Analytics screen reusing existing OperationalAnalyticsController.
class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});
  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  late final OperationalAnalyticsController _ctrl;
  AnalyticsTimeRange _range = AnalyticsTimeRange.last7Days;

  @override
  void initState() {
    super.initState();
    _ctrl = OperationalAnalyticsController();
    _load();
  }

  void _load() {
    _ctrl.setTimeRange(_range);
    _ctrl.loadAnalytics();
  }


  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Date range selector
        Container(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Text('Range:', style: theme.textTheme.bodyMedium),
            const SizedBox(width: 12),
            ...[
              (AnalyticsTimeRange.today, 'Today'),
              (AnalyticsTimeRange.last7Days, '7 days'),
              (AnalyticsTimeRange.last30Days, '30 days'),
            ].map((entry) {
              final (r, label) = entry;
              final sel = _range == r;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () { setState(() => _range = r); _load(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFF59E0B) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(label, style: TextStyle(fontWeight: sel ? FontWeight.bold : FontWeight.normal, color: sel ? Colors.black : null)),
                  ),
                ),
              );
            }),
          ]),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: _ctrl,
            builder: (ctx, _) {
              if (_ctrl.state.isLoading || _ctrl.state.isInitial) return const Center(child: CircularProgressIndicator());
              if (_ctrl.state.isError) return Center(child: Text(_ctrl.state.message ?? 'Failed to load analytics'));
              final data = _ctrl.state.data!;
              return ListView(padding: const EdgeInsets.all(16), children: [
                Text('Ride Statistics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildRideStats(data, isDark),
                const SizedBox(height: 20),
                Text('Driver Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildDriverStats(data, isDark),
                const SizedBox(height: 20),
                if (data.demandByLocation.isNotEmpty) ...[
                  Text('Top Pickup Locations', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildLocationList(data, isDark),
                ],
              ]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRideStats(OperationalAnalytics data, bool isDark) {
    final rc = data.rideCounts;
    final completionRate = rc.total > 0 ? (rc.completed / rc.total * 100).toStringAsFixed(1) : '0';
    return Wrap(spacing: 10, runSpacing: 10, children: [
      _StatCard('Total', rc.total, Icons.route_rounded, Colors.blue, isDark),
      _StatCard('Completed', rc.completed, Icons.check_circle_rounded, Colors.teal, isDark),
      _StatCard('Cancelled', rc.cancelled, Icons.cancel_rounded, Colors.red, isDark),
      _StatCard('Timed Out', rc.timedOut, Icons.timer_off_rounded, Colors.orange, isDark),
      _StatCard('Active', rc.inProgress + rc.accepted + rc.arrived, Icons.navigation_rounded, Colors.green, isDark),
      _StatCard('Completion', int.tryParse(completionRate.replaceAll('.', '')) ?? 0, Icons.percent_rounded, Colors.purple, isDark, suffix: '%'),
    ]);
  }

  Widget _buildDriverStats(OperationalAnalytics data, bool isDark) {
    final ds = data.driverSummary;
    return Wrap(spacing: 10, runSpacing: 10, children: [
      _StatCard('Online', ds.online, Icons.wifi_rounded, Colors.green, isDark),
      _StatCard('Available', ds.available, Icons.check_circle_outline_rounded, Colors.blue, isDark),
      _StatCard('On Ride', ds.onRide, Icons.drive_eta_rounded, Colors.orange, isDark),
    ]);
  }

  Widget _buildLocationList(OperationalAnalytics data, bool isDark) {
    return Container(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(children: data.demandByLocation.take(8).map((loc) => ListTile(
        dense: true,
        leading: const Icon(Icons.location_on_rounded, size: 18, color: Colors.blue),
        title: Text(loc.locationName, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text('${loc.count} rides', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      )).toList()),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final String suffix;
  const _StatCard(this.label, this.value, this.icon, this.color, this.isDark, {this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 52) / 3;
    return Container(
      width: w,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text('$value$suffix', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
    );
  }
}

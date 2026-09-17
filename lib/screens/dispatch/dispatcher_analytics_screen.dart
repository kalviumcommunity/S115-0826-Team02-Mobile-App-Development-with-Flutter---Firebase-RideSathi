import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/state/operational_analytics_controller.dart';
import '../../models/operational_analytics.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_view.dart';

class DispatcherAnalyticsScreen extends StatefulWidget {
  const DispatcherAnalyticsScreen({super.key});

  @override
  State<DispatcherAnalyticsScreen> createState() => _DispatcherAnalyticsScreenState();
}

class _DispatcherAnalyticsScreenState extends State<DispatcherAnalyticsScreen> {
  late final OperationalAnalyticsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OperationalAnalyticsController();
    _controller.addListener(_onStateChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadAnalytics(refresh: true);
    });
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  Widget _buildTimeRangeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceM),
      child: SegmentedButton<AnalyticsTimeRange>(
        segments: const [
          ButtonSegment(value: AnalyticsTimeRange.today, label: Text('Today')),
          ButtonSegment(value: AnalyticsTimeRange.last7Days, label: Text('7 Days')),
          ButtonSegment(value: AnalyticsTimeRange.last30Days, label: Text('30 Days')),
        ],
        selected: {_controller.currentRange},
        onSelectionChanged: (Set<AnalyticsTimeRange> selection) {
          _controller.setTimeRange(selection.first);
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, {String? subtitle}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: AppConstants.spaceS),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[
              const SizedBox(height: AppConstants.spaceXS),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDistribution(RideStatusCounts counts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ride Outcomes', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            ListTile(title: const Text('Completed'), trailing: Text(counts.completed.toString()), visualDensity: VisualDensity.compact),
            ListTile(title: const Text('Cancelled'), trailing: Text(counts.cancelled.toString()), visualDensity: VisualDensity.compact),
            ListTile(title: const Text('Timed Out'), trailing: Text(counts.timedOut.toString()), visualDensity: VisualDensity.compact),
            ListTile(title: const Text('Rejected'), trailing: Text(counts.rejected.toString()), visualDensity: VisualDensity.compact),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverSummary(DriverOperationalSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Driver Activity', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCompactMetric('Online', summary.online.toString()),
                _buildCompactMetric('Available', summary.available.toString()),
                _buildCompactMetric('On Ride', summary.onRide.toString()),
              ],
            )
          ],
        ),
      ),
    );
  }
  
  Widget _buildCompactMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDemandByLocation(List<DemandByLocation> demand) {
    if (demand.isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Pickup Locations', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            ...demand.map((d) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceXS),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(d.locationName, overflow: TextOverflow.ellipsis)),
                  Text(d.count.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    return RefreshIndicator(
      onRefresh: () => _controller.loadAnalytics(refresh: true),
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.spaceM),
        children: [
          _buildTimeRangeSelector(),
          state.when(
            initial: () => const SizedBox.shrink(),
            loading: (_) => const Center(child: Padding(
              padding: EdgeInsets.all(AppConstants.spaceXL),
              child: CircularProgressIndicator(),
            )),
            error: (message, code, err) => ErrorView(
              title: 'Failed to load analytics',
              message: message,
              onRetry: () => _controller.loadAnalytics(refresh: true),
            ),
            empty: (msg) => const EmptyStateView(
              icon: Icons.bar_chart_rounded,
              title: 'No analytics available',
              description: 'Try changing the date range or checking back later.',
            ),
            success: (OperationalAnalytics? analytics) {
              if (analytics == null) return const SizedBox.shrink();
              if (analytics.rideCounts.total == 0) {
                return const EmptyStateView(
                  icon: Icons.bar_chart_rounded,
                  title: 'No Data',
                  description: 'No ride data available for this period.',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDriverSummary(analytics.driverSummary),
                  const SizedBox(height: AppConstants.spaceM),
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard(
                        'Total Rides', 
                        analytics.rideCounts.total.toString(),
                      )),
                      const SizedBox(width: AppConstants.spaceM),
                      Expanded(child: _buildMetricCard(
                        'Completion', 
                        '${(analytics.rideCounts.completionRate * 100).toStringAsFixed(1)}%',
                        subtitle: '${analytics.rideCounts.completed} rides',
                      )),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spaceM),
                  _buildStatusDistribution(analytics.rideCounts),
                  const SizedBox(height: AppConstants.spaceM),
                  _buildDemandByLocation(analytics.demandByLocation),
                  // Additional charts/demand by time can be added here
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

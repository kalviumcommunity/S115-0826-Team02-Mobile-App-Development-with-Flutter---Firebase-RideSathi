import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/state/driver_data_controller.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

/// A minimal dispatcher screen for validating the real-time driver data stream.
///
/// This screen is for data validation only and does not contain matching,
/// ranking, or assignment logic.
class DriverDataValidationScreen extends StatefulWidget {
  const DriverDataValidationScreen({super.key});

  @override
  State<DriverDataValidationScreen> createState() =>
      _DriverDataValidationScreenState();
}

class _DriverDataValidationScreenState
    extends State<DriverDataValidationScreen> {
  late final DriverDataController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DriverDataController();
    _controller.addListener(_onStateChanged);
  }

  void _onStateChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second $period';
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Driver Data'),
      ),
      body: state.when(
        initial: () => const LoadingView(message: 'Initializing stream...'),
        loading: (msg) => LoadingView(message: msg),
        error: (msg, err) => ErrorView(
          message: msg,
          onRetry: _controller.startListening,
        ),
        empty: (msg) => EmptyStateView(
          icon: Icons.group_off_rounded,
          message: msg,
        ),
        success: (drivers) {
          return RefreshIndicator(
            onRefresh: () async {
              _controller.stopListening();
              _controller.startListening();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppConstants.spaceL),
              itemCount: drivers.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppConstants.spaceM),
              itemBuilder: (context, index) {
                final driver = drivers[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spaceM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                driver.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (driver.isUnionVerified)
                              const Icon(Icons.verified, color: Colors.blue, size: 20)
                            else
                              const Icon(Icons.pending_actions, color: Colors.orange, size: 20),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spaceS),
                        Text('Phone: ${driver.phoneNumber}'),
                        if (driver.vehicleInfo != null)
                          Text('Vehicle: ${driver.vehicleInfo}'),
                        const Divider(),
                        Row(
                          children: [
                            Icon(
                              driver.isOnline
                                  ? Icons.sensors_rounded
                                  : Icons.sensors_off_rounded,
                              color: driver.isOnline ? Colors.green : Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: AppConstants.spaceS),
                            Text(driver.isOnline ? 'Online' : 'Offline'),
                            if (driver.availabilityUpdatedAt != null) ...[
                              const Spacer(),
                              Text(
                                'Updated: ${_formatDateTime(driver.availabilityUpdatedAt!)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppConstants.spaceS),
                        Row(
                          children: [
                            Icon(
                              driver.hasLocation
                                  ? Icons.my_location_rounded
                                  : Icons.location_off_rounded,
                              color: driver.hasLocation ? Colors.blue : Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: AppConstants.spaceS),
                            Expanded(
                              child: Text(
                                driver.hasLocation
                                    ? 'Location available (Ride ${driver.activeRideId})'
                                    : 'No active location',
                              ),
                            ),
                            if (driver.hasLocation && driver.location!.updatedAt != null) ...[
                              Text(
                                'Pos: ${_formatDateTime(driver.location!.updatedAt)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

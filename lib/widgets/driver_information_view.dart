import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/state/driver_information_controller.dart';
import '../models/user_model.dart';
import 'view_state_builder.dart';

class DriverInformationView extends StatefulWidget {
  final String? driverId;
  final DriverInformationController? controller;

  const DriverInformationView({
    super.key,
    required this.driverId,
    this.controller,
  });

  @override
  State<DriverInformationView> createState() => _DriverInformationViewState();
}

class _DriverInformationViewState extends State<DriverInformationView> {
  late final DriverInformationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? DriverInformationController();
    _controller.loadDriver(widget.driverId);
  }

  @override
  void didUpdateWidget(covariant DriverInformationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driverId != widget.driverId) {
      _controller.loadDriver(widget.driverId);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return ViewStateBuilder<UserModel>(
          state: _controller.state,
          loadingMessage: 'Loading driver details...',
          initialBuilder: (context) {
            return const _WaitingForDriverCard();
          },
          errorTitle: 'Driver unavailable',
          retryLabel: 'Try Again',
          onRetry: _controller.retry,
          builder: (context, driver) {
            return _DriverDetailsCard(driver: driver);
          },
        );
      },
    );
  }
}

class _WaitingForDriverCard extends StatelessWidget {
  const _WaitingForDriverCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppConstants.spaceM),
          Expanded(
            child: Text(
              'Waiting for driver assignment',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverDetailsCard extends StatelessWidget {
  final UserModel driver;

  const _DriverDetailsCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: const Icon(Icons.person),
          ),
          const SizedBox(width: AppConstants.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driver',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  driver.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (driver.vehicleInfo != null && driver.vehicleInfo!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          driver.vehicleInfo!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

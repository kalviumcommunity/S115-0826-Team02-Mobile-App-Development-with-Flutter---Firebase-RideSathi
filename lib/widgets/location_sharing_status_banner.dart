import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/state/driver_location_controller.dart';

/// A banner widget showing real-time location-publishing status.
///
/// In PR 38 the lifecycle is owned by [DriverActiveRideScreen] via an
/// injected [DriverLocationController].  The banner is purely presentational
/// — it does NOT create or auto-start a controller.
class LocationSharingStatusBanner extends StatelessWidget {
  /// The controller whose state this banner reflects.
  final DriverLocationController controller;

  const LocationSharingStatusBanner({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        final theme = Theme.of(context);

        Color backgroundColor = theme.colorScheme.surfaceContainerHighest;
        Color foregroundColor = theme.colorScheme.onSurfaceVariant;
        IconData icon = Icons.location_off_rounded;
        String message = 'Location sharing inactive';
        Widget? actionButton;

        if (state.isInitial) {
          message = 'Location sharing stopped.';
        } else if (state.isLoading) {
          icon = Icons.gps_fixed_rounded;
          message = state.message ?? 'Acquiring location...';
        } else if (state.isSuccess) {
          backgroundColor = Colors.green.withValues(alpha: 0.15);
          foregroundColor = Colors.green;
          icon = Icons.my_location_rounded;
          message = 'Sharing live location with rider';
          actionButton = TextButton(
            onPressed: controller.stopPublishing,
            child: Text('Stop', style: TextStyle(color: foregroundColor)),
          );
        } else if (state.isError) {
          backgroundColor = theme.colorScheme.errorContainer;
          foregroundColor = theme.colorScheme.onErrorContainer;
          icon = Icons.location_disabled_rounded;
          message = state.message ?? 'Location unavailable';
          actionButton = TextButton(
            onPressed: controller.startPublishing,
            child: Text('Retry', style: TextStyle(color: foregroundColor)),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceM, vertical: AppConstants.spaceS),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: Row(
            children: [
              if (state.isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                  ),
                )
              else
                Icon(icon, size: 20, color: foregroundColor),
              const SizedBox(width: AppConstants.spaceM),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (actionButton != null) actionButton,
            ],
          ),
        );
      },
    );
  }
}

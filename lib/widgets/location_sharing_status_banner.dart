import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/state/driver_location_controller.dart';

/// A banner widget for the driver's screen indicating the real-time location publishing status.
class LocationSharingStatusBanner extends StatefulWidget {
  final String activeRideId;

  const LocationSharingStatusBanner({
    super.key,
    required this.activeRideId,
  });

  @override
  State<LocationSharingStatusBanner> createState() => _LocationSharingStatusBannerState();
}

class _LocationSharingStatusBannerState extends State<LocationSharingStatusBanner> {
  late final DriverLocationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DriverLocationController(rideId: widget.activeRideId);
    // Auto-start publishing if possible
    _controller.startPublishing();
  }

  @override
  void didUpdateWidget(covariant LocationSharingStatusBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeRideId != widget.activeRideId) {
      // Typically the UI would remount, but just in case:
      _controller.stopPublishing();
      // Should recreate controller for new rideId, but for simplicity we assume it remounts
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;
        final theme = Theme.of(context);

        Color backgroundColor = theme.colorScheme.surfaceContainerHighest;
        Color foregroundColor = theme.colorScheme.onSurfaceVariant;
        IconData icon = Icons.location_off_rounded;
        String message = 'Location sharing inactive';
        Widget? actionButton;

        if (state.isInitial) {
          message = 'Location sharing stopped.';
          actionButton = TextButton(
            onPressed: _controller.startPublishing,
            child: const Text('Start'),
          );
        } else if (state.isLoading) {
          icon = Icons.gps_fixed_rounded;
          message = state.message ?? 'Acquiring location...';
        } else if (state.isSuccess) {
          backgroundColor = Colors.green.withValues(alpha: 0.15);
          foregroundColor = Colors.green;
          icon = Icons.my_location_rounded;
          message = 'Sharing live location with rider';
          actionButton = TextButton(
            onPressed: _controller.stopPublishing,
            child: Text('Stop', style: TextStyle(color: foregroundColor)),
          );
        } else if (state.isError) {
          backgroundColor = theme.colorScheme.errorContainer;
          foregroundColor = theme.colorScheme.onErrorContainer;
          icon = Icons.location_disabled_rounded;
          message = state.message ?? 'Location unavailable';
          actionButton = TextButton(
            onPressed: _controller.startPublishing,
            child: Text('Retry', style: TextStyle(color: foregroundColor)),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM, vertical: AppConstants.spaceS),
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

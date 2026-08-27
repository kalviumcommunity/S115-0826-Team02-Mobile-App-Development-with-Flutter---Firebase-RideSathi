import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'location_display.dart';
import 'status_badge.dart';

/// Reusable card displaying high-level ride summary information across Rider, Driver, and Dispatcher screens.
class RideSummaryCard extends StatelessWidget {
  /// Pickup address or location name.
  final String pickupAddress;

  /// Drop-off address or location name.
  final String dropoffAddress;

  /// Current ride status (e.g. 'Requested', 'In Progress', 'Completed').
  final String status;

  /// Formatted date and time of the ride (e.g. '27 Aug 2026, 02:30 PM').
  final String dateTime;

  /// Optional name of the assigned driver.
  final String? driverName;

  /// Optional vehicle details (e.g. 'Auto • DL-01-AB-1234').
  final String? vehicleInfo;

  /// Optional fare or price string (e.g. '₹150').
  final String? fare;

  /// Optional callback when the card is tapped.
  final VoidCallback? onTap;

  const RideSummaryCard({
    super.key,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.status,
    required this.dateTime,
    this.driverName,
    this.vehicleInfo,
    this.fare,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardContent = Padding(
      padding: const EdgeInsets.all(AppConstants.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row: Date/Time + StatusBadge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    dateTime,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              StatusBadge(status: status, isCompact: true),
            ],
          ),

          const SizedBox(height: AppConstants.spaceM),
          const Divider(height: 1),
          const SizedBox(height: AppConstants.spaceM),

          // Route display
          LocationDisplay(
            pickupAddress: pickupAddress,
            dropoffAddress: dropoffAddress,
            isCompact: true,
          ),

          // Footer details: Driver, Vehicle, Fare
          if (driverName != null || vehicleInfo != null || fare != null) ...[
            const SizedBox(height: AppConstants.spaceM),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spaceM,
                vertical: AppConstants.spaceS,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Row(
                children: [
                  if (driverName != null || vehicleInfo != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (driverName != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person_rounded,
                                  size: 14,
                                  color: AppConstants.secondaryTeal,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    driverName!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          if (vehicleInfo != null) ...[
                            if (driverName != null) const SizedBox(height: 2),
                            Text(
                              vehicleInfo!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (fare != null) ...[
                    const SizedBox(width: AppConstants.spaceS),
                    Text(
                      fare!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spaceM),
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppConstants.radiusXL),
              child: cardContent,
            )
          : cardContent,
    );
  }
}

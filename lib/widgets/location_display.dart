import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

/// Reusable route display showing pickup and drop-off locations with visual route connectors.
class LocationDisplay extends StatelessWidget {
  /// Primary address or name of the pickup location.
  final String pickupAddress;

  /// Primary address or name of the drop-off / destination location.
  final String dropoffAddress;

  /// Optional label above the pickup address (defaults to 'Pickup').
  final String? pickupLabel;

  /// Optional label above the drop-off address (defaults to 'Drop-off').
  final String? dropoffLabel;

  /// Optional secondary subtitle or landmark for the pickup location.
  final String? pickupSubtitle;

  /// Optional secondary subtitle or landmark for the drop-off location.
  final String? dropoffSubtitle;

  /// Whether to render in a compact dense layout.
  final bool isCompact;

  const LocationDisplay({
    super.key,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.pickupLabel = 'Pickup',
    this.dropoffLabel = 'Drop-off',
    this.pickupSubtitle,
    this.dropoffSubtitle,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const pickupColor = AppConstants.secondaryTeal;
    const dropoffColor = AppConstants.primaryAmber;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Visual connector column
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 3),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: pickupColor,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: isCompact ? 24 : 36,
              margin: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dropoffColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(width: AppConstants.spaceM),

        // Address texts column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pickup Section
              if (pickupLabel != null && !isCompact) ...[
                Text(
                  pickupLabel!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 1),
              ],
              Text(
                pickupAddress,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: isCompact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (pickupSubtitle != null && !isCompact) ...[
                Text(
                  pickupSubtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              SizedBox(height: isCompact ? AppConstants.spaceS : AppConstants.spaceM),

              // Drop-off Section
              if (dropoffLabel != null && !isCompact) ...[
                Text(
                  dropoffLabel!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 1),
              ],
              Text(
                dropoffAddress,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: isCompact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (dropoffSubtitle != null && !isCompact) ...[
                Text(
                  dropoffSubtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

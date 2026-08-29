import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

/// Reusable semantic status badge for RideSathi.
///
/// Distinguishes states across Rider, Driver, and Dispatcher screens using
/// combined text, iconography, background tint, and border styling for
/// full accessibility and clear visual hierarchy.
class StatusBadge extends StatelessWidget {
  /// The status string to display (e.g. 'Requested', 'In Progress', 'Completed').
  final String status;

  /// Optional override for the status icon.
  final IconData? customIcon;

  /// Optional override for the badge theme color.
  final Color? customColor;

  /// Whether to render in compact format (smaller padding & typography).
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.customIcon,
    this.customColor,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final styleInfo = _resolveStyle(context, status);
    final color = customColor ?? styleInfo.color;
    final icon = customIcon ?? styleInfo.icon;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final verticalPadding = isCompact ? 2.0 : AppConstants.spaceXS;
    final horizontalPadding = isCompact ? AppConstants.spaceS : AppConstants.spaceM;
    final fontSize = isCompact ? 11.0 : 12.0;
    final iconSize = isCompact ? 12.0 : 14.0;

    return Semantics(
      label: 'Status: $status',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(AppConstants.radiusPill),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.55 : 0.4),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: iconSize,
                color: color,
              ),
              SizedBox(width: isCompact ? 4.0 : 6.0),
            ],
            Text(
              status,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _StatusStyleInfo _resolveStyle(BuildContext context, String rawStatus) {
    final normalized = rawStatus.trim().toLowerCase();

    switch (normalized) {
      case 'requested':
      case 'pending':
        return const _StatusStyleInfo(
          color: Color(0xFFD97706), // Warm Amber
          icon: Icons.hourglass_top_rounded,
        );

      case 'assigned':
        return const _StatusStyleInfo(
          color: Color(0xFF0284C7), // Sky Blue
          icon: Icons.assignment_ind_rounded,
        );

      case 'driver en route':
      case 'en route':
        return const _StatusStyleInfo(
          color: Color(0xFF2563EB), // Royal Blue
          icon: Icons.directions_car_filled_rounded,
        );

      case 'picked up':
      case 'in progress':
      case 'ongoing':
      case 'active':
        return const _StatusStyleInfo(
          color: AppConstants.secondaryTeal, // Union Teal
          icon: Icons.navigation_rounded,
        );

      case 'completed':
      case 'delivered':
      case 'finished':
        return const _StatusStyleInfo(
          color: Color(0xFF16A34A), // Emerald Green
          icon: Icons.check_circle_rounded,
        );

      case 'cancelled':
      case 'canceled':
        return const _StatusStyleInfo(
          color: AppConstants.errorColor, // Red
          icon: Icons.cancel_rounded,
        );

      case 'no show':
      case 'no_show':
        return const _StatusStyleInfo(
          color: Color(0xFFE11D48), // Rose Red
          icon: Icons.person_off_rounded,
        );

      case 'needs dispatch':
      case 'unassigned':
        return const _StatusStyleInfo(
          color: Color(0xFF9333EA), // Purple
          icon: Icons.support_agent_rounded,
        );

      default:
        final theme = Theme.of(context);
        return _StatusStyleInfo(
          color: theme.colorScheme.onSurfaceVariant,
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

class _StatusStyleInfo {
  final Color color;
  final IconData? icon;

  const _StatusStyleInfo({
    required this.color,
    this.icon,
  });
}

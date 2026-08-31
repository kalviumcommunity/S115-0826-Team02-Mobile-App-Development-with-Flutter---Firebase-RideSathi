import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

/// Reusable section header widget for dashboards, lists, and operational screens.
class SectionHeader extends StatelessWidget {
  /// Primary title for the section.
  final String title;

  /// Optional secondary subtitle providing context.
  final String? subtitle;

  /// Optional text label for the trailing action button.
  final String? actionLabel;

  /// Optional callback invoked when the trailing action is pressed.
  final VoidCallback? onAction;

  /// Optional icon to accompany the trailing action button.
  final IconData? actionIcon;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title & Subtitle column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Trailing action
          if (onAction != null && (actionLabel != null || actionIcon != null)) ...[
            const SizedBox(width: AppConstants.spaceS),
            if (actionLabel != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spaceM,
                    vertical: AppConstants.spaceXS,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (actionIcon != null) ...[
                      Icon(actionIcon, size: 16),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      actionLabel!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else if (actionIcon != null)
              IconButton(
                icon: Icon(actionIcon, size: 20),
                onPressed: onAction,
                tooltip: title,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ],
      ),
    );
  }
}

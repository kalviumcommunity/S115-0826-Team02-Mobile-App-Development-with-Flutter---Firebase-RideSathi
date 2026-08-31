import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'custom_button.dart';

/// Reusable empty state presentation for RideSathi lists, queues, and history.
class EmptyStateView extends StatelessWidget {
  /// Primary icon representing the empty state.
  final IconData icon;

  /// Main title text (e.g. 'No Rides Yet').
  final String title;

  /// Optional detailed explanatory description.
  final String? description;

  /// Optional label for the call-to-action button.
  final String? actionLabel;

  /// Optional callback invoked when the action button is pressed.
  final VoidCallback? onAction;

  /// Optional icon to display inside the action button.
  final IconData? actionIcon;

  const EmptyStateView({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceXL,
          vertical: AppConstants.spaceXXL,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon container with soft circular background
              Container(
                padding: const EdgeInsets.all(AppConstants.spaceXL),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppConstants.spaceXL),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Description
              if (description != null) ...[
                const SizedBox(height: AppConstants.spaceS),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],

              // Action button
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppConstants.spaceXL),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 160, maxWidth: 280),
                  child: CustomButton(
                    label: actionLabel!,
                    icon: actionIcon,
                    onPressed: onAction,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

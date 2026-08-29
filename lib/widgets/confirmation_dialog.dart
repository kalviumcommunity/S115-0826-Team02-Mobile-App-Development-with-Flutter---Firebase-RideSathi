import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

/// Reusable confirmation dialog for critical or destructive user actions.
class ConfirmationDialog extends StatelessWidget {
  /// Dialog title.
  final String title;

  /// Explanatory confirmation message.
  final String message;

  /// Label for the confirmation action button (defaults to 'Confirm').
  final String confirmLabel;

  /// Label for the cancellation button (defaults to 'Cancel').
  final String cancelLabel;

  /// Whether this action is destructive (applies error/warning coloring).
  final bool isDestructive;

  /// Optional icon displayed before the title.
  final IconData? icon;

  /// Optional custom callback on confirmation. If not provided, defaults to `Navigator.pop(true)`.
  final VoidCallback? onConfirm;

  /// Optional custom callback on cancellation. If not provided, defaults to `Navigator.pop(false)`.
  final VoidCallback? onCancel;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.icon,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confirmColor = isDestructive ? theme.colorScheme.error : theme.colorScheme.primary;
    final confirmTextColor = isDestructive ? theme.colorScheme.onError : theme.colorScheme.onPrimary;

    return AlertDialog(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: isDestructive ? theme.colorScheme.error : theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: AppConstants.spaceS),
          ],
          Flexible(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceL,
        vertical: AppConstants.spaceM,
      ),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: confirmTextColor,
            minimumSize: const Size(90, 40),
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceL),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            elevation: 0,
          ),
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          child: Text(
            confirmLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// Convenience helper to display a standardized [ConfirmationDialog].
///
/// Returns `true` if confirmed, `false` or `null` if cancelled or dismissed.
Future<bool?> showAppConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
  IconData? icon,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => ConfirmationDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
      icon: icon,
    ),
  );
}

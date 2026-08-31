import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'custom_button.dart';

/// Reusable error presentation for failed operations, network errors, or empty query results.
class ErrorView extends StatelessWidget {
  /// Header title for the error state.
  final String title;

  /// Detailed error message or user guidance.
  final String message;

  /// Icon representing the error.
  final IconData icon;

  /// Label for the optional retry button.
  final String retryLabel;

  /// Optional callback invoked when the retry button is tapped.
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.retryLabel = 'Try Again',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
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
              // Error icon container
              Container(
                padding: const EdgeInsets.all(AppConstants.spaceXL),
                decoration: BoxDecoration(
                  color: errorColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: errorColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: errorColor,
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
              const SizedBox(height: AppConstants.spaceS),

              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),

              // Retry Button
              if (onRetry != null) ...[
                const SizedBox(height: AppConstants.spaceXL),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 160, maxWidth: 280),
                  child: CustomButton(
                    label: retryLabel,
                    icon: Icons.refresh_rounded,
                    onPressed: onRetry,
                    isSecondary: true,
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

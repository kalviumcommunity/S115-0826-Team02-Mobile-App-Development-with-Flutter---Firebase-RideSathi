import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

/// Reusable loading indicator presentation for RideSathi screens and components.
///
/// Supports both full-page centered loading states and compact inline rows.
class LoadingView extends StatelessWidget {
  /// Optional explanatory text shown alongside or below the spinner.
  final String? message;

  /// Whether to render in a compact inline row rather than a full-page centered layout.
  final bool isCompact;

  /// Diameter of the circular progress indicator.
  final double? size;

  /// Custom color for the progress indicator. Defaults to [ColorScheme.primary].
  final Color? color;

  const LoadingView({
    super.key,
    this.message,
    this.isCompact = false,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = color ?? theme.colorScheme.primary;
    final defaultSize = isCompact ? 20.0 : 36.0;
    final actualSize = size ?? defaultSize;
    final strokeWidth = isCompact ? 2.2 : 3.2;

    final spinner = SizedBox(
      height: actualSize,
      width: actualSize,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
      ),
    );

    if (isCompact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          spinner,
          if (message != null) ...[
            const SizedBox(width: AppConstants.spaceM),
            Flexible(
              child: Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            spinner,
            if (message != null) ...[
              const SizedBox(height: AppConstants.spaceL),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

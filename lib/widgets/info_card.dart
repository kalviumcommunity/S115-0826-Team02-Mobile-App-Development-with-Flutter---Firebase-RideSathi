import 'package:flutter/material.dart';
import 'package:ridesathi/core/constants/app_constants.dart';

/// Reusable status and feature card widget for RideSathi baseline interface.
class InfoCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final String? badgeText;
  final Color? badgeColor;

  const InfoCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    this.badgeText,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spaceM),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceL),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (badgeText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spaceS,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? theme.colorScheme.primary)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppConstants.radiusS),
                          ),
                          child: Text(
                            badgeText!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: badgeColor ?? theme.colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spaceXS),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


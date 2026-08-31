import 'package:flutter/material.dart';
import 'package:ridesathi/core/constants/app_constants.dart';

/// Reusable inline banner for informational, warning, or error messages
/// shown on RideSathi authentication screens.
class InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const InfoBanner({
    super.key,
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppConstants.spaceS),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}


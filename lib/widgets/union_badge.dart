import 'package:flutter/material.dart';
import 'package:ridesathi/core/constants/app_constants.dart';

/// Reusable badge widget showcasing Union network identity and status.
class UnionBadge extends StatelessWidget {
  const UnionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceL,
        vertical: AppConstants.spaceS,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryAmber,
            AppConstants.primaryAmber.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryAmber.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 16,
            color: Colors.black,
          ),
          SizedBox(width: 6),
          Text(
            '${AppConstants.unionCode} • Official App',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}


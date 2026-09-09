import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/location_selection_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/section_header.dart';

class RideReviewBoundaryScreen extends StatelessWidget {
  final LocationSelectionController controller;

  const RideReviewBoundaryScreen({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = controller.draft;

    // Safety check in case navigated here directly without valid state
    if (!draft.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppNavigator.pop(context);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Ride'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spaceXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'Review your ride details',
                subtitle: 'Confirm your pickup and destination locations.',
              ),
              const SizedBox(height: AppConstants.spaceXL),

              // Pickup Details
              _ReviewLocationCard(
                label: 'Pickup',
                displayName: draft.pickup!.displayName,
                address: draft.pickup!.address,
                icon: Icons.my_location_rounded,
                onChange: () {
                  AppNavigator.pop(context);
                },
              ),
              const SizedBox(height: AppConstants.spaceL),

              // Destination Details
              _ReviewLocationCard(
                label: 'Destination',
                displayName: draft.destination!.displayName,
                address: draft.destination!.address,
                icon: Icons.location_on_rounded,
                onChange: () {
                  AppNavigator.pop(context);
                },
              ),

              const Spacer(),

              // Placeholder message for PR 20
              Container(
                padding: const EdgeInsets.all(AppConstants.spaceM),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Ride creation and confirmation will be implemented in the next release. This is the boundary for PR 20.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppConstants.spaceL),

              // Final Continue Action (Mock)
              CustomButton(
                text: 'Confirm Ride (Coming Soon)',
                onPressed: () {
                  // Do nothing in PR 20 boundary
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ride creation is out of scope for PR 20.'),
                    ),
                  );
                },
                isLoading: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewLocationCard extends StatelessWidget {
  final String label;
  final String displayName;
  final String address;
  final IconData icon;
  final VoidCallback onChange;

  const _ReviewLocationCard({
    required this.label,
    required this.displayName,
    required this.address,
    required this.icon,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppConstants.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  address,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

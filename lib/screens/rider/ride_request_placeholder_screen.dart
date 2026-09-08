import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/section_header.dart';

/// Placeholder screen for the upcoming ride-request workflow.
///
/// PR 19 establishes this screen as the navigation boundary for the rider
/// ride-request journey. The actual location selection, ride creation, and
/// Firestore persistence are out of scope and will be implemented in
/// subsequent PRs.
///
/// This screen intentionally does NOT:
/// - Write to Firestore
/// - Create a [RideModel]
/// - Assign a driver
/// - Simulate a successful ride request
class RideRequestPlaceholderScreen extends StatelessWidget {
  const RideRequestPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppConstants.primaryAmber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.my_location_rounded,
                size: 20,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Request a Ride',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spaceXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'Where would you like to go?',
                subtitle: 'Choose your pickup and drop-off locations.',
              ),
              const SizedBox(height: AppConstants.spaceXL),

              // Placeholder card indicating upcoming functionality
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spaceXL),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spaceL),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on_outlined,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spaceL),
                      Text(
                        'Location Selection Coming Soon',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spaceS),
                      Text(
                        'Pickup and drop-off location selection will be '
                        'available in the next release.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

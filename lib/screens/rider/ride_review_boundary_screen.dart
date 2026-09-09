import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/location_selection_controller.dart';
import '../../core/state/ride_request_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class RideReviewBoundaryScreen extends StatefulWidget {
  final LocationSelectionController controller;

  const RideReviewBoundaryScreen({
    super.key,
    required this.controller,
  });

  @override
  State<RideReviewBoundaryScreen> createState() => _RideReviewBoundaryScreenState();
}

class _RideReviewBoundaryScreenState extends State<RideReviewBoundaryScreen> {
  late final RideRequestController _requestController;

  @override
  void initState() {
    super.initState();
    _requestController = RideRequestController();
    _requestController.addListener(_onRequestStateChange);
  }

  void _onRequestStateChange() {
    final state = _requestController.state;
    if (state.isSuccess) {
      // Show success snackbar and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your ride request has been submitted.')),
      );
      // Clear draft
      widget.controller.clear();
      // Navigate to Rider Home
      AppNavigator.pushNamedAndRemoveUntil(context, AppRoutes.riderHome);
    } else if (state.isError && state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage!)),
      );
      _requestController.reset();
    }
  }

  @override
  void dispose() {
    _requestController.removeListener(_onRequestStateChange);
    _requestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = widget.controller.draft;

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
              const SectionHeader(
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

              ListenableBuilder(
                listenable: _requestController,
                builder: (context, child) {
                  final state = _requestController.state;
                  
                  if (state.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppConstants.spaceM),
                      child: LoadingView(message: 'Requesting ride...'),
                    );
                  }

                  return CustomButton(
                    text: 'Request Ride',
                    onPressed: () {
                      _requestController.submitRequest(draft);
                    },
                    isLoading: false,
                  );
                },
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

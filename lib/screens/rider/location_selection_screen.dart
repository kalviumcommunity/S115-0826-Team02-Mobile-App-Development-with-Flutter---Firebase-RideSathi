import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/location_selection_controller.dart';
import '../../models/location_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/section_header.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final LocationSelectionController _controller = LocationSelectionController();
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {
      _validationError = null; // Clear error on change
    });
  }

  Future<void> _selectLocation(bool isPickup) async {
    final result = await AppNavigator.pushNamed<LocationModel>(
      context,
      AppRoutes.riderLocationSearch,
      arguments: isPickup ? 'pickup' : 'destination',
    );

    if (result != null) {
      if (isPickup) {
        _controller.setPickup(result);
      } else {
        _controller.setDestination(result);
      }
    }
  }

  void _onContinue() {
    final error = _controller.validate();
    if (error != null) {
      setState(() {
        _validationError = error;
      });
      return;
    }

    AppNavigator.pushNamed(context, AppRoutes.riderReviewRide, arguments: _controller);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = _controller.draft;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request a Ride'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spaceXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'Where would you like to go?',
                subtitle: 'Choose your pickup and drop-off locations.',
              ),
              const SizedBox(height: AppConstants.spaceXL),

              // Pickup Location
              _LocationSelector(
                label: 'Pickup location',
                placeholder: 'Search or select pickup location',
                icon: Icons.my_location_rounded,
                location: draft.pickup,
                onTap: () => _selectLocation(true),
              ),
              const SizedBox(height: AppConstants.spaceL),

              // Destination Location
              _LocationSelector(
                label: 'Where are you going?',
                placeholder: 'Search destination',
                icon: Icons.location_on_rounded,
                location: draft.destination,
                onTap: () => _selectLocation(false),
              ),

              if (_validationError != null) ...[
                const SizedBox(height: AppConstants.spaceL),
                Text(
                  _validationError!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const Spacer(),

              // Continue Button
              CustomButton(
                label: 'Continue',
                onPressed: _onContinue,
                isLoading: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationSelector extends StatelessWidget {
  final String label;
  final String placeholder;
  final IconData icon;
  final LocationModel? location;
  final VoidCallback onTap;

  const _LocationSelector({
    required this.label,
    required this.placeholder,
    required this.icon,
    this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = location != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spaceS),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.spaceM),
            decoration: BoxDecoration(
              border: Border.all(
                color: hasValue
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: hasValue ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surface,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: hasValue
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppConstants.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasValue) ...[
                        Text(
                          location!.displayName,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          location!.address,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else
                        Text(
                          placeholder,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

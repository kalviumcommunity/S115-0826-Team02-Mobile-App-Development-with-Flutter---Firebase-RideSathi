import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/state/view_state.dart';
import '../../models/location_model.dart';
import '../../services/location_service.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/view_state_builder.dart';

class LocationSearchScreen extends StatefulWidget {
  final String locationType; // 'pickup' or 'destination'

  const LocationSearchScreen({
    super.key,
    required this.locationType,
  });

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = MockLocationService();
  
  ViewState<List<LocationModel>> _searchState = const ViewState.initial();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchState = const ViewState.initial();
      });
      return;
    }

    setState(() {
      _searchState = const ViewState.loading(message: 'Searching locations...');
    });

    try {
      final results = await _locationService.searchLocations(query);
      
      if (!mounted) return;

      if (results.isEmpty) {
        setState(() {
          _searchState = const ViewState.empty(message: 'No locations found. Try a different search.');
        });
      } else {
        setState(() {
          _searchState = ViewState.success(results);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchState = ViewState.error(
          'We couldn\'t find that location. Please try again.',
          error: e,
        );
      });
    }
  }

  void _onLocationSelected(LocationModel location) {
    Navigator.of(context).pop(location);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.locationType == 'pickup' 
        ? 'Search Pickup' 
        : 'Search Destination';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceL,
              vertical: AppConstants.spaceM,
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              onChanged: _performSearch,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ViewStateBuilder<List<LocationModel>>(
          state: _searchState,
          initialBuilder: (context) => const Center(
            child: Text('Type to search for a location'),
          ),
          loadingBuilder: (context, message) => LoadingView(message: message),
          emptyBuilder: (context, message) => EmptyStateView(
            message: message ?? 'No locations found',
            icon: Icons.search_off_rounded,
          ),
          errorBuilder: (context, message, code, error) => ErrorView(
            message: message,
            onRetry: () => _performSearch(_searchController.text),
          ),
          successBuilder: (context, locations) {
            return ListView.separated(
              itemCount: locations.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final location = locations[index];
                return ListTile(
                  leading: Icon(
                    widget.locationType == 'pickup'
                        ? Icons.my_location_rounded
                        : Icons.location_on_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(location.displayName),
                  subtitle: Text(location.address),
                  onTap: () => _onLocationSelected(location),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

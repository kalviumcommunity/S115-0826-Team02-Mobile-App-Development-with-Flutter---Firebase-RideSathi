import 'dart:async';
import '../models/location_model.dart';
import 'service_exception.dart';

/// Abstraction for location search and retrieval services.
abstract class LocationService {
  /// Searches for locations matching the given [query].
  /// 
  /// Throws a [ServiceException] if the lookup fails.
  Future<List<LocationModel>> searchLocations(String query);
}

/// A mock implementation of [LocationService] that returns predefined
/// results to simulate a location provider without needing an external
/// SDK or map dependency.
class MockLocationService implements LocationService {
  final List<LocationModel> _mockDatabase = const [
    LocationModel(
      id: 'loc_1',
      displayName: 'Central Station',
      address: 'Main Railway Station Road, City Center',
    ),
    LocationModel(
      id: 'loc_2',
      displayName: 'City Airport',
      address: 'Terminal 1, Airport Road',
    ),
    LocationModel(
      id: 'loc_3',
      displayName: 'Shopping Mall',
      address: 'Grand Avenue, North District',
    ),
    LocationModel(
      id: 'loc_4',
      displayName: 'Tech Park',
      address: 'Innovation Drive, Business Area',
    ),
    LocationModel(
      id: 'loc_5',
      displayName: 'City Hospital',
      address: 'Medical Center Avenue',
    ),
  ];

  @override
  Future<List<LocationModel>> searchLocations(String query) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (query.trim().isEmpty) {
      return [];
    }

    // Simulate an occasional random provider error (1 in 10 chance)
    // Removed to make manual testing more deterministic, or we can keep it 
    // strictly to query matching for predictable UI tests.

    final normalizedQuery = query.toLowerCase().trim();

    // Special case to trigger a simulated error for testing
    if (normalizedQuery == 'error') {
      throw ServiceException('Simulated location provider error', code: 'mock_error');
    }

    final results = _mockDatabase.where((loc) {
      return loc.displayName.toLowerCase().contains(normalizedQuery) ||
             loc.address.toLowerCase().contains(normalizedQuery);
    }).toList();

    return results;
  }
}

import 'dart:async';
import '../models/location_model.dart';

/// Abstraction for location search and retrieval services.
abstract class LocationService {
  /// Searches for locations matching the given [query].
  /// 
  /// Throws a [ServiceException] if the lookup fails.
  Future<List<LocationModel>> searchLocations(String query);
}

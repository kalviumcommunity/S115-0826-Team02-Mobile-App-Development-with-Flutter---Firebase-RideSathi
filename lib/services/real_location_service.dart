import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import 'service_exception.dart';
import 'location_service.dart';

/// Real location service using geolocator for GPS and Nominatim (OpenStreetMap)
/// for geocoding — no native geocoding SDK required.
class RealLocationService implements LocationService {
  static const String _nominatimBase = 'https://nominatim.openstreetmap.org';
  static const Map<String, String> _headers = {
    'User-Agent': 'RideSathi/1.0 (com.ridesathi.ridesathi)',
    'Accept-Language': 'en',
  };

  @override
  Future<List<LocationModel>> searchLocations(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      // Use Photon API instead of Nominatim for much better full-text search and typo tolerance.
      // We pass the user's current location if available to bias the search results.
      Position? pos;
      try {
        pos = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      final queryParams = {
        'q': query.trim(),
        'limit': '5',
      };
      
      // Bias results to India and the user's rough location if available
      if (pos != null) {
        queryParams['lat'] = pos.latitude.toString();
        queryParams['lon'] = pos.longitude.toString();
      }

      final uri = Uri.parse('https://photon.komoot.io/api/').replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>? ?? [];
      final results = <LocationModel>[];

      for (var i = 0; i < features.length; i++) {
        final feature = features[i] as Map<String, dynamic>;
        final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
        final coords = geometry['coordinates'] as List<dynamic>? ?? [0.0, 0.0];
        // Photon uses [lon, lat] format
        final lon = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();

        final props = feature['properties'] as Map<String, dynamic>? ?? {};
        
        // Filter out non-Indian results to keep it strictly local
        final countrycode = props['countrycode']?.toString().toUpperCase();
        if (countrycode != null && countrycode != 'IN') continue;

        final name = props['name']?.toString() ?? props['street']?.toString() ?? query;
        
        final formattedAddress = [
          props['street'] as String?,
          props['district'] as String? ?? props['suburb'] as String?,
          props['city'] as String? ?? props['town'] as String?,
          props['state'] as String?,
        ].where((s) => s != null && s.isNotEmpty).join(', ');

        results.add(LocationModel(
          id: 'photon_$i',
          displayName: name,
          address: formattedAddress.isNotEmpty ? formattedAddress : name,
          latitude: lat,
          longitude: lon,
        ));
      }
      return results;
    } on TimeoutException {
      throw const ServiceException('Search timed out. Please check your connection.');
    } catch (_) {
      return [];
    }
  }

  /// Gets the user's current device location and reverse-geocodes it via Nominatim.
  Future<LocationModel> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const ServiceException('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        final ipLoc = await _getIpLocationFallback();
        if (ipLoc != null) return ipLoc;
        throw const ServiceException('Location permissions are denied.');
      }
    }

    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        final ipLoc = await _getIpLocationFallback();
        if (ipLoc != null) return ipLoc;
        throw const ServiceException('Failed to get current location.');
      }

      String displayName = 'Current Location';
      String formattedAddress =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';

      try {
        final uri = Uri.parse('$_nominatimBase/reverse').replace(
          queryParameters: {
            'lat': position.latitude.toString(),
            'lon': position.longitude.toString(),
            'format': 'json',
            'addressdetails': '1',
          },
        );
        final response = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final address = data['address'] as Map<String, dynamic>? ?? {};
          displayName = address['amenity'] as String? ??
              address['road'] as String? ??
              address['neighbourhood'] as String? ??
              'Current Location';
          formattedAddress = [
            address['road'] as String?,
            address['suburb'] as String?,
            address['city'] as String? ?? address['town'] as String?,
            address['state'] as String?,
          ].where((s) => s != null && s.isNotEmpty).join(', ');
          if (formattedAddress.isEmpty) {
            formattedAddress = data['display_name']?.toString() ?? formattedAddress;
          }
        }
      } catch (_) {}

      return LocationModel(
        id: 'current_device_location',
        displayName: displayName,
        address: formattedAddress,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      final ipLoc = await _getIpLocationFallback();
      if (ipLoc != null) return ipLoc;
      throw const ServiceException('Failed to get current location.');
    }
  }

  Future<LocationModel?> _getIpLocationFallback() async {
    try {
      final ipResponse = await http.get(Uri.parse('http://ip-api.com/json/')).timeout(const Duration(seconds: 5));
      if (ipResponse.statusCode == 200) {
        final ipData = jsonDecode(ipResponse.body);
        if (ipData['status'] == 'success') {
          return LocationModel(
            id: 'ip_location',
            displayName: ipData['city']?.toString() ?? 'Current Location',
            address: '${ipData['city']}, ${ipData['regionName']}, ${ipData['country']}',
            latitude: (ipData['lat'] as num).toDouble(),
            longitude: (ipData['lon'] as num).toDouble(),
          );
        }
      }
    } catch (_) {}
    return null;
  }
}


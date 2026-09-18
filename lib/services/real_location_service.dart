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
      final uri = Uri.parse('$_nominatimBase/search').replace(
        queryParameters: {
          'q': query.trim(),
          'format': 'json',
          'limit': '5',
          'addressdetails': '1',
        },
      );

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      final results = <LocationModel>[];

      for (var i = 0; i < data.length; i++) {
        final item = data[i] as Map<String, dynamic>;
        final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
        final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;
        final displayName = item['display_name']?.toString() ?? query;
        final address = item['address'] as Map<String, dynamic>? ?? {};
        final shortName = address['amenity'] as String? ??
            address['road'] as String? ??
            address['neighbourhood'] as String? ??
            address['suburb'] as String? ??
            query;
        final formattedAddress = [
          address['road'] as String?,
          address['suburb'] as String?,
          address['city'] as String? ?? address['town'] as String?,
          address['state'] as String?,
        ].where((s) => s != null && s.isNotEmpty).join(', ');

        results.add(LocationModel(
          id: 'nominatim_$i',
          displayName: shortName,
          address: formattedAddress.isNotEmpty ? formattedAddress : displayName,
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
      if (permission == LocationPermission.denied) {
        throw const ServiceException('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const ServiceException(
          'Location permissions are permanently denied.');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15));

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
      } catch (_) {
        // Fallback to raw coordinates if reverse-geocoding fails
      }

      return LocationModel(
        id: 'current_device_location',
        displayName: displayName,
        address: formattedAddress,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      throw const ServiceException('Failed to get current location.');
    }
  }
}


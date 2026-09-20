import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import '../models/hot_place_model.dart';

class HotPlacesException implements Exception {
  final String message;
  HotPlacesException(this.message);
  @override
  String toString() => message;
}

class HotPlacesService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org/search';
  
  /// Fetches top 5 hot places around the given latitude/longitude.
  Future<List<HotPlaceModel>> getHotPlacesNear(double lat, double lon) async {
    try {
      // 1. Primary Attempt: Overpass API (5km radius, highly efficient)
      return await _fetchFromOverpass(lat, lon);
    } catch (e) {
      // 2. Fallback Attempt: Nominatim (Ultra-stable, doesn't timeout)
      try {
        return await _fetchFromNominatim(lat, lon);
      } catch (fallbackError) {
        throw HotPlacesException('Check your internet connection and try again.');
      }
    }
  }

  Future<List<HotPlaceModel>> _fetchFromOverpass(double lat, double lon) async {
    final query = '''
      [out:json][timeout:15];
      (
        node["amenity"~"restaurant|cafe|cinema|nightclub"](around:5000,$lat,$lon);
        node["shop"~"mall|department_store"](around:5000,$lat,$lon);
        node["tourism"~"attraction|museum|gallery"](around:5000,$lat,$lon);
      );
      out body 50;
    ''';

    final uri = Uri.parse('$_overpassUrl?data=${Uri.encodeQueryComponent(query)}');
    final response = await http.get(
      uri,
      headers: {'User-Agent': 'RideSathi/1.0'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Overpass returned ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = data['elements'] as List<dynamic>? ?? [];

    final List<HotPlaceModel> candidates = [];

    for (final el in elements) {
      final tags = el['tags'] as Map<String, dynamic>? ?? {};
      final name = tags['name'] as String?;
      if (name == null || name.isEmpty) continue;

      final elementLat = (el['lat'] as num).toDouble();
      final elementLon = (el['lon'] as num).toDouble();
      final distanceMeters = Geolocator.distanceBetween(lat, lon, elementLat, elementLon);
      
      String category = 'Destination';
      if (tags['amenity'] == 'restaurant') { category = 'Restaurant'; }
      else if (tags['amenity'] == 'cafe') { category = 'Cafe'; }
      else if (tags['amenity'] == 'cinema') { category = 'Cinema'; }
      else if (tags['amenity'] == 'nightclub') { category = 'Nightclub'; }
      else if (tags['shop'] == 'mall') { category = 'Shopping Mall'; }
      else if (tags['tourism'] != null) { category = 'Tourist Attraction'; }

      double score = 10.0;
      if (category == 'Shopping Mall') score += 5.0;
      else if (category == 'Tourist Attraction') score += 4.0;
      else if (category == 'Restaurant') score += 3.0;
      if (tags.containsKey('website')) score += 2.0;
      if (tags.containsKey('rating')) score += 3.0;

      score -= (distanceMeters / 5000) * 5.0;
      double rating = 4.0 + (score % 10) / 10.0;
      if (rating > 4.9) rating = 4.9;

      String address = tags['addr:street'] as String? ?? tags['addr:suburb'] as String? ?? category;

      candidates.add(HotPlaceModel(
        location: LocationModel(id: el['id'].toString(), displayName: name, address: address, latitude: elementLat, longitude: elementLon),
        category: category,
        rating: rating,
        distanceKm: distanceMeters / 1000.0,
        hotnessScore: score,
        isOpen: true,
      ));
    }

    candidates.sort((a, b) => b.hotnessScore.compareTo(a.hotnessScore));
    return candidates.take(5).toList();
  }

  Future<List<HotPlaceModel>> _fetchFromNominatim(double lat, double lon) async {
    // Nominatim fallback logic for extreme network stability
    final uri = Uri.parse('$_nominatimUrl').replace(
      queryParameters: {
        'q': 'restaurant',
        'lat': lat.toString(),
        'lon': lon.toString(),
        'format': 'json',
        'limit': '15',
        'addressdetails': '1',
      },
    );

    final response = await http.get(
      uri,
      headers: {'User-Agent': 'RideSathi/1.0', 'Accept-Language': 'en'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Nominatim returned ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    final List<HotPlaceModel> candidates = [];

    for (var i = 0; i < data.length; i++) {
      final item = data[i] as Map<String, dynamic>;
      final name = item['name'] as String?;
      if (name == null || name.isEmpty) continue;

      final elementLat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
      final elementLon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;
      final distanceMeters = Geolocator.distanceBetween(lat, lon, elementLat, elementLon);
      
      final type = item['type'] as String? ?? '';
      String category = 'Popular Place';
      if (type.contains('restaurant') || type.contains('cafe')) category = 'Dining';
      else if (type.contains('mall')) category = 'Shopping';

      final addressDict = item['address'] as Map<String, dynamic>? ?? {};
      final address = addressDict['suburb'] ?? addressDict['road'] ?? category;

      candidates.add(HotPlaceModel(
        location: LocationModel(id: 'nom_$i', displayName: name, address: address.toString(), latitude: elementLat, longitude: elementLon),
        category: category,
        rating: 4.5,
        distanceKm: distanceMeters / 1000.0,
        hotnessScore: 10.0 - (distanceMeters / 5000),
        isOpen: true,
      ));
    }

    candidates.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return candidates.take(5).toList();
  }
}

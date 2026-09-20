import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'service_exception.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class RouteService {
  static const String _osrmBase = 'https://router.project-osrm.org/route/v1/driving';

  Future<RouteResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final String coords = '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';
      final uri = Uri.parse('$_osrmBase/$coords?overview=full&geometries=geojson');

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ServiceException('Failed to fetch route. Please try again.');
      }

      final data = jsonDecode(response.body);

      if (data['code'] != 'Ok') {
        throw ServiceException('No route found between these locations.');
      }

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        throw ServiceException('No route found between these locations.');
      }

      final route = routes.first;
      final geometry = route['geometry'];
      if (geometry == null || geometry['type'] != 'LineString') {
        throw ServiceException('Invalid route geometry received.');
      }

      final coordinates = geometry['coordinates'] as List<dynamic>;
      final points = coordinates.map((coord) {
        // GeoJSON coordinates are [longitude, latitude]
        final lon = (coord[0] as num).toDouble();
        final lat = (coord[1] as num).toDouble();
        return LatLng(lat, lon);
      }).toList();

      final distance = (route['distance'] as num?)?.toDouble() ?? 0.0;
      final duration = (route['duration'] as num?)?.toDouble() ?? 0.0;

      return RouteResult(
        points: points,
        distanceMeters: distance,
        durationSeconds: duration,
      );
    } on ServiceException {
      rethrow;
    } catch (e) {
      throw ServiceException('Unable to calculate route. Please check your connection and try again.');
    }
  }
}

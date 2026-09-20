import 'location_model.dart';

/// Represents a trending or popular destination.
class HotPlaceModel {
  final LocationModel location;
  final String category;
  final double rating;
  final double distanceKm;
  final double hotnessScore;
  final bool isOpen;

  const HotPlaceModel({
    required this.location,
    required this.category,
    required this.rating,
    required this.distanceKm,
    required this.hotnessScore,
    this.isOpen = true,
  });
}

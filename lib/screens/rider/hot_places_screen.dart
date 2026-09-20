import 'package:flutter/material.dart';
import '../../models/hot_place_model.dart';
import '../../services/hot_places_service.dart';
import '../../services/real_location_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/location_selection_controller.dart';
import '../../models/location_model.dart';

class HotPlacesScreen extends StatefulWidget {
  const HotPlacesScreen({super.key});

  @override
  State<HotPlacesScreen> createState() => _HotPlacesScreenState();
}

class _HotPlacesScreenState extends State<HotPlacesScreen> {
  final _hotPlacesService = HotPlacesService();
  final _locationService = RealLocationService();

  List<HotPlaceModel>? _hotPlaces;
  String? _errorMessage;
  bool _isRefreshing = false;
  LocationModel? _currentLocation;

  @override
  void initState() {
    super.initState();
    _fetchHotPlaces();
  }

  Future<void> _fetchHotPlaces({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() => _isRefreshing = true);
    } else {
      setState(() {
        _hotPlaces = null;
        _errorMessage = null;
      });
    }

    try {
      final loc = await _locationService.getCurrentLocation();
      _currentLocation = loc;

      final places = await _hotPlacesService.getHotPlacesNear(loc.latitude ?? 18.5204, loc.longitude ?? 73.8567);
      
      if (!mounted) return;

      if (places.isEmpty) {
        setState(() => _errorMessage = 'No popular places found nearby.');
      } else {
        setState(() => _hotPlaces = places);
      }
    } on HotPlacesException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Location permission is required to find places near you. Turn on location services.');
    } finally {
      if (isRefresh && mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _onGetRide(HotPlaceModel place) {
    if (_currentLocation == null) return;
    
    final controller = LocationSelectionController();
    controller.setPickup(LocationModel(
      id: 'pickup_current',
      latitude: _currentLocation!.latitude,
      longitude: _currentLocation!.longitude,
      displayName: 'Current Location',
      address: '',
    ));
    controller.setDestination(place.location);
    Navigator.pushNamed(context, AppRoutes.riderReviewRide, arguments: controller);
  }

  void _onChangeLocation() {
    Navigator.pushNamed(context, AppRoutes.riderLocationSearch);
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = const Color(0xFF121B27);
    final cardBg = const Color(0xFF1C2738);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('🔥 ', style: TextStyle(fontSize: 22)),
                Text('Hot Places', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
            Text('Trending around you today', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMainList(cardBg),
          ),
          // Bottom Refresh Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: scaffoldBg,
              border: const Border(top: BorderSide(color: Colors.white10)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _isRefreshing ? null : () => _fetchHotPlaces(isRefresh: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: _isRefreshing ? Colors.grey : const Color(0xFFF59E0B)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isRefreshing)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B)))
                        else
                          const Icon(Icons.refresh, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        Text('Refresh Places', style: TextStyle(color: _isRefreshing ? Colors.grey : const Color(0xFFF59E0B), fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainList(Color cardBg) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _fetchHotPlaces(),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
                child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      );
    }

    if (_hotPlaces == null) {
      // Skeletons
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => _buildSkeletonCard(cardBg),
      );
    }

    // Success State
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _hotPlaces!.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 22, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Near your current location', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.grey.shade300), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _onChangeLocation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFF59E0B)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.my_location, size: 16, color: Color(0xFFF59E0B)),
                        SizedBox(width: 4),
                        Text('Change Location', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        
        if (index == 1) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'Displaying top ${_hotPlaces!.length} trending spots.',
              style: TextStyle(color: Colors.green.shade400, fontWeight: FontWeight.w500, fontSize: 14),
            ),
          );
        }

        final place = _hotPlaces![index - 2];
        return Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          child: _buildPlaceCard(place, cardBg),
        );
      },
    );
  }

  Widget _buildPlaceCard(HotPlaceModel place, Color cardBg) {
    // Generate badge aesthetics based on hotness score
    String badgeText = 'Popular';
    IconData badgeIcon = Icons.people;
    if (place.hotnessScore > 15) {
      badgeText = 'Trending';
      badgeIcon = Icons.local_fire_department;
    } else if (place.hotnessScore > 12) {
      badgeText = 'Hot today';
      badgeIcon = Icons.trending_up;
    }

    // Deterministically pick an image based on place ID so it stays consistent
    final imageList = [
      'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1481833758786-ceed163e90cb?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1537047902294-62a40c20a6ae?auto=format&fit=crop&w=300&q=80',
    ];
    final imageIndex = place.location.id.hashCode.abs() % imageList.length;
    final imageUrl = imageList[imageIndex];

    final fallbackGradient = Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blueGrey.shade800,
            Colors.grey.shade900,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(place.category),
          color: Colors.white54,
          size: 32,
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Real Image with fallback
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 90,
              height: 90,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallbackGradient,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return fallbackGradient;
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(place.location.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4332), // Dark green background
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 12, color: badgeText == 'Trending' ? Colors.amber : const Color(0xFF74C69D)),
                          const SizedBox(width: 4),
                          Text(badgeText, style: const TextStyle(color: Color(0xFF74C69D), fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  ],
                ),
                const SizedBox(height: 2),
                Text('${place.category} • ${place.location.address}', style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFFFACC15), size: 14),
                              const SizedBox(width: 4),
                              Text('${place.rating.toStringAsFixed(1)} ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              const Text('(Recent)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.grey, size: 14),
                              const SizedBox(width: 2),
                              Text('${place.distanceKm.toStringAsFixed(1)} km away', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _onGetRide(place),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.directions_car, size: 16, color: Colors.black),
                            SizedBox(width: 4),
                            Text('Get Ride', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    if (category.contains('Restaurant') || category.contains('Cafe')) return Icons.restaurant;
    if (category.contains('Mall')) return Icons.local_mall;
    if (category.contains('Cinema')) return Icons.movie;
    if (category.contains('Park') || category.contains('Attraction')) return Icons.park;
    return Icons.place;
  }

  Widget _buildSkeletonCard(Color cardBg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(width: 90, height: 90, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 150, height: 16, color: Colors.white10),
                const SizedBox(height: 8),
                Container(width: 100, height: 12, color: Colors.white10),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 80, height: 12, color: Colors.white10),
                    Container(width: 80, height: 32, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8))),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

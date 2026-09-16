import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/operational_analytics.dart';
import '../models/ride_model.dart';
import 'firestore_exception.dart';

class OperationalAnalyticsService {
  final FirebaseFirestore _firestore;

  OperationalAnalyticsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<OperationalAnalytics> getAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // 1. Fetch all rides in the bounded period (Avoids N+1 status queries)
      // Note: We use Timestamp to query Firestore properly.
      final ridesSnapshot = await _firestore
          .collection('rides')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // 2. Fetch current driver state (this isn't strictly bounded by date,
      // it's a snapshot of "now" to satisfy active operations).
      final driversSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .where('isOnline', isEqualTo: true)
          .get();

      int total = 0, completed = 0, cancelled = 0, timedOut = 0, rejected = 0;
      int requested = 0, accepted = 0, arrived = 0, inProgress = 0;

      final locationDemandMap = <String, int>{};
      final timeDemandMap = <int, int>{};

      for (final doc in ridesSnapshot.docs) {
        final data = doc.data();
        total++;
        
        // Status counts
        final status = data['status'] as String?;
        if (status == RideStatus.completed.name) completed++;
        else if (status == RideStatus.cancelled.name) cancelled++;
        else if (status == RideStatus.timedOut.name) timedOut++;
        else if (status == RideStatus.rejected.name) rejected++;
        else if (status == RideStatus.requested.name) requested++;
        else if (status == RideStatus.accepted.name) accepted++;
        else if (status == RideStatus.arrived.name) arrived++;
        else if (status == RideStatus.inProgress.name) inProgress++;

        // Demand by Location (using pickup displayName)
        final pickup = data['pickup'] as Map<String, dynamic>?;
        if (pickup != null) {
          final displayName = pickup['displayName'] as String? ?? 'Unknown Location';
          // Clean the name slightly or just use it raw
          locationDemandMap[displayName] = (locationDemandMap[displayName] ?? 0) + 1;
        } else {
          locationDemandMap['Unknown Location'] = (locationDemandMap['Unknown Location'] ?? 0) + 1;
        }

        // Demand by Time (Hour of day)
        final createdAt = data['createdAt'];
        if (createdAt is Timestamp) {
          // Use local time for hour grouping as per timezone instructions
          final dt = createdAt.toDate();
          timeDemandMap[dt.hour] = (timeDemandMap[dt.hour] ?? 0) + 1;
        }
      }

      // Driver Counts
      int online = 0, available = 0, onRide = 0;
      for (final doc in driversSnapshot.docs) {
        final data = doc.data();
        online++;
        final activeRideId = data['activeRideId'] as String?;
        if (activeRideId != null && activeRideId.isNotEmpty) {
          onRide++;
        } else {
          available++;
        }
      }

      // Format maps to sorted lists
      final demandByLocation = locationDemandMap.entries
          .map((e) => DemandByLocation(e.key, e.value))
          .toList()
          ..sort((a, b) => b.count.compareTo(a.count)); // Descending by volume

      // Top 10 locations to keep UI clean
      final topLocations = demandByLocation.take(10).toList();

      final demandByTime = timeDemandMap.entries
          .map((e) => DemandByTime(e.key, e.value))
          .toList()
          ..sort((a, b) => a.hourOfDay.compareTo(b.hourOfDay)); // Chronological

      return OperationalAnalytics(
        rideCounts: RideStatusCounts(
          total: total,
          completed: completed,
          cancelled: cancelled,
          timedOut: timedOut,
          rejected: rejected,
          requested: requested,
          accepted: accepted,
          arrived: arrived,
          inProgress: inProgress,
        ),
        driverSummary: DriverOperationalSummary(
          online: online,
          available: available,
          onRide: onRide,
        ),
        demandByLocation: topLocations,
        demandByTime: demandByTime,
      );
    } catch (e) {
      throw FirestoreException.from(e);
    }
  }
}

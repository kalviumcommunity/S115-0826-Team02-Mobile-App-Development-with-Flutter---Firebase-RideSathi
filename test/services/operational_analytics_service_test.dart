import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ridesathi/models/ride_model.dart';
import 'package:ridesathi/services/operational_analytics_service.dart';

void main() {
  group('OperationalAnalyticsService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late OperationalAnalyticsService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = OperationalAnalyticsService(firestore: fakeFirestore);
    });

    test('getAnalytics computes metrics correctly', () async {
      final now = DateTime.now();
      
      // Add fake rides
      await fakeFirestore.collection('rides').add({
        'status': RideStatus.completed.name,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
        'pickup': {'displayName': 'Downtown'},
      });
      
      await fakeFirestore.collection('rides').add({
        'status': RideStatus.cancelled.name,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
        'pickup': {'displayName': 'Airport'},
      });
      
      await fakeFirestore.collection('rides').add({
        'status': RideStatus.completed.name,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 3))),
        'pickup': {'displayName': 'Downtown'},
      });

      // Add fake drivers
      await fakeFirestore.collection('users').add({
        'role': 'driver',
        'isOnline': true,
        'activeRideId': 'ride123',
      });
      
      await fakeFirestore.collection('users').add({
        'role': 'driver',
        'isOnline': true,
        'activeRideId': null,
      });

      final analytics = await service.getAnalytics(
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 1)),
      );

      // Verify Rides
      expect(analytics.rideCounts.total, 3);
      expect(analytics.rideCounts.completed, 2);
      expect(analytics.rideCounts.cancelled, 1);
      expect(analytics.rideCounts.completionRate, 2 / 3);

      // Verify Drivers
      expect(analytics.driverSummary.online, 2);
      expect(analytics.driverSummary.onRide, 1);
      expect(analytics.driverSummary.available, 1);

      // Verify Locations
      expect(analytics.demandByLocation.length, 2);
      expect(analytics.demandByLocation.first.locationName, 'Downtown');
      expect(analytics.demandByLocation.first.count, 2);
    });
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../models/driver_operational_data.dart';
import '../models/user_model.dart';
import 'firestore_exception.dart';
import 'ride_service.dart';

/// Service responsible for aggregating real-time driver operational data for dispatch.
class DriverDataService {
  static FirebaseFirestore? firestoreOverride;

  final FirebaseFirestore? firestore;
  final RideService _rideService;

  DriverDataService({
    this.firestore,
    RideService? rideService,
  }) : _rideService = rideService ?? RideService();

  FirebaseFirestore get _instance => firestore ?? firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _instance.collection('users');

  /// Streams real-time operational data for all drivers who are currently Online.
  ///
  /// Aggregates profile availability data with current active ride location data.
  /// Throws [FirestoreException] on stream failure.
  Stream<List<DriverOperationalData>> watchOnlineDriversData() {
    return _watchDriversData(onlyOnline: true);
  }

  /// Streams real-time operational data for all drivers (online and offline).
  ///
  /// Aggregates profile availability data with current active ride location data.
  /// Throws [FirestoreException] on stream failure.
  Stream<List<DriverOperationalData>> watchAllDriversData() {
    return _watchDriversData(onlyOnline: false);
  }

  Stream<List<DriverOperationalData>> _watchDriversData({required bool onlyOnline}) {
    try {
      var query = _usersCollection.where('role', isEqualTo: UserRole.driver.name);
      
      if (onlyOnline) {
        query = query.where('isOnline', isEqualTo: true);
      }

      return query.snapshots().switchMap((snapshot) {
        if (snapshot.docs.isEmpty) {
          return Stream.value(<DriverOperationalData>[]);
        }

        final driverStreams = snapshot.docs.map((doc) {
          final data = doc.data();
          UserModel? driver;
          try {
            driver = UserModel.fromMap(data);
          } catch (e) {
            // Skip malformed profiles
            return Stream.value(null);
          }

          if (driver.id.isEmpty) {
            return Stream.value(null);
          }

          // 2. Stream the active ride for this driver to resolve location
          return _rideService.watchDriverActiveRide(driver.id).map((activeRide) {
            return DriverOperationalData(
              id: driver!.id,
              name: driver.name,
              phoneNumber: driver.phoneNumber,
              vehicleInfo: driver.vehicleInfo,
              isUnionVerified: driver.isUnionVerified,
              isOnline: driver.isOnline,
              availabilityUpdatedAt: driver.availabilityUpdatedAt,
              location: activeRide?.driverLocation,
              activeRideId: activeRide?.id,
            );
          }).onErrorReturn(
            // If active ride query fails, fallback to driver data without location
            DriverOperationalData(
              id: driver.id,
              name: driver.name,
              phoneNumber: driver.phoneNumber,
              vehicleInfo: driver.vehicleInfo,
              isUnionVerified: driver.isUnionVerified,
              isOnline: driver.isOnline,
              availabilityUpdatedAt: driver.availabilityUpdatedAt,
            ),
          );
        }).toList();

        // Combine all individual driver streams into a single list stream
        return Rx.combineLatestList(driverStreams).map((drivers) {
          return drivers.whereType<DriverOperationalData>().toList();
        });
      });
    } catch (e) {
      return Stream.error(FirestoreException.from(e));
    }
  }
}

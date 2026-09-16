class RideStatusCounts {
  final int total;
  final int completed;
  final int cancelled;
  final int timedOut;
  final int rejected;
  final int requested;
  final int accepted;
  final int arrived;
  final int inProgress;

  const RideStatusCounts({
    this.total = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.timedOut = 0,
    this.rejected = 0,
    this.requested = 0,
    this.accepted = 0,
    this.arrived = 0,
    this.inProgress = 0,
  });

  int get active => requested + accepted + arrived + inProgress;
  
  double get completionRate => total > 0 ? completed / total : 0.0;
  double get cancellationRate => total > 0 ? cancelled / total : 0.0;
  double get timeoutRate => total > 0 ? timedOut / total : 0.0;
  double get rejectionRate => total > 0 ? rejected / total : 0.0;
}

class DriverOperationalSummary {
  final int online;
  final int available;
  final int onRide;

  const DriverOperationalSummary({
    this.online = 0,
    this.available = 0,
    this.onRide = 0,
  });
}

class DemandByLocation {
  final String locationName;
  final int count;

  const DemandByLocation(this.locationName, this.count);
}

class DemandByTime {
  final int hourOfDay;
  final int count;

  const DemandByTime(this.hourOfDay, this.count);
}

class OperationalAnalytics {
  final RideStatusCounts rideCounts;
  final DriverOperationalSummary driverSummary;
  final List<DemandByLocation> demandByLocation;
  final List<DemandByTime> demandByTime;

  const OperationalAnalytics({
    required this.rideCounts,
    required this.driverSummary,
    required this.demandByLocation,
    required this.demandByTime,
  });
}

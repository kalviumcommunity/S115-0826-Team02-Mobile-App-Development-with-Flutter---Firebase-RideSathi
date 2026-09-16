/// An abstraction over the system clock to allow deterministic time-based testing.
abstract class Clock {
  const Clock();

  /// Returns the current date and time.
  DateTime now();
}

/// The default production implementation of [Clock] that uses the system time.
class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

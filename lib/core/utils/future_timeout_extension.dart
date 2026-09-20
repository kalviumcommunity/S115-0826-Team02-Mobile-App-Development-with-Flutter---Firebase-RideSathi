import 'dart:async';

/// Extension to apply a standardized network timeout to async operations.
extension FutureTimeoutExtension<T> on Future<T> {
  /// Applies a timeout to the Future, throwing a [TimeoutException] if it takes longer than [seconds].
  /// Default is 15 seconds.
  Future<T> withNetworkTimeout({int seconds = 15}) {
    return timeout(
      Duration(seconds: seconds),
      onTimeout: () {
        throw TimeoutException('The operation timed out. Please check your internet connection.');
      },
    );
  }
}

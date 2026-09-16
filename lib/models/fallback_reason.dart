/// Represents the domain reason why a previously selected candidate
/// is no longer considered the active fallback candidate.
enum FallbackReason {
  /// The driver went offline or is no longer available.
  wentOffline,
  
  /// The driver became active on another ride.
  activeOnAnotherRide,
  
  /// The driver lost location or their coordinates became invalid.
  lostLocation,
  
  /// The driver is no longer eligible (e.g. lost verification).
  noLongerEligible,
  
  /// The candidate entirely disappeared from the realtime stream.
  disappeared,
  
  /// A closer driver appeared, or this driver moved away, changing their rank.
  rankChanged,
  
  /// The driver manually accepted another ride or was assigned elsewhere.
  acceptedAnotherRide,
  
  /// Fallback reason could not be specifically determined.
  unknown,
}

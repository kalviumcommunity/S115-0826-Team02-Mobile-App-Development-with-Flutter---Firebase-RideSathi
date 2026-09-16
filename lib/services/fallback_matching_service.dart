import '../models/candidate_evaluation.dart';
import '../models/fallback_reason.dart';
import '../models/matching_attempt_state.dart';

/// Pure domain service responsible for determining the next eligible candidate
/// and identifying fallback reasons when the selected candidate changes.
class FallbackMatchingService {
  const FallbackMatchingService();

  /// Calculates the next state based on the latest ranked candidates and the previous state.
  MatchingAttemptState computeNextState(
    List<CandidateEvaluation> currentRankedCandidates,
    MatchingAttemptState previousState,
  ) {
    // 1. Identify all currently eligible candidates from the PR 41 stream.
    final eligibleCandidates = currentRankedCandidates.where((c) => c.isEligible).toList();

    // 2. If there are no eligible candidates at all, we enter the noCandidates state.
    if (eligibleCandidates.isEmpty) {
      return MatchingAttemptState(
        status: MatchingAttemptStatus.noCandidates,
        rankedCandidates: currentRankedCandidates,
      );
    }

    // 3. The newly selected candidate is always the #1 nearest eligible candidate.
    final nextCandidate = eligibleCandidates.first;
    final prevCandidate = previousState.currentCandidate;

    // 4. If there was no previous candidate, or it's the exact same driver, just return the selection.
    if (prevCandidate == null || prevCandidate.driver.id == nextCandidate.driver.id) {
      return MatchingAttemptState.selected(nextCandidate, currentRankedCandidates);
    }

    // 5. If the driver changed, we have experienced a fallback transition.
    // We must determine the reason why we left the previous candidate.
    final reason = _determineFallbackReason(prevCandidate, currentRankedCandidates);

    return MatchingAttemptState.fallback(nextCandidate, reason, currentRankedCandidates);
  }

  /// Determines why a previously selected candidate was dropped from the #1 spot.
  FallbackReason _determineFallbackReason(
    CandidateEvaluation previousCandidate,
    List<CandidateEvaluation> currentRankedCandidates,
  ) {
    // Try to find the previous candidate in the latest list (even if they are now ineligible).
    final currentStatus = currentRankedCandidates.where((c) => c.driver.id == previousCandidate.driver.id).firstOrNull;

    // If they disappeared entirely from the stream.
    if (currentStatus == null) {
      return FallbackReason.disappeared;
    }

    // If they are no longer eligible, their exclusionReason tells us why.
    if (!currentStatus.isEligible) {
      final exclusion = currentStatus.exclusionReason?.toUpperCase() ?? '';
      
      switch (exclusion) {
        case 'OFFLINE':
          return FallbackReason.wentOffline;
        case 'ACTIVE_RIDE':
          return FallbackReason.activeOnAnotherRide;
        case 'INVALID_LOCATION_DATA':
        case 'NO_LOCATION':
          return FallbackReason.lostLocation;
        case 'UNVERIFIED':
        case 'SUSPENDED':
          return FallbackReason.noLongerEligible;
        default:
          return FallbackReason.unknown;
      }
    }

    // If they are STILL eligible, but are no longer #1, it means their rank changed 
    // (e.g. they drove further away, or another driver came online much closer).
    return FallbackReason.rankChanged;
  }
}

import 'package:flutter/foundation.dart';
import 'candidate_evaluation.dart';
import 'fallback_reason.dart';

/// Represents the status of the current matching or fallback session.
enum MatchingAttemptStatus {
  /// Session has not started or has been reset.
  idle,
  
  /// Waiting for candidates to appear in the stream.
  searching,
  
  /// A valid candidate is selected and ranked #1.
  candidateSelected,
  
  /// The system transitioned to a new fallback candidate.
  fallbackTransition,
  
  /// The stream provided an empty or fully ineligible list.
  noCandidates,
  
  /// The ride request timed out before a driver could be assigned.
  timedOut,
  
  /// An error occurred in the stream.
  error,
  
  /// Currently attempting an authoritative assignment transaction.
  assigning,
  
  /// Assignment succeeded.
  assigned,
}

/// A lightweight state representation for a matching attempt.
@immutable
class MatchingAttemptState {
  final MatchingAttemptStatus status;
  final CandidateEvaluation? currentCandidate;
  final FallbackReason? lastFallbackReason;
  final String? errorMessage;
  final List<CandidateEvaluation> rankedCandidates;

  const MatchingAttemptState({
    this.status = MatchingAttemptStatus.idle,
    this.currentCandidate,
    this.lastFallbackReason,
    this.errorMessage,
    this.rankedCandidates = const [],
  });

  MatchingAttemptState copyWith({
    MatchingAttemptStatus? status,
    CandidateEvaluation? currentCandidate,
    FallbackReason? lastFallbackReason,
    String? errorMessage,
    List<CandidateEvaluation>? rankedCandidates,
  }) {
    return MatchingAttemptState(
      status: status ?? this.status,
      // Use null-aware assignments only if we explicitly want to retain them.
      // Since currentCandidate can be cleared, we provide a way to unset it.
      // However, for this simple copyWith, we'll assume standard replacement.
      currentCandidate: currentCandidate ?? this.currentCandidate,
      lastFallbackReason: lastFallbackReason ?? this.lastFallbackReason,
      errorMessage: errorMessage ?? this.errorMessage,
      rankedCandidates: rankedCandidates ?? this.rankedCandidates,
    );
  }

  /// Create a fresh state with a new current candidate.
  factory MatchingAttemptState.selected(
    CandidateEvaluation candidate,
    List<CandidateEvaluation> allCandidates,
  ) {
    return MatchingAttemptState(
      status: MatchingAttemptStatus.candidateSelected,
      currentCandidate: candidate,
      rankedCandidates: allCandidates,
    );
  }

  /// Create a fallback transition state.
  factory MatchingAttemptState.fallback(
    CandidateEvaluation newCandidate,
    FallbackReason reason,
    List<CandidateEvaluation> allCandidates,
  ) {
    return MatchingAttemptState(
      status: MatchingAttemptStatus.fallbackTransition,
      currentCandidate: newCandidate,
      lastFallbackReason: reason,
      rankedCandidates: allCandidates,
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/models/candidate_evaluation.dart';
import 'package:ridesathi/models/driver_operational_data.dart';
import 'package:ridesathi/models/fallback_reason.dart';
import 'package:ridesathi/models/matching_attempt_state.dart';
import 'package:ridesathi/services/fallback_matching_service.dart';

void main() {
  group('FallbackMatchingService', () {
    late FallbackMatchingService service;

    setUp(() {
      service = const FallbackMatchingService();
    });

    DriverOperationalData createDriver(String id) {
      return DriverOperationalData(
        id: id,
        name: 'Driver $id',
        phoneNumber: '1234567890',
        isOnline: true,
        isUnionVerified: true,
      );
    }

    CandidateEvaluation createCandidate(String id, bool eligible, {String? reason, double? distance}) {
      return CandidateEvaluation(
        driver: createDriver(id),
        isEligible: eligible,
        exclusionReason: reason,
        distanceKm: distance,
      );
    }

    test('idle/no candidates -> searching yields noCandidates', () {
      final state = service.computeNextState([], const MatchingAttemptState());
      expect(state.status, MatchingAttemptStatus.noCandidates);
      expect(state.currentCandidate, isNull);
    });

    test('idle -> candidateSelected for first eligible', () {
      final c1 = createCandidate('1', false, reason: 'OFFLINE');
      final c2 = createCandidate('2', true, distance: 1.0);
      
      final state = service.computeNextState([c1, c2], const MatchingAttemptState());
      
      expect(state.status, MatchingAttemptStatus.candidateSelected);
      expect(state.currentCandidate?.driver.id, '2');
    });

    test('candidateSelected -> candidateSelected (same candidate)', () {
      final c2 = createCandidate('2', true, distance: 1.0);
      final initialState = MatchingAttemptState.selected(c2, [c2]);
      
      final state = service.computeNextState([c2], initialState);
      
      expect(state.status, MatchingAttemptStatus.candidateSelected);
      expect(state.currentCandidate?.driver.id, '2');
    });

    test('fallback -> disappeared', () {
      final c1 = createCandidate('1', true, distance: 1.0);
      final c2 = createCandidate('2', true, distance: 2.0);
      final initialState = MatchingAttemptState.selected(c1, [c1, c2]);
      
      // Candidate 1 entirely missing
      final state = service.computeNextState([c2], initialState);
      
      expect(state.status, MatchingAttemptStatus.fallbackTransition);
      expect(state.currentCandidate?.driver.id, '2');
      expect(state.lastFallbackReason, FallbackReason.disappeared);
    });

    test('fallback -> wentOffline', () {
      final c1 = createCandidate('1', true, distance: 1.0);
      final c2 = createCandidate('2', true, distance: 2.0);
      final initialState = MatchingAttemptState.selected(c1, [c1, c2]);
      
      final c1Offline = createCandidate('1', false, reason: 'OFFLINE');
      final state = service.computeNextState([c1Offline, c2], initialState);
      
      expect(state.status, MatchingAttemptStatus.fallbackTransition);
      expect(state.currentCandidate?.driver.id, '2');
      expect(state.lastFallbackReason, FallbackReason.wentOffline);
    });

    test('fallback -> activeOnAnotherRide', () {
      final c1 = createCandidate('1', true, distance: 1.0);
      final c2 = createCandidate('2', true, distance: 2.0);
      final initialState = MatchingAttemptState.selected(c1, [c1, c2]);
      
      final c1Active = createCandidate('1', false, reason: 'ACTIVE_RIDE');
      final state = service.computeNextState([c1Active, c2], initialState);
      
      expect(state.status, MatchingAttemptStatus.fallbackTransition);
      expect(state.currentCandidate?.driver.id, '2');
      expect(state.lastFallbackReason, FallbackReason.activeOnAnotherRide);
    });

    test('fallback -> rankChanged (another driver became closer)', () {
      final c1 = createCandidate('1', true, distance: 2.0);
      final c2 = createCandidate('2', true, distance: 3.0);
      final initialState = MatchingAttemptState.selected(c1, [c1, c2]);
      
      // C3 logs on and is closer
      final c3 = createCandidate('3', true, distance: 1.0);
      final state = service.computeNextState([c3, c1, c2], initialState);
      
      expect(state.status, MatchingAttemptStatus.fallbackTransition);
      expect(state.currentCandidate?.driver.id, '3');
      expect(state.lastFallbackReason, FallbackReason.rankChanged);
    });
  });
}

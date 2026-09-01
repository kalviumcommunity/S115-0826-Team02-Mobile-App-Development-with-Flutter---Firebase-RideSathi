import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/state/view_state.dart';

void main() {
  group('ViewState — Construction & Initial State', () {
    test('ViewState.initial creates idle state with initial status', () {
      const state = ViewState<String>.initial();

      expect(state.status, equals(ViewStatus.initial));
      expect(state.isInitial, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.isEmpty, isFalse);
      expect(state.isError, isFalse);
      expect(state.data, isNull);
      expect(state.hasData, isFalse);
      expect(state.message, isNull);
    });

    test('ViewState.loading creates loading state with optional message and data', () {
      const state = ViewState<String>.loading(
        message: 'Fetching rides...',
        previousData: 'old-data',
      );

      expect(state.status, equals(ViewStatus.loading));
      expect(state.isLoading, isTrue);
      expect(state.message, equals('Fetching rides...'));
      expect(state.data, equals('old-data'));
      expect(state.hasData, isTrue);
    });

    test('ViewState.success creates success state with payload data', () {
      const state = ViewState<int>.success(42, message: 'Loaded successfully');

      expect(state.status, equals(ViewStatus.success));
      expect(state.isSuccess, isTrue);
      expect(state.data, equals(42));
      expect(state.hasData, isTrue);
      expect(state.message, equals('Loaded successfully'));
    });

    test('ViewState.empty creates empty state with optional message', () {
      const state = ViewState<List<String>>.empty(message: 'No rides found');

      expect(state.status, equals(ViewStatus.empty));
      expect(state.isEmpty, isTrue);
      expect(state.data, isNull);
      expect(state.message, equals('No rides found'));
    });

    test('ViewState.error creates error state with message, code, and error object', () {
      final customError = Exception('Network error');
      final state = ViewState<String>.error(
        'Failed to load',
        code: 'NETWORK_TIMEOUT',
        error: customError,
        previousData: 'cached',
      );

      expect(state.status, equals(ViewStatus.error));
      expect(state.isError, isTrue);
      expect(state.message, equals('Failed to load'));
      expect(state.code, equals('NETWORK_TIMEOUT'));
      expect(state.error, equals(customError));
      expect(state.data, equals('cached'));
    });
  });

  group('ViewState — Pattern Matching (when / maybeWhen)', () {
    test('when invokes the corresponding callback for all states', () {
      const initial = ViewState<String>.initial();
      expect(
        initial.when(
          initial: () => 'is-initial',
          loading: (_) => 'is-loading',
          success: (_) => 'is-success',
          empty: (_) => 'is-empty',
          error: (_, _, _) => 'is-error',
        ),
        equals('is-initial'),
      );

      const loading = ViewState<String>.loading(message: 'Loading...');
      expect(
        loading.when(
          initial: () => 'is-initial',
          loading: (msg) => 'loading: $msg',
          success: (_) => 'is-success',
          empty: (_) => 'is-empty',
          error: (_, _, _) => 'is-error',
        ),
        equals('loading: Loading...'),
      );

      const success = ViewState<String>.success('Payload');
      expect(
        success.when(
          initial: () => 'is-initial',
          loading: (_) => 'is-loading',
          success: (data) => 'success: $data',
          empty: (_) => 'is-empty',
          error: (_, _, _) => 'is-error',
        ),
        equals('success: Payload'),
      );

      const empty = ViewState<String>.empty(message: 'Empty');
      expect(
        empty.when(
          initial: () => 'is-initial',
          loading: (_) => 'is-loading',
          success: (_) => 'is-success',
          empty: (msg) => 'empty: $msg',
          error: (_, _, _) => 'is-error',
        ),
        equals('empty: Empty'),
      );

      const error = ViewState<String>.error('Failed', code: 'ERR_01');
      expect(
        error.when(
          initial: () => 'is-initial',
          loading: (_) => 'is-loading',
          success: (_) => 'is-success',
          empty: (_) => 'is-empty',
          error: (msg, code, _) => 'error: $msg ($code)',
        ),
        equals('error: Failed (ERR_01)'),
      );
    });

    test('maybeWhen returns orElse when specific callback is omitted', () {
      const success = ViewState<int>.success(100);

      final result = success.maybeWhen(
        loading: (_) => 'loading',
        orElse: () => 'fallback',
      );

      expect(result, equals('fallback'));
    });
  });

  group('ViewState — Equality and toString', () {
    test('equal states match and have identical hashCodes', () {
      const state1 = ViewState<String>.success('data', message: 'ok');
      const state2 = ViewState<String>.success('data', message: 'ok');
      const state3 = ViewState<String>.success('other', message: 'ok');

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
      expect(state1, isNot(equals(state3)));
    });

    test('toString formats cleanly with status and data', () {
      const state = ViewState<String>.success('ride-123');
      expect(state.toString(), contains('ViewState<String>'));
      expect(state.toString(), contains('ride-123'));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/state/view_state.dart';
import 'package:ridesathi/widgets/empty_state_view.dart';
import 'package:ridesathi/widgets/error_view.dart';
import 'package:ridesathi/widgets/loading_view.dart';
import 'package:ridesathi/widgets/view_state_builder.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('ViewStateBuilder — State Mapping', () {
    testWidgets('renders LoadingView for initial state', (tester) async {
      await tester.pumpWidget(wrap(
        ViewStateBuilder<String>(
          state: const ViewState<String>.initial(),
          builder: (context, data) => Text('Content: $data'),
        ),
      ));

      expect(find.byType(LoadingView), findsOneWidget);
      expect(find.text('Content: test'), findsNothing);
    });

    testWidgets('renders custom initial builder when provided', (tester) async {
      await tester.pumpWidget(wrap(
        ViewStateBuilder<String>(
          state: const ViewState<String>.initial(),
          builder: (context, data) => Text('Content: $data'),
          initialBuilder: (context) => const Text('Custom Initial'),
        ),
      ));

      expect(find.text('Custom Initial'), findsOneWidget);
      expect(find.byType(LoadingView), findsNothing);
    });

    testWidgets('renders LoadingView for loading state', (tester) async {
      await tester.pumpWidget(wrap(
        ViewStateBuilder<String>(
          state: const ViewState<String>.loading(message: 'Fetching rides...'),
          builder: (context, data) => Text('Content: $data'),
        ),
      ));

      expect(find.byType(LoadingView), findsOneWidget);
      expect(find.text('Fetching rides...'), findsOneWidget);
    });

    testWidgets('renders LoadingView with custom message for loading state',
        (tester) async {
      await tester.pumpWidget(wrap(
        ViewStateBuilder<String>(
          state: const ViewState<String>.loading(),
          builder: (context, data) => Text('Content: $data'),
          loadingMessage: 'Please wait...',
        ),
      ));

      expect(find.byType(LoadingView), findsOneWidget);
      expect(find.text('Please wait...'), findsOneWidget);
    });

    testWidgets('renders content builder for success state', (tester) async {
      await tester.pumpWidget(wrap(
        ViewStateBuilder<String>(
          state: const ViewState<String>.success('Ride Data'),
          builder: (context, data) => Text('Content: $data'),
        ),
      ));

      expect(find.text('Content: Ride Data'), findsOneWidget);
      expect(find.byType(LoadingView), findsNothing);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.byType(EmptyStateView), findsNothing);
    });

    testWidgets('renders EmptyStateView for empty state', (tester) async {
      await tester.pumpWidget(wrap(
        ViewStateBuilder<String>(
          state: const ViewState<String>.empty(message: 'No rides found'),
          builder: (context, data) => Text('Content: $data'),
          emptyTitle: 'No Rides Yet',
        ),
      ));

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('No Rides Yet'), findsOneWidget);
      expect(find.text('No rides found'), findsOneWidget);
    });

    testWidgets('renders EmptyStateView with description fallback',
        (tester) async {
      await tester.pumpWidget(wrap(
        ViewStateBuilder<String>(
          state: const ViewState<String>.empty(),
          builder: (context, data) => Text('Content: $data'),
          emptyTitle: 'No Results',
          emptyDescription: 'Default description',
        ),
      ));

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('No Results'), findsOneWidget);
      expect(find.text('Default description'), findsOneWidget);
    });

    testWidgets('renders ErrorView for error state', (tester) async {
      await tester.pumpWidget(wrap(
        ViewStateBuilder<String>(
          state: const ViewState<String>.error('Network timeout'),
          builder: (context, data) => Text('Content: $data'),
        ),
      ));

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Network timeout'), findsOneWidget);
    });

    testWidgets('renders ErrorView with custom title', (tester) async {
      await tester.pumpWidget(wrap(
        ViewStateBuilder<String>(
          state: const ViewState<String>.error('Failed to load rides'),
          builder: (context, data) => Text('Content: $data'),
          errorTitle: 'Loading Failed',
        ),
      ));

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Loading Failed'), findsOneWidget);
      expect(find.text('Failed to load rides'), findsOneWidget);
    });
  });

  group('ViewStateBuilder — Retry Callback', () {
    testWidgets('propagates onRetry to ErrorView', (tester) async {
      bool retried = false;

      await tester.pumpWidget(wrap(
        ViewStateBuilder<String>(
          state: const ViewState<String>.error('Something broke'),
          builder: (context, data) => Text('Content: $data'),
          onRetry: () => retried = true,
        ),
      ));

      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('ErrorView has no retry button when onRetry is null',
        (tester) async {
      await tester.pumpWidget(wrap(
        ViewStateBuilder<String>(
          state: const ViewState<String>.error('Something broke'),
          builder: (context, data) => Text('Content: $data'),
        ),
      ));

      expect(find.text('Try Again'), findsNothing);
    });
  });

  group('ViewStateBuilder — Empty State Action', () {
    testWidgets('propagates action to EmptyStateView', (tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(wrap(
        ViewStateBuilder<String>(
          state: const ViewState<String>.empty(),
          builder: (context, data) => Text('Content: $data'),
          emptyTitle: 'No Results',
          emptyActionLabel: 'Create New',
          onEmptyAction: () => actionPressed = true,
        ),
      ));

      expect(find.text('Create New'), findsOneWidget);

      await tester.tap(find.text('Create New'));
      await tester.pump();

      expect(actionPressed, isTrue);
    });
  });

  group('ViewStateBuilder — State Transitions', () {
    testWidgets('transitions from initial to loading to success',
        (tester) async {
      final stateNotifier = ValueNotifier<ViewState<String>>(
        const ViewState<String>.initial(),
      );

      await tester.pumpWidget(wrap(
        ValueListenableBuilder<ViewState<String>>(
          valueListenable: stateNotifier,
          builder: (context, state, _) {
            return ViewStateBuilder<String>(
              state: state,
              builder: (context, data) => Text('Content: $data'),
            );
          },
        ),
      ));

      // Initial → LoadingView
      expect(find.byType(LoadingView), findsOneWidget);

      // Transition to loading
      stateNotifier.value =
          const ViewState<String>.loading(message: 'Loading...');
      await tester.pump();
      expect(find.byType(LoadingView), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);

      // Transition to success
      stateNotifier.value = const ViewState<String>.success('Result');
      await tester.pump();
      expect(find.text('Content: Result'), findsOneWidget);
      expect(find.byType(LoadingView), findsNothing);
    });

    testWidgets('transitions from initial to loading to error',
        (tester) async {
      final stateNotifier = ValueNotifier<ViewState<String>>(
        const ViewState<String>.initial(),
      );

      await tester.pumpWidget(wrap(
        ValueListenableBuilder<ViewState<String>>(
          valueListenable: stateNotifier,
          builder: (context, state, _) {
            return ViewStateBuilder<String>(
              state: state,
              builder: (context, data) => Text('Content: $data'),
              onRetry: () {},
            );
          },
        ),
      ));

      // Initial → LoadingView
      expect(find.byType(LoadingView), findsOneWidget);

      // Transition to loading
      stateNotifier.value = const ViewState<String>.loading();
      await tester.pump();
      expect(find.byType(LoadingView), findsOneWidget);

      // Transition to error
      stateNotifier.value =
          const ViewState<String>.error('Connection failed');
      await tester.pump();
      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Connection failed'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('transitions from initial to loading to empty',
        (tester) async {
      final stateNotifier = ValueNotifier<ViewState<String>>(
        const ViewState<String>.initial(),
      );

      await tester.pumpWidget(wrap(
        ValueListenableBuilder<ViewState<String>>(
          valueListenable: stateNotifier,
          builder: (context, state, _) {
            return ViewStateBuilder<String>(
              state: state,
              builder: (context, data) => Text('Content: $data'),
              emptyTitle: 'No Data',
            );
          },
        ),
      ));

      // Initial → LoadingView
      expect(find.byType(LoadingView), findsOneWidget);

      // Transition to loading
      stateNotifier.value = const ViewState<String>.loading();
      await tester.pump();
      expect(find.byType(LoadingView), findsOneWidget);

      // Transition to empty
      stateNotifier.value = const ViewState<String>.empty();
      await tester.pump();
      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('No Data'), findsOneWidget);
    });
  });
}

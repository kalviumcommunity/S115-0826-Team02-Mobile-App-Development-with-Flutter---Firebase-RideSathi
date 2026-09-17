import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/state/ride_feedback_controller.dart';
import 'package:ridesathi/core/state/view_state.dart';
import 'package:ridesathi/screens/rider/ride_feedback_screen.dart';
import 'package:ridesathi/widgets/star_rating_input.dart';

class MockRideFeedbackController extends RideFeedbackController {
  ViewState<void> _mockState = const ViewState.initial();
  bool submitCalled = false;
  bool shouldSucceed = true;

  @override
  ViewState<void> get state => _mockState;

  void setMockState(ViewState<void> state) {
    _mockState = state;
    notifyListeners();
  }

  @override
  Future<bool> submitFeedback(String rideId, int rating, String? comment) async {
    submitCalled = true;
    if (shouldSucceed) {
      _mockState = const ViewState.success(null);
      notifyListeners();
      return true;
    } else {
      _mockState = const ViewState.error('Submission failed.');
      notifyListeners();
      return false;
    }
  }
}

void main() {
  Widget buildTestWidget(RideFeedbackController controller) {
    return MaterialApp(
      home: RideFeedbackScreen(rideId: 'test_ride_123', controller: controller),
    );
  }

  group('RideFeedbackScreen', () {
    late MockRideFeedbackController mockController;

    setUp(() {
      mockController = MockRideFeedbackController();
    });

    testWidgets('shows form initially', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(mockController));

      expect(find.text('How was your ride?'), findsOneWidget);
      expect(find.byType(StarRatingInput), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Submit Feedback'), findsOneWidget);
    });

    testWidgets('submit button is disabled when no rating is selected', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(mockController));

      final button = tester.widget<ElevatedButton>(find.ancestor(
        of: find.text('Submit Feedback'),
        matching: find.byType(ElevatedButton),
      ));

      // Button should be disabled (onPressed == null) when rating == 0
      expect(button.onPressed, isNull);
    });

    testWidgets('tapping a star enables the submit button', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(mockController));

      // Tap the 4th star icon
      final stars = find.descendant(
        of: find.byType(StarRatingInput),
        matching: find.byType(GestureDetector),
      );
      expect(stars, findsNWidgets(5));
      await tester.tap(stars.at(3)); // 4th star
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.ancestor(
        of: find.text('Submit Feedback'),
        matching: find.byType(ElevatedButton),
      ));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows error banner when state is error', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(mockController));
      mockController.setMockState(const ViewState.error('Something went wrong.'));
      await tester.pump();

      expect(find.text('Something went wrong.'), findsOneWidget);
    });

    testWidgets('loading state disables star input', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(mockController));
      mockController.setMockState(const ViewState.loading());
      await tester.pump();

      // When loading, the onRatingChanged callback is null on StarRatingInput
      final starWidget = tester.widget<StarRatingInput>(find.byType(StarRatingInput));
      expect(starWidget.onRatingChanged, isNull);
    });
  });

  group('StarRatingInput', () {
    testWidgets('renders 5 stars', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRatingInput(
              rating: 3,
              onRatingChanged: (_) {},
            ),
          ),
        ),
      );

      // Should find 5 GestureDetectors (one per star)
      expect(find.byType(GestureDetector), findsNWidgets(5));
    });

    testWidgets('selected star count reflects current rating', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRatingInput(
              rating: 3,
              onRatingChanged: (_) {},
            ),
          ),
        ),
      );

      // 3 filled stars, 2 outlined
      final filledStars = find.byIcon(Icons.star_rounded);
      final outlinedStars = find.byIcon(Icons.star_outline_rounded);
      expect(filledStars, findsNWidgets(3));
      expect(outlinedStars, findsNWidgets(2));
    });

    testWidgets('calls onRatingChanged when star is tapped', (WidgetTester tester) async {
      int? tappedRating;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRatingInput(
              rating: 0,
              onRatingChanged: (r) => tappedRating = r,
            ),
          ),
        ),
      );

      final stars = find.byType(GestureDetector);
      await tester.tap(stars.at(4)); // 5th star
      await tester.pump();

      expect(tappedRating, equals(5));
    });

    testWidgets('has semantic labels for accessibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRatingInput(
              rating: 3,
              onRatingChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('1 star'), findsOneWidget);
      expect(find.bySemanticsLabel('2 stars'), findsOneWidget);
      expect(find.bySemanticsLabel('5 stars'), findsOneWidget);
    });
  });
}

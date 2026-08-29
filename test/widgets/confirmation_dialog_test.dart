import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridesathi/core/theme/app_theme.dart';
import 'package:ridesathi/widgets/confirmation_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget wrapWithTheme(Widget child, {bool isDark = false}) {
    return MaterialApp(
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  group('ConfirmationDialog', () {
    testWidgets('renders title, message, icon, and default button labels',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const ConfirmationDialog(
          title: 'Cancel Ride?',
          message: 'Are you sure you want to cancel this ongoing ride request?',
          icon: Icons.warning_amber_rounded,
        ),
      ));

      expect(find.text('Cancel Ride?'), findsOneWidget);
      expect(
        find.text('Are you sure you want to cancel this ongoing ride request?'),
        findsOneWidget,
      );
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('triggers onConfirm and onCancel callbacks', (tester) async {
      var confirmed = false;
      var cancelled = false;

      await tester.pumpWidget(wrapWithTheme(
        ConfirmationDialog(
          title: 'Suspend Driver',
          message: 'This will temporarily disable dispatch for this driver.',
          confirmLabel: 'Suspend',
          cancelLabel: 'Keep Active',
          isDestructive: true,
          onConfirm: () => confirmed = true,
          onCancel: () => cancelled = true,
        ),
      ));

      expect(find.text('Suspend'), findsOneWidget);
      expect(find.text('Keep Active'), findsOneWidget);

      await tester.tap(find.text('Keep Active'));
      await tester.pump();
      expect(cancelled, isTrue);

      await tester.tap(find.text('Suspend'));
      await tester.pump();
      expect(confirmed, isTrue);
    });

    testWidgets('showAppConfirmationDialog helper opens and resolves value',
        (tester) async {
      bool? result;

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showAppConfirmationDialog(
                    context,
                    title: 'Log Out',
                    message: 'Do you want to log out of RideSathi?',
                    confirmLabel: 'Log Out',
                    isDestructive: true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Log Out'), findsNWidgets(2)); // Button & Dialog Title
      expect(find.text('Do you want to log out of RideSathi?'), findsOneWidget);

      // Tap confirmation
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log Out'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}

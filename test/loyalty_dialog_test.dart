import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiceandbilling/features/pos/presentation/screens/loyalty_dialog.dart';

void main() {
  for (final choice
      in {
        'Loyalty card received': 'received',
        'Loyalty card given': 'given',
        'Continue anyway': 'skipped',
        'Back to order': null,
      }.entries) {
    testWidgets('loyalty dialog returns ${choice.value}', (tester) async {
      String? result = 'unanswered';
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await showLoyaltyDialog(context);
                  },
                  child: const Text('Save'),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(result, 'unanswered');
      final received = tester.getRect(
        find.widgetWithText(FilledButton, 'Loyalty card received'),
      );
      final given = tester.getRect(
        find.widgetWithText(FilledButton, 'Loyalty card given'),
      );
      final skipped = tester.getRect(
        find.widgetWithText(OutlinedButton, 'Continue anyway'),
      );
      expect(given.top - received.bottom, greaterThanOrEqualTo(12));
      expect(skipped.top - given.bottom, greaterThanOrEqualTo(12));
      await tester.tap(find.text(choice.key));
      await tester.pumpAndSettle();
      expect(result, choice.value);
    });
  }
}

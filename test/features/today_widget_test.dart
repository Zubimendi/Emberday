import 'package:emberday/ui/theme.dart';
import 'package:emberday/ui/widgets/empty_state.dart';
import 'package:emberday/ui/widgets/check_circle.dart';
import 'package:emberday/domain/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EmptyState shows message and action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: EmptyState(
            message:
                'No habits yet. Start with one that takes under two minutes.',
            actionLabel: 'Add habit',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.textContaining('No habits yet'), findsOneWidget);
    await tester.tap(find.text('Add habit'));
    expect(tapped, isTrue);
  });

  testWidgets('CheckCircle toggles via tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: CheckCircle(
            status: null,
            label: 'Drink water, not done',
            onTap: () => taps++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CheckCircle));
    expect(taps, 1);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: CheckCircle(
            status: CheckInStatus.done,
            label: 'Drink water, done',
            onTap: () => taps++,
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/features/accountability/presentation/accountability_screen.dart';

Future<void> start(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: AccountabilityScreen()));
  await tester.tap(find.text('Start private draft'));
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.text(label),
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('optional draft includes only explicit nonempty selections', (
    tester,
  ) async {
    await start(tester);
    expect(find.byType(TextField), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Review draft'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Include Reflection'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  A quiet day  ');
    await tester.pumpAndSettle();
    await reveal(tester, 'Review draft');
    await tester.tap(find.text('Review draft'));
    await tester.pumpAndSettle();
    expect(find.text('A quiet day'), findsOneWidget);
    expect(find.text('Next step'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(
      find.text('This is a local preview. There is no send action.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Edit draft'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '  A quiet day  ',
    );
    await tester.tap(find.text('Include Reflection'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Include Reflection'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.ensureVisible(find.text('Cancel draft'));
    await tester.tap(find.text('Cancel draft'));
    await tester.pumpAndSettle();
    expect(find.text('Start private draft'), findsOneWidget);
  });

  testWidgets('clear removes both fields and selections', (tester) async {
    await start(tester);
    await tester.tap(find.text('Include Reflection'));
    await tester.tap(find.text('Include Next step'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Today');
    await tester.enterText(find.byType(TextField).last, 'Tomorrow');
    await reveal(tester, 'Review draft');
    await tester.tap(find.text('Review draft'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    await tester.tap(find.text('Clear draft'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start private draft'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Review draft'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'large text and small viewport keep review and cancel reachable',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const AccountabilityScreen(),
        ),
      );
      await reveal(tester, 'Start private draft');
      await tester.tap(find.text('Start private draft'));
      await tester.pumpAndSettle();
      await reveal(tester, 'Include Reflection');
      await tester.tap(find.text('Include Reflection'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'A small next step');
      await reveal(tester, 'Review draft');
      await tester.tap(find.text('Review draft'));
      await tester.pumpAndSettle();
      expect(find.text('A small next step'), findsOneWidget);
      await reveal(tester, 'Clear draft');
      await tester.tap(find.text('Clear draft'));
      await tester.pumpAndSettle();
      expect(find.text('Start private draft'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('draft controls have accessible labels and touch targets', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await start(tester);
    expect(
      tester.getSemantics(find.byType(Checkbox).first),
      matchesSemantics(
        label: 'Include Reflection',
        hasSelectedState: true,
        hasCheckedState: true,
        isChecked: false,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });
}

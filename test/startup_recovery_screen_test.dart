import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/app/bootstrap/local_data_bootstrap.dart';
import 'package:scripture_planner/src/app/bootstrap/startup_app.dart';
import 'package:scripture_planner/src/app/new_man_app.dart';

void main() {
  testWidgets('typed blocked startup renders only data-preservation guidance', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      await buildStartupApp(() async {
        attempts++;
        throw _SyntheticRecoveryError();
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text('New Man paused to protect your data'), findsOneWidget);
    expect(
      find.textContaining('Your existing data was left in place.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Don’t uninstall New Man or clear its storage.'),
      findsOneWidget,
    );
    expect(find.textContaining('synthetic-private'), findsNothing);
    expect(find.byType(NewManApp), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(ButtonStyleButton), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('New Man paused to protect your data'), findsOneWidget);
    expect(attempts, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('warning can be scrolled at large text on a small viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 340));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      await buildStartupApp(() async {
        throw LocalDataRecoveryRequired();
      }),
    );

    final warning = find.textContaining('clear its storage');
    await tester.ensureVisible(warning);
    await tester.pumpAndSettle();
    expect(warning.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'other startup failures propagate with their original identity',
    () async {
      final error = StateError('Unrelated boot failure');
      await expectLater(
        buildStartupApp(() async => throw error),
        throwsA(same(error)),
      );
    },
  );
}

class _SyntheticRecoveryError extends LocalDataRecoveryRequired {
  @override
  String toString() => 'synthetic-private-profile-path-and-id';
}

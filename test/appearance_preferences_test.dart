import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scripture_planner/src/app/new_man_app.dart';
import 'package:scripture_planner/src/app/theme/new_man_theme.dart';
import 'package:scripture_planner/src/controllers/app_controller.dart';
import 'package:scripture_planner/src/features/settings/data/shared_preferences_appearance_repository.dart';
import 'package:scripture_planner/src/features/settings/domain/appearance_preferences.dart';
import 'package:scripture_planner/src/models/reading_plan.dart';
import 'package:scripture_planner/src/screens/settings_screen.dart';
import 'package:scripture_planner/src/services/bible_version_repository.dart';
import 'package:scripture_planner/src/services/plan_repository.dart';

AppController _controllerFor(_Preferences store) => AppController(
  repository: _Plans(),
  versionRepository: _Versions(),
  appearanceRepository: SharedPreferencesAppearanceRepository(
    preferences: store,
  ),
);

void main() {
  test(
    'queued changes survive restart without touching unrelated data',
    () async {
      final store = _Preferences()..values['existing_plans'] = 'keep';
      final controller = _controllerFor(store);
      await Future.wait([
        controller.setAppearance(mode: AppearanceMode.dark),
        controller.setAppearance(accent: AccentColor.brown),
      ]);
      final restarted = _controllerFor(store);
      await restarted.load();
      expect(restarted.appearance.mode, AppearanceMode.dark);
      expect(restarted.appearance.accent, AccentColor.brown);
      expect(store.values['existing_plans'], 'keep');
    },
  );

  test('failed write retains current theme and allows retry', () async {
    final store = _Preferences()..failWrites = true;
    final controller = _controllerFor(store);
    await expectLater(
      controller.setAppearance(accent: AccentColor.green),
      throwsStateError,
    );
    expect(controller.appearance.accent, AccentColor.blue);
    expect(controller.savingAppearance, isFalse);
    store.failWrites = false;
    await controller.setAppearance(accent: AccentColor.green);
    expect(controller.appearance.accent, AccentColor.green);
  });

  test('invalid preferences fall back safely', () async {
    final store = _Preferences();
    final repository = SharedPreferencesAppearanceRepository(
      preferences: store,
    );
    store.values[SharedPreferencesAppearanceRepository.storageKey] = 'not json';
    expect((await repository.load()).mode, AppearanceMode.system);
    store.values[SharedPreferencesAppearanceRepository.storageKey] =
        '{"mode":"dark","accent":"unknown"}';
    final loaded = await repository.load();
    expect(loaded.mode, AppearanceMode.dark);
    expect(loaded.accent, AccentColor.blue);
  });

  test('all accent buttons meet normal text contrast on neutral surfaces', () {
    for (final brightness in Brightness.values) {
      for (final accent in AccentColor.values) {
        final theme = NewManTheme.build(brightness, accent);
        final button = theme.filledButtonTheme.style!.backgroundColor!.resolve(
          {},
        )!;
        final text = theme.filledButtonTheme.style!.foregroundColor!.resolve(
          {},
        )!;
        final contrast =
            (text.computeLuminance() + .05) / (button.computeLuminance() + .05);
        expect(
          contrast,
          greaterThanOrEqualTo(4.5),
          reason: '$brightness $accent',
        );
        expect(
          theme.scaffoldBackgroundColor,
          brightness == Brightness.dark ? Colors.black : Colors.white,
        );
      }
    }
  });

  testWidgets('appearance changes update an open route without losing it', (
    tester,
  ) async {
    final controller = _controllerFor(_Preferences());
    await tester.pumpWidget(NewManApp(controller: controller));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(body: SettingsScreen(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Brown'));
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);
    final context = tester.element(find.text('Appearance'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(
      Theme.of(context).colorScheme.primary,
      NewManTheme.build(Brightness.dark, AccentColor.brown).colorScheme.primary,
    );
    expect(navigator.canPop(), isTrue);
  });

  testWidgets('appearance choices fit a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsScreen(controller: _controllerFor(_Preferences())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Blue'), findsOneWidget);
    expect(find.text('Green'), findsOneWidget);
    expect(find.text('Brown'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Preferences extends Fake implements SharedPreferencesAsync {
  final values = <String, String>{};
  final _failWrites = <bool>[false];
  bool get failWrites => _failWrites.single;
  set failWrites(bool value) => _failWrites[0] = value;
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    if (failWrites) throw StateError('Storage unavailable');
    values[key] = value;
  }
}

class _Plans implements PlanRepository {
  @override
  Future<List<ReadingPlan>> loadPlans() async => [];
  @override
  Future<void> savePlans(List<ReadingPlan> plans) async {}
}

class _Versions extends BibleVersionRepository {
  @override
  Future<Set<BibleTranslation>> loadInstalled() async => {};
}

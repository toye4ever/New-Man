import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/models/reading_plan.dart';
import 'package:scripture_planner/src/models/scripture_reference.dart';
import 'package:scripture_planner/src/services/bible_version_repository.dart';
import 'package:scripture_planner/src/services/plan_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test(
    'round trips meaningful Plan, schedule, and completion fields',
    () async {
      final repository = SharedPreferencesPlanRepository();
      final original = ReadingPlan(
        id: 'round-trip-plan',
        title: 'Synthetic round trip',
        defaultTranslation: BibleTranslation.nlt,
        createdAt: DateTime.utc(2025, 3, 1, 10, 30),
        startDate: DateTime.utc(2025, 3, 3),
        endDate: DateTime.utc(2025, 3, 7),
        readingWeekdays: <int>{1, 3, 5},
        reminderTime: '06:30',
        sourceReferences: const <ScriptureReference>[
          ScriptureReference(
            book: 'Romans',
            startChapter: 8,
            startVerse: 1,
            endChapter: 8,
            endVerse: 4,
          ),
        ],
        assignments: <ScheduledReading>[
          ScheduledReading(
            date: DateTime.utc(2025, 3, 3),
            references: const <ScriptureReference>[
              ScriptureReference(
                book: 'Romans',
                startChapter: 8,
                startVerse: 1,
              ),
            ],
            completed: true,
            translationOverride: BibleTranslation.kjv,
          ),
          ScheduledReading(
            date: DateTime.utc(2025, 3, 7),
            references: const <ScriptureReference>[
              ScriptureReference(
                book: 'Romans',
                startChapter: 8,
                startVerse: 4,
              ),
            ],
          ),
        ],
        templateId: 'synthetic-template',
      );

      await repository.savePlans(<ReadingPlan>[original]);
      final loaded = (await repository.loadPlans()).single;

      expect(loaded.id, original.id);
      expect(loaded.title, original.title);
      expect(loaded.defaultTranslation, BibleTranslation.nlt);
      expect(loaded.createdAt, original.createdAt);
      expect(loaded.startDate, original.startDate);
      expect(loaded.endDate, original.endDate);
      expect(loaded.readingWeekdays, original.readingWeekdays);
      expect(loaded.reminderTime, original.reminderTime);
      expect(loaded.sourceReferences.single.display, 'Romans 8:1-4');
      expect(
        loaded.assignments.map((item) => item.date),
        original.assignments.map((item) => item.date),
      );
      expect(loaded.assignments.map((item) => item.completed), <bool>[
        true,
        false,
      ]);
      expect(
        loaded.assignments.first.translationOverride,
        BibleTranslation.kjv,
      );
      expect(loaded.templateId, original.templateId);
      expect(loaded.progress, 0.5);
    },
  );

  test('decodes the complete synthetic v1 fixture', () async {
    final plans = await _loadFixture('plans_v1_current.json');
    final plan = plans.single;

    expect(plan.id, 'fixture-current-plan');
    expect(plan.defaultTranslation, BibleTranslation.nlt);
    expect(plan.readingWeekdays, <int>{1, 3, 5});
    expect(plan.sourceReferences.map((item) => item.display), <String>[
      'Matthew 5:1-12',
      'Romans 8:1-4',
    ]);
    expect(plan.assignments.map((item) => item.completed), <bool>[true, false]);
    expect(plan.assignments.first.translationOverride, BibleTranslation.kjv);
    expect(
      plan.assignments.last.date,
      DateTime.parse('2025-01-10T00:00:00.000Z'),
    );
    expect(plan.progress, 0.5);
  });

  test(
    'decodes supported optional legacy fields with documented defaults',
    () async {
      final plans = await _loadFixture('plans_v1_optional_legacy.json');
      final plan = plans.single;

      expect(plan.defaultTranslation, BibleTranslation.kjv);
      expect(plan.endDate, DateTime.parse('2024-02-06T00:00:00.000Z'));
      expect(plan.sourceReferences.map((item) => item.display), <String>[
        'John 1',
        'John 2',
      ]);
      expect(plan.assignments.every((item) => !item.completed), isTrue);
      expect(
        plan.assignments.every((item) => item.translationOverride == null),
        isTrue,
      );
      expect(plan.templateId, isNull);
    },
  );

  test(
    'protects legacy storage identities and writes only the Plan v1 key',
    () async {
      expect(
        SharedPreferencesPlanRepository.storageKey,
        'scripture_planner.plans.v1',
      );
      expect(
        BibleVersionRepository.storageKey,
        'scripture_planner.installed_versions.v2',
      );

      await SharedPreferencesPlanRepository().savePlans(<ReadingPlan>[]);
      final preferences = SharedPreferencesAsync();
      expect(
        await preferences.getString(SharedPreferencesPlanRepository.storageKey),
        '[]',
      );
      expect(await preferences.getKeys(), <String>{
        SharedPreferencesPlanRepository.storageKey,
      });
    },
  );

  test('returns an empty list for malformed stored JSON', () async {
    await SharedPreferencesAsync().setString(
      SharedPreferencesPlanRepository.storageKey,
      '[not valid JSON',
    );

    expect(await SharedPreferencesPlanRepository().loadPlans(), isEmpty);
  });
}

Future<List<ReadingPlan>> _loadFixture(String name) async {
  final raw = await File('test/fixtures/legacy/word/$name').readAsString();
  await SharedPreferencesAsync().setString(
    SharedPreferencesPlanRepository.storageKey,
    raw,
  );
  return SharedPreferencesPlanRepository().loadPlans();
}

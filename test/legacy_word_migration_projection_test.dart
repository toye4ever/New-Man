import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/features/word/plans/data/migration/legacy_word_migration_projection.dart';
import 'package:scripture_planner/src/features/word/plans/domain/reading_plan.dart';

void main() {
  final projector = LegacyWordMigrationProjection();

  test('projects current plan payload without losing semantics', () async {
    final result = projector.projectPlans(
      await _loadPlans('plans_v1_current.json'),
    );
    final plan = result.plans.single;
    expect(plan.legacyId, 'fixture-current-plan');
    expect(plan.defaultTranslationId, 'nlt');
    expect(plan.createdAtUtcMicros, 1735723800000000);
    expect(plan.startDate, '2025-01-06');
    expect(plan.endDate, '2025-01-10');
    expect(plan.readingWeekdaysMask, 21);
    expect(plan.reminderMinutesLocal, 405);
    expect(result.sourceItems, hasLength(2));
    expect(result.scheduleEntries, hasLength(2));
    expect(result.scheduleItems, hasLength(2));
    expect(result.scheduleEntries.first.isCompleted, isTrue);
    expect(result.scheduleEntries.first.completedAtUtcMicros, isNull);
    expect(result.scheduleEntries.first.translationOverrideId, 'kjv');
  });

  test(
    'stable IDs preserve UUIDs and deterministically map legacy IDs',
    () async {
      final plan = (await _loadPlans('plans_v1_current.json')).single;
      final first = projector.projectPlans([plan]);
      final second = projector.projectPlans([plan]);
      expect(first.plans.single.id, second.plans.single.id);
      expect(first.scheduleEntries.first.id, second.scheduleEntries.first.id);
      const uuid = '123e4567-e89b-42d3-a456-426614174000';
      final uuidPlan = ReadingPlan.fromJson({...plan.toJson(), 'id': uuid});
      final projected = projector.projectPlans([uuidPlan]).plans.single;
      expect(projected.id, uuid);
      expect(projected.legacyId, isNull);
    },
  );

  test('projects the supported legacy optional-field shape', () async {
    final result = projector.projectPlans(
      await _loadPlans('plans_v1_optional_legacy.json'),
    );
    final plan = result.plans.single;
    expect(plan.defaultTranslationId, 'kjv');
    expect(plan.endDate, '2024-02-06');
    expect(plan.templateId, isNull);
    expect(result.sourceItems, hasLength(2));
    expect(result.scheduleEntries.every((row) => !row.isCompleted), isTrue);
    expect(
      result.scheduleEntries.every((row) => row.translationOverrideId == null),
      isTrue,
    );
  });

  test('rejects duplicate legacy plan identities', () async {
    final plan = (await _loadPlans('plans_v1_current.json')).single;
    expect(() => projector.projectPlans([plan, plan]), throwsFormatException);
  });

  test('translation flags retain offline versus online semantics', () async {
    final names =
        (jsonDecode(
                  await File(
                    'test/fixtures/legacy/word/installed_versions_v2.json',
                  ).readAsString(),
                )
                as List<dynamic>)
            .cast<String>();
    final withoutFile = projector.projectTranslationStates(
      names,
      verifiedCompleteKjvFile: false,
    );
    expect(withoutFile.map((row) => row.translationId), ['nlt']);
    expect(withoutFile.single.accessMode, 'online');
    expect(withoutFile.single.state, 'enabled');
    final withFile = projector.projectTranslationStates(
      names,
      verifiedCompleteKjvFile: true,
    );
    expect(withFile.map((row) => row.translationId), ['kjv', 'nlt']);
    expect(withFile.first.accessMode, 'offline');
  });

  test('rejects unknown persisted translation names', () {
    expect(
      () => projector.projectTranslationStates([
        'future-version',
      ], verifiedCompleteKjvFile: false),
      throwsArgumentError,
    );
  });
}

Future<List<ReadingPlan>> _loadPlans(String name) async {
  final decoded =
      jsonDecode(await File('test/fixtures/legacy/word/$name').readAsString())
          as List<dynamic>;
  return decoded
      .map((item) => ReadingPlan.fromJson(item as Map<String, dynamic>))
      .toList();
}

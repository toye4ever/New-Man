import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/core/database/app_database.dart';
import 'package:scripture_planner/src/features/word/plans/data/local/word_plan_dao.dart';
import 'package:scripture_planner/src/models/reading_plan.dart';
import 'package:scripture_planner/src/models/scripture_reference.dart';
import 'package:scripture_planner/src/features/word/bible/application/scripture_search.dart';
import 'package:scripture_planner/src/features/word/bible/presentation/scripture_search_preview.dart';
import 'package:scripture_planner/src/features/word/audio/application/playback_speed.dart';
import 'package:scripture_planner/src/features/word/audio/presentation/playback_speed_selector.dart';
import 'package:scripture_planner/src/features/word/audio/application/audio_preferences_repository.dart';
import 'package:scripture_planner/src/features/word/audio/data/drift_audio_preferences_repository.dart';

void main() {
  test(
    'expanded audio rate survives closing and reopening the database',
    () async {
      final dir = await Directory.systemTemp.createTemp('newman-speed-test-');
      final file = File('${dir.path}/test.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      await DriftAudioPreferencesRepository(
        db,
      ).save(const AudioPreferences(playbackRate: .85, voiceKey: 'retained'));
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      final restored = await DriftAudioPreferencesRepository(db).load();
      expect(restored.playbackRate, .85);
      expect(restored.voiceKey, 'retained');
      await db.close();
      await dir.delete(recursive: true);
    },
  );
  test('last reading persists separately from furthest progress', () async {
    final dir = await Directory.systemTemp.createTemp('newman-resume-test-');
    final file = File('${dir.path}/test.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });
    var dao = WordPlanDao(db);
    final date = DateTime(2026, 10, 2);
    final plan = ReadingPlan(
      id: '123e4567-e89b-42d3-a456-426614174000',
      title: 'Resume',
      defaultTranslation: BibleTranslation.kjv,
      createdAt: date,
      startDate: date,
      endDate: date.add(const Duration(days: 9)),
      readingWeekdays: {1, 2, 3, 4, 5, 6, 7},
      reminderTime: '07:00',
      sourceReferences: const [
        ScriptureReference(book: 'Genesis', startChapter: 1, endChapter: 10),
      ],
      lastReadLocation: const ScriptureReference(
        book: 'Genesis',
        startChapter: 2,
      ),
      assignments: List.generate(
        10,
        (i) => ScheduledReading(
          date: date.add(Duration(days: i)),
          completed: i < 7,
          references: [
            ScriptureReference(book: 'Genesis', startChapter: i + 1),
          ],
        ),
      ),
    );
    await dao.replacePlans([plan]);
    await db.close();
    db = AppDatabase(NativeDatabase(file));
    dao = WordPlanDao(db);
    var restored = (await WordPlanDao(db).loadPlans()).single;
    expect(restored.lastReadAssignmentIndex, 1);
    expect(restored.progressAssignmentIndex, 7);
    await dao.replacePlans([restored.copyWith(title: 'Edited')]);
    restored = (await dao.loadPlans()).single;
    expect(restored.lastReadAssignmentIndex, 1);
    expect(ReadingPlan.fromJson(restored.toJson()).lastReadAssignmentIndex, 1);
    final repeated = restored.copyWith(
      assignments: [restored.assignments[1], restored.assignments[1]],
      lastReadAssignmentHint: 1,
    );
    await dao.replacePlans([repeated]);
    expect((await dao.loadPlans()).single.lastReadAssignmentIndex, 1);
  });

  test('direct references, quotations, and multiple indexed concepts', () async {
    final search = ScriptureSearch(
      () async => const [
        SearchVerse(
          ScriptureReference(
            book: 'Philippians',
            startChapter: 4,
            startVerse: 8,
          ),
          'Finally, brethren, whatsoever things are true, whatsoever things are pure, think on these things.',
        ),
        SearchVerse(
          ScriptureReference(book: 'Exodus', startChapter: 20, startVerse: 1),
          'And God spake all these words',
        ),
      ],
    );
    expect(
      (await search.search('Philippians 4:8')).single.reference.display,
      'Philippians 4:8',
    );
    expect(
      (await search.search(
        'Whatsoever things are pure',
      )).first.reference.display,
      'Philippians 4:8',
    );
    expect(
      (await search.search('Ten Commandments')).map((r) => r.reference.book),
      ['Exodus', 'Deuteronomy'],
    );
    expect(
      (await search.search('good samaritan')).first.reference.display,
      'Luke 10:25-37',
    );
    expect(
      (await search.search('fruit of the spirit')).first.reference.book,
      'Galatians',
    );
    expect(await search.search('unrelated fictional passage'), isEmpty);
  });

  testWidgets('preview uses bold word matches and ellipsis', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScriptureSearchPreview(
            text:
                '${'Surrounding text ' * 12}whatsoever things are pure ${'more text ' * 30}',
            query: 'whatsoever things are pure',
          ),
        ),
      ),
    );
    final text =
        tester.widget<Text>(find.byType(Text).last).textSpan! as TextSpan;
    expect(text.toPlainText(), contains('…'));
    expect(
      text.children!
          .whereType<TextSpan>()
          .where((s) => s.style?.fontWeight == FontWeight.bold)
          .map((s) => s.text),
      containsAll(['whatsoever', 'things', 'are', 'pure']),
    );
  });

  test('expanded rates retain existing labels and valid native bounds', () {
    expect(PlaybackSpeed.label(.35), '0.75×');
    expect(PlaybackSpeed.label(.45), '1×');
    expect(PlaybackSpeed.label(.55), '1.25×');
    expect(PlaybackSpeed.multipliers, hasLength(13));
    expect(PlaybackSpeed.nativeRate(.5), closeTo(.25, .0001));
    expect(PlaybackSpeed.nativeRate(2), closeTo(.85, .0001));
  });

  testWidgets('speed wheel commits the chosen expanded rate', (tester) async {
    double? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaybackSpeedSelector(rate: .45, onChanged: (v) => chosen = v),
        ),
      ),
    );
    await tester.tap(find.text('1×'));
    await tester.pumpAndSettle();
    final picker = tester.widget<CupertinoPicker>(find.byType(CupertinoPicker));
    picker.scrollController!.jumpToItem(12);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(chosen, closeTo(.85, .0001));
  });
}

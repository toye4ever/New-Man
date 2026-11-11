import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:scripture_planner/src/app/bootstrap/local_data_bootstrap.dart';
import 'package:scripture_planner/src/features/tasks/domain/task.dart';
import 'package:scripture_planner/src/features/word/bible/domain/scripture_anchor.dart';
import 'package:scripture_planner/src/features/word/saved_scripture/domain/saved_scripture.dart';
import 'package:scripture_planner/src/models/reading_plan.dart';
import 'package:scripture_planner/src/models/scripture_reference.dart';

class OwnedPaths extends PathProviderPlatform {
  OwnedPaths(this.root);
  final String root;
  final calls = <String>[];
  String path(String name) {
    calls.add(name);
    return '$root${Platform.pathSeparator}$name';
  }

  @override
  Future<String?> getApplicationSupportPath() async => path('support');
  @override
  Future<String?> getApplicationDocumentsPath() async => path('documents');
  @override
  Future<String?> getApplicationCachePath() async => path('cache');
  @override
  Future<String?> getTemporaryPath() async => path('temp');
}

class DenyNetwork extends HttpOverrides {
  int attempts = 0;
  final clients = <HttpClient>[];
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    clients.add(client);
    client.connectionFactory = (uri, proxyHost, proxyPort) {
      attempts++;
      throw StateError('Network forbidden: $uri');
    };
    return client;
  }
}

Future<void> closeBootstrap(LocalDataBootstrapResult result) async {
  result.taskService.dispose();
  result.controller.versionRepository.dispose();
  result.controller.dispose();
  await result.database.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'actual bootstrap persists synthetic beta journeys across two reopens',
    () async {
      final parent = Directory('.dart_tool/beta-bootstrap-diagnostic');
      await parent.create(recursive: true);
      final profile = await parent.createTemp('profile-');
      final paths = OwnedPaths(profile.absolute.path);
      for (final name in ['support', 'documents', 'cache', 'temp']) {
        await Directory(
          '${profile.path}${Platform.pathSeparator}$name',
        ).create();
      }
      final oldPaths = PathProviderPlatform.instance;
      final oldAsync = SharedPreferencesAsyncPlatform.instance;
      final oldLegacy = SharedPreferencesStorePlatform.instance;
      final network = DenyNetwork();
      LocalDataBootstrapResult? current;
      PathProviderPlatform.instance = paths;
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      await HttpOverrides.runWithHttpOverrides(() async {
        try {
          current = await bootstrapLocalData();
          expect(current!.driftIsAuthoritative, isTrue);
          final schema = await current!.database
              .customSelect('PRAGMA user_version')
              .getSingle();
          expect(schema.read<int>('user_version'), 10);
          expect(
            await File(
              '${profile.path}/support/database/new_man.sqlite',
            ).exists(),
            isTrue,
          );
          expect(current!.controller.plans, isEmpty);
          expect(await current!.taskService.loadTasks(), isEmpty);
          final saved = current!.controller.savedScriptureRepository;
          expect(await saved.loadBookmarks(), isEmpty);
          expect(await saved.loadHighlights(), isEmpty);
          expect(await saved.loadNotes(), isEmpty);
          expect(await saved.loadHistory(), isEmpty);
          expect(
            await current!.controller.readerStateRepository.load(),
            isNull,
          );

          final date = DateTime(2026, 10, 5);
          const one = ScriptureReference(book: 'Genesis', startChapter: 1);
          const two = ScriptureReference(book: 'Genesis', startChapter: 2);
          const anchor = ScriptureAnchor(
            book: 'Genesis',
            chapter: 1,
            startVerse: 3,
          );
          final plan = ReadingPlan(
            id: '123e4567-e89b-42d3-a456-426614174000',
            title: 'Synthetic plan',
            defaultTranslation: BibleTranslation.kjv,
            createdAt: date,
            startDate: date,
            endDate: date.add(const Duration(days: 2)),
            readingWeekdays: {1, 2, 3, 4, 5, 6, 7},
            reminderTime: '07:00',
            sourceReferences: const [one, two],
            assignments: [
              ScheduledReading(date: date, references: const [one, two]),
            ],
          );
          await current!.controller.savePlan(plan);
          await current!.controller.completePlanChapter(plan.id, 0, one);
          await current!.controller.saveReaderPosition(
            book: 'Genesis',
            chapter: 2,
            translation: BibleTranslation.kjv,
          );
          await saved.saveBookmark(anchor);
          await saved.saveHighlight(anchor, HighlightStyle.blue);
          final stamp = DateTime.utc(2026, 10, 5);
          await saved.saveNote(
            ScriptureNote(
              id: 'synthetic-note',
              anchors: [anchor],
              body: 'Synthetic note',
              createdAt: stamp,
              updatedAt: stamp,
            ),
          );
          await saved.recordSuccessfulOpen(anchor);
          final first = await current!.taskService.createTask(
            title: 'Synthetic first',
            dueDate: date,
            timeBlock: TaskTimeBlock(
              plannedDate: date,
              startMinutesLocal: 540,
              endMinutesLocal: 600,
            ),
          );
          final second = await current!.taskService.createTask(
            title: 'Synthetic second',
            dueDate: date,
          );
          await current!.taskService.setCompleted(second, true);
          await current!.taskService.selectDailyPriority(date, first.id);
          await current!.taskService.selectDailyPriority(date, second.id);
          await current!.taskService.reorderDailyPriorities(date, [
            second.id,
            first.id,
          ]);
          await closeBootstrap(current!);
          current = null;

          current = await bootstrapLocalData();
          expect(current!.driftIsAuthoritative, isTrue);
          expect(current!.controller.plans, hasLength(1));
          final restoredPlan = current!.controller.plans.single;
          expect(restoredPlan.id, plan.id);
          expect(restoredPlan.title, plan.title);
          expect(restoredPlan.assignments.single.completedChapterCount, 1);
          expect(
            restoredPlan.assignments.single.isChapterCompleted(one),
            isTrue,
          );
          expect(
            restoredPlan.assignments.single.isChapterCompleted(two),
            isFalse,
          );
          final position = await current!.controller.readerStateRepository
              .load();
          expect(position?.book, 'Genesis');
          expect(position?.chapter, 2);
          expect(position?.translation, BibleTranslation.kjv);
          final restoredSaved = current!.controller.savedScriptureRepository;
          final bookmarks = await restoredSaved.loadBookmarks();
          final highlights = await restoredSaved.loadHighlights();
          final notes = await restoredSaved.loadNotes();
          final history = await restoredSaved.loadHistory();
          expect(bookmarks, hasLength(1));
          expect(bookmarks.single.anchor, anchor);
          expect(highlights, hasLength(1));
          expect(highlights.single.anchor, anchor);
          expect(highlights.single.style, HighlightStyle.blue);
          expect(notes, hasLength(1));
          expect(notes.single.id, 'synthetic-note');
          expect(notes.single.body, 'Synthetic note');
          expect(notes.single.anchors, [anchor]);
          expect(history, hasLength(1));
          expect(history.single.anchor, anchor);
          final tasks = await current!.taskService.loadTasks();
          expect(tasks, hasLength(2));
          final restoredFirst = tasks.singleWhere((t) => t.id == first.id);
          final restoredSecond = tasks.singleWhere((t) => t.id == second.id);
          expect(restoredFirst.title, 'Synthetic first');
          expect(restoredFirst.dueDate, date);
          expect(restoredFirst.isCompleted, isFalse);
          expect(restoredFirst.timeBlock?.plannedDate, date);
          expect(restoredFirst.timeBlock?.startMinutesLocal, 540);
          expect(restoredFirst.timeBlock?.endMinutesLocal, 600);
          expect(restoredSecond.title, 'Synthetic second');
          expect(restoredSecond.dueDate, date);
          expect(restoredSecond.isCompleted, isTrue);
          expect(restoredSecond.completedAt, isNotNull);
          expect(
            (await current!.taskService.loadDailyPriorities(
              date,
            )).map((p) => p.taskId).toList(),
            [second.id, first.id],
          );
          await current!.taskService.clearTimeBlock(restoredFirst);
          await closeBootstrap(current!);
          current = null;

          current = await bootstrapLocalData();
          expect(current!.driftIsAuthoritative, isTrue);
          final finalTasks = await current!.taskService.loadTasks();
          expect(finalTasks, hasLength(2));
          final cleared = finalTasks.singleWhere((t) => t.id == first.id);
          expect(cleared.timeBlock, isNull);
          expect(cleared.dueDate, date);
          expect(
            (await current!.taskService.loadDailyPriorities(
              date,
            )).map((p) => p.taskId).toList(),
            [second.id, first.id],
          );
          expect(network.attempts, 0);
          expect(paths.calls, isNotEmpty);
          expect(
            paths.calls.every(
              (p) => ['support', 'documents', 'cache', 'temp'].contains(p),
            ),
            isTrue,
          );
        } finally {
          if (current != null) await closeBootstrap(current!);
          for (final client in network.clients) {
            client.close(force: true);
          }
          SharedPreferences.setMockInitialValues({});
          SharedPreferencesStorePlatform.instance = oldLegacy;
          SharedPreferencesAsyncPlatform.instance = oldAsync;
          PathProviderPlatform.instance = oldPaths;
        }
      }, network);
    },
  );
}

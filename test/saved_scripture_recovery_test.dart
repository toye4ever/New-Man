import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/controllers/app_controller.dart';
import 'package:scripture_planner/src/features/word/bible/domain/scripture_anchor.dart';
import 'package:scripture_planner/src/features/word/saved_scripture/application/saved_scripture_repository.dart';
import 'package:scripture_planner/src/features/word/saved_scripture/domain/saved_scripture.dart';
import 'package:scripture_planner/src/features/word/saved_scripture/presentation/saved_scripture_screen.dart';
import 'package:scripture_planner/src/models/reading_plan.dart';
import 'package:scripture_planner/src/services/plan_repository.dart';
import 'package:scripture_planner/src/services/bible_version_repository.dart';

const _anchor = ScriptureAnchor(book: 'Romans', chapter: 8);
const _sections = ['Bookmarks', 'Highlights', 'Notes', 'History'];
const _actions = [
  'Remove bookmark',
  'Remove highlight',
  'Delete note',
  'Delete history item',
  'Clear history',
];

Future<_Repository> _mount(WidgetTester tester) async {
  final repo = _Repository();
  await repo.saveBookmark(_anchor);
  await repo.saveHighlight(_anchor, HighlightStyle.gold);
  await repo.saveNote(
    ScriptureNote(
      id: 'synthetic-note',
      anchors: [_anchor],
      body: 'Synthetic note body',
      createdAt: DateTime.utc(2001),
      updatedAt: DateTime.utc(2001),
    ),
  );
  await repo.recordSuccessfulOpen(_anchor);
  final controller = AppController(
    repository: _Plans(),
    versionRepository: BibleVersionRepository(),
    savedScriptureRepository: repo,
  );
  addTearDown(() {
    controller.versionRepository.dispose();
    controller.dispose();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SavedScriptureScreen(controller: controller)),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _section(WidgetTester tester, int section) async {
  await tester.tap(find.text(_sections[section]));
  await tester.pumpAndSettle();
}

Finder _action(int action) =>
    action == 4 ? find.text('Clear history') : find.byTooltip(_actions[action]);

void main() {
  for (var section = 0; section < 4; section++) {
    testWidgets('read failure is sanitized and retryable section=$section', (
      tester,
    ) async {
      final repo = await _mount(tester);
      // Navigate away first, so each failed future is a fresh section load.
      await _section(tester, (section + 1) % 4);
      repo.failRead = section;
      await _section(tester, section);
      expect(
        find.text('Saved Scripture could not be loaded. Please try again.'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('synthetic secret'), findsNothing);
      repo.failRead = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Romans 8'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (var action = 0; action < 5; action++) {
    testWidgets(
      'failed deletion retains row and success retries action=$action',
      (tester) async {
        final repo = await _mount(tester);
        await _section(tester, action.clamp(0, 3));
        repo.failWrite = true;
        await tester.tap(_action(action));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Romans 8'), findsOneWidget);
        expect(
          find.text('Saved Scripture could not be updated. Please try again.'),
          findsOneWidget,
        );
        expect(find.textContaining('synthetic secret'), findsNothing);
        repo.failWrite = false;
        await tester.tap(_action(action));
        await tester.pumpAndSettle();
        expect(find.text('Romans 8'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
    for (final fails in [false, true]) {
      testWidgets(
        'pending deletion is safe after disposal action=$action fails=$fails',
        (tester) async {
          final repo = await _mount(tester);
          await _section(tester, action.clamp(0, 3));
          final gate = Completer<void>();
          repo.gate = gate;
          repo.failWrite = fails;
          await tester.tap(_action(action));
          await tester.pump();
          await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: Text('Other page'))),
          );
          await tester.pumpAndSettle();
          gate.complete();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.textContaining('could not'), findsNothing);
          expect(find.byType(SnackBar), findsNothing);
        },
      );
    }
  }
  for (final fails in [false, true]) {
    testWidgets(
      'old section load and pending deletion cannot replace newer section fails=$fails',
      (tester) async {
        final repo = await _mount(tester);
        final old = Completer<List<ScriptureBookmark>>();
        repo.pendingBookmarks = old;
        await _section(tester, 2);
        await tester.tap(find.text('Bookmarks'));
        await tester.pump();
        await _section(tester, 2);
        old.completeError(StateError('synthetic secret old read'));
        await tester.pumpAndSettle();
        expect(find.text('Synthetic note body'), findsOneWidget);
        expect(find.text('Retry'), findsNothing);
        final gate = Completer<void>();
        repo.gate = gate;
        repo.failWrite = fails;
        await tester.tap(find.byTooltip('Delete note'));
        await tester.pump();
        await _section(tester, 3);
        gate.complete();
        await tester.pumpAndSettle();
        expect(find.text('Romans 8'), findsOneWidget);
        expect(find.byTooltip('Delete history item'), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        expect(await repo.loadNotes(), hasLength(fails ? 1 : 0));
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _Repository extends VolatileSavedScriptureRepository {
  int? failRead;
  bool failWrite = false;
  Completer<void>? gate;
  Completer<List<ScriptureBookmark>>? pendingBookmarks;
  Future<List<T>> read<T>(int section, Future<List<T>> Function() load) =>
      failRead == section
      ? Future.error(StateError('synthetic secret read'))
      : load();
  @override
  Future<List<ScriptureBookmark>> loadBookmarks() =>
      pendingBookmarks?.future ?? read(0, super.loadBookmarks);
  @override
  Future<List<ScriptureHighlight>> loadHighlights() =>
      read(1, super.loadHighlights);
  @override
  Future<List<ScriptureNote>> loadNotes() => read(2, super.loadNotes);
  @override
  Future<List<ReadingHistoryItem>> loadHistory() => read(3, super.loadHistory);
  Future<void> beforeWrite() async {
    await gate?.future;
    if (failWrite) throw StateError('synthetic secret write');
  }

  @override
  Future<void> removeBookmark(ScriptureAnchor a) async {
    await beforeWrite();
    await super.removeBookmark(a);
  }

  @override
  Future<void> removeHighlight(ScriptureAnchor a) async {
    await beforeWrite();
    await super.removeHighlight(a);
  }

  @override
  Future<void> deleteNote(String id) async {
    await beforeWrite();
    await super.deleteNote(id);
  }

  @override
  Future<void> deleteHistory(ScriptureAnchor a) async {
    await beforeWrite();
    await super.deleteHistory(a);
  }

  @override
  Future<void> clearHistory() async {
    await beforeWrite();
    await super.clearHistory();
  }
}

class _Plans implements PlanRepository {
  @override
  Future<List<ReadingPlan>> loadPlans() async => [];
  @override
  Future<void> savePlans(List<ReadingPlan> plans) async {}
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/features/tasks/application/task_repository.dart';
import 'package:scripture_planner/src/features/tasks/application/task_service.dart';
import 'package:scripture_planner/src/features/tasks/domain/task.dart';
import 'package:scripture_planner/src/features/tasks/presentation/task_editor_dialog.dart';

void main() {
  testWidgets(
    'failed save keeps title and prevents dismissal until retry succeeds',
    (tester) async {
      final repo = _Repository()..fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TaskEditorDialog(service: TaskService(repo))),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Keep my input');
      await tester.tap(find.text('Save task'));
      await tester.pumpAndSettle();
      expect(
        find.text('The task could not be saved. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Keep my input'), findsOneWidget);
      expect(repo.tasks, isEmpty);
      repo.fail = false;
      await tester.tap(find.text('Save task'));
      await tester.pumpAndSettle();
      expect(repo.tasks.values.single.title, 'Keep my input');
    },
  );
  testWidgets('validates a block and retains input until valid', (
    tester,
  ) async {
    final repo = _Repository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskEditorDialog(
            service: TaskService(repo),
            initialDate: DateTime(2026, 9, 3),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Read');
    await tester.tap(find.text('Add time block (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Start time (HH:MM)'),
      '12:00',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'End time (HH:MM, 24:00 is end of day)'),
      '11:00',
    );
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Enter a valid start and end time'),
      findsOneWidget,
    );
    expect(repo.tasks, isEmpty);
    await tester.enterText(
      find.widgetWithText(TextField, 'End time (HH:MM, 24:00 is end of day)'),
      '24:00',
    );
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();
    expect(repo.tasks.values.single.timeBlock!.endMinutesLocal, 1440);
  });
  testWidgets(
    'dialog blocks barrier and back during save and retains failed draft',
    (tester) async {
      final repo = _Repository();
      final pending = Completer<void>();
      repo.pending = pending.future;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showTaskEditor(context, TaskService(repo)),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Task title'),
        'Draft',
      );
      await tester.tap(find.text('Save task'));
      await tester.pump();
      await tester.tapAt(const Offset(5, 5));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Saving…'), findsOneWidget);
      repo.fail = true;
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Draft'), findsOneWidget);
      expect(
        find.text('The task could not be saved. Please try again.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Draft'), findsNothing);
    },
  );
  testWidgets(
    'editing and clearing a block preserves due date and completion',
    (tester) async {
      final repo = _Repository();
      final original = Task(
        id: 'one',
        title: 'Original',
        isCompleted: true,
        completedAt: DateTime.utc(2026, 9, 3),
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        dueDate: DateTime(2026, 9, 5),
        timeBlock: TaskTimeBlock(
          plannedDate: DateTime(2026, 9, 3),
          startMinutesLocal: 600,
          endMinutesLocal: 660,
        ),
      );
      repo.tasks[original.id] = original;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showTaskEditor(context, TaskService(repo), task: original),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Task title'),
        'Edited',
      );
      await tester.ensureVisible(find.text('Clear time block'));
      await tester.tap(find.text('Clear time block'));
      await tester.tap(find.text('Save task'));
      await tester.pumpAndSettle();
      final saved = repo.tasks['one']!;
      expect(saved.title, 'Edited');
      expect(saved.dueDate, DateTime(2026, 9, 5));
      expect(saved.isCompleted, isTrue);
      expect(saved.timeBlock, isNull);
    },
  );
  testWidgets(
    'dialog title focus and ordered keyboard traversal activate cancel',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showTaskEditor(context, TaskService(_Repository())),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      bool focused(Finder finder) => tester
          .widget<EditableText>(
            find.descendant(of: finder, matching: find.byType(EditableText)),
          )
          .focusNode
          .hasPrimaryFocus;
      expect(focused(find.widgetWithText(TextField, 'Task title')), isTrue);
      for (final label in [
        'Add due date (optional)',
        'Add time block (optional)',
        'Cancel',
      ]) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final button = find.ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate(
            (widget) => widget is ButtonStyleButton,
          ),
        );
        final buttonElement = tester.element(button);
        var belongsToButton = false;
        FocusManager.instance.primaryFocus!.context!.visitAncestorElements((
          element,
        ) {
          if (element == buttonElement) belongsToButton = true;
          return !belongsToButton;
        });
        expect(
          belongsToButton,
          isTrue,
          reason: 'Expected keyboard focus on $label',
        );
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Add task'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets('picker outside tap cancels tentative dates at $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 360);
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);
      final repo = _Repository();
      final task = Task(
        id: 'outside',
        title: 'Original',
        isCompleted: false,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        dueDate: DateTime(2026, 9, 5),
        timeBlock: TaskTimeBlock(
          plannedDate: DateTime(2026, 9, 3),
          startMinutesLocal: 600,
          endMinutesLocal: 660,
        ),
      );
      repo.tasks[task.id] = task;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showTaskEditor(context, TaskService(repo), task: task),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final title = find.widgetWithText(TextField, 'Task title');
      final start = find.widgetWithText(TextField, 'Start time (HH:MM)');
      await tester.ensureVisible(title);
      await tester.enterText(title, 'Unsaved draft');
      await tester.ensureVisible(start);
      await tester.enterText(start, '10:15');
      for (final entry in {
        'Due date: Sep 5, 2026': DateTime(2026, 9, 5),
        'Block date: Sep 3, 2026': DateTime(2026, 9, 3),
      }.entries) {
        await tester.ensureVisible(find.text(entry.key));
        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();
        final day = find.text('6');
        await tester.ensureVisible(day);
        await tester.tap(day);
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsNothing);
        expect(find.byType(TaskEditorDialog), findsOneWidget);
        expect(
          tester.widget<TextField>(title).controller!.text,
          'Unsaved draft',
        );
        expect(tester.widget<TextField>(start).controller!.text, '10:15');
        expect(find.text(entry.key), findsOneWidget);
        expect(repo.writes, 0);
        expect(repo.tasks[task.id], same(task));
        expect(tester.view.viewInsets.bottom, 220);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text(entry.key));
        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
              .initialDate,
          entry.value,
        );
        final cancel = find.text('Cancel').last;
        await tester.ensureVisible(cancel);
        await tester.tap(cancel);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
  for (final height in [400.0, 360.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('landscape keyboard populated editor $height at $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(900, height);
        tester.view.viewInsets = const FakeViewPadding(bottom: 220);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetViewInsets);
        final repo = _Repository();
        final task = Task(
          id: 'landscape',
          title: 'Existing task',
          isCompleted: true,
          completedAt: DateTime.utc(2026, 9, 3),
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          dueDate: DateTime(2026, 9, 5),
          timeBlock: TaskTimeBlock(
            plannedDate: DateTime(2026, 9, 3),
            startMinutesLocal: 600,
            endMinutesLocal: 660,
          ),
        );
        repo.tasks[task.id] = task;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () =>
                      showTaskEditor(context, TaskService(repo), task: task),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.namesRoute == true &&
                widget.properties.label == 'Edit task',
          ),
          findsOneWidget,
        );
        final title = find.widgetWithText(TextField, 'Task title');
        final start = find.widgetWithText(TextField, 'Start time (HH:MM)');
        final end = find.widgetWithText(
          TextField,
          'End time (HH:MM, 24:00 is end of day)',
        );
        expect(
          tester
              .widget<EditableText>(
                find.descendant(of: title, matching: find.byType(EditableText)),
              )
              .focusNode
              .hasPrimaryFocus,
          isTrue,
        );
        await tester.ensureVisible(title);
        await tester.enterText(title, 'Edited landscape');
        for (final label in [
          'Due date: Sep 5, 2026',
          'Clear due date',
          'Block date: Sep 3, 2026',
        ]) {
          await tester.ensureVisible(find.text(label));
          expect(find.text(label).hitTestable(), findsOneWidget);
        }
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(title).controller!.text,
          'Edited landscape',
        );
        expect(
          tester
              .widget<EditableText>(
                find.descendant(of: title, matching: find.byType(EditableText)),
              )
              .focusNode
              .hasPrimaryFocus,
          isTrue,
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 220);
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(title).controller!.text,
          'Edited landscape',
        );
        expect(
          tester
              .widget<EditableText>(
                find.descendant(of: title, matching: find.byType(EditableText)),
              )
              .focusNode
              .hasPrimaryFocus,
          isTrue,
        );
        expect(tester.takeException(), isNull);
        for (final label in [
          'Due date: Sep 5, 2026',
          'Block date: Sep 3, 2026',
        ]) {
          for (final confirm in [false, true]) {
            await tester.ensureVisible(find.text(label));
            await tester.tap(find.text(label));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.byType(DatePickerDialog), findsOneWidget);
            final day = find.text('6');
            await tester.ensureVisible(day);
            expect(day.hitTestable(), findsOneWidget);
            await tester.tap(day);
            await tester.pumpAndSettle();
            final action = find.text(confirm ? 'OK' : 'Cancel').last;
            await tester.ensureVisible(action);
            expect(action.hitTestable(), findsOneWidget);
            expect(
              tester.getBottomRight(action).dy,
              lessThanOrEqualTo(height - 220),
            );
            await tester.tap(action);
            await tester.pumpAndSettle();
            expect(tester.view.viewInsets.bottom, 220);
            expect(tester.takeException(), isNull);
            if (!confirm) expect(find.text(label), findsOneWidget);
          }
        }
        await tester.ensureVisible(start);
        await tester.enterText(start, '10:15');
        await tester.ensureVisible(end);
        await tester.enterText(end, '11:30');
        await tester.ensureVisible(find.text('Clear time block'));
        expect(find.text('Clear time block').hitTestable(), findsOneWidget);
        await tester.ensureVisible(find.text('Save task'));
        expect(find.text('Save task').hitTestable(), findsOneWidget);
        await tester.tap(find.text('Save task'));
        await tester.pumpAndSettle();
        final saved = repo.tasks[task.id]!;
        expect(saved.title, 'Edited landscape');
        expect(saved.isCompleted, isTrue);
        expect(saved.completedAt, task.completedAt);
        expect(saved.dueDate, DateTime(2026, 9, 6));
        expect(saved.timeBlock!.plannedDate, DateTime(2026, 9, 6));
        expect(saved.timeBlock!.startMinutesLocal, 615);
        expect(saved.timeBlock!.endMinutesLocal, 690);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(title);
        await tester.enterText(title, 'Discard me');
        await tester.ensureVisible(find.text('Clear due date'));
        await tester.tap(find.text('Clear due date'));
        await tester.pumpAndSettle();
        expect(find.text('Add due date (optional)'), findsOneWidget);
        await tester.ensureVisible(find.text('Clear time block'));
        await tester.tap(find.text('Clear time block'));
        await tester.pumpAndSettle();
        expect(find.text('Add time block (optional)'), findsOneWidget);
        await tester.ensureVisible(find.text('Cancel'));
        expect(find.text('Cancel').hitTestable(), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(repo.tasks[task.id]!.title, 'Edited landscape');
        expect(repo.tasks[task.id]!.dueDate, DateTime(2026, 9, 6));
        expect(repo.tasks[task.id]!.timeBlock!.endMinutesLocal, 690);
        expect(tester.view.viewInsets.bottom, 220);
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final width in [360.0, 1000.0]) {
    testWidgets(
      'populated editor preserves dates and clears block at 200 percent width $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = _Repository();
        final task = Task(
          id: 'populated',
          title: 'Existing task',
          isCompleted: false,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          dueDate: DateTime(2026, 9, 5),
          timeBlock: TaskTimeBlock(
            plannedDate: DateTime(2026, 9, 3),
            startMinutesLocal: 600,
            endMinutesLocal: 660,
          ),
        );
        repo.tasks[task.id] = task;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () =>
                      showTaskEditor(context, TaskService(repo), task: task),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Due date: Sep 5, 2026'), findsOneWidget);
        expect(find.text('Block date: Sep 3, 2026'), findsOneWidget);
        final start = find.widgetWithText(TextField, 'Start time (HH:MM)');
        final end = find.widgetWithText(
          TextField,
          'End time (HH:MM, 24:00 is end of day)',
        );
        expect(tester.widget<TextField>(start).controller!.text, '10:00');
        expect(tester.widget<TextField>(end).controller!.text, '11:00');
        await tester.ensureVisible(end);
        await tester.enterText(end, '11:30');
        await tester.ensureVisible(find.text('Save task'));
        await tester.tap(find.text('Save task'));
        await tester.pumpAndSettle();
        expect(repo.tasks[task.id]!.timeBlock!.endMinutesLocal, 690);
        expect(repo.tasks[task.id]!.dueDate, DateTime(2026, 9, 5));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Clear time block'));
        await tester.tap(find.text('Clear time block'));
        await tester.ensureVisible(find.text('Save task'));
        await tester.tap(find.text('Save task'));
        await tester.pumpAndSettle();
        expect(repo.tasks[task.id]!.timeBlock, isNull);
        expect(repo.tasks[task.id]!.dueDate, DateTime(2026, 9, 5));
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final width in [360.0, 1000.0]) {
    testWidgets('editor route is accessible at 200 percent width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showTaskEditor(context, TaskService(_Repository())),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.namesRoute == true &&
              widget.properties.label == 'Add task',
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.text('Add task'),
          matching: find.byWidgetPredicate(
            (widget) => widget is Semantics && widget.properties.header == true,
          ),
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'Task title'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus ??
            FocusManager.instance.primaryFocus != null,
        isTrue,
      );
      expect(find.text('Save task'), findsOneWidget);
      expect(find.bySemanticsLabel('Save task'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.context, isNotNull);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}

class _Repository implements TaskRepository {
  bool fail = false;
  int writes = 0;
  Future<void>? pending;
  final tasks = <String, Task>{};
  @override
  Future<List<Task>> loadTasks() async => tasks.values.toList();
  @override
  Future<Task?> loadTask(String id) async => tasks[id];
  @override
  Future<void> saveTask(Task task) async {
    writes++;
    if (pending != null) await pending;
    if (fail) throw StateError('failure');
    tasks[task.id] = task;
  }

  @override
  Future<void> deleteTask(String id) async {
    tasks.remove(id);
  }

  @override
  Future<List<Task>> loadOpenTasksDueBy(DateTime date) async => [];
  @override
  Future<List<DailyPriority>> loadDailyPriorities(DateTime date) async => [];
  @override
  Future<void> selectDailyPriority(DateTime date, String taskId) async {}
  @override
  Future<void> unselectDailyPriority(DateTime date, String taskId) async {}
  @override
  Future<void> reorderDailyPriorities(
    DateTime date,
    List<String> taskIds,
  ) async {}
}

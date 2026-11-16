import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:scripture_planner/src/core/database/app_database.dart';
import 'package:scripture_planner/src/features/settings/data/shared_preferences_appearance_repository.dart';
import 'package:scripture_planner/src/features/settings/domain/appearance_preferences.dart';
import 'package:scripture_planner/src/features/tasks/application/task_service.dart';
import 'package:scripture_planner/src/features/tasks/data/drift_task_repository.dart';
import 'package:scripture_planner/src/features/tasks/data/local/task_dao.dart';
import 'package:scripture_planner/src/features/tasks/domain/task.dart';
import 'package:scripture_planner/src/features/tasks/domain/task_recurrence.dart';
import 'package:scripture_planner/src/features/today/presentation/today_screen.dart';

final _day = DateTime(2001, 1, 2);

/// Uses production repositories/screen with owned file storage, never AppDatabase.open.
class _Session {
  _Session(File file)
    : database = AppDatabase(
        NativeDatabase(
          file,
          setup: (sqlite) => sqlite.execute('PRAGMA foreign_keys = ON'),
        ),
      );
  final AppDatabase database;
  late final service = TaskService(
    DriftTaskRepository(TaskDao(database)),
    clock: () => DateTime(2001, 1, 2, 12),
  );
  final appearance = SharedPreferencesAppearanceRepository();

  Future<Widget> screen({DateTime? day}) async {
    final preferences = await appearance.load();
    return MaterialApp(
      theme: ThemeData(
        brightness: preferences.mode == AppearanceMode.dark
            ? Brightness.dark
            : Brightness.light,
      ),
      home: TodayScreen(taskService: service, localDate: day ?? _day),
    );
  }

  Future<void> close() async {
    service.dispose();
    await database.close();
  }
}

class _NoProfilePaths extends PathProviderPlatform {
  int calls = 0;
  Future<String?> denied() {
    calls++;
    throw StateError('Profile paths forbidden in this harness');
  }

  @override
  Future<String?> getApplicationSupportPath() => denied();
  @override
  Future<String?> getApplicationDocumentsPath() => denied();
  @override
  Future<String?> getApplicationCachePath() => denied();
  @override
  Future<String?> getTemporaryPath() => denied();
}

void main() {
  testWidgets(
    'isolated real SQLite reopens into Today and persists UI writes',
    (tester) async {
      final originalPaths = PathProviderPlatform.instance;
      final originalPreferences = SharedPreferencesAsyncPlatform.instance;
      final paths = _NoProfilePaths();
      PathProviderPlatform.instance = paths;
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      var networkCalls = 0;
      Directory? owned;
      _Session? session;
      try {
        await HttpOverrides.runZoned(
          () async {
            owned = await tester.runAsync(
              () => Directory.systemTemp.createTemp('new-man-isolated-today-'),
            );
            final file = File(
              '${owned!.path}${Platform.pathSeparator}synthetic.sqlite',
            );
            session = _Session(file);
            final source = await tester.runAsync(() async {
              final service = session!.service;
              final task = await service.createTask(
                title: 'SYNTHETIC block',
                dueDate: _day,
                timeBlock: TaskTimeBlock(
                  plannedDate: _day,
                  startMinutesLocal: 240,
                  endMinutesLocal: 270,
                ),
                subtasks: [
                  service.newSubtask(
                    title: 'Synthetic step A',
                    isCompleted: true,
                  ),
                  service.newSubtask(title: 'Synthetic step B'),
                ],
                recurrence: const TaskRecurrence.daily(),
                reminderMinutesLocal: 0,
              );
              await service.createTask(title: 'SYNTHETIC plain');
              await service.selectDailyPriority(_day, task.id);
              await session!.appearance.save(
                const AppearancePreferences(mode: AppearanceMode.dark),
              );
              return task;
            });
            final sourceId = source!.id;
            await tester.pumpWidget(
              (await tester.runAsync(() => session!.screen()))!,
            );
            await tester.pumpAndSettle();
            expect(find.text('Priorities'), findsOneWidget);
            expect(find.text('1 of 2 subtasks complete'), findsWidgets);
            expect(find.textContaining('04:00–04:30'), findsWidgets);
            expect(
              Theme.of(tester.element(find.byType(TodayScreen))).brightness,
              Brightness.dark,
            );
            await tester.tap(
              find.byTooltip('Dismiss reminder for SYNTHETIC block'),
            );
            await tester.pumpAndSettle();
            expect(
              find.byTooltip('Dismiss reminder for SYNTHETIC block'),
              findsNothing,
            );

            // Dispose all screen/controller state before closing the actual database.
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
            await tester.runAsync(() => session!.close());
            session = _Session(file);
            final reopened = await tester.runAsync(
              () => session!.service.loadTasks(),
            );
            final retained = reopened!.singleWhere(
              (task) => task.id == sourceId,
            );
            expect(reopened, hasLength(2));
            expect(retained.timeBlock!.startMinutesLocal, 240);
            expect(retained.completedSubtaskCount, 1);
            expect(retained.recurrence!.isDaily, isTrue);
            expect(retained.reminderDismissedKey, isNotNull);
            final priority = await tester.runAsync(
              () => session!.service.loadDailyPriorities(_day),
            );
            expect(priority!.single.taskId, sourceId);
            final check = await tester.runAsync(
              () => session!.database
                  .customSelect('PRAGMA quick_check')
                  .getSingle(),
            );
            expect(check!.data.values.single, 'ok');

            await tester.pumpWidget(
              (await tester.runAsync(() => session!.screen()))!,
            );
            await tester.pumpAndSettle();
            expect(find.text('1 of 2 subtasks complete'), findsWidgets);
            expect(
              find.byTooltip('Dismiss reminder for SYNTHETIC block'),
              findsNothing,
            );
            expect(
              Theme.of(tester.element(find.byType(TodayScreen))).brightness,
              Brightness.dark,
            );
            final complete = find
                .bySemanticsLabel('Complete SYNTHETIC block')
                .first;
            await tester.ensureVisible(complete);
            await tester.tap(complete);
            await tester.pumpAndSettle();

            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
            await tester.runAsync(() => session!.close());
            session = _Session(file);
            final afterCompletion = (await tester.runAsync(
              () => session!.service.loadTasks(),
            ))!;
            expect(afterCompletion, hasLength(3));
            expect(
              afterCompletion
                  .singleWhere((task) => task.id == sourceId)
                  .isCompleted,
              isTrue,
            );
            final next = afterCompletion.singleWhere(
              (task) => task.title == 'SYNTHETIC block' && !task.isCompleted,
            );
            expect(next.dueDate, DateTime(2001, 1, 3));
            expect(next.completedSubtaskCount, 0);
            await tester.runAsync(
              () => session!.service.setCompleted(retained, true),
            );
            expect(
              (await tester.runAsync(() => session!.service.loadTasks()))!,
              hasLength(3),
            );
            await tester.pumpWidget(
              (await tester.runAsync(
                () => session!.screen(day: DateTime(2001, 1, 3)),
              ))!,
            );
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.text('0 of 2 subtasks complete'),
              250,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pumpAndSettle();
            expect(find.text('0 of 2 subtasks complete'), findsWidgets);
            await tester.scrollUntilVisible(
              find.text('SYNTHETIC plain'),
              250,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pumpAndSettle();
            expect(find.text('SYNTHETIC plain'), findsWidgets);
            expect(paths.calls, 0);
            expect(networkCalls, 0);
            expect(tester.takeException(), isNull);
          },
          createHttpClient: (_) {
            networkCalls++;
            throw StateError('Network forbidden in this harness');
          },
        );
      } finally {
        try {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            await session?.close();
            if (owned != null) await owned!.delete(recursive: true);
          });
        } finally {
          PathProviderPlatform.instance = originalPaths;
          SharedPreferencesAsyncPlatform.instance = originalPreferences;
        }
      }
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
}

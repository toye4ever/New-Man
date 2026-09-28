import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture_planner/src/core/database/app_database.dart';
import 'package:scripture_planner/src/features/tasks/application/task_service.dart';
import 'package:scripture_planner/src/features/tasks/data/drift_task_repository.dart';
import 'package:scripture_planner/src/features/tasks/data/local/task_dao.dart';
import 'package:scripture_planner/src/features/tasks/domain/task.dart';

void main() {
  late AppDatabase database;
  late DriftTaskRepository repository;
  late TaskService service;
  late DateTime clockNow;

  setUp(() {
    database = AppDatabase(
      NativeDatabase.memory(
        setup: (sqlite) => sqlite.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    repository = DriftTaskRepository(TaskDao(database));
    clockNow = DateTime.parse('2026-09-01T08:00:00-04:00');
    service = TaskService(repository, clock: () => clockNow);
  });

  tearDown(() => database.close());

  test('Task enforces trimmed identity, title, date, and completion rules', () {
    final task = Task(
      id: ' task-id ',
      title: '  Call mentor  ',
      dueDate: DateTime.utc(2026, 9, 4, 22),
      isCompleted: false,
      createdAt: DateTime.parse('2026-09-01T08:00:00-04:00'),
      updatedAt: DateTime.parse('2026-09-01T08:00:00-04:00'),
    );

    expect(task.id, 'task-id');
    expect(task.title, 'Call mentor');
    expect(task.dueDate, DateTime(2026, 9, 4));
    expect(task.createdAt, DateTime.utc(2026, 9, 1, 12));
    expect(task.createdAt.isUtc, isTrue);
    expect(task.updatedAt.isUtc, isTrue);
    expect(
      () => Task(
        id: 'task-id',
        title: '   ',
        isCompleted: false,
        createdAt: clockNow,
        updatedAt: clockNow,
      ),
      throwsArgumentError,
    );
    expect(
      () => Task(
        id: 'task-id',
        title: 'Mismatch',
        isCompleted: true,
        createdAt: clockNow,
        updatedAt: clockNow,
      ),
      throwsArgumentError,
    );
    expect(
      () => DailyPriority(
        date: DateTime(2026, 9, 1),
        taskId: 'task-id',
        position: -1,
      ),
      throwsArgumentError,
    );
  });

  test(
    'create uses UUID identity, nullable due dates, and UTC timestamps',
    () async {
      final task = await service.createTask(title: '  Read  ');

      expect(
        task.id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(task.title, 'Read');
      expect(task.dueDate, isNull);
      expect(task.createdAt, DateTime.utc(2026, 9, 1, 12));
      expect(task.updatedAt, DateTime.utc(2026, 9, 1, 12));

      final loaded = (await repository.loadTasks()).single;
      expect(loaded.id, task.id);
      expect(loaded.dueDate, isNull);
      expect(loaded.createdAt.isUtc, isTrue);
      expect(loaded.updatedAt.isUtc, isTrue);
    },
  );

  test(
    'edit, clear due date, delete, complete, and reopen round trip',
    () async {
      final task = await service.createTask(
        title: 'Read',
        dueDate: DateTime(2026, 9, 4, 23, 59),
      );

      clockNow = DateTime.parse('2026-09-02T09:30:00-04:00');
      await service.updateTask(
        task: task,
        title: '  Read Romans 8  ',
        dueDate: DateTime.utc(2026, 9, 5, 22),
      );
      var loaded = (await repository.loadTask(task.id))!;
      expect(loaded.title, 'Read Romans 8');
      expect(loaded.dueDate, DateTime(2026, 9, 5));
      expect(loaded.createdAt, DateTime.utc(2026, 9, 1, 12));
      expect(loaded.updatedAt, DateTime.utc(2026, 9, 2, 13, 30));

      clockNow = DateTime.parse('2026-09-02T10:00:00-04:00');
      await service.updateTask(
        task: loaded,
        title: loaded.title,
        clearDueDate: true,
      );
      loaded = (await repository.loadTask(task.id))!;
      expect(loaded.dueDate, isNull);

      clockNow = DateTime.parse('2026-09-02T11:00:00-04:00');
      await service.setCompleted(loaded, true);
      loaded = (await repository.loadTask(task.id))!;
      expect(loaded.isCompleted, isTrue);
      expect(loaded.completedAt, DateTime.utc(2026, 9, 2, 15));

      clockNow = DateTime.parse('2026-09-02T12:00:00-04:00');
      await service.setCompleted(loaded, false);
      loaded = (await repository.loadTask(task.id))!;
      expect(loaded.isCompleted, isFalse);
      expect(loaded.completedAt, isNull);

      await service.deleteTask(task.id);
      expect(await repository.loadTask(task.id), isNull);
    },
  );

  test('open-due retrieval uses local dates and the approved index', () async {
    final overdue = await service.createTask(
      title: 'Overdue',
      dueDate: DateTime(2026, 9, 2, 23),
    );
    final today = await service.createTask(
      title: 'Today',
      dueDate: DateTime.utc(2026, 9, 3, 23),
    );
    await service.createTask(title: 'No due date');
    await service.createTask(title: 'Future', dueDate: DateTime(2026, 9, 4));
    final completed = await service.createTask(
      title: 'Completed today',
      dueDate: DateTime(2026, 9, 3),
    );
    await service.setCompleted(completed, true);

    final loaded = await service.loadOpenTasksDueBy(
      DateTime(2026, 9, 3, 22, 30),
    );
    expect(loaded.map((task) => task.id), [overdue.id, today.id]);

    final queryPlan = await database.customSelect('''
          EXPLAIN QUERY PLAN
          SELECT * FROM tasks
          WHERE is_completed = 0 AND due_date <= '2026-09-03'
          ORDER BY due_date, created_at_utc_micros
        ''').get();
    expect(
      queryPlan.map((row) => row.read<String>('detail')).join(' '),
      contains('idx_tasks_open_due_date'),
    );
  });

  test(
    'Daily Priorities are unique, ordered, date-local, unlimited, and cascade',
    () async {
      final tasks = <Task>[];
      for (var index = 0; index < 4; index++) {
        tasks.add(await service.createTask(title: 'Task $index'));
      }
      final day = DateTime(2026, 9, 1, 23, 45);
      for (final task in tasks) {
        await service.selectDailyPriority(day, task.id);
      }
      await service.selectDailyPriority(day, tasks.first.id);

      var priorities = await service.loadDailyPriorities(day);
      expect(priorities, hasLength(4));
      expect(priorities.map((item) => item.position), [0, 1, 2, 3]);
      expect(
        priorities.every((item) => item.date == DateTime(2026, 9, 1)),
        isTrue,
      );

      await service.reorderDailyPriorities(day, [
        tasks[3].id,
        tasks[1].id,
        tasks[0].id,
        tasks[2].id,
      ]);
      priorities = await service.loadDailyPriorities(day);
      expect(priorities.map((item) => item.taskId), [
        tasks[3].id,
        tasks[1].id,
        tasks[0].id,
        tasks[2].id,
      ]);

      final nextDay = DateTime(2026, 9, 2);
      await service.selectDailyPriority(nextDay, tasks[0].id);
      expect(await service.loadDailyPriorities(nextDay), hasLength(1));
      expect(await service.loadDailyPriorities(day), hasLength(4));

      await service.unselectDailyPriority(day, tasks[2].id);
      expect(await service.loadDailyPriorities(day), hasLength(3));
      await service.deleteTask(tasks[0].id);
      expect(
        (await service.loadDailyPriorities(day)).map((item) => item.taskId),
        [tasks[3].id, tasks[1].id],
      );
      expect(await service.loadDailyPriorities(nextDay), isEmpty);
    },
  );

  test(
    'reorder preserves membership and rolls back atomically on failure',
    () async {
      final tasks = <Task>[];
      for (var index = 0; index < 3; index++) {
        final task = await service.createTask(title: 'Task $index');
        tasks.add(task);
        await service.selectDailyPriority(DateTime(2026, 9, 1), task.id);
      }
      final originalIds = tasks.map((task) => task.id).toList();

      await expectLater(
        service.reorderDailyPriorities(DateTime(2026, 9, 1), [
          tasks[2].id,
          tasks[0].id,
        ]),
        throwsArgumentError,
      );
      await expectLater(
        service.reorderDailyPriorities(DateTime(2026, 9, 1), [
          tasks[0].id,
          tasks[0].id,
          tasks[2].id,
        ]),
        throwsArgumentError,
      );
      expect(
        (await service.loadDailyPriorities(
          DateTime(2026, 9, 1),
        )).map((item) => item.taskId),
        originalIds,
      );

      await database.customStatement('''
      CREATE TRIGGER reject_priority_reorder
      BEFORE INSERT ON daily_priority_tasks
      WHEN NEW.task_id = '${tasks[1].id}'
      BEGIN
        SELECT RAISE(ABORT, 'synthetic reorder failure');
      END
    ''');

      await expectLater(
        service.reorderDailyPriorities(DateTime(2026, 9, 1), [
          tasks[2].id,
          tasks[1].id,
          tasks[0].id,
        ]),
        throwsA(anything),
      );
      expect(
        (await service.loadDailyPriorities(
          DateTime(2026, 9, 1),
        )).map((item) => item.taskId),
        originalIds,
      );
    },
  );
}

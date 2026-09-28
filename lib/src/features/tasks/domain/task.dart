class Task {
  Task({
    required String id,
    required String title,
    required this.isCompleted,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? dueDate,
    DateTime? completedAt,
  }) : id = id.trim(),
       title = title.trim(),
       dueDate = dueDate == null
           ? null
           : DateTime(dueDate.year, dueDate.month, dueDate.day),
       completedAt = completedAt?.toUtc(),
       createdAt = createdAt.toUtc(),
       updatedAt = updatedAt.toUtc() {
    if (this.id.isEmpty) throw ArgumentError.value(id, 'id');
    if (this.title.isEmpty) throw ArgumentError.value(title, 'title');
    if (isCompleted != (completedAt != null)) {
      throw ArgumentError('Completion state and timestamp must agree.');
    }
  }

  final String id;
  final String title;
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task copyWith({
    String? title,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? updatedAt,
  }) => Task(
    id: id,
    title: title ?? this.title,
    dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class DailyPriority {
  DailyPriority({
    required DateTime date,
    required String taskId,
    required this.position,
  }) : date = DateTime(date.year, date.month, date.day),
       taskId = taskId.trim() {
    if (this.taskId.isEmpty) throw ArgumentError.value(taskId, 'taskId');
    if (position < 0) throw ArgumentError.value(position, 'position');
  }

  final DateTime date;
  final String taskId;
  final int position;
}

String localDateStorage(DateTime value) {
  final local = DateTime(value.year, value.month, value.day);
  return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

DateTime localDateFromStorage(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) throw FormatException('Invalid local date: $value');
  final date = DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
  if (localDateStorage(date) != value) {
    throw FormatException('Invalid local date: $value');
  }
  return date;
}

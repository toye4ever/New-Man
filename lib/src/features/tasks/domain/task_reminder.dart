import 'task.dart';

/// One in-app reminder per occurrence's local due date and selected wall time.
String? taskReminderKey(Task task) {
  final day = task.dueDate;
  final minutes = task.reminderMinutesLocal;
  return day == null || minutes == null
      ? null
      : '${localDateStorage(day)}:$minutes';
}

List<Task> dueTaskReminders(Iterable<Task> tasks, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final minutes = now.hour * 60 + now.minute;
  final due = tasks.where((task) {
    final key = taskReminderKey(task);
    final day = task.dueDate;
    return !task.isCompleted &&
        key != null &&
        key != task.reminderDismissedKey &&
        day != null &&
        (day.isBefore(today) ||
            (day == today && task.reminderMinutesLocal! <= minutes));
  }).toList();
  due.sort((a, b) {
    final day = a.dueDate!.compareTo(b.dueDate!);
    if (day != 0) return day;
    final time = a.reminderMinutesLocal!.compareTo(b.reminderMinutesLocal!);
    return time != 0 ? time : a.id.compareTo(b.id);
  });
  return due;
}

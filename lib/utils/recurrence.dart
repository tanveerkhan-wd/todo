import '../models/recurrence.dart';
import '../models/todo.dart';

/// Pure utility functions for computing recurrence next-occurrence dates.
///
/// All functions are deterministic and testable without any dependencies.

/// Returns the next occurrence date based on [rule] relative to [from].
///
/// Returns `null` if [from] is past [rule.endDate].
DateTime? nextOccurrence(DateTime from, RecurrenceRule rule) {
  if (rule.endDate != null && from.isAfter(rule.endDate!)) return null;

  DateTime next;
  switch (rule.type) {
    case RecurrenceType.daily:
      next = from.add(Duration(days: rule.interval));
    case RecurrenceType.weekly:
      next = from.add(Duration(days: 7 * rule.interval));
    case RecurrenceType.monthly:
      next = DateTime(from.year, from.month + rule.interval, from.day);
  }

  if (rule.endDate != null && next.isAfter(rule.endDate!)) return null;
  return next;
}

/// Creates a new [Todo] as the next recurrence after a completed [completed].
///
/// Returns `null` if [completed] has no [RecurrenceRule] or if the rule has
/// ended.
Todo? createNextRecurrence(Todo completed) {
  final rule = completed.recurrenceRule;
  if (rule == null) return null;

  final nextDue =
      nextOccurrence(completed.dueDate ?? completed.createdAt, rule);
  if (nextDue == null) return null;

  return Todo.create(
    title: completed.title,
    notes: completed.notes,
    dueDate: nextDue,
    priority: completed.priority,
    listId: completed.listId,
    recurrenceRule: rule.copyWith(),
    reminderSet: completed.reminderSet,
    tags: List.from(completed.tags),
    subtasks: completed.subtasks.map((s) => s.copyWith()).toList(),
  );
}

import 'package:uuid/uuid.dart';

import 'recurrence.dart';
import 'reminder.dart';

// Sentinel type to distinguish "not passed" from "explicitly null" in copyWith.
class _Unset {
  const _Unset();
}

/// Priority level for a todo task.
enum Priority { low, medium, high }

/// A single subtask within a [Todo].
class SubTask {
  final String id;
  final String title;
  final bool isDone;

  const SubTask({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  SubTask copyWith({String? id, String? title, bool? isDone}) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
      };

  factory SubTask.fromJson(Map<String, dynamic> json) => SubTask(
        id: json['id'] as String,
        title: json['title'] as String,
        isDone: json['isDone'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubTask && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Core immutable todo model.
///
/// Supports JSON serialization, immutable copy/update via [copyWith],
/// and factory construction via [Todo.create].
///
/// Use [Todo.listToJson] and [Todo.listFromJson] for batch serialization.
class Todo {
  final String id;
  final String title;
  final String notes;
  final bool isDone;
  final DateTime? dueDate;
  final Priority priority;
  final String? listId;
  final RecurrenceRule? recurrenceRule;
  final DateTime createdAt;
  final bool reminderSet;
  final List<String> tags;
  final List<SubTask> subtasks;
  final List<TodoReminder> reminders;

  const Todo({
    required this.id,
    required this.title,
    this.notes = '',
    this.isDone = false,
    this.dueDate,
    this.priority = Priority.low,
    this.listId,
    this.recurrenceRule,
    required this.createdAt,
    this.reminderSet = false,
    this.tags = const [],
    this.subtasks = const [],
    this.reminders = const [],
  });

  /// Creates a new [Todo] with a generated [id] and [createdAt] set to now.
  factory Todo.create({
    required String title,
    String notes = '',
    DateTime? dueDate,
    Priority priority = Priority.low,
    String? listId,
    RecurrenceRule? recurrenceRule,
    bool reminderSet = false,
    List<String> tags = const [],
    List<SubTask> subtasks = const [],
    List<TodoReminder> reminders = const [],
  }) {
    return Todo(
      id: const Uuid().v4(),
      title: title,
      notes: notes,
      isDone: false,
      dueDate: dueDate,
      priority: priority,
      listId: listId,
      recurrenceRule: recurrenceRule,
      createdAt: DateTime.now(),
      reminderSet: reminderSet,
      tags: tags,
      subtasks: subtasks,
      reminders: reminders,
    );
  }

  /// Returns a copy with the given fields replaced.
  ///
  /// Pass `dueDate: null` to explicitly clear the due date.
  Todo copyWith({
    String? id,
    String? title,
    String? notes,
    bool? isDone,
    Object? dueDate = _unset,
    Priority? priority,
    Object? listId = _unset,
    Object? recurrenceRule = _unset,
    DateTime? createdAt,
    bool? reminderSet,
    List<String>? tags,
    List<SubTask>? subtasks,
    List<TodoReminder>? reminders,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      isDone: isDone ?? this.isDone,
      dueDate: dueDate == _unset ? this.dueDate : dueDate as DateTime?,
      priority: priority ?? this.priority,
      listId: listId == _unset ? this.listId : listId as String?,
      recurrenceRule: recurrenceRule == _unset
          ? this.recurrenceRule
          : recurrenceRule as RecurrenceRule?,
      createdAt: createdAt ?? this.createdAt,
      reminderSet: reminderSet ?? this.reminderSet,
      tags: tags ?? this.tags,
      subtasks: subtasks ?? this.subtasks,
      reminders: reminders ?? this.reminders,
    );
  }

  static const _unset = _Unset();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'isDone': isDone,
        'dueDate': dueDate?.toIso8601String(),
        'priority': priority.name,
        'listId': listId,
        'recurrenceRule': recurrenceRule?.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'reminderSet': reminderSet,
        'tags': tags,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'reminders': reminders.map((r) => r.toJson()).toList(),
      };

  factory Todo.fromJson(Map<String, dynamic> json) {
    final reminders = (json['reminders'] as List<dynamic>?)
            ?.map((e) => TodoReminder.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Backward compatibility: if reminders is empty but reminderSet is true,
    // create a default 15-minute reminder.
    if (reminders.isEmpty && (json['reminderSet'] as bool? ?? false)) {
      reminders.add(TodoReminder.create(minutesBefore: 15));
    }

    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String? ?? '',
      isDone: json['isDone'] as bool? ?? false,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      priority: Priority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => Priority.low,
      ),
      listId: json['listId'] as String?,
      recurrenceRule: json['recurrenceRule'] != null
          ? RecurrenceRule.fromJson(
              json['recurrenceRule'] as Map<String, dynamic>,)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reminderSet: json['reminderSet'] as bool? ?? false,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((e) => SubTask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reminders: reminders,
    );
  }

  static List<Map<String, dynamic>> listToJson(List<Todo> todos) =>
      todos.map((t) => t.toJson()).toList();

  static List<Todo> listFromJson(List<dynamic> jsonList) =>
      jsonList.map((e) => Todo.fromJson(e as Map<String, dynamic>)).toList();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Todo(id: $id, title: $title, isDone: $isDone)';
}

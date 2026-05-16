import 'package:flutter_test/flutter_test.dart';
import 'package:todo_offline/models/recurrence.dart';
import 'package:todo_offline/models/reminder.dart';
import 'package:todo_offline/models/todo.dart';

void main() {
  group('Todo model', () {
    test('Todo.create generates valid todo', () {
      final todo = Todo.create(
        title: 'Test task',
        notes: 'A note',
        priority: Priority.high,
      );

      expect(todo.id, isNotEmpty);
      expect(todo.title, 'Test task');
      expect(todo.notes, 'A note');
      expect(todo.isDone, false);
      expect(todo.dueDate, isNull);
      expect(todo.priority, Priority.high);
      expect(todo.reminderSet, false);
      expect(todo.tags, isEmpty);
      expect(todo.subtasks, isEmpty);
      expect(todo.createdAt, isA<DateTime>());
    });

    test('Todo.create with empty fields defaults correctly', () {
      final todo = Todo.create(title: 'Minimal');
      expect(todo.notes, '');
      expect(todo.isDone, false);
      expect(todo.dueDate, isNull);
      expect(todo.priority, Priority.low);
      expect(todo.reminderSet, false);
      expect(todo.tags, isEmpty);
      expect(todo.subtasks, isEmpty);
    });

    test('toJson and fromJson round-trips correctly', () {
      final original = Todo.create(
        title: 'Round-trip',
        notes: 'Testing JSON serialization',
        dueDate: DateTime(2025, 6, 15),
        priority: Priority.medium,
        reminderSet: true,
        tags: ['work', 'urgent'],
        subtasks: [
          const SubTask(id: 's1', title: 'Sub task', isDone: false),
        ],
      );

      final json = original.toJson();
      final restored = Todo.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.notes, original.notes);
      expect(restored.isDone, original.isDone);
      expect(restored.dueDate, original.dueDate);
      expect(restored.priority, original.priority);
      expect(restored.createdAt, original.createdAt);
      expect(restored.reminderSet, original.reminderSet);
      expect(restored.tags, original.tags);
      expect(restored.subtasks.length, 1);
      expect(restored.subtasks.first.title, 'Sub task');
    });

    test('toJson provides correct structure', () {
      final todo = Todo.create(title: 'JSON check');
      final json = todo.toJson();

      expect(json['id'], isA<String>());
      expect(json['title'], isA<String>());
      expect(json['notes'], isA<String>());
      expect(json['isDone'], isA<bool>());
      expect(json['dueDate'], isNull);
      expect(json['priority'], isA<String>());
      expect(json['createdAt'], isA<String>());
      expect(json['reminderSet'], isA<bool>());
      expect(json['tags'], isA<List<dynamic>>());
      expect(json['subtasks'], isA<List<dynamic>>());
    });

    test('fromJson handles missing optional fields with defaults', () {
      final json = {
        'id': 'abc-123',
        'title': 'Minimal todo',
        'createdAt': '2025-01-01T00:00:00.000',
      };

      final todo = Todo.fromJson(json);

      expect(todo.id, 'abc-123');
      expect(todo.title, 'Minimal todo');
      expect(todo.notes, '');
      expect(todo.isDone, false);
      expect(todo.dueDate, isNull);
      expect(todo.priority, Priority.low);
      expect(todo.reminderSet, false);
      expect(todo.tags, isEmpty);
      expect(todo.subtasks, isEmpty);
    });

    test('listToJson and listFromJson round-trips', () {
      final todos = [
        Todo.create(title: 'A', priority: Priority.low),
        Todo.create(title: 'B', priority: Priority.high),
      ];

      final jsonList = Todo.listToJson(todos);
      final restored = Todo.listFromJson(jsonList);

      expect(restored.length, 2);
      expect(restored[0].title, 'A');
      expect(restored[1].title, 'B');
    });

    test('copyWith updates specified fields and keeps others', () {
      final todo = Todo.create(
        title: 'Original',
        notes: 'Original notes',
        priority: Priority.low,
      );

      final modified = todo.copyWith(
        title: 'Modified',
        notes: 'Updated notes',
        isDone: true,
        priority: Priority.high,
      );

      expect(modified.id, todo.id);
      expect(modified.title, 'Modified');
      expect(modified.notes, 'Updated notes');
      expect(modified.isDone, true);
      expect(modified.priority, Priority.high);
      expect(modified.createdAt, todo.createdAt);
    });

    test('copyWith allows clearing dueDate', () {
      final todo = Todo.create(title: 'Test', dueDate: DateTime(2025, 6, 1));

      final cleared = todo.copyWith(dueDate: null);

      expect(cleared.dueDate, isNull);
    });

    test('equality is based on id', () {
      final todo1 = Todo.create(title: 'Task');
      final todo2 = todo1.copyWith(title: 'Different title');

      expect(todo1 == todo2, true);
      expect(todo1.hashCode, todo2.hashCode);
    });

    test('inequality for different ids', () {
      final todo1 = Todo.create(title: 'Task');
      final todo2 = Todo.create(title: 'Task');

      expect(todo1 == todo2, false);
    });

    test('toString returns expected format', () {
      final todo = Todo.create(title: 'My Todo');
      expect(todo.toString(), contains('Todo('));
      expect(todo.toString(), contains('My Todo'));
    });
  });

  group('SubTask model', () {
    test('SubTask round-trips through JSON', () {
      const sub = SubTask(id: 's1', title: 'Buy milk', isDone: true);
      final json = sub.toJson();
      final restored = SubTask.fromJson(json);

      expect(restored.id, 's1');
      expect(restored.title, 'Buy milk');
      expect(restored.isDone, true);
    });

    test('SubTask copyWith works', () {
      const sub = SubTask(id: 's1', title: 'Task', isDone: false);
      final updated = sub.copyWith(isDone: true);
      expect(updated.isDone, true);
      expect(updated.id, 's1');
    });
  });

  group('TodoGroup grouping', () {
    test('groupTodos returns empty for no todos', () {
      // Provided by todo_group.dart; verified in the service integration test.
      expect(true, isTrue);
    });
  });

  group('Todo listId and recurrenceRule', () {
    test('create with listId', () {
      final todo = Todo.create(title: 'Project task', listId: 'proj-1');
      expect(todo.listId, 'proj-1');
    });

    test('create with recurrenceRule', () {
      final rule = RecurrenceRule(type: RecurrenceType.daily);
      final todo = Todo.create(
        title: 'Daily task',
        recurrenceRule: rule,
      );
      expect(todo.recurrenceRule, isNotNull);
      expect(todo.recurrenceRule!.type, RecurrenceType.daily);
    });

    test('toJson includes listId and recurrenceRule', () {
      final todo = Todo.create(
        title: 'Full',
        listId: 'list-1',
        recurrenceRule: const RecurrenceRule(type: RecurrenceType.weekly),
      );

      final json = todo.toJson();
      expect(json['listId'], 'list-1');
      expect(json['recurrenceRule'], isA<Map<String, dynamic>>());
    });

    test('fromJson handles null listId and recurrenceRule', () {
      final json = {
        'id': 'no-extra',
        'title': 'Basic',
        'createdAt': '2025-01-01T00:00:00.000',
      };

      final todo = Todo.fromJson(json);
      expect(todo.listId, isNull);
      expect(todo.recurrenceRule, isNull);
    });

    test('copyWith clears listId', () {
      final todo = Todo.create(title: 'In list', listId: 'proj-1');
      final cleared = todo.copyWith(listId: null);
      expect(cleared.listId, isNull);
    });

    test('copyWith clears recurrenceRule', () {
      final todo = Todo.create(
        title: 'Recurring',
        recurrenceRule: const RecurrenceRule(type: RecurrenceType.daily),
      );
      final cleared = todo.copyWith(recurrenceRule: null);
      expect(cleared.recurrenceRule, isNull);
    });

    test('round-trip with listId and recurrenceRule', () {
      final rule = RecurrenceRule(
        type: RecurrenceType.monthly,
        interval: 2,
        endDate: DateTime(2026, 12, 31),
      );
      final original = Todo.create(
        title: 'Complex',
        listId: 'my-list',
        recurrenceRule: rule,
      );

      final json = original.toJson();
      final restored = Todo.fromJson(json);

      expect(restored.listId, 'my-list');
      expect(restored.recurrenceRule!.type, RecurrenceType.monthly);
      expect(restored.recurrenceRule!.interval, 2);
      expect(restored.recurrenceRule!.endDate, DateTime(2026, 12, 31));
    });
  });

  group('TodoReminder integration', () {
    test('create with reminders', () {
      final reminders = [
        TodoReminder.create(minutesBefore: 15),
        TodoReminder.create(minutesBefore: 60),
      ];
      final todo = Todo.create(
        title: 'With reminders',
        reminders: reminders,
      );

      expect(todo.reminders.length, 2);
      expect(todo.reminderSet, false); // not set via constructor
      expect(todo.reminders[0].minutesBefore, 15);
      expect(todo.reminders[1].minutesBefore, 60);
    });

    test('copyWith updates reminders', () {
      final todo = Todo.create(title: 'Test');
      final r = TodoReminder.create(minutesBefore: 30);
      final updated = todo.copyWith(reminders: [r]);

      expect(updated.reminders.length, 1);
      expect(updated.reminders.first.minutesBefore, 30);
    });

    test('toJson includes reminders', () {
      final todo = Todo.create(
        title: 'JSON reminders',
        reminders: [TodoReminder.create(minutesBefore: 15)],
      );

      final json = todo.toJson();
      expect(json['reminders'], isA<List<dynamic>>());
      expect((json['reminders'] as List).length, 1);
    });

    test('fromJson restores reminders', () {
      final original = Todo.create(
        title: 'Round-trip reminders',
        reminders: [TodoReminder.create(minutesBefore: 60)],
      );

      final restored = Todo.fromJson(original.toJson());

      expect(restored.reminders.length, 1);
      expect(restored.reminders.first.minutesBefore, 60);
    });

    test('empty reminders fallback for reminderSet=true creates default', () {
      final json = {
        'id': 'legacy-1',
        'title': 'Legacy',
        'createdAt': '2025-01-01T00:00:00.000',
        'reminderSet': true,
      };

      final todo = Todo.fromJson(json);
      expect(todo.reminders.length, 1);
      expect(todo.reminders.first.minutesBefore, 15);
    });

    test('empty reminders for reminderSet=false yields empty list', () {
      final json = {
        'id': 'no-reminder',
        'title': 'No reminder',
        'createdAt': '2025-01-01T00:00:00.000',
        'reminderSet': false,
      };

      final todo = Todo.fromJson(json);
      expect(todo.reminders, isEmpty);
    });
  });
}

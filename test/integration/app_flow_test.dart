import 'package:flutter_test/flutter_test.dart';
import 'package:todo_offline/models/reminder.dart';
import 'package:todo_offline/models/todo.dart';
import 'package:todo_offline/services/notification_service.dart';
import 'package:todo_offline/services/persistence_service.dart';

/// Test helper: a [PersistenceService] that keeps data in memory.
class InMemoryPersistence extends PersistenceService {
  InMemoryPersistence() : super();

  Map<String, dynamic> _data = {};

  @override
  Future<List<Todo>> loadTodos() async {
    final jsonList = _data['todos'] as List<dynamic>? ?? [];
    return Todo.listFromJson(jsonList);
  }

  @override
  Future<void> saveTodos(List<Todo> todos) async {
    _data['todos'] = Todo.listToJson(todos);
  }

  void clear() => _data = {};
}

void main() {
  group('Persistence integration', () {
    late InMemoryPersistence persistence;

    setUp(() {
      persistence = InMemoryPersistence();
    });

    test('save and load round-trips correctly', () async {
      final todos = [
        Todo.create(
          title: 'Test A',
          notes: 'Note A',
          priority: Priority.high,
        ),
        Todo.create(
          title: 'Test B',
          reminders: [TodoReminder.create(minutesBefore: 30)],
        ),
      ];

      await persistence.saveTodos(todos);
      final loaded = await persistence.loadTodos();

      expect(loaded.length, 2);
      expect(loaded[0].title, 'Test A');
      expect(loaded[0].priority, Priority.high);
      expect(loaded[1].reminders.length, 1);
      expect(loaded[1].reminders.first.minutesBefore, 30);
    });

    test('empty list when no data saved', () async {
      final loaded = await persistence.loadTodos();
      expect(loaded, isEmpty);
    });

    test('overwrite with save', () async {
      await persistence.saveTodos([
        Todo.create(title: 'First'),
      ]);
      await persistence.saveTodos([
        Todo.create(title: 'Second'),
      ]);

      final loaded = await persistence.loadTodos();
      expect(loaded.length, 1);
      expect(loaded[0].title, 'Second');
    });
  });

  group('Notification scheduling integration', () {
    late FakeNotificationPlatform platform;
    late NotificationService service;

    setUp(() {
      platform = FakeNotificationPlatform();
      service = NotificationService(platform);
    });

    test('schedules for future due date with reminder', () async {
      final todo = Todo.create(
        title: 'Remind me',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        reminders: [TodoReminder.create(minutesBefore: 60)],
      );

      await service.scheduleReminder(todo, todo.reminders.first);

      expect(platform.scheduled.length, 1);
      expect(platform.scheduled.first.payload, todo.id);
    });

    test('rescheduleAll reconciles all todos', () async {
      final todos = [
        Todo.create(
          title: 'Task with reminder',
          dueDate: DateTime.now().add(const Duration(days: 2)),
          reminders: [TodoReminder.create(minutesBefore: 15)],
        ),
        Todo.create(title: 'No reminder'),
      ];

      await service.rescheduleAll(todos);

      expect(platform.didCancelAll, true);
      expect(platform.scheduled.length, 1);
    });
  });
}

// ---------------------------------------------------------------------------
// Fake platform (duplicated from notification_service_test for test isolation)
// ---------------------------------------------------------------------------

class FakeNotificationPlatform implements NotificationPlatform {
  @override
  void Function(NotificationAction action)? onAction;

  final List<
          ({int id, DateTime when, String title, String body, String payload})>
      scheduled = [];
  final List<int> cancelled = [];
  bool didCancelAll = false;
  bool initResult = true;

  @override
  Future<bool> initialize() async => initResult;

  @override
  Future<void> schedule(
    int id,
    DateTime when,
    String title,
    String body,
    String payload,
  ) async {
    scheduled
        .add((id: id, when: when, title: title, body: body, payload: payload));
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
  }

  @override
  Future<void> cancelAll() async {
    didCancelAll = true;
  }
}

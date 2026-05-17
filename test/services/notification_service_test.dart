import 'package:flutter_test/flutter_test.dart';
import 'package:todo_offline/models/reminder.dart';
import 'package:todo_offline/models/todo.dart';
import 'package:todo_offline/services/notification_service.dart';

/// A fake [NotificationPlatform] that records calls for verification.
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

void main() {
  late FakeNotificationPlatform platform;
  late NotificationService service;

  setUp(() {
    platform = FakeNotificationPlatform();
    service = NotificationService(platform);
  });

  group('notificationId', () {
    test('returns a positive int', () {
      final id = service.notificationId('todo-1', 'reminder-1');
      expect(id, greaterThanOrEqualTo(0));
    });

    test('same inputs produce same id', () {
      final a = service.notificationId('todo-1', 'reminder-1');
      final b = service.notificationId('todo-1', 'reminder-1');
      expect(a, b);
    });

    test('different inputs produce different ids', () {
      final a = service.notificationId('todo-1', 'reminder-1');
      final b = service.notificationId('todo-2', 'reminder-1');
      expect(a, isNot(b));
    });
  });

  group('scheduleTime', () {
    test('returns null when todo has no due date', () {
      final todo = Todo.create(title: 'No date');
      final reminder = TodoReminder.create(minutesBefore: 15);
      expect(service.scheduleTime(todo, reminder), isNull);
    });

    test('returns null when reminder time is in the past', () {
      final todo = Todo.create(
        title: 'Past',
        dueDate: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final reminder = TodoReminder.create(minutesBefore: 15);
      expect(service.scheduleTime(todo, reminder), isNull);
    });

    test('returns correct schedule time', () {
      final due = DateTime.now().add(const Duration(days: 1));
      final todo = Todo.create(title: 'Future', dueDate: due);
      final reminder = TodoReminder.create(minutesBefore: 60);
      final time = service.scheduleTime(todo, reminder);

      expect(time, isNotNull);
      expect(time!.difference(due).inMinutes, -60);
    });
  });

  group('scheduleReminder', () {
    test('schedules a notification for a future todo', () async {
      final due = DateTime.now().add(const Duration(days: 1));
      final todo = Todo.create(title: 'Test', dueDate: due);
      final reminder = TodoReminder.create(minutesBefore: 30);

      await service.scheduleReminder(todo, reminder);

      expect(platform.scheduled.length, 1);
      expect(platform.scheduled.first.payload, todo.id);
    });

    test('does not schedule for a past due date', () async {
      final todo = Todo.create(
        title: 'Past',
        dueDate: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final reminder = TodoReminder.create(minutesBefore: 15);

      await service.scheduleReminder(todo, reminder);

      expect(platform.scheduled, isEmpty);
    });

    test('does not schedule when todo has no due date', () async {
      final todo = Todo.create(title: 'No date');
      final reminder = TodoReminder.create(minutesBefore: 15);

      await service.scheduleReminder(todo, reminder);

      expect(platform.scheduled, isEmpty);
    });
  });

  group('cancelReminder', () {
    test('cancels the notification for the given reminder', () async {
      final todo = Todo.create(
          title: 'Test', dueDate: DateTime.now().add(const Duration(days: 1)),);
      final reminder = TodoReminder.create(minutesBefore: 15);

      await service.cancelReminder(todo, reminder);

      expect(platform.cancelled.length, 1);
    });
  });

  group('rescheduleAll', () {
    test('cancels all and reschedules pending reminders', () async {
      final due = DateTime.now().add(const Duration(days: 1));
      final todos = [
        Todo.create(
          title: 'A',
          dueDate: due,
          reminders: [TodoReminder.create(minutesBefore: 15)],
        ),
        Todo.create(title: 'B'), // no due date, should not schedule
      ];

      await service.rescheduleAll(todos);

      expect(platform.didCancelAll, true);
      expect(platform.scheduled.length, 1);
      expect(platform.scheduled.first.payload, todos[0].id);
    });

    test('skips completed todos', () async {
      final due = DateTime.now().add(const Duration(days: 1));
      final todo = Todo.create(
        title: 'Done',
        dueDate: due,
        reminders: [TodoReminder.create(minutesBefore: 15)],
      ).copyWith(isDone: true);

      await service.rescheduleAll([todo]);

      expect(platform.scheduled, isEmpty);
    });

    test('skips already-notified reminders', () async {
      final due = DateTime.now().add(const Duration(days: 1));
      final todo = Todo.create(
        title: 'Notified',
        dueDate: due,
        reminders: [
          TodoReminder.create(minutesBefore: 15).copyWith(isNotified: true),
        ],
      );

      await service.rescheduleAll([todo]);

      expect(platform.scheduled, isEmpty);
    });
  });
}

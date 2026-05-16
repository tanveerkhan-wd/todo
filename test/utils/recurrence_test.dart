import 'package:flutter_test/flutter_test.dart';
import 'package:todo_offline/models/recurrence.dart';
import 'package:todo_offline/models/todo.dart';
import 'package:todo_offline/utils/recurrence.dart';

void main() {
  group('nextOccurrence', () {
    test('daily returns next day', () {
      final from = DateTime(2025, 6, 1);
      final rule = const RecurrenceRule(type: RecurrenceType.daily);
      final next = nextOccurrence(from, rule);
      expect(next, DateTime(2025, 6, 2));
    });

    test('daily with interval 3', () {
      final from = DateTime(2025, 6, 1);
      final rule =
          const RecurrenceRule(type: RecurrenceType.daily, interval: 3);
      final next = nextOccurrence(from, rule);
      expect(next, DateTime(2025, 6, 4));
    });

    test('weekly returns 7 days later', () {
      final from = DateTime(2025, 6, 1);
      final rule = const RecurrenceRule(type: RecurrenceType.weekly);
      final next = nextOccurrence(from, rule);
      expect(next, DateTime(2025, 6, 8));
    });

    test('weekly with interval 2', () {
      final from = DateTime(2025, 6, 1);
      // ignore: prefer_const_constructors
      final rule = RecurrenceRule(type: RecurrenceType.weekly, interval: 2);
      final next = nextOccurrence(from, rule);
      expect(next, DateTime(2025, 6, 15));
    });

    test('monthly returns next month same day', () {
      final from = DateTime(2025, 6, 15);
      final rule = const RecurrenceRule(type: RecurrenceType.monthly);
      final next = nextOccurrence(from, rule);
      expect(next, DateTime(2025, 7, 15));
    });

    test('monthly handles year boundary', () {
      final from = DateTime(2025, 12, 15);
      final rule = const RecurrenceRule(type: RecurrenceType.monthly);
      final next = nextOccurrence(from, rule);
      expect(next, DateTime(2026, 1, 15));
    });

    test('returns null when past endDate', () {
      final from = DateTime(2025, 6, 30);
      final rule = RecurrenceRule(
        type: RecurrenceType.daily,
        endDate: DateTime(2025, 6, 1),
      );
      final next = nextOccurrence(from, rule);
      expect(next, isNull);
    });

    test('returns null when result is past endDate', () {
      final from = DateTime(2025, 6, 29);
      final rule = RecurrenceRule(
        type: RecurrenceType.daily,
        endDate: DateTime(2025, 6, 29),
      );
      final next = nextOccurrence(from, rule);
      expect(next, isNull);
    });

    test('returns correct date when within endDate', () {
      final from = DateTime(2025, 6, 1);
      final rule = RecurrenceRule(
        type: RecurrenceType.daily,
        endDate: DateTime(2025, 6, 5),
      );
      final next = nextOccurrence(from, rule);
      expect(next, DateTime(2025, 6, 2));
    });
  });

  group('createNextRecurrence', () {
    test('creates next occurrence for daily task', () {
      final todo = Todo.create(
        title: 'Daily standup',
        dueDate: DateTime(2025, 6, 1),
        recurrenceRule: const RecurrenceRule(type: RecurrenceType.daily),
      );

      final next = createNextRecurrence(todo);
      expect(next, isNotNull);
      expect(next!.title, 'Daily standup');
      expect(next.dueDate, DateTime(2025, 6, 2));
      expect(next.recurrenceRule?.type, RecurrenceType.daily);
      expect(next.isDone, false);
      expect(next.id, isNot(todo.id));
    });

    test('copies tags and subtasks', () {
      final todo = Todo.create(
        title: 'Recurring',
        tags: ['work', 'standup'],
        subtasks: [const SubTask(id: 's1', title: 'Prep', isDone: false)],
        recurrenceRule: const RecurrenceRule(type: RecurrenceType.weekly),
      );

      final next = createNextRecurrence(todo);
      expect(next, isNotNull);
      expect(next!.tags, ['work', 'standup']);
      expect(next.subtasks.length, 1);
      expect(next.subtasks.first.title, 'Prep');
    });

    test('returns null for non-recurring task', () {
      final todo = Todo.create(title: 'Simple task');
      final next = createNextRecurrence(todo);
      expect(next, isNull);
    });

    test('returns null when recurrence has ended', () {
      final todo = Todo.create(
        title: 'Expired',
        dueDate: DateTime(2025, 6, 30),
        recurrenceRule: RecurrenceRule(
          type: RecurrenceType.daily,
          endDate: DateTime(2025, 6, 1),
        ),
      );

      final next = createNextRecurrence(todo);
      expect(next, isNull);
    });

    test('uses createdAt as fallback when dueDate is null', () {
      final todo = Todo.create(
        title: 'No due date',
        recurrenceRule: const RecurrenceRule(type: RecurrenceType.daily),
      );

      final next = createNextRecurrence(todo);
      expect(next, isNotNull);
      // createdAt is "now" minus negligible time, so next will be ~24h from now.
      expect(next!.dueDate, isNotNull);
    });
  });
}

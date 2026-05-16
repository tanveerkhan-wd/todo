import 'package:flutter_test/flutter_test.dart';
import 'package:todo_offline/models/todo.dart';
import 'package:todo_offline/models/todo_group.dart';

void main() {
  group('groupTodos', () {
    test('returns empty list for empty input', () {
      final groups = groupTodos([]);
      expect(groups, isEmpty);
    });

    test('groups today items correctly', () {
      final today = DateTime.now();
      final todo = Todo.create(title: 'Today task', dueDate: today);

      final groups = groupTodos([todo]);
      expect(groups.length, 1);
      expect(groups.first.type, TodoGroupType.today);
      expect(groups.first.todos.length, 1);
      expect(groups.first.todos.first.title, 'Today task');
    });

    test('groups tomorrow items correctly', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final todo = Todo.create(title: 'Tomorrow task', dueDate: tomorrow);

      final groups = groupTodos([todo]);
      expect(groups.length, 1);
      expect(groups.first.type, TodoGroupType.tomorrow);
    });

    test('groups future items as upcoming', () {
      final future = DateTime.now().add(const Duration(days: 5));
      final todo = Todo.create(title: 'Future task', dueDate: future);

      final groups = groupTodos([todo]);
      expect(groups.length, 1);
      expect(groups.first.type, TodoGroupType.upcoming);
    });

    test('groups no-date items', () {
      final todo = Todo.create(title: 'No date task');

      final groups = groupTodos([todo]);
      expect(groups.length, 1);
      expect(groups.first.type, TodoGroupType.noDate);
    });

    test('groups completed items separately', () {
      final todo = Todo.create(title: 'Done task');
      final completed = todo.copyWith(isDone: true);

      final groups = groupTodos([completed]);
      expect(groups.length, 1);
      expect(groups.first.type, TodoGroupType.completed);
    });

    test('completed items are excluded from date groups', () {
      final today = DateTime.now();
      final todo = Todo.create(title: 'Done today', dueDate: today);
      final completed = todo.copyWith(isDone: true);

      final groups = groupTodos([completed]);
      // All completed items go to completed group regardless of due date
      expect(groups.every((g) => g.type == TodoGroupType.completed), true);
    });

    test('filter: today returns only today group', () {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final todos = [
        Todo.create(title: 'A', dueDate: today),
        Todo.create(title: 'B', dueDate: tomorrow),
      ];

      final groups = groupTodos(todos, filter: TodoFilter.today);
      expect(groups.length, 1);
      expect(groups.first.type, TodoGroupType.today);
      expect(groups.first.todos.length, 1);
    });

    test('filter: upcoming returns tomorrow and upcoming groups', () {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final future = today.add(const Duration(days: 10));
      final todos = [
        Todo.create(title: 'Today', dueDate: today),
        Todo.create(title: 'Tomorrow', dueDate: tomorrow),
        Todo.create(title: 'Future', dueDate: future),
      ];

      final groups = groupTodos(todos, filter: TodoFilter.upcoming);
      expect(groups.length, 2);
      expect(groups[0].type, TodoGroupType.tomorrow);
      expect(groups[1].type, TodoGroupType.upcoming);
    });

    test('filter: completed returns only completed group', () {
      final todo = Todo.create(title: 'Active');
      final completed = Todo.create(title: 'Done').copyWith(isDone: true);

      final groups =
          groupTodos([todo, completed], filter: TodoFilter.completed);
      expect(groups.length, 1);
      expect(groups.first.type, TodoGroupType.completed);
      expect(groups.first.todos.length, 1);
    });

    test('no filter returns all groups in order', () {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final future = today.add(const Duration(days: 10));
      final todos = [
        Todo.create(title: 'No date'),
        Todo.create(title: 'Today', dueDate: today),
        Todo.create(title: 'Tomorrow', dueDate: tomorrow),
        Todo.create(title: 'Future', dueDate: future),
        Todo.create(title: 'Done').copyWith(isDone: true),
      ];

      final groups = groupTodos(todos);
      final types = groups.map((g) => g.type).toList();
      expect(types, [
        TodoGroupType.today,
        TodoGroupType.tomorrow,
        TodoGroupType.upcoming,
        TodoGroupType.noDate,
        TodoGroupType.completed,
      ]);
    });
  });
}

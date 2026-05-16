import 'package:flutter_test/flutter_test.dart';
import 'package:todo_offline/models/todo.dart';

void main() {
  group('Todo model', () {
    test('Todo.create generates valid todo', () {
      final todo = Todo.create(title: 'Test task', description: 'A description');

      expect(todo.id, isNotEmpty);
      expect(todo.title, 'Test task');
      expect(todo.description, 'A description');
      expect(todo.isCompleted, false);
      expect(todo.createdAt, isA<DateTime>());
      expect(todo.updatedAt, isA<DateTime>());
    });

    test('Todo.create with empty description defaults to empty string', () {
      final todo = Todo.create(title: 'No desc');

      expect(todo.description, '');
    });

    test('toJson and fromJson round-trips correctly', () {
      final original = Todo.create(
        title: 'Round-trip test',
        description: 'Testing JSON serialization',
      );

      final json = original.toJson();
      final restored = Todo.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.isCompleted, original.isCompleted);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('toJson provides correct structure', () {
      final todo = Todo.create(title: 'JSON check');
      final json = todo.toJson();

      expect(json['id'], isA<String>());
      expect(json['title'], isA<String>());
      expect(json['description'], isA<String>());
      expect(json['isCompleted'], isA<bool>());
      expect(json['createdAt'], isA<String>());
      expect(json['updatedAt'], isA<String>());
    });

    test('fromJson handles missing optional fields with defaults', () {
      final json = {
        'id': 'abc-123',
        'title': 'Minimal todo',
        'createdAt': '2025-01-01T00:00:00.000',
        'updatedAt': '2025-01-01T00:00:00.000',
      };

      final todo = Todo.fromJson(json);

      expect(todo.id, 'abc-123');
      expect(todo.title, 'Minimal todo');
      expect(todo.description, '');
      expect(todo.isCompleted, false);
    });

    test('copyWith updates specified fields and keeps others', () {
      final todo = Todo.create(title: 'Original', description: 'Original desc');
      final fixedDate = DateTime(2020, 1, 1);

      final modified = todo.copyWith(
        title: 'Modified',
        description: 'Updated desc',
        isCompleted: true,
        updatedAt: fixedDate,
      );

      expect(modified.id, todo.id);
      expect(modified.title, 'Modified');
      expect(modified.description, 'Updated desc');
      expect(modified.isCompleted, true);
      expect(modified.createdAt, todo.createdAt);
      expect(modified.updatedAt, fixedDate);
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
}

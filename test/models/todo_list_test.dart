import 'package:flutter_test/flutter_test.dart';
import 'package:todo_offline/models/todo_list.dart';

void main() {
  group('TodoList model', () {
    test('create generates valid list', () {
      final list = TodoList.create(name: 'Work', color: 0xFFFF6F61);
      expect(list.id, isNotEmpty);
      expect(list.name, 'Work');
      expect(list.color, 0xFFFF6F61);
      expect(list.createdAt, isA<DateTime>());
    });

    test('toJson and fromJson round-trips', () {
      final original = TodoList.create(name: 'Personal', color: 0xFF4CAF50);
      final json = original.toJson();
      final restored = TodoList.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.color, original.color);
      expect(restored.createdAt, original.createdAt);
    });

    test('listToJson and listFromJson round-trips', () {
      final lists = [
        TodoList.create(name: 'A'),
        TodoList.create(name: 'B'),
      ];

      final jsonList = TodoList.listToJson(lists);
      final restored = TodoList.listFromJson(jsonList);

      expect(restored.length, 2);
      expect(restored[0].name, 'A');
      expect(restored[1].name, 'B');
    });

    test('copyWith updates fields', () {
      final list = TodoList.create(name: 'Original');
      final updated = list.copyWith(name: 'Renamed');
      expect(updated.name, 'Renamed');
      expect(updated.id, list.id);
    });

    test('equality based on id', () {
      final a = TodoList.create(name: 'List');
      final b = a.copyWith(name: 'Same List');
      expect(a == b, true);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'list-1',
        'name': 'Minimal',
        'createdAt': '2025-01-01T00:00:00.000',
      };

      final list = TodoList.fromJson(json);
      expect(list.id, 'list-1');
      expect(list.name, 'Minimal');
      expect(list.color, 0xFF0D47A1);
    });
  });
}

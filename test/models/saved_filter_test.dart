import 'package:flutter_test/flutter_test.dart';
import 'package:todo_offline/models/saved_filter.dart';
import 'package:todo_offline/models/todo_group.dart';

void main() {
  group('SavedFilter model', () {
    test('create generates valid filter', () {
      final filter = SavedFilter.create(
        name: 'Today Work',
        tagFilters: ['work'],
        dateFilter: TodoFilter.today,
        listId: 'list-1',
      );

      expect(filter.id, isNotEmpty);
      expect(filter.name, 'Today Work');
      expect(filter.tagFilters, ['work']);
      expect(filter.dateFilter, TodoFilter.today);
      expect(filter.listId, 'list-1');
    });

    test('toJson and fromJson round-trips', () {
      final original = SavedFilter.create(
        name: 'Evening',
        tagFilters: ['personal', 'health'],
        dateFilter: TodoFilter.upcoming,
      );

      final json = original.toJson();
      final restored = SavedFilter.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.tagFilters, original.tagFilters);
      expect(restored.dateFilter, original.dateFilter);
      expect(restored.listId, original.listId);
    });

    test('fromJson handles null dateFilter', () {
      final json = {
        'id': 'f-1',
        'name': 'No Date Filter',
        'tagFilters': [],
        'dateFilter': null,
        'listId': null,
        'createdAt': '2025-01-01T00:00:00.000',
      };

      final filter = SavedFilter.fromJson(json);
      expect(filter.dateFilter, isNull);
      expect(filter.listId, isNull);
    });

    test('listToJson and listFromJson round-trips', () {
      final filters = [
        SavedFilter.create(name: 'A'),
        SavedFilter.create(name: 'B'),
      ];

      final jsonList = SavedFilter.listToJson(filters);
      final restored = SavedFilter.listFromJson(jsonList);

      expect(restored.length, 2);
      expect(restored[0].name, 'A');
      expect(restored[1].name, 'B');
    });

    test('equals based on id', () {
      final a = SavedFilter.create(name: 'Filter');
      final json = a.toJson();
      final b = SavedFilter.fromJson(json);
      expect(a == b, true);
    });
  });
}

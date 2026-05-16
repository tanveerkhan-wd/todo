import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_offline/models/todo.dart';
import 'package:todo_offline/models/todo_list.dart';
import 'package:todo_offline/models/saved_filter.dart';
import 'package:todo_offline/models/todo_group.dart';
import 'package:todo_offline/services/persistence_service.dart';

void main() {
  late Directory tempDir;
  late PersistenceService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('todos_test_');
    service = PersistenceService(overridePath: tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PersistenceService — todos', () {
    test('loadTodos returns empty list when no file exists', () async {
      final todos = await service.loadTodos();
      expect(todos, isEmpty);
    });

    test('saveTodos and loadTodos round-trips correctly', () async {
      final todos = [
        Todo.create(title: 'Task 1', notes: 'First'),
        Todo.create(title: 'Task 2', notes: 'Second', priority: Priority.high),
      ];

      await service.saveTodos(todos);
      final loaded = await service.loadTodos();

      expect(loaded.length, 2);
      expect(loaded[0].title, 'Task 1');
      expect(loaded[0].notes, 'First');
      expect(loaded[1].title, 'Task 2');
      expect(loaded[1].priority, Priority.high);
    });

    test('loadTodos recovers from backup when primary is corrupt', () async {
      final todos = [Todo.create(title: 'Backup task')];

      await service.saveTodos(todos);
      // Second save creates a backup of the first
      await service.saveTodos([Todo.create(title: 'Second')]);

      // Corrupt primary
      final primaryFile = File('${tempDir.path}/todos.json');
      await primaryFile.writeAsString('corrupt json');

      final loaded = await service.loadTodos();

      expect(loaded.length, 1);
      expect(loaded[0].title, 'Backup task');
    });

    test('saveTodos produces valid JSON file', () async {
      final todos = [Todo.create(title: 'Valid JSON check')];

      await service.saveTodos(todos);

      final file = File('${tempDir.path}/todos.json');
      expect(await file.exists(), true);

      final contents = await file.readAsString();
      final List<dynamic> decoded = jsonDecode(contents) as List<dynamic>;
      expect(decoded.length, 1);
      expect(decoded[0]['title'], 'Valid JSON check');
    });

    test('loadTodos returns empty when both primary and backup are corrupt',
        () async {
      final todos = [Todo.create(title: 'Initial')];
      await service.saveTodos(todos);

      final primaryFile = File('${tempDir.path}/todos.json');
      await primaryFile.writeAsString('corrupt');

      final backupFile = File('${tempDir.path}/todos_backup.json');
      await backupFile.writeAsString('also corrupt');

      final loaded = await service.loadTodos();
      expect(loaded, isEmpty);
    });

    test(
        'loadTodos returns empty when primary is missing and backup is corrupt',
        () async {
      final backupFile = File('${tempDir.path}/todos_backup.json');
      await backupFile.writeAsString('corrupt');

      final loaded = await service.loadTodos();
      expect(loaded, isEmpty);
    });

    test('loadTodos handles empty JSON array', () async {
      final file = File('${tempDir.path}/todos.json');
      await file.writeAsString('[]');

      final loaded = await service.loadTodos();
      expect(loaded, isEmpty);
    });

    test('loadTodos handles empty string file', () async {
      final file = File('${tempDir.path}/todos.json');
      await file.writeAsString('');

      final loaded = await service.loadTodos();
      expect(loaded, isEmpty);
    });
  });

  group('PersistenceService — lists', () {
    test('loadLists returns empty when no file', () async {
      final lists = await service.loadLists();
      expect(lists, isEmpty);
    });

    test('saveLists and loadLists round-trips', () async {
      final lists = [
        TodoList.create(name: 'Work', color: 0xFFFF6F61),
        TodoList.create(name: 'Personal'),
      ];

      await service.saveLists(lists);
      final loaded = await service.loadLists();

      expect(loaded.length, 2);
      expect(loaded[0].name, 'Work');
      expect(loaded[0].color, 0xFFFF6F61);
      expect(loaded[1].name, 'Personal');
    });
  });

  group('PersistenceService — saved filters', () {
    test('loadSavedFilters returns empty when no file', () async {
      final filters = await service.loadSavedFilters();
      expect(filters, isEmpty);
    });

    test('saveSavedFilters and loadSavedFilters round-trips', () async {
      final filters = [
        SavedFilter.create(
          name: 'Work today',
          tagFilters: ['work'],
          dateFilter: TodoFilter.today,
        ),
      ];

      await service.saveSavedFilters(filters);
      final loaded = await service.loadSavedFilters();

      expect(loaded.length, 1);
      expect(loaded[0].name, 'Work today');
      expect(loaded[0].tagFilters, ['work']);
      expect(loaded[0].dateFilter, TodoFilter.today);
    });
  });
}

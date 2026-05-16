import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_offline/models/todo.dart';
import 'package:todo_offline/services/todos_json_service.dart';

void main() {
  late Directory tempDir;
  late TodosJsonService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('todos_test_');
    service = TodosJsonService(overridePath: tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('TodosJsonService', () {
    test('load returns empty list when no file exists', () async {
      final todos = await service.load();
      expect(todos, isEmpty);
    });

    test('save and load round-trips correctly', () async {
      final todos = [
        Todo.create(title: 'Task 1', description: 'First'),
        Todo.create(title: 'Task 2', description: 'Second'),
      ];

      await service.save(todos);
      final loaded = await service.load();

      expect(loaded.length, 2);
      expect(loaded[0].title, 'Task 1');
      expect(loaded[1].title, 'Task 2');
    });

    test('load recovers from backup file when primary is corrupt', () async {
      final todos = [
        Todo.create(title: 'Backup task'),
      ];

      await service.save(todos);
      await service.save(todos);

      final primaryFile = File('${tempDir.path}/todos.json');
      await primaryFile.writeAsString('corrupt json');

      final loaded = await service.load();

      expect(loaded.length, 1);
      expect(loaded[0].title, 'Backup task');
    });

    test('save produces valid JSON file', () async {
      final todos = [
        Todo.create(title: 'Valid JSON check'),
      ];

      await service.save(todos);

      final file = File('${tempDir.path}/todos.json');
      expect(await file.exists(), true);

      final contents = await file.readAsString();
      final List<dynamic> decoded = jsonDecode(contents) as List<dynamic>;
      expect(decoded.length, 1);
      expect(decoded[0]['title'], 'Valid JSON check');
    });

    test('load returns empty list when both files are corrupt', () async {
      final primaryFile = File('${tempDir.path}/todos.json');
      await primaryFile.writeAsString('corrupt');

      final backupFile = File('${tempDir.path}/todos.json.bak');
      await backupFile.writeAsString('also corrupt');

      final loaded = await service.load();
      expect(loaded, isEmpty);
    });
  });
}

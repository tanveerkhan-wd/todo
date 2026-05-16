import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_offline/models/todo.dart';
import 'package:todo_offline/services/export_import_service.dart';
import 'package:todo_offline/services/persistence_service.dart';

void main() {
  late Directory tempDir;
  late PersistenceService persistenceService;
  late ExportImportService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('export_test_');
    persistenceService = PersistenceService(overridePath: tempDir.path);
    service = ExportImportService(
      persistenceService: persistenceService,
      overridePath: tempDir.path,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ExportImportService', () {
    test('exportToFile creates a valid JSON file', () async {
      await persistenceService.saveTodos([
        Todo.create(title: 'Test task'),
      ]);

      final path = await service.exportToFile();
      final file = File(path);
      expect(await file.exists(), true);

      final contents = await file.readAsString();
      final decoded = jsonDecode(contents) as Map<String, dynamic>;
      expect(decoded['version'], 2);
      expect(decoded['todos'], isA<List>());
    });

    test('parseImportFile parses exported file', () async {
      await persistenceService.saveTodos([
        Todo.create(title: 'Export test'),
      ]);

      final path = await service.exportToFile();
      final todos = await service.parseImportFile(path);

      expect(todos.length, 1);
      expect(todos.first.title, 'Export test');
    });

    test('parseImportFile parses legacy array format', () async {
      final content = jsonEncode([
        {
          'id': 'legacy-1',
          'title': 'Legacy',
          'notes': '',
          'isDone': false,
          'priority': 'low',
          'createdAt': DateTime.now().toIso8601String(),
        },
      ]);
      final file = File('${tempDir.path}/legacy.json');
      await file.writeAsString(content);

      final todos = await service.parseImportFile(file.path);
      expect(todos.length, 1);
      expect(todos.first.title, 'Legacy');
    });

    test('parseImportFile throws on invalid file', () async {
      final file = File('${tempDir.path}/invalid.json');
      await file.writeAsString('not json');

      expect(
        () => service.parseImportFile(file.path),
        throwsA(isA<FormatException>()),
      );
    });

    test('import merge mode adds only new todos', () async {
      await persistenceService.saveTodos([
        Todo.create(title: 'Existing'),
      ]);

      final incoming = [
        Todo.create(title: 'Existing'), // same title, different ID
        Todo.create(title: 'New'),
      ];

      await service.importTodos(
        incoming,
        mode: ImportMode.merge,
        duplicateResolution: ImportDuplicateResolution.byId,
      );

      final all = await persistenceService.loadTodos();
      expect(all.length, 3); // existing + both incoming (different IDs)
    });

    test('import replace mode replaces all todos', () async {
      await persistenceService.saveTodos([
        Todo.create(title: 'Old'),
      ]);

      final incoming = [
        Todo.create(title: 'New only'),
      ];

      await service.importTodos(
        incoming,
        mode: ImportMode.replace,
      );

      final all = await persistenceService.loadTodos();
      expect(all.length, 1);
      expect(all.first.title, 'New only');
    });

    test('duplicate resolution byTitleAndDate skips matching', () async {
      final existing = Todo.create(
        title: 'Duplicate',
        dueDate: DateTime(2025, 6, 1),
      );
      await persistenceService.saveTodos([existing]);

      final incoming = [
        Todo.create(title: 'Duplicate', dueDate: DateTime(2025, 6, 1)),
        Todo.create(title: 'Unique'),
      ];

      await service.importTodos(
        incoming,
        mode: ImportMode.merge,
        duplicateResolution: ImportDuplicateResolution.byTitleAndDate,
      );

      final all = await persistenceService.loadTodos();
      expect(all.length, 2); // existing + Unique
    });

    test('exportForSharing returns ExportData', () async {
      await persistenceService.saveTodos([
        Todo.create(title: 'Share task'),
      ]);

      final data = await service.exportForSharing();
      expect(data.path, isNotEmpty);
      expect(data.bytes, isNotEmpty);
      expect(data.name, contains('todo_export_'));
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_offline/models/todo.dart';
import 'package:todo_offline/services/backup_service.dart';
import 'package:todo_offline/services/persistence_service.dart';

void main() {
  late Directory tempDir;
  late PersistenceService persistenceService;
  late BackupService backupService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_test_');
    persistenceService = PersistenceService(overridePath: tempDir.path);
    backupService = BackupService(
      persistenceService: persistenceService,
      maxBackups: 3,
      overridePath: tempDir.path,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BackupService', () {
    test('createBackup creates a backup file', () async {
      await persistenceService.saveTodos([
        Todo.create(title: 'To back up'),
      ]);

      final path = await backupService.createBackup();
      final file = File(path);
      expect(await file.exists(), true);
    });

    test('createBackup returns a .json path', () async {
      await persistenceService.saveTodos([
        Todo.create(title: 'Test'),
      ]);

      final path = await backupService.createBackup();
      expect(path.endsWith('.json'), true);
    });

    test('listBackups returns created backup', () async {
      await persistenceService.saveTodos([
        Todo.create(title: 'Test'),
      ]);

      await backupService.createBackup();
      final backups = await backupService.listBackups();

      expect(backups.isNotEmpty, true);
      expect(backups.first.path.endsWith('.json'), true);
    });

    test('restoreBackup restores data and saves it', () async {
      await persistenceService.saveTodos([
        Todo.create(title: 'Original'),
      ]);

      // Add a new todo, then create backup of that state
      await persistenceService.saveTodos([
        Todo.create(title: 'Original'),
        Todo.create(title: 'Backup state'),
      ]);
      final path = await backupService.createBackup();

      // Change todos again
      await persistenceService.saveTodos([
        Todo.create(title: 'Overwritten'),
      ]);

      // Restore
      final restored = await backupService.restoreBackup(path);
      expect(restored.length, 2);
      expect(restored.any((t) => t.title == 'Backup state'), true);

      // Verify persistence also updated
      final loaded = await persistenceService.loadTodos();
      expect(loaded.length, 2);
    });

    test('deleteBackup removes the backup file', () async {
      await persistenceService.saveTodos([
        Todo.create(title: 'Test'),
      ]);

      final path = await backupService.createBackup();
      expect(File(path).existsSync(), true);

      await backupService.deleteBackup(path);
      expect(File(path).existsSync(), false);
    });

    test('rotation removes oldest backups beyond max', () async {
      await persistenceService.saveTodos([
        Todo.create(title: 'Rotation test'),
      ]);

      // Create 4 backups (maxBackups = 3)
      for (var i = 0; i < 4; i++) {
        await backupService.createBackup();
        await Future.delayed(const Duration(milliseconds: 10));
      }

      final backups = await backupService.listBackups();
      expect(backups.length, 3);
    });

    test('listBackups returns empty when no backups', () async {
      final backups = await backupService.listBackups();
      expect(backups, isEmpty);
    });

    test('restoreBackup throws on missing file', () async {
      expect(
        () => backupService.restoreBackup('/nonexistent/backup.json'),
        throwsA(isA<Exception>()),
      );
    });
  });
}

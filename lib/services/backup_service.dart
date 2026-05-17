import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/todo.dart';
import 'persistence_service.dart';

/// Manages automatic local backups with rotation.
///
/// Backups are stored in a `backups/` subdirectory inside the app documents
/// directory. Each backup filename includes a timestamp for sorting.
class BackupService {
  static const _backupDirName = 'backups';
  static const _backupPrefix = 'backup_';

  final PersistenceService _persistenceService;
  final int _maxBackups;
  final String? _overridePath;

  BackupService({
    required PersistenceService persistenceService,
    int maxBackups = 10,
    String? overridePath,
  })  : _persistenceService = persistenceService,
        _maxBackups = maxBackups,
        _overridePath = overridePath;

  Future<String> get _basePath async {
    if (_overridePath != null) return _overridePath!;
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<Directory> get _backupDir async {
    final base = await _basePath;
    final dir = Directory('$base/$_backupDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Creates a timestamped backup of the current todos.
  Future<String> createBackup() async {
    final todos = await _persistenceService.loadTodos();
    final dir = await _backupDir;
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/$_backupPrefix$timestamp.json');
    await file.writeAsString(
      '{"version":2,"exportedAt":"${DateTime.now().toIso8601String()}","todos":${_encodeTodos(todos)}}',
      flush: true,
    );
    await _rotate();
    return file.path;
  }

  /// Lists all available backups sorted newest-first.
  Future<List<BackupEntry>> listBackups() async {
    final dir = await _backupDir;
    final files = await dir.list().toList();
    final entries = <BackupEntry>[];

    for (final entity in files) {
      if (entity is File && entity.path.endsWith('.json')) {
        final stat = await entity.stat();
        entries.add(BackupEntry(
          path: entity.path,
          name: entity.path.split(Platform.pathSeparator).last,
          lastModified: stat.modified,
          sizeBytes: stat.size,
        ),);
      }
    }

    entries.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return entries;
  }

  /// Restores todos from a backup file at [backupPath].
  Future<List<Todo>> restoreBackup(String backupPath) async {
    final file = File(backupPath);
    if (!await file.exists()) {
      throw Exception('Backup file not found: $backupPath');
    }
    final contents = await file.readAsString();
    final decoded = _decodeBackup(contents);
    await _persistenceService.saveTodos(decoded);
    return decoded;
  }

  /// Deletes a specific backup file.
  Future<void> deleteBackup(String backupPath) async {
    final file = File(backupPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Removes oldest backups beyond the configured max.
  Future<void> _rotate() async {
    final dir = await _backupDir;
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .toList();
    files
        .sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

    while (files.length > _maxBackups) {
      await files.removeAt(0).delete();
    }
  }

  String _encodeTodos(List<Todo> todos) {
    return jsonEncode(Todo.listToJson(todos));
  }

  List<Todo> _decodeBackup(String contents) {
    final decoded = jsonDecode(contents);
    if (decoded is List) {
      return Todo.listFromJson(decoded);
    }
    if (decoded is Map && decoded['todos'] is List) {
      return Todo.listFromJson(decoded['todos'] as List<dynamic>);
    }
    return [];
  }
}

/// Metadata about a single backup file.
class BackupEntry {
  final String path;
  final String name;
  final DateTime lastModified;
  final int sizeBytes;

  const BackupEntry({
    required this.path,
    required this.name,
    required this.lastModified,
    required this.sizeBytes,
  });
}

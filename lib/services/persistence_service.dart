import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/todo.dart';
import '../models/todo_list.dart';
import '../models/saved_filter.dart';

/// Central file-based persistence with atomic writes and automatic backup.
///
/// File layout (app documents directory):
///   - `todos.json`         – primary todo data (JSON array)
///   - `lists.json`         – project/list definitions
///   - `saved_filters.json` – filter presets
class PersistenceService {
  static const String _todosFile = 'todos.json';
  static const String _todosBackupFile = 'todos_backup.json';
  static const String _listsFile = 'lists.json';
  static const String _filtersFile = 'saved_filters.json';
  static const String _tempSuffix = '.tmp';

  final String? _overridePath;

  PersistenceService({String? overridePath}) : _overridePath = overridePath;

  Future<String> get _basePath async {
    if (_overridePath != null) return _overridePath!;
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<File> _file(String name) async {
    final path = await _basePath;
    return File('$path/$name');
  }

  // -----------------------------------------------------------------------
  // Todos
  // -----------------------------------------------------------------------

  Future<List<Todo>> loadTodos() async {
    try {
      final file = await _file(_todosFile);
      if (!await file.exists()) return [];
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return [];
      final decoded = jsonDecode(contents);
      // Support both legacy array format and new object format
      if (decoded is List) {
        return Todo.listFromJson(decoded);
      }
      if (decoded is Map && decoded['todos'] is List) {
        return Todo.listFromJson(decoded['todos'] as List<dynamic>);
      }
      return [];
    } catch (_) {
      return _recoverFromBackup();
    }
  }

  /// Attempts to load from the recovery backup.
  Future<List<Todo>> _recoverFromBackup() async {
    try {
      final file = await _file(_todosBackupFile);
      if (!await file.exists()) return [];
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return [];
      final decoded = jsonDecode(contents);
      if (decoded is List) {
        return Todo.listFromJson(decoded);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTodos(List<Todo> todos) async {
    final file = await _file(_todosFile);

    // Create a recovery backup before overwriting.
    if (await file.exists()) {
      final bkFile = await _file(_todosBackupFile);
      await file.copy(bkFile.path);
    }

    const encoder = JsonEncoder.withIndent('  ');
    final content = encoder.convert(Todo.listToJson(todos));
    await _atomicWrite(file, content);
  }

  // -----------------------------------------------------------------------
  // Lists
  // -----------------------------------------------------------------------

  Future<List<TodoList>> loadLists() async {
    try {
      final file = await _file(_listsFile);
      if (!await file.exists()) return [];
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return [];
      final decoded = jsonDecode(contents) as List<dynamic>;
      return TodoList.listFromJson(decoded);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLists(List<TodoList> lists) async {
    final file = await _file(_listsFile);
    const encoder = JsonEncoder.withIndent('  ');
    final content = encoder.convert(TodoList.listToJson(lists));
    await _atomicWrite(file, content);
  }

  // -----------------------------------------------------------------------
  // Saved filters
  // -----------------------------------------------------------------------

  Future<List<SavedFilter>> loadSavedFilters() async {
    try {
      final file = await _file(_filtersFile);
      if (!await file.exists()) return [];
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return [];
      final decoded = jsonDecode(contents) as List<dynamic>;
      return SavedFilter.listFromJson(decoded);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSavedFilters(List<SavedFilter> filters) async {
    final file = await _file(_filtersFile);
    const encoder = JsonEncoder.withIndent('  ');
    final content = encoder.convert(SavedFilter.listToJson(filters));
    await _atomicWrite(file, content);
  }

  // -----------------------------------------------------------------------
  // Atomic write helper
  // -----------------------------------------------------------------------

  Future<void> _atomicWrite(File target, String content) async {
    final dir = target.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final tempFile = File('${target.path}$_tempSuffix');
    await tempFile.writeAsString(content, flush: true);
    await tempFile.rename(target.path);
  }
}

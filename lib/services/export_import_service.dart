import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/todo.dart';
import 'persistence_service.dart';

/// Handles exporting todos to a shareable file and importing from external
/// sources with merge/replace options.
class ExportImportService {
  final PersistenceService _persistenceService;
  final String? _overridePath;

  ExportImportService({
    required PersistenceService persistenceService,
    String? overridePath,
  })  : _persistenceService = persistenceService,
        _overridePath = overridePath;

  Future<String> get _basePath async {
    if (_overridePath != null) return _overridePath!;
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// Exports todos to a JSON file and returns the file path.
  ///
  /// The exported file uses a portable wrapped format:
  /// ```json
  /// { "version": 2, "exportedAt": "...", "todos": [...] }
  /// ```
  Future<String> exportToFile() async {
    final todos = await _persistenceService.loadTodos();
    final base = await _basePath;
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final path = '$base/todo_export_$timestamp.json';

    final data = {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'todos': Todo.listToJson(todos),
    };

    const encoder = JsonEncoder.withIndent('  ');
    await File(path).writeAsString(encoder.convert(data), flush: true);
    return path;
  }

  /// Returns the raw file content for sharing via platform APIs.
  Future<ExportData> exportForSharing() async {
    final path = await exportToFile();
    final file = File(path);
    return ExportData(
      path: path,
      bytes: await file.readAsBytes(),
      name: file.path.split(Platform.pathSeparator).last,
    );
  }

  /// Parses an exported JSON file and returns the contained todos.
  ///
  /// Throws [FormatException] if the file is not valid.
  Future<List<Todo>> parseImportFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FormatException('File not found: $filePath');
    }
    final contents = await file.readAsString();
    final decoded = jsonDecode(contents);

    if (decoded is List) {
      return Todo.listFromJson(decoded);
    }
    if (decoded is Map && decoded['todos'] is List) {
      return Todo.listFromJson(decoded['todos'] as List<dynamic>);
    }
    throw const FormatException('Unrecognised file format');
  }

  /// Merges [incoming] todos into the existing store.
  ///
  /// [mode] controls how duplicates are resolved:
  ///   - `replace`: clears existing todos first
  ///   - `merge`: adds only todos whose [id] is not already present
  Future<void> importTodos(
    List<Todo> incoming, {
    required ImportMode mode,
    ImportDuplicateResolution duplicateResolution =
        ImportDuplicateResolution.byId,
  }) async {
    final existing = await _persistenceService.loadTodos();

    switch (mode) {
      case ImportMode.replace:
        await _persistenceService.saveTodos(
          _resolveDuplicates([], incoming, duplicateResolution),
        );

      case ImportMode.merge:
        await _persistenceService.saveTodos(
          _resolveDuplicates(existing, incoming, duplicateResolution),
        );
    }
  }

  List<Todo> _resolveDuplicates(
    List<Todo> existing,
    List<Todo> incoming,
    ImportDuplicateResolution resolution,
  ) {
    final merged = List<Todo>.from(existing);

    for (final candidate in incoming) {
      final isDuplicate = switch (resolution) {
        ImportDuplicateResolution.byId =>
          existing.any((e) => e.id == candidate.id),
        ImportDuplicateResolution.byTitleAndDate => existing.any((e) =>
            e.title == candidate.title &&
            _sameDay(e.dueDate, candidate.dueDate),),
      };

      if (!isDuplicate) {
        // Generate a fresh ID to avoid collisions on re-import
        merged.add(candidate.copyWith(id: candidate.id));
      }
    }

    return merged;
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Raw bytes of an export file ready for platform sharing.
class ExportData {
  final String path;
  final List<int> bytes;
  final String name;

  const ExportData({
    required this.path,
    required this.bytes,
    required this.name,
  });
}

/// How imported data should be combined with existing data.
enum ImportMode { replace, merge }

/// How duplicates are identified during import.
enum ImportDuplicateResolution { byId, byTitleAndDate }

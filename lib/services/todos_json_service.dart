import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/todo.dart';

class TodosJsonService {
  static const String _fileName = 'todos.json';
  static const String _backupFileName = 'todos.json.bak';
  static const String _tempFileName = 'todos.json.tmp';

  final String? _overridePath;

  TodosJsonService({String? overridePath}) : _overridePath = overridePath;

  Future<String> get _basePath async {
    if (_overridePath != null) return _overridePath!;
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<File> _file(String name) async {
    final path = await _basePath;
    return File('$path/$name');
  }

  Future<List<Todo>> load() async {
    try {
      final file = await _file(_fileName);
      if (!await file.exists()) return [];
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(contents) as List<dynamic>;
      return decoded
          .map((e) => Todo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      try {
        final backupFile = await _file(_backupFileName);
        if (await backupFile.exists()) {
          final contents = await backupFile.readAsString();
          if (contents.trim().isEmpty) return [];
          final List<dynamic> decoded =
              jsonDecode(contents) as List<dynamic>;
          return decoded
              .map((e) => Todo.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
      return [];
    }
  }

  Future<void> save(List<Todo> todos) async {
    final file = await _file(_fileName);

    if (await file.exists()) {
      final bkFile = await _file(_backupFileName);
      await file.copy(bkFile.path);
    }

    const encoder = JsonEncoder.withIndent('  ');
    final content = encoder.convert(todos.map((t) => t.toJson()).toList());

    final tempFile = await _file(_tempFileName);
    await tempFile.writeAsString(content, flush: true);
    await tempFile.rename(file.path);
  }
}

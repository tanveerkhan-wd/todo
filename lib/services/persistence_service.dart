import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/todo.dart';
import '../models/todo_list.dart';
import '../models/saved_filter.dart';

/// Simplified local storage using SharedPreferences.
/// This avoids file system locking and permission issues across platforms.
///
/// // TODO: Consider adding encryption for sensitive task data in future phases.
class PersistenceService {
  static const String _kTodos = 'todos_data';
  static const String _kLists = 'lists_data';
  static const String _kFilters = 'filters_data';

  // -----------------------------------------------------------------------
  // Todos
  // -----------------------------------------------------------------------

  Future<List<Todo>> loadTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_kTodos);
      if (data == null || data.isEmpty) return [];
      
      final decoded = jsonDecode(data);
      if (decoded is List) {
        return Todo.listFromJson(decoded);
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('Error loading todos: $e');
      return [];
    }
  }

  Future<void> saveTodos(List<Todo> todos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(Todo.listToJson(todos));
      await prefs.setString(_kTodos, data);
    } catch (e) {
      // ignore: avoid_print
      print('Error saving todos: $e');
    }
  }

  // -----------------------------------------------------------------------
  // Lists
  // -----------------------------------------------------------------------

  Future<List<TodoList>> loadLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_kLists);
      if (data == null || data.isEmpty) return [];
      
      final decoded = jsonDecode(data) as List<dynamic>;
      return TodoList.listFromJson(decoded);
    } catch (e) {
      // ignore: avoid_print
      print('Error loading lists: $e');
      return [];
    }
  }

  Future<void> saveLists(List<TodoList> lists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(TodoList.listToJson(lists));
      await prefs.setString(_kLists, data);
    } catch (e) {
      // ignore: avoid_print
      print('Error saving lists: $e');
    }
  }

  // -----------------------------------------------------------------------
  // Saved filters
  // -----------------------------------------------------------------------

  Future<List<SavedFilter>> loadSavedFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_kFilters);
      if (data == null || data.isEmpty) return [];
      
      final decoded = jsonDecode(data) as List<dynamic>;
      return SavedFilter.listFromJson(decoded);
    } catch (e) {
      // ignore: avoid_print
      print('Error loading filters: $e');
      return [];
    }
  }

  Future<void> saveSavedFilters(List<SavedFilter> filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(SavedFilter.listToJson(filters));
      await prefs.setString(_kFilters, data);
    } catch (e) {
      // ignore: avoid_print
      print('Error saving filters: $e');
    }
  }
}

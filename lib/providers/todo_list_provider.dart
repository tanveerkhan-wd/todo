import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/todo.dart';
import '../services/persistence_service.dart';
import '../utils/recurrence.dart';

// ---------------------------------------------------------------------------
// PersistenceService provider
// ---------------------------------------------------------------------------

final persistenceServiceProvider = Provider<PersistenceService>((ref) {
  return PersistenceService();
});

// ---------------------------------------------------------------------------
// TodoListNotifier – business-logic hub for todo CRUD
// ---------------------------------------------------------------------------

/// [StateNotifier] that holds the full list of [Todo]s and persists every
/// mutation through [PersistenceService].
class TodoListNotifier extends StateNotifier<List<Todo>> {
  final PersistenceService _persistenceService;

  TodoListNotifier(this._persistenceService) : super([]) {
    // Initial load when the provider is first used.
    load();
  }

  /// Loads todos from local storage.
  Future<void> load() async {
    final todos = await _persistenceService.loadTodos();
    state = todos;
  }

  /// Adds [todo] to the list and persists.
  Future<void> add(Todo todo) async {
    // Immediate state update for UI responsiveness
    state = [...state, todo];
    // Background persistence
    await _persistenceService.saveTodos(state);
  }

  /// Replaces the todo matching [updated.id] and persists.
  Future<void> update(Todo updated) async {
    state = [
      for (final todo in state)
        if (todo.id == updated.id) updated else todo,
    ];
    await _persistenceService.saveTodos(state);
  }

  /// Removes the todo with [id] and persists.
  Future<void> remove(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _persistenceService.saveTodos(state);
  }

  /// Toggles [isDone] for the todo with [id] and persists.
  Future<void> toggleComplete(String id) async {
    Todo? pendingRecurrence;
    final updated = state.map((todo) {
      if (todo.id != id) return todo;
      final newDone = !todo.isDone;
      if (newDone && todo.recurrenceRule != null) {
        pendingRecurrence = createNextRecurrence(todo.copyWith(isDone: true));
      }
      return todo.copyWith(isDone: newDone);
    }).toList();

    final next = pendingRecurrence;
    state = next != null ? [...updated, next] : updated;
    await _persistenceService.saveTodos(state);
  }
}

// ---------------------------------------------------------------------------
// Provider – consumed by the UI
// ---------------------------------------------------------------------------

final todoListProvider =
    StateNotifierProvider<TodoListNotifier, List<Todo>>((ref) {
  final persistenceService = ref.watch(persistenceServiceProvider);
  return TodoListNotifier(persistenceService);
});

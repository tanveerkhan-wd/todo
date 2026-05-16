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
///
/// The UI should never call [PersistenceService] directly; all mutations go
/// through this notifier.
class TodoListNotifier extends StateNotifier<List<Todo>> {
  final PersistenceService _persistenceService;

  TodoListNotifier(this._persistenceService) : super([]) {
    load();
  }

  /// Loads todos from disk (called once at startup and on explicit [load]).
  Future<void> load() async {
    state = await _persistenceService.loadTodos();
  }

  /// Adds [todo] to the list and persists.
  Future<void> add(Todo todo) async {
    state = [...state, todo];
    await _persist();
  }

  /// Replaces the todo matching [updated.id] and persists.
  Future<void> update(Todo updated) async {
    state = [
      for (final todo in state)
        if (todo.id == updated.id) updated else todo,
    ];
    await _persist();
  }

  /// Removes the todo with [id] and persists.
  Future<void> remove(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _persist();
  }

  /// Toggles [isDone] for the todo with [id] and persists.
  ///
  /// If the todo has a [RecurrenceRule] and is being marked done, the next
  /// occurrence is automatically created.
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
    await _persist();
  }

  Future<void> _persist() async {
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

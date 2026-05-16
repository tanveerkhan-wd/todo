import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/todo_list.dart';
import '../services/persistence_service.dart';
import 'todo_list_provider.dart';

// ---------------------------------------------------------------------------
// ListCollectionNotifier
// ---------------------------------------------------------------------------

/// Manages the collection of named project lists.
///
/// Persists to a separate `lists.json` file via [PersistenceService].
class ListCollectionNotifier extends StateNotifier<List<TodoList>> {
  final PersistenceService _persistenceService;

  ListCollectionNotifier(this._persistenceService) : super([]) {
    load();
  }

  Future<void> load() async {
    state = await _persistenceService.loadLists();
  }

  /// Creates a new list and persists.
  Future<TodoList> create(String name, {int color = 0xFF0D47A1}) async {
    final list = TodoList.create(name: name, color: color);
    state = [...state, list];
    await _persist();
    return list;
  }

  /// Renames an existing list.
  Future<void> rename(String id, String newName) async {
    state = [
      for (final list in state)
        if (list.id == id) list.copyWith(name: newName) else list,
    ];
    await _persist();
  }

  /// Updates the color of a list.
  Future<void> recolor(String id, int color) async {
    state = [
      for (final list in state)
        if (list.id == id) list.copyWith(color: color) else list,
    ];
    await _persist();
  }

  /// Removes a list by [id].
  Future<void> remove(String id) async {
    state = state.where((l) => l.id != id).toList();
    await _persist();
  }

  Future<void> _persist() async {
    await _persistenceService.saveLists(state);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final listCollectionProvider =
    StateNotifierProvider<ListCollectionNotifier, List<TodoList>>((ref) {
  final persistenceService = ref.watch(persistenceServiceProvider);
  return ListCollectionNotifier(persistenceService);
});

/// Returns the [TodoList] with the given [id], or null.
final todoListByIdProvider = Provider.family<TodoList?, String>((ref, id) {
  final lists = ref.watch(listCollectionProvider);
  try {
    return lists.firstWhere((l) => l.id == id);
  } catch (_) {
    return null;
  }
});

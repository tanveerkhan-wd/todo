import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/saved_filter.dart';
import '../services/persistence_service.dart';
import 'todo_list_provider.dart';

// ---------------------------------------------------------------------------
// SavedFilterNotifier
// ---------------------------------------------------------------------------

/// Manages filter presets that users can save and restore.
class SavedFilterNotifier extends StateNotifier<List<SavedFilter>> {
  final PersistenceService _persistenceService;

  SavedFilterNotifier(this._persistenceService) : super([]) {
    load();
  }

  Future<void> load() async {
    state = await _persistenceService.loadSavedFilters();
  }

  /// Saves a new filter preset.
  Future<void> save(SavedFilter filter) async {
    state = [...state, filter];
    await _persist();
  }

  /// Removes a filter preset by [id].
  Future<void> delete(String id) async {
    state = state.where((f) => f.id != id).toList();
    await _persist();
  }

  Future<void> _persist() async {
    await _persistenceService.saveSavedFilters(state);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final savedFilterProvider =
    StateNotifierProvider<SavedFilterNotifier, List<SavedFilter>>((ref) {
  final persistenceService = ref.watch(persistenceServiceProvider);
  return SavedFilterNotifier(persistenceService);
});

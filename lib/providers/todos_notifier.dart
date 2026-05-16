import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/todo.dart';
import '../services/todos_json_service.dart';

class TodosNotifier extends StateNotifier<AsyncValue<List<Todo>>> {
  final TodosJsonService _service;

  TodosNotifier(this._service) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final todos = await _service.load();
      state = AsyncValue.data(todos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTodo({required String title, String description = ''}) async {
    final todo = Todo.create(title: title, description: description);
    state.whenData((todos) async {
      final updated = [...todos, todo];
      await _service.save(updated);
      state = AsyncValue.data(updated);
    });
  }

  Future<void> toggleTodo(String id) async {
    state.whenData((todos) async {
      final updated = todos.map((t) {
        if (t.id == id) return t.copyWith(isCompleted: !t.isCompleted);
        return t;
      }).toList();
      await _service.save(updated);
      state = AsyncValue.data(updated);
    });
  }

  Future<void> deleteTodo(String id) async {
    state.whenData((todos) async {
      final updated = todos.where((t) => t.id != id).toList();
      await _service.save(updated);
      state = AsyncValue.data(updated);
    });
  }

  Future<void> editTodo(Todo updatedTodo) async {
    state.whenData((todos) async {
      final updated = todos.map((t) {
        if (t.id == updatedTodo.id) return updatedTodo;
        return t;
      }).toList();
      await _service.save(updated);
      state = AsyncValue.data(updated);
    });
  }

  Future<void> refresh() async {
    await _load();
  }
}

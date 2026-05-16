import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/todo.dart';
import '../services/todos_json_service.dart';
import 'todos_notifier.dart';

final todosJsonServiceProvider = Provider<TodosJsonService>((ref) {
  return TodosJsonService();
});

final todosProvider =
    StateNotifierProvider<TodosNotifier, AsyncValue<List<Todo>>>((ref) {
  final service = ref.watch(todosJsonServiceProvider);
  return TodosNotifier(service);
});

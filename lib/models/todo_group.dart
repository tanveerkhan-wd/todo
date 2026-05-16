import 'todo.dart';

// ---------------------------------------------------------------------------
// Filter & grouping types
// ---------------------------------------------------------------------------

/// Active filter segment on the home screen.
enum TodoFilter { today, upcoming, completed }

/// Internal group identifier for sticky-header sections.
enum TodoGroupType { today, tomorrow, upcoming, noDate, completed }

/// A named bucket of [Todo]s displayed under one sticky header.
class TodoGroup {
  const TodoGroup(this.type, this.label, this.todos);

  final TodoGroupType type;
  final String label;
  final List<Todo> todos;
}

/// Strips the time component from a [DateTime] for date-only comparisons.
DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Groups [todos] into sections ordered by date.
///
/// When [filter] is provided only matching sections are returned.
List<TodoGroup> groupTodos(List<Todo> todos, {TodoFilter? filter}) {
  final now = DateTime.now();
  final today = _dateOnly(now);
  final tomorrow = today.add(const Duration(days: 1));

  final todayList = <Todo>[];
  final tomorrowList = <Todo>[];
  final upcomingList = <Todo>[];
  final noDateList = <Todo>[];
  final completedList = <Todo>[];

  for (final todo in todos) {
    if (todo.isDone) {
      completedList.add(todo);
      continue;
    }

    if (todo.dueDate == null) {
      noDateList.add(todo);
      continue;
    }

    final due = _dateOnly(todo.dueDate!);
    if (due == today || due.isBefore(today)) {
      todayList.add(todo);
    } else if (due == tomorrow) {
      tomorrowList.add(todo);
    } else {
      upcomingList.add(todo);
    }
  }

  final groups = <TodoGroup>[];

  void addIfNonEmpty(TodoGroupType type, String label, List<Todo> items) {
    if (items.isNotEmpty) groups.add(TodoGroup(type, label, items));
  }

  switch (filter) {
    case TodoFilter.today:
      addIfNonEmpty(TodoGroupType.today, 'Today', todayList);
    case TodoFilter.upcoming:
      addIfNonEmpty(TodoGroupType.tomorrow, 'Tomorrow', tomorrowList);
      addIfNonEmpty(TodoGroupType.upcoming, 'Upcoming', upcomingList);
    case TodoFilter.completed:
      addIfNonEmpty(TodoGroupType.completed, 'Completed', completedList);
    case null:
      addIfNonEmpty(TodoGroupType.today, 'Today', todayList);
      addIfNonEmpty(TodoGroupType.tomorrow, 'Tomorrow', tomorrowList);
      addIfNonEmpty(TodoGroupType.upcoming, 'Upcoming', upcomingList);
      addIfNonEmpty(TodoGroupType.noDate, 'No Date', noDateList);
      addIfNonEmpty(TodoGroupType.completed, 'Completed', completedList);
  }

  return groups;
}

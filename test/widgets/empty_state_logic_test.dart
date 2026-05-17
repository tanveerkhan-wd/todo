import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_offline/app.dart';
import 'package:todo_offline/providers/todo_list_provider.dart';
import 'package:todo_offline/models/todo.dart';

void main() {
  testWidgets('HomePage shows NoResults when search returns nothing but tasks exist', (tester) async {
    // Create a ProviderContainer with one task
    final container = ProviderContainer(
      overrides: [
        todoListProvider.overrideWith((ref) => TodoListNotifier(ref.watch(persistenceServiceProvider))..state = [
          Todo.create(title: 'Existing Task')
        ]),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TodoApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify task is there
    expect(find.text('Existing Task'), findsOneWidget);

    // Enter search text that doesn't match
    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'Non-existent');
    await tester.pump();

    // Should show "No results found" instead of "No todos yet"
    expect(find.text('No results found'), findsOneWidget);
    expect(find.text('No todos yet'), findsNothing);
  });

  testWidgets('HomePage shows EmptyState when list is truly empty', (tester) async {
    final container = ProviderContainer(
      overrides: [
        todoListProvider.overrideWith((ref) => TodoListNotifier(ref.watch(persistenceServiceProvider))..state = []),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TodoApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No todos yet'), findsOneWidget);
    expect(find.text('No results found'), findsNothing);
  });
}

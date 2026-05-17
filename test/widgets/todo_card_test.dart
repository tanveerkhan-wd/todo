import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_offline/models/todo.dart';
import 'package:todo_offline/widgets/todo_card.dart';
import 'package:todo_offline/theme/app_theme.dart';

void main() {
  testWidgets('TodoCard renders task title with correct color', (tester) async {
    final todo = Todo.create(title: 'Test Task');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: TodoCard(
            todo: todo,
            onToggle: () {},
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    final titleText = find.text('Test Task');
    expect(titleText, findsOneWidget);

    final textWidget = tester.widget<Text>(titleText);
    expect(textWidget.style?.color, AppTheme.primary);
  });

  testWidgets('TodoCard shows notes and due date if provided', (tester) async {
    final dueDate = DateTime.now().add(const Duration(days: 1));
    final todo = Todo.create(
      title: 'Test Task',
      notes: 'Some notes here',
      dueDate: dueDate,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: TodoCard(
            todo: todo,
            onToggle: () {},
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    expect(find.text('Some notes here'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget); // Assuming DueDateChip logic
  });
}

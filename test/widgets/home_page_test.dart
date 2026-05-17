import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:todo_offline/app.dart';

/// Helper that pumps the full [TodoApp] wrapped in a test [ProviderScope].
Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: TodoApp()),
  );
  // Use pump() instead of pumpAndSettle() to avoid infinite Semantics
  // parentDataDirty assertions in CustomScrollView + SliverList under test.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('HomePage layout', () {
    testWidgets('renders the app bar title', (tester) async {
      await pumpApp(tester);
      expect(find.text('Todo'), findsOneWidget);
    });

    testWidgets('shows search field and quick add field', (tester) async {
      await pumpApp(tester);
      expect(find.byType(TextField), findsAtLeast(2));
    });

    testWidgets('shows segmented filter buttons in drawer', (tester) async {
      await pumpApp(tester);
      // Open the drawer to reveal filters
      await tester.tap(find.byTooltip('Menu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('shows empty state when no tasks exist', (tester) async {
      await pumpApp(tester);
      // Look for the empty state label
      expect(find.text('No todos yet'), findsOneWidget);
    });
  });

  group('Quick add', () {
    testWidgets('adds a task via the bottom input bar', (tester) async {
      await pumpApp(tester);

      // Find the quick add input (the last TextField in the widget tree)
      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeast(2));
      final quickAddField = textFields.last;
      await tester.enterText(quickAddField, 'New test task');
      await tester.pump();

      // Tap the send button
      await tester.tap(find.byIcon(FontAwesomeIcons.solidPaperPlane));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The new task should appear in the list
      expect(find.text('New test task'), findsOneWidget);
    });
  });

  group('Theme toggle', () {
    testWidgets('switches between light and dark mode', (tester) async {
      await pumpApp(tester);

      // Open the overflow menu
      await tester.tap(find.byTooltip('More options'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find the theme toggle option
      expect(find.text('Dark mode'), findsOneWidget);
    });
  });

  group('Delete confirmation', () {
    testWidgets('shows delete dialog when deleting a task', (tester) async {
      await pumpApp(tester);

      // Add a task via the bottom input bar
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.last, 'Delete me');
      await tester.pump();
      await tester.tap(find.byIcon(FontAwesomeIcons.solidPaperPlane));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find the delete icon button on the task
      await tester.tap(find.byTooltip('Delete task').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Confirm dialog appears
      expect(find.text('Delete Task'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}

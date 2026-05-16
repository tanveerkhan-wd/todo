import 'package:flutter/material.dart';

import '../models/todo.dart';
import 'date_chip.dart';
import 'priority_dot.dart';

/// A single todo list item displaying a checkbox, title, optional notes,
/// a [DueDateChip], a [PriorityDot], a subtask badge, a reminder indicator,
/// and a trailing overflow menu.
///
/// Wraps the card in a [Hero] for smooth tile-to-editor transitions.
class TodoTile extends StatelessWidget {
  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.onSnooze,
    this.showSubtaskBadge = false,
  });

  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(int minutes)? onSnooze;
  final bool showSubtaskBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final doneSubtaskCount = todo.subtasks.where((s) => s.isDone).length;

    return Semantics(
      label: 'Task: ${todo.title}${todo.isDone ? ", completed" : ""}',
      child: Hero(
        tag: 'todo-${todo.id}',
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label:
                        todo.isDone ? 'Mark as incomplete' : 'Mark as complete',
                    child: Checkbox(
                      value: todo.isDone,
                      activeColor: colorScheme.secondary,
                      onChanged: (_) => onToggle(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                todo.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  decoration: todo.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: todo.isDone
                                      ? colorScheme.onSurface
                                          .withValues(alpha: 0.4)
                                      : colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (todo.priority != Priority.low)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: PriorityDot(priority: todo.priority),
                              ),
                            const SizedBox(width: 4),
                            if (todo.dueDate != null)
                              DueDateChip(dueDate: todo.dueDate!),
                            if (todo.reminders.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Semantics(
                                label: 'Has reminders',
                                child: const Icon(
                                  Icons.notifications_active,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                            if (showSubtaskBadge &&
                                todo.subtasks.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              _SubtaskBadge(
                                done: doneSubtaskCount,
                                total: todo.subtasks.length,
                              ),
                            ],
                            _OverflowMenu(
                              onEdit: onEdit,
                              onDelete: onDelete,
                              onSnooze: onSnooze,
                              hasReminders: todo.reminders.isNotEmpty,
                            ),
                          ],
                        ),
                        if (todo.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            todo.notes,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubtaskBadge extends StatelessWidget {
  const _SubtaskBadge({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$done of $total subtasks done',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$done/$total',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({
    required this.onEdit,
    required this.onDelete,
    this.onSnooze,
    this.hasReminders = false,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(int minutes)? onSnooze;
  final bool hasReminders;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Task options',
      child: PopupMenuButton<String>(
        iconSize: 18,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: 'More actions',
        onSelected: (value) {
          switch (value) {
            case 'edit':
              onEdit();
            case 'delete':
              onDelete();
            case 'snooze_15':
              onSnooze?.call(15);
            case 'snooze_30':
              onSnooze?.call(30);
            case 'snooze_60':
              onSnooze?.call(60);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit, size: 18),
              title: Text('Edit'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (hasReminders) ...[
            const PopupMenuItem(
              enabled: false,
              child: Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text('Snooze',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey)),
              ),
            ),
            const PopupMenuItem(
              value: 'snooze_15',
              child: ListTile(
                leading: Icon(Icons.timer_outlined, size: 18),
                title: Text('15 minutes'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'snooze_30',
              child: ListTile(
                leading: Icon(Icons.timer_outlined, size: 18),
                title: Text('30 minutes'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'snooze_60',
              child: ListTile(
                leading: Icon(Icons.timer_outlined, size: 18),
                title: Text('1 hour'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_outline, size: 18),
              title: Text('Delete'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

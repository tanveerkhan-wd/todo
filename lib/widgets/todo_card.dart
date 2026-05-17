import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/todo.dart';
import '../theme/app_theme.dart';
import 'date_chip.dart';
import 'priority_dot.dart';

/// A unified card widget for displaying a single [Todo].
///
/// Features:
/// - Priority indication via [PriorityDot]
/// - Human-readable due date via [DueDateChip]
/// - Subtask progress indicator
/// - Inline actions for edit, delete, and reminders
///
/// // TODO: Implement drag-and-drop reordering in future phases.
class TodoCard extends StatelessWidget {
  const TodoCard({
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Checkbox
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: todo.isDone,
                      activeColor: AppTheme.primary,
                      onChanged: (_) => onToggle(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and Metadata
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
                                  fontWeight: FontWeight.w700,
                                  color: todo.isDone
                                      ? colorScheme.onSurface.withValues(alpha: 0.4)
                                      : AppTheme.primary, // Using palette color
                                  decoration: todo.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            if (todo.priority != Priority.low) ...[
                              const SizedBox(width: 8),
                              PriorityDot(priority: todo.priority),
                            ],
                          ],
                        ),
                        if (todo.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            todo.notes,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
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
              const SizedBox(height: 12),
              // Footer: Date, Subtasks, and Quick Actions
              Row(
                children: [
                  if (todo.dueDate != null) ...[
                    DueDateChip(dueDate: todo.dueDate!),
                    const SizedBox(width: 8),
                  ],
                  if (showSubtaskBadge && todo.subtasks.isNotEmpty) ...[
                    _SubtaskBadge(
                      done: doneSubtaskCount,
                      total: todo.subtasks.length,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (todo.reminders.isNotEmpty)
                    const Icon(
                      Icons.notifications_active,
                      size: 14,
                      color: Colors.orange,
                    ),
                  const Spacer(),
                  // Quick Actions
                  _QuickActionButton(
                    icon: FontAwesomeIcons.pen,
                    onPressed: onEdit,
                    tooltip: 'Edit task',
                  ),
                  _QuickActionButton(
                    icon: FontAwesomeIcons.bell,
                    onPressed: onSnooze != null ? () => onSnooze?.call(15) : null,
                    tooltip: 'Snooze 15m',
                  ),
                  _QuickActionButton(
                    icon: FontAwesomeIcons.trashCan,
                    onPressed: onDelete,
                    tooltip: 'Delete task',
                    isDestructive: true,
                  ),
                ],
              ),
            ],
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
    return Container(
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
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.isDestructive = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      icon: FaIcon(icon, size: 14),
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
      color: isDestructive
          ? theme.colorScheme.error.withValues(alpha: 0.7)
          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
    );
  }
}

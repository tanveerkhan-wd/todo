import 'package:flutter/material.dart';

/// A compact chip that displays a due date in a human-friendly format.
///
/// Shows "Today", "Tomorrow", or a short date string.
/// Uses accent color when overdue (before today).
class DueDateChip extends StatelessWidget {
  const DueDateChip({super.key, required this.dueDate});

  final DateTime dueDate;

  String _formatDate(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (due == today) return 'Today';
    if (due == today.add(const Duration(days: 1))) return 'Tomorrow';

    // Show abbreviated date
    return '${due.month}/${due.day}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final isOverdue = due.isBefore(today);

    final theme = Theme.of(context);
    final color =
        isOverdue ? theme.colorScheme.secondary : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _formatDate(context),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

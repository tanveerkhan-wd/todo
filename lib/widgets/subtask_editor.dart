import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/todo.dart';

/// Inline editor for adding, toggling, reordering, and deleting subtasks.
///
/// Uses a [ReorderableListView] for drag-to-reorder support.
class SubtaskEditor extends StatelessWidget {
  const SubtaskEditor({
    super.key,
    required this.subtasks,
    required this.onChanged,
  });

  final List<SubTask> subtasks;
  final ValueChanged<List<SubTask>> onChanged;

  void _add(String title) {
    final newTask = SubTask(id: const Uuid().v4(), title: title);
    onChanged([...subtasks, newTask]);
  }

  void _toggle(String id) {
    onChanged([
      for (final s in subtasks)
        if (s.id == id) s.copyWith(isDone: !s.isDone) else s,
    ]);
  }

  void _remove(String id) {
    onChanged(subtasks.where((s) => s.id != id).toList());
  }

  void _reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final list = List<SubTask>.from(subtasks);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    onChanged(list);
  }

  void _edit(String id, String newTitle) {
    onChanged([
      for (final s in subtasks)
        if (s.id == id) s.copyWith(title: newTitle) else s,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Subtasks', style: theme.textTheme.titleSmall),
            const SizedBox(width: 8),
            Text(
              '${subtasks.where((s) => s.isDone).length}/${subtasks.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (subtasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No subtasks yet',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subtasks.length,
            onReorder: _reorder,
            proxyDecorator: (child, _, __) => Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: child,
            ),
            itemBuilder: (ctx, i) {
              final sub = subtasks[i];
              return _SubtaskItem(
                key: ValueKey(sub.id),
                subtask: sub,
                onToggle: () => _toggle(sub.id),
                onDelete: () => _remove(sub.id),
                onEdit: (title) => _edit(sub.id, title),
              );
            },
          ),
        const SizedBox(height: 8),
        _AddSubtaskField(onAdd: _add),
      ],
    );
  }
}

class _SubtaskItem extends StatefulWidget {
  const _SubtaskItem({
    super.key,
    required this.subtask,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  final SubTask subtask;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final ValueChanged<String> onEdit;

  @override
  State<_SubtaskItem> createState() => _SubtaskItemState();
}

class _SubtaskItemState extends State<_SubtaskItem> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.subtask.title);
  }

  @override
  void didUpdateWidget(_SubtaskItem old) {
    super.didUpdateWidget(old);
    if (old.subtask.id != widget.subtask.id) {
      _controller.text = widget.subtask.title;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Drag handle
          const ReorderableDragStartListener(
            index: 0,
            child: Icon(Icons.drag_handle, size: 20, color: Colors.grey),
          ),
          const SizedBox(width: 4),
          // Checkbox
          Checkbox(
            value: widget.subtask.isDone,
            onChanged: (_) => widget.onToggle(),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          // Title (editable on tap)
          Expanded(
            child: _isEditing
                ? TextField(
                    controller: _controller,
                    autofocus: true,
                    onSubmitted: (value) {
                      final trimmed = value.trim();
                      if (trimmed.isNotEmpty) widget.onEdit(trimmed);
                      setState(() => _isEditing = false);
                    },
                    onTapOutside: (_) {
                      final trimmed = _controller.text.trim();
                      if (trimmed.isNotEmpty) widget.onEdit(trimmed);
                      setState(() => _isEditing = false);
                    },
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(),
                    ),
                  )
                : GestureDetector(
                    onTap: () => setState(() => _isEditing = true),
                    child: Text(
                      widget.subtask.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        decoration: widget.subtask.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        color: widget.subtask.isDone
                            ? colorScheme.onSurface.withValues(alpha: 0.4)
                            : null,
                      ),
                    ),
                  ),
          ),
          // Delete
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: widget.onDelete,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _AddSubtaskField extends StatefulWidget {
  const _AddSubtaskField({required this.onAdd});

  final ValueChanged<String> onAdd;

  @override
  State<_AddSubtaskField> createState() => _AddSubtaskFieldState();
}

class _AddSubtaskFieldState extends State<_AddSubtaskField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 48),
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Add subtask…',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: _submit,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

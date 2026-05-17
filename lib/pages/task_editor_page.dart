import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recurrence.dart';
import '../models/reminder.dart';
import '../models/todo.dart';
import '../providers/list_collection_provider.dart';
import '../providers/todo_list_provider.dart';
import '../widgets/subtask_editor.dart';

/// Full task editor page for creating or editing a [Todo].
///
/// Supports all fields: title, notes, due date, priority, list, tags,
/// recurrence rule, reminder, and subtasks.
class TaskEditorPage extends ConsumerStatefulWidget {
  const TaskEditorPage({super.key, this.todo, this.defaultListId});

  /// If non-null the editor starts in edit mode; otherwise it creates a new task.
  final Todo? todo;

  /// Pre-selected list when creating from within a project.
  final String? defaultListId;

  @override
  ConsumerState<TaskEditorPage> createState() => _TaskEditorPageState();
}

class _TaskEditorPageState extends ConsumerState<TaskEditorPage> {
  late final TextEditingController _titleCtl;
  late final TextEditingController _notesCtl;
  late final TextEditingController _tagCtl;

  late DateTime? _dueDate;
  late Priority _priority;
  late String? _listId;
  late RecurrenceRule? _recurrenceRule;
  late List<TodoReminder> _reminders;
  late List<String> _tags;
  late List<SubTask> _subtasks;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.todo;
    _titleCtl = TextEditingController(text: t?.title ?? '');
    _notesCtl = TextEditingController(text: t?.notes ?? '');
    _tagCtl = TextEditingController();
    _dueDate = t?.dueDate;
    _priority = t?.priority ?? Priority.low;
    _listId = t?.listId ?? widget.defaultListId;
    _recurrenceRule = t?.recurrenceRule;
    _reminders = List.from(t?.reminders ?? []);
    _tags = List.from(t?.tags ?? []);
    _subtasks = List.from(t?.subtasks ?? []);
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _notesCtl.dispose();
    _tagCtl.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.todo != null;

  void _save() {
    final title = _titleCtl.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);

    final todo = (widget.todo ?? Todo.create(title: title)).copyWith(
      title: title,
      notes: _notesCtl.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      listId: _listId,
      recurrenceRule: _recurrenceRule,
      reminderSet: _reminders.isNotEmpty,
      reminders: List.from(_reminders),
      tags: List.from(_tags),
      subtasks: List.from(_subtasks),
    );

    if (_isEditing) {
      ref.read(todoListProvider.notifier).update(todo);
    } else {
      ref.read(todoListProvider.notifier).add(todo);
    }

    Navigator.pop(context);
  }

  void _pickDate() async {
    final initial = _dueDate ?? DateTime.now().add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  void _addTag() {
    final tag = _tagCtl.text.trim().toLowerCase();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() => _tags = [..._tags, tag]);
    _tagCtl.clear();
  }

  void _removeTag(String tag) {
    setState(() => _tags = _tags.where((t) => t != tag).toList());
  }

  static const _reminderPresets = [
    (15, '15 min before'),
    (60, '1 hour before'),
    (1440, '1 day before'),
    (2880, '2 days before'),
    (10080, '1 week before'),
  ];

  void _addReminder(int minutesBefore) {
    final exists = _reminders.any((r) => r.minutesBefore == minutesBefore);
    if (exists) return;
    setState(() => _reminders = [
          ..._reminders,
          TodoReminder.create(minutesBefore: minutesBefore),
        ],);
  }

  void _removeReminder(TodoReminder reminder) {
    setState(() =>
        _reminders = _reminders.where((r) => r.id != reminder.id).toList(),);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lists = ref.watch(listCollectionProvider);
    final canSave = _titleCtl.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          FilledButton(
            onPressed: canSave && !_isSaving ? _save : null,
            child: const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Hero(
        tag: 'todo-${widget.todo?.id ?? ''}',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextField(
                controller: _titleCtl,
                autofocus: !_isEditing,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'What needs to be done?',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Notes
              TextField(
                controller: _notesCtl,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Add details…',
                ),
                maxLines: 4,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 20),

              // Due date
              _sectionLabel('Due Date'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        _dueDate != null
                            ? '${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}'
                            : 'No date',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      if (_dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => setState(() => _dueDate = null),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Priority
              _sectionLabel('Priority'),
              const SizedBox(height: 8),
              SegmentedButton<Priority>(
                segments: const [
                  ButtonSegment(value: Priority.low, label: Text('Low')),
                  ButtonSegment(value: Priority.medium, label: Text('Medium')),
                  ButtonSegment(value: Priority.high, label: Text('High')),
                ],
                selected: {_priority},
                onSelectionChanged: (v) => setState(() => _priority = v.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 20),

              // List assignment
              _sectionLabel('List'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _listId,
                    isExpanded: true,
                    hint: const Text('No list'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('No list'),),
                      ...lists.map((l) => DropdownMenuItem(
                            value: l.id,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Color(l.color),
                                  radius: 8,
                                ),
                                const SizedBox(width: 8),
                                Text(l.name),
                              ],
                            ),
                          ),),
                    ],
                    onChanged: (v) => setState(() => _listId = v),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Recurrence
              _sectionLabel('Repeat'),
              const SizedBox(height: 8),
              SegmentedButton<RecurrenceType?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('None')),
                  ButtonSegment(
                      value: RecurrenceType.daily, label: Text('Daily'),),
                  ButtonSegment(
                      value: RecurrenceType.weekly, label: Text('Weekly'),),
                  ButtonSegment(
                      value: RecurrenceType.monthly, label: Text('Monthly'),),
                ],
                selected: {_recurrenceRule?.type},
                onSelectionChanged: (v) {
                  final type = v.first;
                  setState(() {
                    _recurrenceRule =
                        type != null ? RecurrenceRule(type: type) : null;
                  });
                },
                showSelectedIcon: false,
              ),
              const SizedBox(height: 20),

              // Tags
              _sectionLabel('Tags'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ..._tags.map((tag) => Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => _removeTag(tag),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),),
                  // Add-tag input
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _tagCtl,
                      decoration: const InputDecoration(
                        hintText: 'Add tag…',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Reminders
              _sectionLabel('Reminders'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ..._reminders.map((r) => Chip(
                        label:
                            Text(r.label, style: const TextStyle(fontSize: 12)),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => _removeReminder(r),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),),
                  PopupMenuButton<int>(
                    onSelected: _addReminder,
                    tooltip: 'Add reminder',
                    child: const Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 14),
                          SizedBox(width: 4),
                          Text('Add reminder', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    itemBuilder: (_) => _reminderPresets
                        .map((p) => PopupMenuItem(
                              value: p.$1,
                              child: Text(p.$2),
                            ),)
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Subtasks
              SubtaskEditor(
                subtasks: _subtasks,
                onChanged: (v) => setState(() => _subtasks = v),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

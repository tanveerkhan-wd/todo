import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/reminder.dart';
import '../models/saved_filter.dart';
import '../models/todo.dart';
import '../models/todo_group.dart';
import '../providers/notification_provider.dart';
import '../providers/saved_filter_provider.dart';
import '../providers/security_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/todo_list_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/date_header_delegate.dart';
import '../widgets/empty_state.dart';
import '../widgets/labeled_icon_button.dart';
import '../widgets/list_selector.dart';
import '../widgets/no_results.dart';
import '../widgets/tag_filter_bar.dart';
import '../widgets/todo_card.dart';
import 'backup_page.dart';
import 'task_editor_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  final _quickAddController = TextEditingController();
  final _quickAddFocus = FocusNode();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  TodoFilter? _selectedFilter;
  String? _selectedListId;
  Set<String> _selectedTags = {};
  int _previousTodoCount = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _quickAddController.dispose();
    _quickAddFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Filtering & grouping
  // ---------------------------------------------------------------------------

  List<Todo> _filteredTodos(List<Todo> todos) {
    var result = todos;

    if (_selectedListId != null) {
      result = result.where((t) => t.listId == _selectedListId).toList();
    }

    if (_selectedTags.isNotEmpty) {
      result = result
          .where((t) => t.tags.any((tag) => _selectedTags.contains(tag)))
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((t) =>
              t.title.toLowerCase().contains(query) ||
              t.notes.toLowerCase().contains(query),)
          .toList();
    }

    return result;
  }

  List<TodoGroup> _buildGroups(List<Todo> todos) {
    return groupTodos(_filteredTodos(todos), filter: _selectedFilter);
  }

  Set<String> _collectTags(List<Todo> todos) {
    final scope = _selectedListId != null
        ? todos.where((t) => t.listId == _selectedListId).toList()
        : todos;
    return scope.fold<Set<String>>({}, (acc, t) => acc..addAll(t.tags));
  }

  // ---------------------------------------------------------------------------
  // Save / apply filter presets
  // ---------------------------------------------------------------------------

  void _saveCurrentFilter() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Filter'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Filter name',
            labelText: 'Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(savedFilterProvider.notifier).save(
                      SavedFilter.create(
                        name: name,
                        tagFilters: _selectedTags.toList(),
                        dateFilter: _selectedFilter,
                        listId: _selectedListId,
                      ),
                    );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _applyFilterPreset(SavedFilter filter) {
    setState(() {
      _selectedTags = filter.tagFilters.toSet();
      _selectedFilter = filter.dateFilter;
      _selectedListId = filter.listId;
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.listen(notificationActionStreamProvider, (_, next) {
      next.whenData((action) {
        if (action.type == NotificationActionType.open) {
          _openTaskEditorFromId(action.todoId);
        }
      });
    });

    final todos = ref.watch(todoListProvider);
    final savedFilters = ref.watch(savedFilterProvider);
    final groups = _buildGroups(todos);
    final allTags = _collectTags(todos).toList()..sort();
    final theme = Theme.of(context);
    final highContrast = ref.watch(highContrastProvider);
    final biometricEnabled = ref.watch(biometricLockEnabledProvider);

    // Auto-scroll to bottom when a new task is added
    final totalCount = todos.length;
    if (totalCount > _previousTodoCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _previousTodoCount = totalCount);
        }
        if (_scrollController.hasClients && 
            _scrollController.position.hasContentDimensions) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else if (totalCount < _previousTodoCount) {
      // Sync count if items were removed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _previousTodoCount = totalCount);
        }
      });
    }

    return Scaffold(
      drawer: Semantics(
        label: 'Lists drawer',
        child: Drawer(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
              children: [
                // --- Lists ---
                Semantics(
                  label: 'Lists',
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      'Lists',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                ListSelector(
                  selectedListId: _selectedListId,
                  onSelectList: (id) {
                    setState(() => _selectedListId = id);
                    Navigator.pop(context);
                  },
                  onSelectAll: () {
                    setState(() => _selectedListId = null);
                    Navigator.pop(context);
                  },
                ),
                const Divider(height: 32),

                // --- Tag filters ---
                if (allTags.isNotEmpty) ...[
                  Semantics(
                    label: 'Tag filters',
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Text(
                        'Tags',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TagFilterBar(
                      allTags: allTags,
                      selectedTags: _selectedTags,
                      onSelectionChanged: (v) =>
                          setState(() => _selectedTags = v),
                    ),
                  ),
                  const Divider(height: 32),
                ],

                // --- Date filters ---
                Semantics(
                  label: 'Date filters',
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      'Dates',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.list, size: 20),
                  title: const Text('All'),
                  trailing: _selectedFilter == null
                      ? Icon(Icons.check, size: 18,
                          color: theme.colorScheme.primary,)
                      : null,
                  onTap: () => setState(() => _selectedFilter = null),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.today, size: 20),
                  title: const Text('Today'),
                  trailing: _selectedFilter == TodoFilter.today
                      ? Icon(Icons.check, size: 18,
                          color: theme.colorScheme.primary,)
                      : null,
                  onTap: () =>
                      setState(() => _selectedFilter = TodoFilter.today),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.calendar_month, size: 20),
                  title: const Text('Upcoming'),
                  trailing: _selectedFilter == TodoFilter.upcoming
                      ? Icon(Icons.check, size: 18,
                          color: theme.colorScheme.primary,)
                      : null,
                  onTap: () =>
                      setState(() => _selectedFilter = TodoFilter.upcoming),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.check_circle_outline, size: 20),
                  title: const Text('Completed'),
                  trailing: _selectedFilter == TodoFilter.completed
                      ? Icon(Icons.check, size: 18,
                          color: theme.colorScheme.primary,)
                      : null,
                  onTap: () =>
                      setState(() => _selectedFilter = TodoFilter.completed),
                ),
                const Divider(height: 8),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.bookmark_outline, size: 20),
                  title: const Text('Save current filter'),
                  onTap: () {
                    Navigator.pop(context);
                    _saveCurrentFilter();
                  },
                ),
                if (savedFilters.isNotEmpty)
                  ...savedFilters.map((f) => ListTile(
                        dense: true,
                        leading: Icon(Icons.bookmark, size: 20,
                            color: theme.colorScheme.primary,),
                        title: Text(f.name),
                        onTap: () {
                          Navigator.pop(context);
                          _applyFilterPreset(f);
                        },
                      ),),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(
        leading: Semantics(
          label: 'Open navigation drawer',
          child: Builder(
            builder: (ctx) => IconButton(
              icon: const FaIcon(FontAwesomeIcons.bars, size: 18),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              tooltip: 'Menu',
            ),
          ),
        ),
        title: Semantics(
          label: 'Todo app',
          child: const Text('Todo'),
        ),
        actions: [
          LabeledIconButton(
            icon: const FaIcon(FontAwesomeIcons.database, size: 16),
            tooltip: 'Backups',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BackupPage()),
            ),
          ),
          // Overflow menu: theme, high contrast, security
          PopupMenuButton<String>(
            iconSize: 18,
            tooltip: 'More options',
            onSelected: (value) async {
              switch (value) {
                case 'theme':
                  final current = ref.read(themeModeProvider);
                  ref.read(themeModeProvider.notifier).state =
                      current == ThemeMode.dark
                          ? ThemeMode.light
                          : ThemeMode.dark;
                case 'high_contrast':
                  ref.read(highContrastProvider.notifier).state = !highContrast;
                case 'security':
                  final enabled = ref.read(biometricLockEnabledProvider);
                  if (!enabled) {
                    final canAuth = await ref
                        .read(biometricServiceProvider)
                        .canAuthenticate();
                    if (!canAuth && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No biometrics available on this device',
                          ),
                        ),
                      );
                      return;
                    }
                  }
                  ref.read(biometricLockEnabledProvider.notifier).state =
                      !enabled;
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          enabled
                              ? 'Security lock disabled'
                              : 'Security lock enabled',
                        ),
                      ),
                    );
                  }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'theme',
                child: ListTile(
                  leading: Icon(
                    ref.watch(themeModeProvider) == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    size: 18,
                  ),
                  title: Text(
                    ref.watch(themeModeProvider) == ThemeMode.dark
                        ? 'Light mode'
                        : 'Dark mode',
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'high_contrast',
                child: ListTile(
                  leading: Icon(
                    highContrast ? Icons.contrast : Icons.contrast_outlined,
                    size: 18,
                  ),
                  title: Text(
                    highContrast ? 'High contrast: ON' : 'High contrast: OFF',
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'security',
                child: ListTile(
                  leading: Icon(
                    biometricEnabled ? Icons.lock : Icons.lock_open,
                    size: 18,
                  ),
                  title: Text(
                    biometricEnabled ? 'Security: ON' : 'Security: OFF',
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Semantics(
            label: 'Search tasks',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search tasks\u2026',
                  filled: true,
                  fillColor: AppTheme.neutral,
                  prefixIcon: Icon(Icons.search,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5),),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Todo list
          Expanded(
            child: todos.isEmpty
                ? const EmptyState()
                : groups.isEmpty
                    ? NoResults(query: _searchQuery)
                    : CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          for (final group in groups) ...[
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: DateHeaderDelegate(
                                group.label,
                                count: group.todos.length,
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) {
                                  final todo = group.todos[i];
                                  final hasSubtasks = todo.subtasks.isNotEmpty;
                                  return TodoCard(
                                    todo: todo,
                                    showSubtaskBadge: hasSubtasks,
                                    onToggle: () => ref
                                        .read(todoListProvider.notifier)
                                        .toggleComplete(todo.id),
                                    onEdit: () => _openTaskEditor(todo),
                                    onDelete: () => _confirmDelete(todo),
                                    onSnooze: (minutes) =>
                                        _snoozeTodo(todo, minutes),
                                  );
                                },
                                childCount: group.todos.length,
                              ),
                            ),
                          ],
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 80),
                          ),
                        ],
                      ),
          ),

          // Bottom persistent quick input bar (replaces FAB)
          Semantics(
            label: 'Quick add task',
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.dividerTheme.color ?? Colors.grey.shade200,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'New task title',
                        child: TextField(
                          controller: _quickAddController,
                          focusNode: _quickAddFocus,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _quickAdd(),
                          decoration: InputDecoration(
                            hintText: 'Quick add task\u2026',
                            filled: true,
                            fillColor: AppTheme.neutral,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: Spacing.md,
                              vertical: 12,
                            ),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.12),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Semantics(
                      label: 'Add task',
                      button: true,
                      child: IconButton.filled(
                        icon: const FaIcon(
                          FontAwesomeIcons.solidPaperPlane,
                          size: 16,
                        ),
                        onPressed: () => _quickAdd(),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(46, 46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _quickAdd() async {
    final title = _quickAddController.text.trim();
    if (title.isEmpty) return;
    _quickAddController.clear();
    _quickAddFocus.requestFocus();
    try {
      await ref.read(todoListProvider.notifier).add(
            Todo.create(title: title, listId: _selectedListId),
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save task: $e')),
        );
      }
    }
  }

  void _openTaskEditor([Todo? todo]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskEditorPage(
          todo: todo,
          defaultListId: _selectedListId,
        ),
      ),
    );
  }

  void _openTaskEditorFromId(String todoId) {
    final todos = ref.read(todoListProvider);
    final todo = todos.firstWhere(
      (t) => t.id == todoId,
      orElse: () => Todo.create(title: ''),
    );
    if (todo.title.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskEditorPage(todo: todo),
      ),
    );
  }

  Future<void> _snoozeTodo(Todo todo, int minutes) async {
    final service = ref.read(notificationServiceProvider);
    for (final reminder in todo.reminders) {
      await service.cancelReminder(todo, reminder);
    }
    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    final snoozedTodo = todo.copyWith(
      dueDate: snoozeTime,
      reminders: [TodoReminder.create(minutesBefore: 0)],
    );
    await service.scheduleReminder(snoozedTodo, snoozedTodo.reminders.first);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder snoozed for $minutes minute(s)')),
      );
    }
  }

  void _confirmDelete(Todo todo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(todoListProvider.notifier).remove(todo.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

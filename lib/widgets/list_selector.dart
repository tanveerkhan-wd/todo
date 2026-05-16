import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/todo_list.dart';
import '../providers/list_collection_provider.dart';

/// A drawer section that allows switching between project lists and creating /
/// renaming / deleting them.
class ListSelector extends ConsumerWidget {
  const ListSelector({
    super.key,
    required this.selectedListId,
    required this.onSelectList,
    required this.onSelectAll,
  });

  final String? selectedListId;
  final ValueChanged<String> onSelectList;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(listCollectionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "All Tasks" default entry
        ListTile(
          leading: const Icon(Icons.inbox),
          title: const Text('All Tasks'),
          selected: selectedListId == null,
          selectedTileColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          onTap: onSelectAll,
        ),
        const SizedBox(height: 4),

        // Project lists
        ...lists.map((list) => _ListTile(
              list: list,
              isSelected: list.id == selectedListId,
              onTap: () => onSelectList(list.id),
              onRename: (name) => ref
                  .read(listCollectionProvider.notifier)
                  .rename(list.id, name),
              onDelete: () => _confirmDelete(context, ref, list),
              onRecolor: (color) => ref
                  .read(listCollectionProvider.notifier)
                  .recolor(list.id, color),
            )),

        const Divider(height: 24),

        // Create new list
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('New List'),
          onTap: () => _createList(context, ref),
        ),
      ],
    );
  }

  void _createList(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New List'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'List name',
            labelText: 'Name',
          ),
          onSubmitted: (_) {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              ref.read(listCollectionProvider.notifier).create(name);
            }
            Navigator.pop(ctx);
          },
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
                ref.read(listCollectionProvider.notifier).create(name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, TodoList list) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete List'),
        content: Text(
            'Delete "${list.name}"? Tasks in this list will not be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(listCollectionProvider.notifier).remove(list.id);
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

class _ListTile extends StatelessWidget {
  const _ListTile({
    required this.list,
    required this.isSelected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onRecolor,
  });

  final TodoList list;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<String> onRename;
  final VoidCallback onDelete;
  final ValueChanged<int> onRecolor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Color(list.color),
        radius: 14,
        child: Text(
          list.name[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(list.name),
      selected: isSelected,
      selectedTileColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: onTap,
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'rename':
              _showRenameDialog(context);
            case 'delete':
              onDelete();
            case 'color':
              _showColorPicker(context);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'rename', child: Text('Rename')),
          PopupMenuItem(value: 'color', child: Text('Change color')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: list.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename List'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
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
                onRename(name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    const colors = [
      0xFF0D47A1,
      0xFFFF6F61,
      0xFF4CAF50,
      0xFFFF9800,
      0xFF9C27B0,
      0xFF00BCD4,
      0xFFE91E63,
      0xFF607D8B,
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((c) {
            return GestureDetector(
              onTap: () {
                onRecolor(c);
                Navigator.pop(ctx);
              },
              child: CircleAvatar(
                backgroundColor: Color(c),
                radius: 20,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

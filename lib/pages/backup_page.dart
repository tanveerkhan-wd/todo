import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../providers/backup_provider.dart';
import '../providers/todo_list_provider.dart';

/// Page for viewing, creating, restoring, and deleting automatic backups.
class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  List<BackupEntryUi> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    final service = ref.read(backupServiceProvider);
    final backups = await service.listBackups();
    setState(() {
      _entries = backups
          .map((b) => BackupEntryUi(
                path: b.path,
                name: b.name,
                lastModified: b.lastModified,
                sizeBytes: b.sizeBytes,
              ))
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _createBackup() async {
    final service = ref.read(backupServiceProvider);
    await service.createBackup();
    _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup created')),
      );
    }
  }

  Future<void> _restoreBackup(BackupEntryUi entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup'),
        content:
            Text('This will replace all current tasks with the backup from\n'
                '${_formatDate(entry.lastModified)}.\n\n'
                'Current data will be lost. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = ref.read(backupServiceProvider);
      await service.restoreBackup(entry.path);
      ref.read(todoListProvider.notifier).load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }

  Future<void> _deleteBackup(BackupEntryUi entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Backup'),
        content: Text('Delete backup from ${_formatDate(entry.lastModified)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final service = ref.read(backupServiceProvider);
    await service.deleteBackup(entry.path);
    _refresh();
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backups'),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.rotate, size: 18),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBackup,
        icon: const FaIcon(FontAwesomeIcons.floppyDisk, size: 16),
        label: const Text('Backup Now'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.database,
                        size: 48,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No backups yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: _entries.length,
                  itemBuilder: (ctx, i) {
                    final entry = _entries[i];
                    final isEven = i.isEven;
                    return Card(
                      color: isEven ? null : theme.colorScheme.surface,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: FaIcon(
                          FontAwesomeIcons.fileLines,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          _formatDate(entry.lastModified),
                          style: theme.textTheme.bodyMedium,
                        ),
                        subtitle: Text(_formatSize(entry.sizeBytes)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const FaIcon(FontAwesomeIcons.rotateLeft,
                                  size: 16),
                              tooltip: 'Restore',
                              onPressed: () => _restoreBackup(entry),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 18, color: theme.colorScheme.error),
                              tooltip: 'Delete',
                              onPressed: () => _deleteBackup(entry),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class BackupEntryUi {
  final String path;
  final String name;
  final DateTime lastModified;
  final int sizeBytes;

  BackupEntryUi({
    required this.path,
    required this.name,
    required this.lastModified,
    required this.sizeBytes,
  });
}

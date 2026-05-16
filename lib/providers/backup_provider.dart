import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/backup_service.dart';
import 'todo_list_provider.dart';

// ---------------------------------------------------------------------------
// BackupService provider
// ---------------------------------------------------------------------------

final backupServiceProvider = Provider<BackupService>((ref) {
  final persistenceService = ref.watch(persistenceServiceProvider);
  return BackupService(persistenceService: persistenceService);
});

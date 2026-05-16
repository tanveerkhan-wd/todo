import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reminder.dart';
import '../services/notification_service.dart';
import 'todo_list_provider.dart';

// ---------------------------------------------------------------------------
// NotificationPlatform & NotificationService providers
// ---------------------------------------------------------------------------

final notificationPlatformProvider =
    Provider<NotificationPlatform>((ref) => FlutterNotificationPlatform());

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final platform = ref.watch(notificationPlatformProvider);
  return NotificationService(platform);
});

// ---------------------------------------------------------------------------
// Notification action stream — the UI watches this to respond to taps
// ---------------------------------------------------------------------------

final _actionControllerProvider =
    Provider<StreamController<NotificationAction>>(
  (ref) => StreamController<NotificationAction>.broadcast(),
);

final notificationActionStreamProvider = StreamProvider<NotificationAction>(
  (ref) => ref.watch(_actionControllerProvider).stream,
);

/// Pushes an [NotificationAction] onto the broadcast stream so that
/// widgets (e.g. the home page) can respond by navigating.
void dispatchAction(NotificationAction action) {
  // The controller is obtained through the global container.
  final container = _getContainer();
  if (container == null) return;
  final controller = container.read(_actionControllerProvider);
  controller.add(action);
}

// ---------------------------------------------------------------------------
// Action handler — called from notification platform callbacks
// ---------------------------------------------------------------------------

/// Processes incoming notification actions by updating todo state and
/// rescheduling, then dispatches the action for UI-side handling.
class NotificationActionHandler {
  NotificationActionHandler(this.container);

  final ProviderContainer container;

  Future<void> handle(NotificationAction action) async {
    try {
      switch (action.type) {
        case NotificationActionType.complete:
          await container
              .read(todoListProvider.notifier)
              .toggleComplete(action.todoId);
          break;

        case NotificationActionType.snooze:
          await _snooze(action.todoId, action.snoozeMinutes);
          break;

        case NotificationActionType.open:
          break;
      }
    } catch (_) {
      // Silently swallow errors from notification callbacks.
    }

    // Always dispatch so the UI can navigate / show feedback.
    dispatchAction(action);
  }

  Future<void> _snooze(String todoId, int minutes) async {
    final todos = container.read(todoListProvider);
    final todo = todos.firstWhere(
      (t) => t.id == todoId,
      orElse: () => throw StateError('Todo not found: $todoId'),
    );

    final service = container.read(notificationServiceProvider);

    // Cancel existing reminders for this todo
    for (final reminder in todo.reminders) {
      await service.cancelReminder(todo, reminder);
    }

    // Schedule a single snooze notification
    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    final snoozeReminder = TodoReminder.create(minutesBefore: 0);
    // Temporarily create a copy with a fake "due date" at snoozeTime
    final snoozedTodo = todo.copyWith(
      dueDate: snoozeTime,
      reminders: [snoozeReminder],
    );
    await service.scheduleReminder(snoozedTodo, snoozeReminder);
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

ProviderContainer? _getContainer() {
  // Imported from main.dart through a top-level variable
  try {
    // ignore: depend_on_referenced_packages
    return _container;
  } catch (_) {
    return null;
  }
}

// This is set by main.dart via globalContainer assignment.
// ignore: prefer_const_declarations
ProviderContainer? _container;

/// Called from main.dart to wire up the global reference.
void setGlobalContainer(ProviderContainer c) {
  _container = c;
}

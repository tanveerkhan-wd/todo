import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';
import '../models/todo.dart' hide Priority;

// ---------------------------------------------------------------------------
// Notification action model
// ---------------------------------------------------------------------------

/// What the user did with a received notification.
enum NotificationActionType { open, complete, snooze }

/// A parsed action from a notification tap or action button press.
class NotificationAction {
  final NotificationActionType type;
  final String todoId;
  final int snoozeMinutes;

  const NotificationAction._({
    required this.type,
    required this.todoId,
    this.snoozeMinutes = 0,
  });

  factory NotificationAction.open(String todoId) =>
      NotificationAction._(type: NotificationActionType.open, todoId: todoId);

  factory NotificationAction.complete(String todoId) => NotificationAction._(
      type: NotificationActionType.complete, todoId: todoId);

  factory NotificationAction.snooze(String todoId, int minutes) =>
      NotificationAction._(
          type: NotificationActionType.snooze,
          todoId: todoId,
          snoozeMinutes: minutes);
}

// ---------------------------------------------------------------------------
// Flutter local notifications — platform abstraction
// ---------------------------------------------------------------------------

/// Abstraction over the platform notification APIs for testability.
abstract class NotificationPlatform {
  void Function(NotificationAction action)? onAction;

  Future<bool> initialize();
  Future<void> schedule(
    int id,
    DateTime when,
    String title,
    String body,
    String payload,
  );
  Future<void> cancel(int id);
  Future<void> cancelAll();
}

/// Concrete implementation backed by [FlutterLocalNotificationsPlugin].
class FlutterNotificationPlatform implements NotificationPlatform {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Callback invoked when the user taps a notification or action.
  @override
  void Function(NotificationAction action)? onAction;

  @override
  Future<bool> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final result = await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onResponse,
    );
    return result ?? false;
  }

  void _onResponse(NotificationResponse response) {
    final payload = response.payload;
    final actionId = response.actionId;
    if (payload == null || payload.isEmpty) return;

    if (actionId == 'complete') {
      onAction?.call(NotificationAction.complete(payload));
    } else if (actionId?.startsWith('snooze_') == true) {
      final minutes = int.tryParse(actionId!.split('_')[1]) ?? 15;
      onAction?.call(NotificationAction.snooze(payload, minutes));
    } else {
      // Default action: open the task
      onAction?.call(NotificationAction.open(payload));
    }
  }

  @override
  Future<void> schedule(
    int id,
    DateTime when,
    String title,
    String body,
    String payload,
  ) async {
    final androidDetails = AndroidNotificationDetails(
      'todo_reminders',
      'Task Reminders',
      channelDescription: 'Reminders for your todo tasks',
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('complete', 'Complete'),
        const AndroidNotificationAction('snooze_15', 'Snooze 15m'),
        const AndroidNotificationAction('snooze_30', 'Snooze 30m'),
        const AndroidNotificationAction('snooze_60', 'Snooze 60m'),
      ],
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.UTC),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}

// ---------------------------------------------------------------------------
// NotificationService — pure scheduling logic on top of the platform
// ---------------------------------------------------------------------------

/// High-level notification service that maps [Todo] + [TodoReminder] pairs to
/// platform notifications and handles action routing.
class NotificationService {
  final NotificationPlatform _platform;

  NotificationService(this._platform);

  /// Computes a unique, positive notification ID from a todo + reminder pair.
  int notificationId(String todoId, String reminderId) =>
      (todoId + reminderId).hashCode & 0x7FFFFFFF;

  /// Returns the [DateTime] at which the reminder's notification should fire,
  /// or `null` if the todo has no due date or the time is already past.
  DateTime? scheduleTime(Todo todo, TodoReminder reminder) {
    if (todo.dueDate == null) return null;
    final time =
        todo.dueDate!.subtract(Duration(minutes: reminder.minutesBefore));
    if (time.isBefore(DateTime.now())) return null;
    return time;
  }

  /// Schedules a single reminder notification for [todo].
  Future<void> scheduleReminder(Todo todo, TodoReminder reminder) async {
    final time = scheduleTime(todo, reminder);
    if (time == null) return;
    await _platform.schedule(
      notificationId(todo.id, reminder.id),
      time,
      todo.title,
      todo.notes.isNotEmpty ? todo.notes : 'Task reminder',
      todo.id,
    );
  }

  /// Cancels the notification for a specific reminder.
  Future<void> cancelReminder(Todo todo, TodoReminder reminder) async {
    await _platform.cancel(notificationId(todo.id, reminder.id));
  }

  /// Cancels all existing notifications and re-schedules every pending
  /// reminder across [todos]. Called on app start to handle reboot recovery.
  Future<void> rescheduleAll(List<Todo> todos) async {
    await _platform.cancelAll();
    for (final todo in todos) {
      if (todo.isDone) continue;
      for (final reminder in todo.reminders) {
        if (reminder.isNotified) continue;
        await scheduleReminder(todo, reminder);
      }
    }
  }
}

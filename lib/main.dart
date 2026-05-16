import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app.dart';
import 'providers/notification_provider.dart';
import 'providers/todo_list_provider.dart';

/// Global navigator key so notification callbacks can navigate.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Global provider container so notification callbacks (which run outside
/// the widget tree) can read providers.
ProviderContainer? globalContainer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  final container = ProviderContainer();
  globalContainer = container;
  setGlobalContainer(container);

  // Initialise notification platform and wiring.
  final platform = container.read(notificationPlatformProvider);
  final service = container.read(notificationServiceProvider);
  final handler = NotificationActionHandler(container);
  platform.onAction = handler.handle;
  await platform.initialize();

  // Pre-load persisted todos and reconcile notifications.
  await container.read(todoListProvider.notifier).load();
  await service.rescheduleAll(container.read(todoListProvider));

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TodoApp(),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'main.dart' as entry;
import 'pages/home_page.dart';
import 'pages/lock_screen.dart';
import 'providers/security_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';

class TodoApp extends ConsumerWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final highContrast = ref.watch(highContrastProvider);
    final biometricEnabled = ref.watch(biometricLockEnabledProvider);
    final unlocked = ref.watch(biometricUnlockedProvider);

    final showLock = biometricEnabled && !unlocked;

    return MaterialApp(
      navigatorKey: entry.navigatorKey,
      title: 'Todo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(highContrast: highContrast),
      darkTheme: AppTheme.dark(highContrast: highContrast),
      themeMode: themeMode,
      home: showLock ? const LockScreen() : const HomePage(),
    );
  }
}

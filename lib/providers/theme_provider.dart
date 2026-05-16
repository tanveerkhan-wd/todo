import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current [ThemeMode] state (light / dark / system).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

/// Whether high-contrast mode is enabled.
final highContrastProvider = StateProvider<bool>((ref) => false);

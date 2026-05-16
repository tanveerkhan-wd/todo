# 📝 Todo Offline

> **A fully offline, cross-platform Todo app** — persistent local storage, push reminders, biometric lock, recurring tasks, backup/restore, and export/import.

![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)
![Tests](https://img.shields.io/badge/tests-131%20passing-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| ✅ **Task Management** | Create, edit, complete, delete tasks with subtasks, tags, priorities & due dates |
| 🔁 **Recurring Tasks** | Daily / weekly / monthly repeats — auto-creates next occurrence on completion |
| 🔔 **Push Reminders** | Configurable reminders with snooze (15m/30m/1h) — works fully offline |
| 🔒 **Biometric Lock** | Optional Face ID / Touch ID / PIN lock on app start |
| 🏷️ **Lists & Filters** | Multiple lists, tag filters, date-based segments (Today / Upcoming / Completed) |
| 💾 **Local Persistence** | All data stored as local JSON — no account, no cloud, no internet needed |
| 📤 **Export / Import** | Share your tasks as JSON files; merge or replace on import |
| 🗃️ **Auto Backup** | Timestamped backups with rotation (keeps last 10 by default) |
| 🌓 **Theming** | Light / Dark / High-Contrast modes with Material 3 design |
| ♿ **Accessibility** | Semantic labels on all interactive elements, proper contrast ratios |
| 🔍 **Search** | Full-text search across task titles |

---

## 📸 Screenshots

<p align="center">
  <img src="assets/screenshots/home_light.png" width="250" alt="Home screen (light mode)" />
  <img src="assets/screenshots/home_dark.png" width="250" alt="Home screen (dark mode)" />
  <img src="assets/screenshots/editor.png" width="250" alt="Task editor" />
</p>

> **Note:** Screenshots are placeholders. Run the app on a device/emulator and add your own to `assets/screenshots/`.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>=3.22.0`
- Dart `>=3.0.0 <4.0.0`

### Installation

```bash
# Clone the repo
git clone https://github.com/yourusername/todo_offline.git
cd todo_offline

# Install dependencies
flutter pub get

# Run on connected device / emulator
flutter run
```

### Build for Release

```bash
# Android APK
flutter build apk --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

---

## 🧱 Architecture

```
lib/
├── app.dart                     # Root widget (theme, lock gate)
├── main.dart                    # Entry point (init, notification setup)
├── models/                      # Data models (Todo, Reminder, List, etc.)
│   ├── todo.dart                # Todo + SubTask models
│   ├── recurrence.dart          # RecurrenceRule (daily/weekly/monthly)
│   ├── reminder.dart           # TodoReminder model
│   ├── todo_group.dart          # Grouping & filtering logic
│   ├── todo_list.dart           # TodoList (project/collection)
│   └── saved_filter.dart        # Persisted filter presets
├── providers/                   # Riverpod state management
│   ├── todo_list_provider.dart  # CRUD + persistence + recurrence
│   ├── theme_provider.dart      # ThemeMode + high-contrast
│   ├── security_provider.dart   # Biometric lock state
│   ├── notification_provider.dart  # Notification action handler
│   ├── backup_provider.dart     # Backup service provider
│   ├── list_collection_provider.dart  # List CRUD
│   └── saved_filter_provider.dart     # Filter CRUD
├── pages/                       # Full-screen pages
│   ├── home_page.dart           # Main screen (search, filter, list, quick-add)
│   ├── task_editor_page.dart    # Create / edit task
│   ├── lock_screen.dart         # Biometric lock UI
│   └── backup_page.dart         # Backup management
├── services/                    # Business logic & platform APIs
│   ├── persistence_service.dart # JSON file I/O with recovery
│   ├── notification_service.dart # Local push notifications
│   ├── export_import_service.dart # JSON export/import
│   ├── backup_service.dart      # Timestamped backups with rotation
│   └── biometric_service.dart   # Biometric/PIN authentication
├── theme/                       # Visual design system
│   ├── tokens.dart              # Spacing, icon sizes, elevation
│   └── app_theme.dart           # Light/dark/high-contrast Material 3 themes
├── utils/
│   └── recurrence.dart          # Pure functions for recurrence math
└── widgets/                     # Reusable UI components
    ├── todo_tile.dart           # Single task list item
    ├── tag_filter_bar.dart      # Filter by tags
    ├── date_header_delegate.dart # Sticky date group headers
    ├── list_selector.dart       # Drawer list picker
    ├── labeled_icon_button.dart # Accessible icon button
    ├── subtask_editor.dart      # Subtask checklist editor
    ├── date_chip.dart           # Date display chip
    ├── priority_dot.dart        # Priority indicator
    ├── empty_state.dart         # Empty list placeholder
    └── quick_add_sheet.dart     # Quick-add bottom sheet
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Riverpod** over Provider / BLoC | Compile-time safety, no `BuildContext` dependency for service access |
| **Local JSON** over SQLite | No schema migrations, easy manual inspection, trivial backup/export |
| **Material 3** | Modern design language with built-in accessibility |
| **`flutter_local_notifications` v17** | Reliable offline scheduling with actionable notifications |
| **`local_auth`** | Platform-native biometric authentication (Face ID / Touch ID / PIN) |

---

## 🧪 Testing

The project includes **131 tests** across 13 files covering models, services, widgets, and integration flows.

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/models/todo_test.dart

# Run with coverage (requires lcov)
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

| Category | Tests | What's Covered |
|----------|-------|----------------|
| **Models** | 69 | JSON round-trips, `copyWith`, equality, edge cases |
| **Services** | 37 | Persistence (corruption recovery), notifications (scheduling, cancel), backup (rotation), export/import (merge, replace) |
| **Widgets** | 7 | Layout, empty state, quick-add, theme toggle, delete dialog |
| **Integration** | 5 | End-to-end: persistence round-trip, notification scheduling, rescheduleAll |
| **Utilities** | 13 | Recurrence math: daily/weekly/monthly intervals, endDate handling |

### CI/CD

GitHub Actions runs `flutter analyze` + `flutter test` on every push/PR to `main`.

---

## 🛠️ Configuration

### Analysis Options

Additional lint rules in `analysis_options.yaml`:

| Rule | Purpose |
|------|---------|
| `require_trailing_commas` | Consistent formatting |
| `prefer_single_quotes` | String style consistency |
| `annotate_overrides` | Explicit `@override` markers |
| `avoid_types_on_closure_parameters` | Cleaner lambda syntax |
| `prefer_final_locals` | Immutability best practices |

### Backup Rotation

Default max backups: **10**. Change in `lib/services/backup_service.dart`:

```dart
BackupService({PersistenceService? persistence, int maxBackups = 10}) ...
```

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) | State management |
| [`font_awesome_flutter`](https://pub.dev/packages/font_awesome_flutter) | Icon library |
| [`path_provider`](https://pub.dev/packages/path_provider) | App documents directory |
| [`uuid`](https://pub.dev/packages/uuid) | Unique ID generation |
| [`share_plus`](https://pub.dev/packages/share_plus) | Platform share sheet |
| [`file_picker`](https://pub.dev/packages/file_picker) | File picker for imports |
| [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) | Push notifications |
| [`local_auth`](https://pub.dev/packages/local_auth) | Biometric authentication |
| [`timezone`](https://pub.dev/packages/timezone) | Timezone-aware scheduling |
| [`collection`](https://pub.dev/packages/collection) | Collection utilities |

---

## 🗺️ Roadmap

- [ ] Widget tests for task editor page
- [ ] Search by tags + dates (advanced search)
- [ ] Drag-and-drop reordering
- [ ] Multi-select batch operations
- [ ] Widget (home screen) for quick task view
- [ ] iCloud / Google Drive sync (opt-in)

---

## 🤝 Contributing

1. Fork the repo
2. Create your feature branch (`git checkout -b feat/amazing`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feat/amazing`)
5. Open a Pull Request

Please ensure all tests pass and lint rules are clean before submitting.

```bash
flutter analyze && flutter test
```

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <sub>Built with ❤️ using <a href="https://flutter.dev">Flutter</a></sub>
</p>

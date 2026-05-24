# My Timetable App

A personal + school timetable manager with timed todo lists, planning board, and notifications.

## Features

- **Multiple timetables** — Personal and School built-in; add unlimited custom ones, each color-coded and toggle-able
- **Today view** — Shows all events and tasks for the selected day, merged into a timeline
- **Week view** — Calendar with daily timeline breakdown (hour slots)
- **Timed tasks** — Every todo has an optional start & end time, priority level, and timetable tag
- **Timed todo filters** — All, Today, Upcoming, Unscheduled, Completed; drag to reorder
- **Planning board** — Kanban-style drag-and-drop with custom columns; unscheduled inbox
- **Notifications** — Per-event and per-task reminders with configurable lead time (5–60 min)
- **Daily digest** — Morning summary notification at your chosen time
- **Persistent storage** — Hive local database, no internet required
- **Dark mode** — Full Material 3 light/dark support

## Setup

### Prerequisites
- Flutter 3.16+
- Dart 3.0+

### Install & run
```bash
cd timetable_app
flutter pub get
flutter run
```

### Generate Hive adapters (if you modify models)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Project structure

```
lib/
├── main.dart                 # App entry, navigation scaffold
├── models/
│   ├── models.dart           # Hive data models
│   └── models.g.dart         # Generated adapters
├── providers/
│   └── providers.dart        # Riverpod state notifiers
├── screens/
│   ├── today_screen.dart     # Home / today timeline
│   ├── week_screen.dart      # Calendar + daily breakdown
│   ├── tasks_screen.dart     # Full task list with filters
│   ├── planning_screen.dart  # Kanban planning board
│   └── settings_screen.dart  # Timetable management + settings
├── widgets/
│   ├── task_card.dart        # Dismissible task card
│   ├── entry_card.dart       # Timetable entry card
│   ├── add_task_sheet.dart   # Add/edit task bottom sheet
│   └── add_entry_sheet.dart  # Add/edit timetable entry sheet
└── utils/
    ├── db_service.dart       # Hive init + seed data
    ├── notification_service.dart  # flutter_local_notifications
    └── theme.dart            # Material 3 theme + helpers
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `hive_flutter` | Local database (no network) |
| `flutter_local_notifications` | Push notifications & reminders |
| `timezone` | Correct timezone handling for scheduled notifications |
| `table_calendar` | Calendar widget in week view |
| `go_router` | Navigation (available for deep linking) |
| `uuid` | Unique IDs for all records |
| `intl` | Date formatting |

## Notes

- All data is stored locally with Hive — no account or internet required
- Notifications require permissions granted at runtime (prompted on first launch)
- On Android 12+, exact alarms require `USE_EXACT_ALARM` permission (included in manifest)
- Planning board columns are fully customizable; the "Unscheduled inbox" column is permanent
- Timetable entries are recurring (weekly); tasks are one-time events

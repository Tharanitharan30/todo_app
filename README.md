# Personal Command Center

**Personal Command Center** is a high-performance, local-first personal productivity, task management, calendar planning, focus/pomodoro, and financial tracking application built with Flutter, Riverpod, and Drift (SQLite).

---

## Key Features

- 🏠 **Dashboard / Command Center**: Today's overview, instant quick actions, chronological schedule, upcoming & overdue task alerts, daily briefing, and finance/focus snapshots.
- 📋 **Task Management**: Prioritization (High/Medium/Low), categories, subtasks, due dates/times, tags, notes, and recurring rules (daily, weekly, monthly).
- 📅 **Calendar & Planning**: Month grid, 7-column time-based Week view, 24-hour Day timeline, and 30-day chronological Agenda stream with recurrence calculations.
- ⏱️ **Focus / Pomodoro**: Customizable focus timer, short/long break cycles, task integration, and daily goal progress tracking.
- 💰 **Finance & Budgeting**: Income tracking, expense logging with payment methods, category budget limits with percentage usage alerts, savings goals, and recurring subscription reminders.
- 📊 **Analytics & Insights**: Local calculation of task completion trends, category productivity breakdown, financial spending distribution, and focus duration metrics.
- 🔍 **Global Search & Command Palette**: Cross-module SQLite search across all tables (`/search`) and desktop `Ctrl + K` Command Palette overlay.
- ⌨️ **Keyboard Shortcuts**: Desktop shortcuts (`Ctrl+K` Command Palette, `Ctrl+T` Add Task, `Ctrl+E` Add Expense, `Ctrl+I` Add Income, `Ctrl+F` Search).
- 🔔 **Notifications & Daily Briefing**: Timezone-aware local reminders for tasks, overdue items, budget limits, subscriptions, and daily briefings.
- 💾 **Data Safety & Backup**: JSON backup & restoration with validation safety checks, CSV data export/import, and local Settings customization.

---

## Tech Stack & Architecture

- **Framework**: Flutter 3.x (Android & Linux Desktop)
- **State Management**: Flutter Riverpod
- **Local Persistence**: Drift (SQLite) with `sqlite3_flutter_libs`
- **Routing**: GoRouter
- **Local Notifications**: `flutter_local_notifications` + `timezone`
- **Charts**: `fl_chart`

---

## Project Structure

```text
lib/
├── database/         # SQLite tables schema, migrations & AppDatabase queries
├── models/           # Data models & helpers
├── providers/        # Riverpod StateNotifiers & AsyncNotifier providers
├── screens/          # Application screens (Home, Tasks, Calendar, Finance, Focus, etc.)
├── services/         # Centralized Notification, Backup/Restore, & Export services
├── utils/            # Currency formatting & date utilities
└── widgets/          # Reusable UI components & dialogs
```

---

## Setup & Commands

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run Database Code Generator (Optional)
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Run Static Analysis & Tests
```bash
dart format lib test
flutter analyze
flutter test
```

### 4. Run Application
```bash
# Run on Linux Desktop
flutter run -d linux

# Run on Android Device / Emulator
flutter run -d android
```

### 5. Build Release Artifacts
```bash
# Build Android Release APK
flutter build apk --release

# Build Linux Desktop Release Bundle
flutter build linux --release
```

---

## License

Private & Local-First Application. All data remains exclusively on your device.

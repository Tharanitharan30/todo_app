import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';
import 'database_provider.dart';

class AppSettings {
  final ThemeMode themeMode;
  final String accentColor;
  final String currency;
  final String defaultTaskPriority;
  final String defaultTaskCategory;
  final String defaultPaymentMethod;
  final String weekStartsOn;
  final bool autoBackupEnabled;
  final DateTime? lastBackupTime;

  // Notification settings
  final bool dailyBriefingEnabled;
  final int dailyBriefingHour;
  final int dailyBriefingMinute;
  final bool dailyBriefingOpenApp;
  final bool dailySummaryEnabled;
  final TimeOfDay dailySummaryTime;
  final bool taskRemindersEnabled;
  final bool dueTaskNotificationsEnabled;
  final bool overdueNotificationsEnabled;
  final bool budgetAlertsEnabled;
  final bool subscriptionAlertsEnabled;
  final bool expenseRemindersEnabled;

  // Focus / Pomodoro Settings
  final int focusDurationMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int sessionsBeforeLongBreak;
  final bool autoStartBreaks;
  final bool autoStartFocus;
  final double dailyFocusGoalHours;
  final bool timerSoundEnabled;
  final bool timerVibrationEnabled;

  TimeOfDay get dailyBriefingTime =>
      TimeOfDay(hour: dailyBriefingHour, minute: dailyBriefingMinute);

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.accentColor = 'default',
    this.currency = 'INR',
    this.defaultTaskPriority = 'medium',
    this.defaultTaskCategory = 'personal',
    this.defaultPaymentMethod = 'UPI',
    this.weekStartsOn = 'Monday',
    this.autoBackupEnabled = false,
    this.lastBackupTime,
    this.dailyBriefingEnabled = true,
    this.dailyBriefingHour = 8,
    this.dailyBriefingMinute = 0,
    this.dailyBriefingOpenApp = true,
    this.dailySummaryEnabled = true,
    this.dailySummaryTime = const TimeOfDay(hour: 20, minute: 0),
    this.taskRemindersEnabled = true,
    this.dueTaskNotificationsEnabled = true,
    this.overdueNotificationsEnabled = true,
    this.budgetAlertsEnabled = true,
    this.subscriptionAlertsEnabled = true,
    this.expenseRemindersEnabled = false,
    this.focusDurationMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsBeforeLongBreak = 4,
    this.autoStartBreaks = false,
    this.autoStartFocus = false,
    this.dailyFocusGoalHours = 2.0,
    this.timerSoundEnabled = true,
    this.timerVibrationEnabled = true,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? accentColor,
    String? currency,
    String? defaultTaskPriority,
    String? defaultTaskCategory,
    String? defaultPaymentMethod,
    String? weekStartsOn,
    bool? autoBackupEnabled,
    DateTime? lastBackupTime,
    bool? dailyBriefingEnabled,
    int? dailyBriefingHour,
    int? dailyBriefingMinute,
    bool? dailyBriefingOpenApp,
    TimeOfDay? dailyBriefingTime,
    bool? dailySummaryEnabled,
    TimeOfDay? dailySummaryTime,
    bool? taskRemindersEnabled,
    bool? dueTaskNotificationsEnabled,
    bool? overdueNotificationsEnabled,
    bool? budgetAlertsEnabled,
    bool? subscriptionAlertsEnabled,
    bool? expenseRemindersEnabled,
    int? focusDurationMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLongBreak,
    bool? autoStartBreaks,
    bool? autoStartFocus,
    double? dailyFocusGoalHours,
    bool? timerSoundEnabled,
    bool? timerVibrationEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      currency: currency ?? this.currency,
      defaultTaskPriority: defaultTaskPriority ?? this.defaultTaskPriority,
      defaultTaskCategory: defaultTaskCategory ?? this.defaultTaskCategory,
      defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
      weekStartsOn: weekStartsOn ?? this.weekStartsOn,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      dailyBriefingEnabled: dailyBriefingEnabled ?? this.dailyBriefingEnabled,
      dailyBriefingHour:
          dailyBriefingHour ??
          (dailyBriefingTime != null
              ? dailyBriefingTime.hour
              : this.dailyBriefingHour),
      dailyBriefingMinute:
          dailyBriefingMinute ??
          (dailyBriefingTime != null
              ? dailyBriefingTime.minute
              : this.dailyBriefingMinute),
      dailyBriefingOpenApp: dailyBriefingOpenApp ?? this.dailyBriefingOpenApp,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
      dailySummaryTime: dailySummaryTime ?? this.dailySummaryTime,
      taskRemindersEnabled: taskRemindersEnabled ?? this.taskRemindersEnabled,
      dueTaskNotificationsEnabled:
          dueTaskNotificationsEnabled ?? this.dueTaskNotificationsEnabled,
      overdueNotificationsEnabled:
          overdueNotificationsEnabled ?? this.overdueNotificationsEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      subscriptionAlertsEnabled:
          subscriptionAlertsEnabled ?? this.subscriptionAlertsEnabled,
      expenseRemindersEnabled:
          expenseRemindersEnabled ?? this.expenseRemindersEnabled,
      focusDurationMinutes: focusDurationMinutes ?? this.focusDurationMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartFocus: autoStartFocus ?? this.autoStartFocus,
      dailyFocusGoalHours: dailyFocusGoalHours ?? this.dailyFocusGoalHours,
      timerSoundEnabled: timerSoundEnabled ?? this.timerSoundEnabled,
      timerVibrationEnabled:
          timerVibrationEnabled ?? this.timerVibrationEnabled,
    );
  }
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  bool _isLoaded = false;

  @override
  AppSettings build() {
    _loadSettingsFromDb();
    return const AppSettings();
  }

  Future<void> reloadSettings() async {
    _isLoaded = false;
    await _loadSettingsFromDb();
  }

  Future<void> _loadSettingsFromDb() async {
    try {
      final db = ref.read(databaseProvider);
      final allSettings = await db.getAllSettings();
      if (!ref.mounted) return;
      if (_isLoaded) return;

      final Map<String, String> map = {
        for (final s in allSettings) s.key: s.value,
      };

      bool parseBool(String key, bool defaultValue) {
        if (!map.containsKey(key)) return defaultValue;
        return map[key]?.toLowerCase() == 'true';
      }

      int parseInt(String key, int defaultValue) {
        if (!map.containsKey(key)) return defaultValue;
        return int.tryParse(map[key] ?? '') ?? defaultValue;
      }

      double parseDouble(String key, double defaultValue) {
        if (!map.containsKey(key)) return defaultValue;
        return double.tryParse(map[key] ?? '') ?? defaultValue;
      }

      TimeOfDay parseTime(String key, TimeOfDay defaultValue) {
        if (!map.containsKey(key)) return defaultValue;
        final parts = map[key]!.split(':');
        if (parts.length == 2) {
          final h = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          if (h != null && m != null) return TimeOfDay(hour: h, minute: m);
        }
        return defaultValue;
      }

      ThemeMode parseTheme(String? val) {
        switch (val?.toLowerCase()) {
          case 'light':
            return ThemeMode.light;
          case 'dark':
            return ThemeMode.dark;
          case 'system':
          default:
            return ThemeMode.system;
        }
      }

      DateTime? parseDate(String? val) {
        if (val == null || val.isEmpty) return null;
        return DateTime.tryParse(val);
      }

      final parsedTime = parseTime(
        'daily_briefing_time',
        const TimeOfDay(hour: 8, minute: 0),
      );
      final briefingHour = parseInt('daily_briefing_hour', parsedTime.hour);
      final briefingMin = parseInt('daily_briefing_minute', parsedTime.minute);

      state = AppSettings(
        themeMode: parseTheme(map['theme_mode']),
        accentColor: map['accent_color'] ?? 'default',
        currency: map['currency'] ?? 'INR',
        defaultTaskPriority: map['default_task_priority'] ?? 'medium',
        defaultTaskCategory: map['default_task_category'] ?? 'personal',
        defaultPaymentMethod: map['default_payment_method'] ?? 'UPI',
        weekStartsOn: map['week_starts_on'] ?? 'Monday',
        autoBackupEnabled: parseBool('auto_backup_enabled', false),
        lastBackupTime: parseDate(map['last_backup_time']),
        dailyBriefingEnabled: parseBool('daily_briefing_enabled', true),
        dailyBriefingHour: briefingHour,
        dailyBriefingMinute: briefingMin,
        dailyBriefingOpenApp: parseBool('daily_briefing_open_app', true),
        dailySummaryEnabled: parseBool('daily_summary_enabled', true),
        dailySummaryTime: parseTime(
          'daily_summary_time',
          const TimeOfDay(hour: 20, minute: 0),
        ),
        taskRemindersEnabled: parseBool('task_reminders_enabled', true),
        dueTaskNotificationsEnabled: parseBool(
          'due_task_notifications_enabled',
          true,
        ),
        overdueNotificationsEnabled: parseBool(
          'overdue_notifications_enabled',
          true,
        ),
        budgetAlertsEnabled: parseBool('budget_alerts_enabled', true),
        subscriptionAlertsEnabled: parseBool(
          'subscription_alerts_enabled',
          true,
        ),
        expenseRemindersEnabled: parseBool('expense_reminders_enabled', false),
        focusDurationMinutes: parseInt('focus_duration_minutes', 25),
        shortBreakMinutes: parseInt('short_break_minutes', 5),
        longBreakMinutes: parseInt('long_break_minutes', 15),
        sessionsBeforeLongBreak: parseInt('sessions_before_long_break', 4),
        autoStartBreaks: parseBool('auto_start_breaks', false),
        autoStartFocus: parseBool('auto_start_focus', false),
        dailyFocusGoalHours: parseDouble('daily_focus_goal_hours', 2.0),
        timerSoundEnabled: parseBool('timer_sound_enabled', true),
        timerVibrationEnabled: parseBool('timer_vibration_enabled', true),
      );
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading app settings: $e');
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _isLoaded = true;
    state = newSettings;
    try {
      if (!ref.mounted) return;
      final db = ref.read(databaseProvider);

      String themeStr;
      switch (newSettings.themeMode) {
        case ThemeMode.light:
          themeStr = 'light';
          break;
        case ThemeMode.dark:
          themeStr = 'dark';
          break;
        case ThemeMode.system:
          themeStr = 'system';
          break;
      }

      await db.setSetting('theme_mode', themeStr);
      await db.setSetting('accent_color', newSettings.accentColor);
      await db.setSetting('currency', newSettings.currency);
      await db.setSetting(
        'default_task_priority',
        newSettings.defaultTaskPriority,
      );
      await db.setSetting(
        'default_task_category',
        newSettings.defaultTaskCategory,
      );
      await db.setSetting(
        'default_payment_method',
        newSettings.defaultPaymentMethod,
      );
      await db.setSetting('week_starts_on', newSettings.weekStartsOn);
      await db.setSetting(
        'auto_backup_enabled',
        newSettings.autoBackupEnabled.toString(),
      );
      if (newSettings.lastBackupTime != null) {
        await db.setSetting(
          'last_backup_time',
          newSettings.lastBackupTime!.toIso8601String(),
        );
      }
      await db.setSetting(
        'daily_briefing_enabled',
        newSettings.dailyBriefingEnabled.toString(),
      );
      await db.setSetting(
        'daily_briefing_hour',
        newSettings.dailyBriefingHour.toString(),
      );
      await db.setSetting(
        'daily_briefing_minute',
        newSettings.dailyBriefingMinute.toString(),
      );
      await db.setSetting(
        'daily_briefing_open_app',
        newSettings.dailyBriefingOpenApp.toString(),
      );
      await db.setSetting(
        'daily_briefing_time',
        '${newSettings.dailyBriefingHour}:${newSettings.dailyBriefingMinute}',
      );
      await db.setSetting(
        'daily_summary_enabled',
        newSettings.dailySummaryEnabled.toString(),
      );
      await db.setSetting(
        'daily_summary_time',
        '${newSettings.dailySummaryTime.hour}:${newSettings.dailySummaryTime.minute}',
      );
      await db.setSetting(
        'task_reminders_enabled',
        newSettings.taskRemindersEnabled.toString(),
      );
      await db.setSetting(
        'due_task_notifications_enabled',
        newSettings.dueTaskNotificationsEnabled.toString(),
      );
      await db.setSetting(
        'overdue_notifications_enabled',
        newSettings.overdueNotificationsEnabled.toString(),
      );
      await db.setSetting(
        'budget_alerts_enabled',
        newSettings.budgetAlertsEnabled.toString(),
      );
      await db.setSetting(
        'subscription_alerts_enabled',
        newSettings.subscriptionAlertsEnabled.toString(),
      );
      await db.setSetting(
        'expense_reminders_enabled',
        newSettings.expenseRemindersEnabled.toString(),
      );
      await db.setSetting(
        'focus_duration_minutes',
        newSettings.focusDurationMinutes.toString(),
      );
      await db.setSetting(
        'short_break_minutes',
        newSettings.shortBreakMinutes.toString(),
      );
      await db.setSetting(
        'long_break_minutes',
        newSettings.longBreakMinutes.toString(),
      );
      await db.setSetting(
        'sessions_before_long_break',
        newSettings.sessionsBeforeLongBreak.toString(),
      );
      await db.setSetting(
        'auto_start_breaks',
        newSettings.autoStartBreaks.toString(),
      );
      await db.setSetting(
        'auto_start_focus',
        newSettings.autoStartFocus.toString(),
      );
      await db.setSetting(
        'daily_focus_goal_hours',
        newSettings.dailyFocusGoalHours.toString(),
      );
      await db.setSetting(
        'timer_sound_enabled',
        newSettings.timerSoundEnabled.toString(),
      );
      await db.setSetting(
        'timer_vibration_enabled',
        newSettings.timerVibrationEnabled.toString(),
      );
    } catch (e) {
      debugPrint('Error saving app settings: $e');
    }
  }

  Future<void> setDailyBriefingTime(TimeOfDay time) async {
    final updated = state.copyWith(
      dailyBriefingHour: time.hour,
      dailyBriefingMinute: time.minute,
    );
    await updateSettings(updated);
    if (updated.dailyBriefingEnabled) {
      try {
        final tasks = await ref.read(databaseProvider).getAllTasks();
        final highPriority = tasks
            .where(
              (t) =>
                  (t.priority == 'urgent' || t.priority == 'high') &&
                  t.status != 'completed',
            )
            .length;
        final body =
            'You have ${tasks.length} tasks ($highPriority high priority). Tap to view briefing.';
        await NotificationService().scheduleDailyBriefing(
          time: time,
          body: body,
        );
      } catch (_) {}
    }
  }

  Future<void> setDailyBriefingEnabled(bool enabled) async {
    final updated = state.copyWith(dailyBriefingEnabled: enabled);
    await updateSettings(updated);
    if (enabled) {
      await setDailyBriefingTime(updated.dailyBriefingTime);
    } else {
      try {
        await NotificationService().cancelDailyBriefing();
      } catch (_) {}
    }
  }

  Future<void> setDailyBriefingOpenApp(bool openApp) async {
    final updated = state.copyWith(dailyBriefingOpenApp: openApp);
    await updateSettings(updated);
  }
}

// Aliases for compatibility
typedef NotificationSettings = AppSettings;

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

final notificationSettingsProvider = appSettingsProvider;

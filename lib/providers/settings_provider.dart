import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final TimeOfDay dailyBriefingTime;
  final bool dailySummaryEnabled;
  final TimeOfDay dailySummaryTime;
  final bool taskRemindersEnabled;
  final bool dueTaskNotificationsEnabled;
  final bool overdueNotificationsEnabled;
  final bool budgetAlertsEnabled;
  final bool subscriptionAlertsEnabled;
  final bool expenseRemindersEnabled;

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
    this.dailyBriefingTime = const TimeOfDay(hour: 7, minute: 30),
    this.dailySummaryEnabled = true,
    this.dailySummaryTime = const TimeOfDay(hour: 20, minute: 0),
    this.taskRemindersEnabled = true,
    this.dueTaskNotificationsEnabled = true,
    this.overdueNotificationsEnabled = true,
    this.budgetAlertsEnabled = true,
    this.subscriptionAlertsEnabled = true,
    this.expenseRemindersEnabled = false,
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
    TimeOfDay? dailyBriefingTime,
    bool? dailySummaryEnabled,
    TimeOfDay? dailySummaryTime,
    bool? taskRemindersEnabled,
    bool? dueTaskNotificationsEnabled,
    bool? overdueNotificationsEnabled,
    bool? budgetAlertsEnabled,
    bool? subscriptionAlertsEnabled,
    bool? expenseRemindersEnabled,
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
      dailyBriefingTime: dailyBriefingTime ?? this.dailyBriefingTime,
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
    );
  }
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _loadSettingsFromDb();
    return const AppSettings();
  }

  Future<void> reloadSettings() async {
    await _loadSettingsFromDb();
  }

  Future<void> _loadSettingsFromDb() async {
    try {
      final db = ref.read(databaseProvider);
      final allSettings = await db.getAllSettings();
      final Map<String, String> map = {
        for (final s in allSettings) s.key: s.value
      };

      bool parseBool(String key, bool defaultValue) {
        if (!map.containsKey(key)) return defaultValue;
        return map[key]?.toLowerCase() == 'true';
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
        dailyBriefingTime: parseTime(
            'daily_briefing_time', const TimeOfDay(hour: 7, minute: 30)),
        dailySummaryEnabled: parseBool('daily_summary_enabled', true),
        dailySummaryTime: parseTime(
            'daily_summary_time', const TimeOfDay(hour: 20, minute: 0)),
        taskRemindersEnabled: parseBool('task_reminders_enabled', true),
        dueTaskNotificationsEnabled:
            parseBool('due_task_notifications_enabled', true),
        overdueNotificationsEnabled:
            parseBool('overdue_notifications_enabled', true),
        budgetAlertsEnabled: parseBool('budget_alerts_enabled', true),
        subscriptionAlertsEnabled:
            parseBool('subscription_alerts_enabled', true),
        expenseRemindersEnabled:
            parseBool('expense_reminders_enabled', false),
      );
    } catch (e) {
      debugPrint('Error loading app settings: $e');
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    state = newSettings;
    try {
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
          'default_task_priority', newSettings.defaultTaskPriority);
      await db.setSetting(
          'default_task_category', newSettings.defaultTaskCategory);
      await db.setSetting(
          'default_payment_method', newSettings.defaultPaymentMethod);
      await db.setSetting('week_starts_on', newSettings.weekStartsOn);
      await db.setSetting(
          'auto_backup_enabled', newSettings.autoBackupEnabled.toString());
      if (newSettings.lastBackupTime != null) {
        await db.setSetting(
            'last_backup_time', newSettings.lastBackupTime!.toIso8601String());
      }
      await db.setSetting(
          'daily_briefing_enabled', newSettings.dailyBriefingEnabled.toString());
      await db.setSetting('daily_briefing_time',
          '${newSettings.dailyBriefingTime.hour}:${newSettings.dailyBriefingTime.minute}');
      await db.setSetting(
          'daily_summary_enabled', newSettings.dailySummaryEnabled.toString());
      await db.setSetting('daily_summary_time',
          '${newSettings.dailySummaryTime.hour}:${newSettings.dailySummaryTime.minute}');
      await db.setSetting(
          'task_reminders_enabled', newSettings.taskRemindersEnabled.toString());
      await db.setSetting('due_task_notifications_enabled',
          newSettings.dueTaskNotificationsEnabled.toString());
      await db.setSetting('overdue_notifications_enabled',
          newSettings.overdueNotificationsEnabled.toString());
      await db.setSetting(
          'budget_alerts_enabled', newSettings.budgetAlertsEnabled.toString());
      await db.setSetting('subscription_alerts_enabled',
          newSettings.subscriptionAlertsEnabled.toString());
      await db.setSetting('expense_reminders_enabled',
          newSettings.expenseRemindersEnabled.toString());
    } catch (e) {
      debugPrint('Error saving app settings: $e');
    }
  }
}

// Aliases for compatibility
typedef NotificationSettings = AppSettings;

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);

final notificationSettingsProvider = appSettingsProvider;

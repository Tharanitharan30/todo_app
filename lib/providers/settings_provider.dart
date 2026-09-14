import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_provider.dart';

class NotificationSettings {
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

  const NotificationSettings({
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

  NotificationSettings copyWith({
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
    return NotificationSettings(
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

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() {
    _loadSettingsFromDb();
    return const NotificationSettings();
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

      state = NotificationSettings(
        dailyBriefingEnabled: parseBool('daily_briefing_enabled', true),
        dailyBriefingTime: parseTime('daily_briefing_time', const TimeOfDay(hour: 7, minute: 30)),
        dailySummaryEnabled: parseBool('daily_summary_enabled', true),
        dailySummaryTime: parseTime('daily_summary_time', const TimeOfDay(hour: 20, minute: 0)),
        taskRemindersEnabled: parseBool('task_reminders_enabled', true),
        dueTaskNotificationsEnabled: parseBool('due_task_notifications_enabled', true),
        overdueNotificationsEnabled: parseBool('overdue_notifications_enabled', true),
        budgetAlertsEnabled: parseBool('budget_alerts_enabled', true),
        subscriptionAlertsEnabled: parseBool('subscription_alerts_enabled', true),
        expenseRemindersEnabled: parseBool('expense_reminders_enabled', false),
      );
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  Future<void> updateSettings(NotificationSettings newSettings) async {
    state = newSettings;
    try {
      final db = ref.read(databaseProvider);
      await db.setSetting('daily_briefing_enabled', newSettings.dailyBriefingEnabled.toString());
      await db.setSetting('daily_briefing_time', '${newSettings.dailyBriefingTime.hour}:${newSettings.dailyBriefingTime.minute}');
      await db.setSetting('daily_summary_enabled', newSettings.dailySummaryEnabled.toString());
      await db.setSetting('daily_summary_time', '${newSettings.dailySummaryTime.hour}:${newSettings.dailySummaryTime.minute}');
      await db.setSetting('task_reminders_enabled', newSettings.taskRemindersEnabled.toString());
      await db.setSetting('due_task_notifications_enabled', newSettings.dueTaskNotificationsEnabled.toString());
      await db.setSetting('overdue_notifications_enabled', newSettings.overdueNotificationsEnabled.toString());
      await db.setSetting('budget_alerts_enabled', newSettings.budgetAlertsEnabled.toString());
      await db.setSetting('subscription_alerts_enabled', newSettings.subscriptionAlertsEnabled.toString());
      await db.setSetting('expense_reminders_enabled', newSettings.expenseRemindersEnabled.toString());
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
        NotificationSettingsNotifier.new);

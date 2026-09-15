import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import 'neumorphic_button.dart';
import 'neumorphic_card.dart';
import 'neumorphic_container.dart';

class NotificationSettingsSection extends ConsumerWidget {
  const NotificationSettingsSection({super.key});

  static String formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  Future<void> _selectBriefingTime(
    BuildContext context,
    WidgetRef ref,
    TimeOfDay initialTime,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      await ref.read(appSettingsProvider.notifier).setDailyBriefingTime(picked);
    }
  }

  Future<void> _selectSummaryTime(
    BuildContext context,
    WidgetRef ref,
    TimeOfDay initialTime,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      final notifier = ref.read(appSettingsProvider.notifier);
      final current = ref.read(appSettingsProvider);
      await notifier.updateSettings(current.copyWith(dailySummaryTime: picked));
      await NotificationService().rescheduleAllNotifications(ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);
    final theme = Theme.of(context);

    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Notification Preferences',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // DEDICATED DAILY BRIEFING SECTION
          NeumorphicContainer(
            style: NeumorphicStyle.inset,
            borderRadius: 14,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.wb_sunny_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Daily Briefing',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Receive your personal daily overview at your preferred time.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),

                // 1. Enable Daily Briefing (ON/OFF)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Daily Briefing'),
                  value: settings.dailyBriefingEnabled,
                  onChanged: (val) {
                    notifier.setDailyBriefingEnabled(val);
                  },
                ),

                // 2. Briefing Time Picker Tile
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Briefing Time'),
                  subtitle: const Text(
                    'Local time for your morning notification',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatTimeOfDay(settings.dailyBriefingTime),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: settings.dailyBriefingEnabled
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      NeumorphicButton(
                        label: 'Change Time',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        onPressed: settings.dailyBriefingEnabled
                            ? () => _selectBriefingTime(
                                context,
                                ref,
                                settings.dailyBriefingTime,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),

                // 3. Open Daily Briefing (ON/OFF)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Open Daily Briefing App'),
                  subtitle: const Text(
                    'Navigate directly to briefing when notification is tapped',
                  ),
                  value: settings.dailyBriefingOpenApp,
                  onChanged: settings.dailyBriefingEnabled
                      ? (val) => notifier.setDailyBriefingOpenApp(val)
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),

          // Daily Summary Setting
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Daily Evening Summary'),
            subtitle: Text(
              'Receive evening recap at ${formatTimeOfDay(settings.dailySummaryTime)}',
            ),
            value: settings.dailySummaryEnabled,
            onChanged: (val) {
              notifier.updateSettings(
                settings.copyWith(dailySummaryEnabled: val),
              );
              NotificationService().rescheduleAllNotifications(ref);
            },
            secondary: IconButton(
              icon: const Icon(Icons.access_time),
              tooltip: 'Change summary time',
              onPressed: () {
                _selectSummaryTime(context, ref, settings.dailySummaryTime);
              },
            ),
          ),
          const Divider(),

          // Individual Notification Toggles
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Task Reminders'),
            subtitle: const Text('Alerts before tasks are due'),
            value: settings.taskRemindersEnabled,
            onChanged: (val) {
              notifier.updateSettings(
                settings.copyWith(taskRemindersEnabled: val),
              );
              NotificationService().rescheduleAllNotifications(ref);
            },
          ),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Due Tasks'),
            subtitle: const Text('Notify when task reaches due time'),
            value: settings.dueTaskNotificationsEnabled,
            onChanged: (val) {
              notifier.updateSettings(
                settings.copyWith(dueTaskNotificationsEnabled: val),
              );
            },
          ),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Overdue Tasks'),
            subtitle: const Text('Notify when tasks become overdue'),
            value: settings.overdueNotificationsEnabled,
            onChanged: (val) {
              notifier.updateSettings(
                settings.copyWith(overdueNotificationsEnabled: val),
              );
            },
          ),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Budget Alerts'),
            subtitle: const Text('Notify when budgets hit 80% or 100%'),
            value: settings.budgetAlertsEnabled,
            onChanged: (val) {
              notifier.updateSettings(
                settings.copyWith(budgetAlertsEnabled: val),
              );
            },
          ),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Subscription Reminders'),
            subtitle: const Text('Remind 3 days before renewal'),
            value: settings.subscriptionAlertsEnabled,
            onChanged: (val) {
              notifier.updateSettings(
                settings.copyWith(subscriptionAlertsEnabled: val),
              );
              NotificationService().rescheduleAllNotifications(ref);
            },
          ),
        ],
      ),
    );
  }
}

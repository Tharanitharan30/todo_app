import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../services/notification_service.dart';

class NotificationSettingsSection extends ConsumerWidget {
  const NotificationSettingsSection({super.key});

  Future<void> _selectTime(
    BuildContext context,
    WidgetRef ref,
    TimeOfDay initialTime,
    Function(TimeOfDay) onTimeSelected,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      onTimeSelected(picked);
      // Trigger notification rescheduling
      Future.microtask(
        () => NotificationService().rescheduleAllNotifications(ref),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications_active_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Notification Preferences',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Daily Briefing Setting
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Daily Briefing'),
              subtitle: Text(
                'Receive morning summary at ${_formatTimeOfDay(settings.dailyBriefingTime)}',
              ),
              value: settings.dailyBriefingEnabled,
              onChanged: (val) {
                notifier.updateSettings(
                  settings.copyWith(dailyBriefingEnabled: val),
                );
                NotificationService().rescheduleAllNotifications(ref);
              },
              secondary: IconButton(
                icon: const Icon(Icons.access_time),
                tooltip: 'Change briefing time',
                onPressed: () {
                  _selectTime(context, ref, settings.dailyBriefingTime, (
                    newTime,
                  ) {
                    notifier.updateSettings(
                      settings.copyWith(dailyBriefingTime: newTime),
                    );
                  });
                },
              ),
            ),
            const Divider(),

            // Daily Summary Setting
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Daily Evening Summary'),
              subtitle: Text(
                'Receive evening recap at ${_formatTimeOfDay(settings.dailySummaryTime)}',
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
                  _selectTime(context, ref, settings.dailySummaryTime, (
                    newTime,
                  ) {
                    notifier.updateSettings(
                      settings.copyWith(dailySummaryTime: newTime),
                    );
                  });
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

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expense Reminders'),
              subtitle: const Text('Daily reminder to log expenses'),
              value: settings.expenseRemindersEnabled,
              onChanged: (val) {
                notifier.updateSettings(
                  settings.copyWith(expenseRemindersEnabled: val),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../providers/database_provider.dart';
import '../providers/settings_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Function(String?)? _onPayloadTap;

  bool get isInitialized => _initialized;

  Future<void> init({Function(String?)? onPayloadTap}) async {
    if (_initialized) return;

    if (onPayloadTap != null) {
      _onPayloadTap = onPayloadTap;
    }

    try {
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        linux: linuxSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
          if (_onPayloadTap != null) {
            _onPayloadTap!(response.payload);
          }
        },
      );

      _initialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  Future<void> requestPermissions() async {
    if (!_initialized) await init();
    try {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String type = 'generic',
  }) async {
    if (!_initialized) await init();

    try {
      const androidDetails = AndroidNotificationDetails(
        'general_channel',
        'General Notifications',
        channelDescription: 'Notifications for app events',
        importance: Importance.high,
        priority: Priority.high,
      );
      const linuxDetails = LinuxNotificationDetails();
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        linux: linuxDetails,
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing immediate notification: $e');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    String type = 'generic',
  }) async {
    if (!_initialized) await init();

    if (scheduledDate.isBefore(DateTime.now())) {
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'scheduled_channel',
        'Scheduled Reminders',
        channelDescription: 'Timezone-aware scheduled reminders',
        importance: Importance.high,
        priority: Priority.high,
      );
      const linuxDetails = LinuxNotificationDetails();
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        linux: linuxDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint('Scheduled notification #$id ("$title") for $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    if (!_initialized) await init();
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint('Error cancelling notification #$id: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!_initialized) await init();
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  // ----------------------------------------------------
  // Task Reminders & Due Notifications
  // ----------------------------------------------------

  Future<void> scheduleTaskReminder({
    required int taskId,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final notifId = 10000 + taskId;
    await scheduleNotification(
      id: notifId,
      title: 'Task Reminder: $title',
      body: body,
      scheduledDate: scheduledDate,
      payload: 'task:$taskId',
      type: 'task_reminder',
    );
  }

  Future<void> scheduleTaskDue({
    required int taskId,
    required String title,
    required DateTime dueDateTime,
  }) async {
    final notifId = 20000 + taskId;
    await scheduleNotification(
      id: notifId,
      title: 'Task Due',
      body: '"$title" is due now.',
      scheduledDate: dueDateTime,
      payload: 'task:$taskId',
      type: 'task_due',
    );
  }

  Future<void> cancelTaskNotifications(int taskId) async {
    await cancelNotification(10000 + taskId);
    await cancelNotification(20000 + taskId);
    await cancelNotification(30000 + taskId);
  }

  // ----------------------------------------------------
  // Daily Briefing & Daily Summary
  // ----------------------------------------------------

  Future<void> scheduleDailyBriefing({
    required TimeOfDay time,
    required String body,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await cancelNotification(40000);
    await scheduleNotification(
      id: 40000,
      title: 'Good Morning ☀️',
      body: body,
      scheduledDate: scheduledDate,
      payload: 'briefing',
      type: 'daily_briefing',
    );
  }

  Future<void> scheduleDailySummary({
    required TimeOfDay time,
    required String body,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await cancelNotification(50000);
    await scheduleNotification(
      id: 50000,
      title: 'Daily Summary 🌙',
      body: body,
      scheduledDate: scheduledDate,
      payload: 'summary',
      type: 'daily_summary',
    );
  }

  // ----------------------------------------------------
  // Budget & Subscription Alerts
  // ----------------------------------------------------

  Future<void> showBudgetAlert({
    required String category,
    required double percentage,
    required double spent,
    required double budget,
  }) async {
    final notifId = 60000 + category.hashCode.abs() % 10000;
    final isExceeded = percentage >= 100;
    final title = isExceeded
        ? 'Budget Exceeded: $category'
        : 'Budget Warning ($percentage%): $category';
    final body =
        '₹${spent.toStringAsFixed(0)} / ₹${budget.toStringAsFixed(0)} used for $category.';

    await showImmediateNotification(
      id: notifId,
      title: title,
      body: body,
      payload: 'budget:$category',
      type: isExceeded ? 'budget_exceeded' : 'budget_warning',
    );
  }

  Future<void> scheduleSubscriptionReminder({
    required int subscriptionId,
    required String subscriptionName,
    required DateTime nextBillingDate,
    int daysBefore = 3,
  }) async {
    final notifId = 70000 + subscriptionId;
    final reminderDate = nextBillingDate
        .subtract(Duration(days: daysBefore))
        .copyWith(hour: 9, minute: 0, second: 0);

    if (reminderDate.isBefore(DateTime.now())) return;

    await scheduleNotification(
      id: notifId,
      title: 'Subscription Reminder: $subscriptionName',
      body: 'Upcoming payment due on ${_formatDate(nextBillingDate)}',
      scheduledDate: reminderDate,
      payload: 'subscription:$subscriptionId',
      type: 'subscription_reminder',
    );
  }

  Future<void> cancelSubscriptionReminder(int subscriptionId) async {
    await cancelNotification(70000 + subscriptionId);
  }

  // ----------------------------------------------------
  // Master Reschedule Helper
  // ----------------------------------------------------

  Future<void> rescheduleAllNotifications(WidgetRef ref) async {
    if (!_initialized) await init();

    try {
      final settings = ref.read(notificationSettingsProvider);
      final db = ref.read(databaseProvider);

      // 1. Reschedule Daily Briefing
      if (settings.dailyBriefingEnabled) {
        final tasks = await db.getAllTasks();
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

        final todayTasks = tasks.where((t) =>
            t.dueDate != null &&
            t.dueDate!.isAfter(todayStart.subtract(const Duration(milliseconds: 1))) &&
            t.dueDate!.isBefore(todayEnd.add(const Duration(milliseconds: 1)))).toList();
        final highPriority = todayTasks.where((t) => t.priority == 'urgent' || t.priority == 'high').length;

        final body = 'You have ${todayTasks.length} tasks today ($highPriority high priority). Tap to view briefing.';
        await scheduleDailyBriefing(time: settings.dailyBriefingTime, body: body);
      } else {
        await cancelNotification(40000);
      }

      // 2. Reschedule Daily Summary
      if (settings.dailySummaryEnabled) {
        final tasks = await db.getAllTasks();
        final completedToday = tasks.where((t) =>
            t.status == 'completed' &&
            t.completedAt != null &&
            t.completedAt!.year == DateTime.now().year &&
            t.completedAt!.month == DateTime.now().month &&
            t.completedAt!.day == DateTime.now().day).length;

        final body = 'Completed $completedToday tasks today. Tap for full summary.';
        await scheduleDailySummary(time: settings.dailySummaryTime, body: body);
      } else {
        await cancelNotification(50000);
      }

      // 3. Reschedule Task Reminders
      if (settings.taskRemindersEnabled) {
        final tasks = await db.getAllTasks();
        for (final t in tasks) {
          if (t.status != 'completed' && t.reminderAt != null && t.reminderAt!.isAfter(DateTime.now())) {
            await scheduleTaskReminder(
              taskId: t.id,
              title: t.title,
              body: 'Due soon at ${_formatTime(t.dueTime ?? t.reminderAt!)}',
              scheduledDate: t.reminderAt!,
            );
          }
        }
      }

      // 4. Reschedule Subscriptions
      if (settings.subscriptionAlertsEnabled) {
        final subs = await db.getAllSubscriptions();
        for (final sub in subs) {
          if (sub.active) {
            await scheduleSubscriptionReminder(
              subscriptionId: sub.id,
              subscriptionName: sub.name,
              nextBillingDate: sub.nextBillingDate,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error rescheduling notifications: $e');
    }
  }

  static String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
  static String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

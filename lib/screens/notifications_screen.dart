import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'task_reminder':
      case 'task_due':
        return Icons.alarm;
      case 'overdue_task':
        return Icons.warning_amber_rounded;
      case 'daily_briefing':
        return Icons.wb_sunny_outlined;
      case 'daily_summary':
        return Icons.nights_stay_outlined;
      case 'budget_warning':
      case 'budget_exceeded':
        return Icons.account_balance_wallet_outlined;
      case 'subscription_reminder':
        return Icons.subscriptions_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'overdue_task':
      case 'budget_exceeded':
        return Colors.red;
      case 'budget_warning':
        return Colors.orange;
      case 'daily_briefing':
        return Colors.amber[800]!;
      case 'daily_summary':
        return Colors.purple;
      case 'subscription_reminder':
        return Colors.deepPurple;
      default:
        return Colors.blue;
    }
  }

  void _onNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification item,
  ) {
    final db = ref.read(databaseProvider);
    if (!item.read) {
      db.markNotificationAsRead(item.id);
    }

    final payload = item.payload;
    if (payload != null && payload.isNotEmpty) {
      if (payload == 'briefing' || payload == 'summary') {
        context.go('/briefing');
      } else if (payload.startsWith('task:')) {
        context.go('/tasks');
      } else if (payload.startsWith('budget:') ||
          payload.startsWith('subscription:')) {
        context.go('/finance');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(appNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification History'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) async {
              final db = ref.read(databaseProvider);
              if (val == 'read_all') {
                await db.markAllNotificationsAsRead();
              } else if (val == 'clear_all') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear All Notifications'),
                    content: const Text(
                      'Are you sure you want to clear all notification history?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await db.clearAllNotifications();
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'read_all',
                child: Row(
                  children: [
                    Icon(Icons.done_all, size: 18),
                    SizedBox(width: 8),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Clear all history',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No notification history yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Group by date
          final Map<String, List<AppNotification>> grouped = {};
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final yesterdayStart = todayStart.subtract(const Duration(days: 1));

          for (final item in list) {
            final itemStart = DateTime(
              item.createdAt.year,
              item.createdAt.month,
              item.createdAt.day,
            );
            String header;
            if (itemStart == todayStart) {
              header = 'Today';
            } else if (itemStart == yesterdayStart) {
              header = 'Yesterday';
            } else {
              header =
                  '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}';
            }
            grouped.putIfAbsent(header, () => []).add(item);
          }

          final entries = grouped.entries.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ...entry.value.map((item) {
                    final color = _getTypeColor(item.type);
                    final icon = _getTypeIcon(item.type);
                    final timeStr =
                        '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}';

                    return Dismissible(
                      key: Key('notif_${item.id}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        ref
                            .read(databaseProvider)
                            .deleteAppNotification(item.id);
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: item.read ? 0 : 1,
                        color: item.read ? null : color.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: item.read
                                ? Theme.of(
                                    context,
                                  ).dividerColor.withValues(alpha: 0.2)
                                : color.withValues(alpha: 0.4),
                          ),
                        ),
                        child: ListTile(
                          onTap: () => _onNotificationTap(context, ref, item),
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.15),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: item.read
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!item.read)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(item.body),
                              const SizedBox(height: 4),
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

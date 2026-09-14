import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/finance_provider.dart';
import '../providers/focus_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';

class DailyBriefingScreen extends ConsumerWidget {
  const DailyBriefingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final financeSummaryAsync = ref.watch(financeSummaryProvider);
    final expensesAsync = ref.watch(expensesStreamProvider);

    final now = DateTime.now();
    const weekdayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final dateString =
        '${weekdayNames[now.weekday - 1]}, ${monthNames[now.month - 1]} ${now.day}';

    final greeting = now.hour < 12
        ? 'Good Morning ☀️'
        : (now.hour < 17 ? 'Good Afternoon 🌤️' : 'Good Evening 🌙');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Briefing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(tasksProvider);
              ref.invalidate(expensesStreamProvider);
            },
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading briefing: $err')),
        data: (allTasks) {
          final todayStart = DateTime(now.year, now.month, now.day);
          final todayEnd = DateTime(
            now.year,
            now.month,
            now.day,
            23,
            59,
            59,
            999,
          );

          final todayTasks = allTasks
              .where(
                (t) =>
                    t.dueDate != null &&
                    t.dueDate!.isAfter(
                      todayStart.subtract(const Duration(milliseconds: 1)),
                    ) &&
                    t.dueDate!.isBefore(
                      todayEnd.add(const Duration(milliseconds: 1)),
                    ),
              )
              .toList();

          final highPriorityCount = todayTasks
              .where((t) => t.priority == 'urgent' || t.priority == 'high')
              .length;

          final overdueTasks = allTasks
              .where(
                (t) =>
                    t.status != 'completed' &&
                    t.dueDate != null &&
                    t.dueDate!.isBefore(todayStart),
              )
              .toList();

          // Yesterday completed tasks
          final yesterdayStart = todayStart.subtract(const Duration(days: 1));
          final yesterdayEnd = todayStart.subtract(
            const Duration(milliseconds: 1),
          );
          final completedYesterday = allTasks
              .where(
                (t) =>
                    t.status == 'completed' &&
                    t.completedAt != null &&
                    t.completedAt!.isAfter(yesterdayStart) &&
                    t.completedAt!.isBefore(yesterdayEnd),
              )
              .length;

          // Today completed / rate
          final todayCompleted = todayTasks
              .where((t) => t.status == 'completed')
              .length;
          final todayRate = todayTasks.isEmpty
              ? 0.0
              : (todayCompleted / todayTasks.length) * 100;

          // Today's spending
          final expenses = expensesAsync.value ?? [];
          final todaySpent = expenses
              .where(
                (e) =>
                    e.date.isAfter(
                      todayStart.subtract(const Duration(milliseconds: 1)),
                    ) &&
                    e.date.isBefore(
                      todayEnd.add(const Duration(milliseconds: 1)),
                    ),
              )
              .fold(0.0, (sum, e) => sum + e.amount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateString,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Today's Tasks Card
                _buildSectionCard(
                  context,
                  title: "Today's Tasks",
                  icon: Icons.task_alt,
                  color: Colors.blue,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (todayTasks.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No tasks scheduled for today. Take a break or add new tasks!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else ...[
                        ...todayTasks.map(
                          (t) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  t.status == 'completed'
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: t.status == 'completed'
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    t.title,
                                    style: TextStyle(
                                      decoration: t.status == 'completed'
                                          ? TextDecoration.lineThrough
                                          : null,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (t.priority == 'urgent' ||
                                    t.priority == 'high')
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(
                                      t.priority.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    backgroundColor: Colors.red.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${todayTasks.length} tasks today',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '$highPriorityCount high priority',
                              style: TextStyle(
                                color: highPriorityCount > 0
                                    ? Colors.red
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Overdue Section
                if (overdueTasks.isNotEmpty) ...[
                  _buildSectionCard(
                    context,
                    title: 'Overdue Tasks',
                    icon: Icons.warning_amber_rounded,
                    color: Colors.red,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You have ${overdueTasks.length} overdue task(s):',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        ...overdueTasks.map(
                          (t) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '• ${t.title}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. Finance Section
                financeSummaryAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                  data: (summary) {
                    return _buildSectionCard(
                      context,
                      title: 'Finance Overview',
                      icon: Icons.account_balance_wallet_outlined,
                      color: Colors.teal,
                      child: Column(
                        children: [
                          _financeRow(
                            "Today's spending",
                            '₹${todaySpent.toStringAsFixed(0)}',
                          ),
                          _financeRow(
                            "This month's spending",
                            '₹${summary.expenses.toStringAsFixed(0)}',
                          ),
                          _financeRow(
                            "This month's income",
                            '₹${summary.income.toStringAsFixed(0)}',
                          ),
                          const Divider(),
                          _financeRow(
                            'Current balance',
                            '₹${summary.balance.toStringAsFixed(0)}',
                            isBold: true,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // 4. Productivity Summary
                _buildSectionCard(
                  context,
                  title: 'Productivity Summary',
                  icon: Icons.speed_outlined,
                  color: Colors.purple,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Completed Yesterday',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '$completedYesterday tasks',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Completion Rate",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${todayRate.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 5. Smart Recommendations & Focus Action Button
                Consumer(
                  builder: (context, ref, _) {
                    final todayFocusSeconds = ref.watch(
                      todayFocusTimeSecondsProvider,
                    );
                    final todayFocusSessions = ref.watch(
                      todayFocusSessionsProvider,
                    );
                    final completedSessions = todayFocusSessions
                        .where((s) => s.completed)
                        .length;
                    final settings = ref.watch(appSettingsProvider);

                    final hours = todayFocusSeconds ~/ 3600;
                    final mins = (todayFocusSeconds % 3600) ~/ 60;
                    final timeFormatted = hours > 0
                        ? '${hours}h ${mins}m'
                        : '${mins}m';
                    final goalHours = settings.dailyFocusGoalHours;

                    return _buildSectionCard(
                      context,
                      title: "Today's Focus",
                      icon: Icons.center_focus_strong,
                      color: Colors.amber[800]!,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    timeFormatted,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '$completedSessions sessions done (Goal: ${goalHours.toStringAsFixed(1)}h)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              IconButton.filledTonal(
                                onPressed: () => context.go('/focus'),
                                icon: const Icon(Icons.timer_outlined),
                                tooltip: 'Focus Mode',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (overdueTasks.isNotEmpty)
                            const Text(
                              '💡 You have overdue tasks. Consider clearing them first before starting new tasks.',
                              style: TextStyle(fontSize: 13),
                            )
                          else if (highPriorityCount > 0)
                            Text(
                              '💡 Focus on your $highPriorityCount high-priority task(s) first today.',
                              style: const TextStyle(fontSize: 13),
                            )
                          else
                            const Text(
                              '💡 Your schedule is clear. Great day to work on long-term goals!',
                              style: TextStyle(fontSize: 13),
                            ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => context.go('/focus'),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start Focus Session'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _financeRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

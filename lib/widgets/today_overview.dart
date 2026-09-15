import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/finance_provider.dart';
import '../providers/focus_provider.dart';
import '../providers/task_provider.dart';
import '../utils/currency_formatter.dart';
import 'neumorphic_card.dart';

class TodayOverview extends ConsumerWidget {
  const TodayOverview({super.key});

  String _formatSeconds(int seconds) {
    if (seconds <= 0) return '0m';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final focusSeconds = ref.watch(todayFocusTimeSecondsProvider);
    final expensesAsync = ref.watch(expensesStreamProvider);

    final now = DateTime.now();

    final allTasks = tasksAsync.value ?? [];
    final todayTasks = allTasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == now.year &&
          t.dueDate!.month == now.month &&
          t.dueDate!.day == now.day;
    }).toList();

    final completedTodayCount = todayTasks
        .where((t) => t.status == 'completed')
        .length;
    final totalTodayCount = todayTasks.length;

    final overdueCount = allTasks
        .where(
          (t) =>
              t.status != 'completed' &&
              t.dueDate != null &&
              t.dueDate!.isBefore(DateTime(now.year, now.month, now.day)),
        )
        .length;

    final importantCount = allTasks
        .where((t) => t.isImportant && t.status != 'completed')
        .length;

    final expenses = expensesAsync.value ?? [];
    final todayExpensesSum = expenses
        .where(
          (e) =>
              e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day,
        )
        .fold<double>(0, (sum, e) => sum + e.amount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return GridView.count(
          crossAxisCount: isWide ? 5 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isWide ? 1.4 : 1.6,
          children: [
            _buildStatCard(
              context,
              title: 'Today\'s Tasks',
              value: '$completedTodayCount / $totalTodayCount',
              subtitle: 'completed',
              icon: Icons.check_circle_outline,
              color: Colors.blue,
            ),
            _buildStatCard(
              context,
              title: 'Focus Time',
              value: _formatSeconds(focusSeconds),
              subtitle: 'today',
              icon: Icons.timer_outlined,
              color: Colors.deepPurple,
            ),
            _buildStatCard(
              context,
              title: 'Spending',
              value: CurrencyFormatter.format(todayExpensesSum),
              subtitle: 'today',
              icon: Icons.account_balance_wallet_outlined,
              color: Colors.red,
            ),
            _buildStatCard(
              context,
              title: 'Overdue Tasks',
              value: '$overdueCount',
              subtitle: 'require attention',
              icon: Icons.warning_amber_rounded,
              color: overdueCount > 0 ? Colors.red : Colors.grey,
            ),
            _buildStatCard(
              context,
              title: 'Important',
              value: '$importantCount',
              subtitle: 'starred tasks',
              icon: Icons.star_outline,
              color: Colors.amber,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return NeumorphicCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

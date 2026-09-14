import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/analytics_provider.dart';

class AnalyticsStatTile extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const AnalyticsStatTile({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: isDark ? 0.2 : 0.1),
              radius: 20,
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductivityOverviewCard extends ConsumerWidget {
  const ProductivityOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(productivityOverviewProvider);

    return overviewAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Text('Error loading productivity: $err'),
      data: (overview) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Productivity Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                AnalyticsStatTile(
                  title: 'Tasks Created',
                  value: '${overview.tasksCreated}',
                  icon: Icons.task_outlined,
                  color: Colors.blue,
                ),
                AnalyticsStatTile(
                  title: 'Tasks Completed',
                  value: '${overview.tasksCompleted}',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
                AnalyticsStatTile(
                  title: 'Completion Rate',
                  value: '${overview.completionRate.toStringAsFixed(1)}%',
                  icon: Icons.pie_chart_outline,
                  color: Colors.teal,
                ),
                AnalyticsStatTile(
                  title: 'Overdue',
                  value: '${overview.overdueCount}',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class FinanceOverviewCard extends ConsumerWidget {
  const FinanceOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(financeAnalyticsOverviewProvider);

    return overviewAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, _) => Text('Error loading finance: $err'),
      data: (overview) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Finance Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                AnalyticsStatTile(
                  title: 'Income',
                  value: '₹${overview.income.toStringAsFixed(0)}',
                  icon: Icons.arrow_downward,
                  color: Colors.green,
                ),
                AnalyticsStatTile(
                  title: 'Expenses',
                  value: '₹${overview.expenses.toStringAsFixed(0)}',
                  icon: Icons.arrow_upward,
                  color: Colors.red,
                ),
                AnalyticsStatTile(
                  title: 'Balance',
                  value: '₹${overview.balance.toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet_outlined,
                  color: overview.balance >= 0 ? Colors.green : Colors.red,
                ),
                AnalyticsStatTile(
                  title: 'Savings Rate',
                  value: '${overview.savingsRate.toStringAsFixed(1)}%',
                  icon: Icons.savings_outlined,
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class KeyHighlightsCard extends ConsumerWidget {
  const KeyHighlightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlightsAsync = ref.watch(productivityHighlightProvider);
    final overviewAsync = ref.watch(productivityOverviewProvider);

    if (highlightsAsync.isLoading || overviewAsync.isLoading) {
      return const SizedBox.shrink();
    }

    final highlights = highlightsAsync.value;
    final overview = overviewAsync.value;
    if (highlights == null || overview == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Highlights & Key Metrics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            AnalyticsStatTile(
              title: 'Highest Spending',
              value: highlights.highestSpendingCategory,
              subtitle: '₹${highlights.highestSpendingAmount.toStringAsFixed(0)} (${highlights.highestSpendingPercentage.toStringAsFixed(0)}%)',
              icon: Icons.shopping_bag_outlined,
              color: Colors.deepOrange,
            ),
            AnalyticsStatTile(
              title: 'Most Productive Category',
              value: highlights.mostProductiveCategory,
              subtitle: '${highlights.mostProductiveCategoryCount} completed tasks',
              icon: Icons.category_outlined,
              color: Colors.indigo,
            ),
            AnalyticsStatTile(
              title: 'Best Day',
              value: highlights.bestProductivityDay,
              subtitle: '${highlights.bestProductivityDayCount} completed tasks',
              icon: Icons.event_available_outlined,
              color: Colors.purple,
            ),
            AnalyticsStatTile(
              title: 'Avg Daily Spending',
              value: '₹${highlights.avgDailySpending.toStringAsFixed(0)}/day',
              subtitle: 'Selected period',
              icon: Icons.price_change_outlined,
              color: Colors.teal,
            ),
            AnalyticsStatTile(
              title: 'Avg Task Completion',
              value: '${overview.avgCompletedPerDay.toStringAsFixed(1)} tasks/day',
              subtitle: 'Calendar average',
              icon: Icons.speed_outlined,
              color: Colors.amber[800]!,
            ),
          ],
        ),
      ],
    );
  }
}

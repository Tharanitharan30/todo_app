import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/analytics_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/analytics_summary_card.dart';
import '../widgets/chart_card.dart';
import '../widgets/insight_card.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  String _periodLabel(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.today:
        return 'Today';
      case AnalyticsPeriod.sevenDays:
        return '7 Days';
      case AnalyticsPeriod.thirtyDays:
        return '30 Days';
      case AnalyticsPeriod.twelveMonths:
        return '12 Months';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePeriod = ref.watch(analyticsPeriodProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final expensesAsync = ref.watch(expensesStreamProvider);

    final hasTaskData =
        tasksAsync.value != null && tasksAsync.value!.isNotEmpty;
    final hasExpenseData =
        expensesAsync.value != null && expensesAsync.value!.isNotEmpty;
    final hasData = hasTaskData || hasExpenseData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(tasksProvider);
              ref.invalidate(expensesStreamProvider);
              ref.invalidate(incomeStreamProvider);
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(tasksProvider);
              ref.invalidate(expensesStreamProvider);
              ref.invalidate(incomeStreamProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Period Selector Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Analytics',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SegmentedButton<AnalyticsPeriod>(
                        segments: [
                          ButtonSegment(
                            value: AnalyticsPeriod.today,
                            label: Text(_periodLabel(AnalyticsPeriod.today)),
                          ),
                          ButtonSegment(
                            value: AnalyticsPeriod.sevenDays,
                            label: Text(
                              _periodLabel(AnalyticsPeriod.sevenDays),
                            ),
                          ),
                          ButtonSegment(
                            value: AnalyticsPeriod.thirtyDays,
                            label: Text(
                              _periodLabel(AnalyticsPeriod.thirtyDays),
                            ),
                          ),
                          ButtonSegment(
                            value: AnalyticsPeriod.twelveMonths,
                            label: Text(
                              _periodLabel(AnalyticsPeriod.twelveMonths),
                            ),
                          ),
                        ],
                        selected: {activePeriod},
                        onSelectionChanged: (selected) {
                          ref
                              .read(analyticsPeriodProvider.notifier)
                              .setPeriod(selected.first);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Empty State Handling
                  if (!hasData)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.analytics_outlined,
                              size: 72,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No data yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add some tasks or transactions to see your analytics.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Rule-based Insights Section
                    const InsightCardSection(),
                    const SizedBox(height: 16),

                    // Productivity Overview Grid
                    const ProductivityOverviewCard(),
                    const SizedBox(height: 16),

                    // Key Highlights Grid
                    const KeyHighlightsCard(),
                    const SizedBox(height: 16),

                    // Responsive Section Layout
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: const [
                                TaskCompletionChartCard(),
                                SizedBox(height: 16),
                                FocusTrendChartCard(),
                                SizedBox(height: 16),
                                CategoryProductivityCard(),
                                SizedBox(height: 16),
                                TaskStatusChartCard(),
                                SizedBox(height: 16),
                                DailySpendingChartCard(),
                                SizedBox(height: 16),
                                SavingsTrendChartCard(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: const [
                                TasksCreatedVsCompletedChartCard(),
                                SizedBox(height: 16),
                                PriorityAnalysisCard(),
                                SizedBox(height: 16),
                                FinanceOverviewCard(),
                                SizedBox(height: 16),
                                ExpenseCategoryChartCard(),
                                SizedBox(height: 16),
                                MonthlyExpensesChartCard(),
                                SizedBox(height: 16),
                                BudgetAnalyticsCard(),
                                SizedBox(height: 16),
                                SubscriptionAnalyticsCard(),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: const [
                          TaskCompletionChartCard(),
                          SizedBox(height: 16),
                          FocusTrendChartCard(),
                          SizedBox(height: 16),
                          TasksCreatedVsCompletedChartCard(),
                          SizedBox(height: 16),
                          CategoryProductivityCard(),
                          SizedBox(height: 16),
                          PriorityAnalysisCard(),
                          SizedBox(height: 16),
                          TaskStatusChartCard(),
                          SizedBox(height: 16),
                          FinanceOverviewCard(),
                          SizedBox(height: 16),
                          ExpenseCategoryChartCard(),
                          SizedBox(height: 16),
                          DailySpendingChartCard(),
                          SizedBox(height: 16),
                          MonthlyExpensesChartCard(),
                          SizedBox(height: 16),
                          SavingsTrendChartCard(),
                          SizedBox(height: 16),
                          BudgetAnalyticsCard(),
                          SizedBox(height: 16),
                          SubscriptionAnalyticsCard(),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

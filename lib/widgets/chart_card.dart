import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/analytics_provider.dart';

class ChartCard extends ConsumerWidget {
  const ChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: const [
          ExpenseCategoryChartCard(),
          SizedBox(height: 16),
          DailySpendingChartCard(),
          SizedBox(height: 16),
          MonthlyExpensesChartCard(),
          SizedBox(height: 16),
          SavingsTrendChartCard(),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 3. Task Completion Line Chart
// ----------------------------------------------------

class TaskCompletionChartCard extends ConsumerWidget {
  const TaskCompletionChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completionAsync = ref.watch(taskCompletionTrendProvider);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Completion Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            completionAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text('Error: $err'),
              data: (points) {
                if (points.isEmpty) {
                  return const SizedBox(
                    height: 180,
                    child: Center(
                      child: Text('No task completion data available'),
                    ),
                  );
                }

                int maxCount = 5;
                for (final p in points) {
                  if (p.count > maxCount) maxCount = p.count;
                }

                final spots = List.generate(points.length, (i) {
                  return FlSpot(i.toDouble(), points[i].count.toDouble());
                });

                return SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              if (idx >= 0 && idx < points.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    points[idx].label,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (val, meta) {
                              if (val % 1 == 0) {
                                return Text(
                                  val.toInt().toString(),
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (points.length - 1).toDouble(),
                      minY: 0,
                      maxY: (maxCount * 1.2).toDouble(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.green.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 4. Tasks Created vs Completed Grouped Bar Chart
// ----------------------------------------------------

class TasksCreatedVsCompletedChartCard extends ConsumerWidget {
  const TasksCreatedVsCompletedChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonAsync = ref.watch(tasksCreatedVsCompletedProvider);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Created vs Completed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    _legendDot('Created', Colors.blue),
                    const SizedBox(width: 12),
                    _legendDot('Completed', Colors.green),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            comparisonAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text('Error: $err'),
              data: (points) {
                if (points.isEmpty) {
                  return const SizedBox(
                    height: 180,
                    child: Center(
                      child: Text('No task activity data available'),
                    ),
                  );
                }

                double maxY = 5;
                for (final p in points) {
                  if (p.created > maxY) maxY = p.created.toDouble();
                  if (p.completed > maxY) maxY = p.completed.toDouble();
                }

                final groups = List.generate(points.length, (i) {
                  final p = points[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: p.created.toDouble(),
                        color: Colors.blue,
                        width: 10,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      BarChartRodData(
                        toY: p.completed.toDouble(),
                        color: Colors.green,
                        width: 10,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  );
                });

                return SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY * 1.2,
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              if (idx >= 0 && idx < points.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    points[idx].label,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (val, meta) {
                              if (val % 1 == 0) {
                                return Text(
                                  val.toInt().toString(),
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      barGroups: groups,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// 5. Category Productivity (Horizontal Progress Bars)
// ----------------------------------------------------

class CategoryProductivityCard extends ConsumerWidget {
  const CategoryProductivityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(categoryProductivityProvider);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Productivity by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            categoryAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text('Error: $err'),
              data: (categories) {
                if (categories.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No completed tasks by category'),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final item = categories[index];
                    final progress = (item.percentage / 100).clamp(0.0, 1.0);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${item.completedCount} tasks (${item.percentage.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.grey.withValues(
                                alpha: 0.15,
                              ),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 6. Priority Analysis & Completion Rates
// ----------------------------------------------------

class PriorityAnalysisCard extends ConsumerWidget {
  const PriorityAnalysisCard({super.key});

  Color _getPriorityColor(String prio) {
    switch (prio.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priorityAsync = ref.watch(priorityAnalysisProvider);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Priority Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            priorityAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text('Error: $err'),
              data: (list) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final color = _getPriorityColor(item.priority);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.2),
                            radius: 14,
                            child: Icon(Icons.flag, color: color, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.priority,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: color,
                                  ),
                                ),
                                Text(
                                  '${item.completedTasks} of ${item.totalTasks} tasks completed',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${item.completionRate.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 7. Task Status Donut Chart
// ----------------------------------------------------

class TaskStatusChartCard extends ConsumerWidget {
  const TaskStatusChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(taskStatusDistributionProvider);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Status Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            statusAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text('Error: $err'),
              data: (dist) {
                final total =
                    dist.pending +
                    dist.completed +
                    dist.overdue +
                    dist.important;
                if (total == 0) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No tasks recorded')),
                  );
                }

                final sections = [
                  if (dist.completed > 0)
                    PieChartSectionData(
                      color: Colors.green,
                      value: dist.completed.toDouble(),
                      title: '${dist.completed}',
                      radius: 40,
                      titleStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (dist.pending > 0)
                    PieChartSectionData(
                      color: Colors.blue,
                      value: dist.pending.toDouble(),
                      title: '${dist.pending}',
                      radius: 40,
                      titleStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (dist.overdue > 0)
                    PieChartSectionData(
                      color: Colors.red,
                      value: dist.overdue.toDouble(),
                      title: '${dist.overdue}',
                      radius: 40,
                      titleStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (dist.important > 0)
                    PieChartSectionData(
                      color: Colors.amber,
                      value: dist.important.toDouble(),
                      title: '${dist.important}',
                      radius: 40,
                      titleStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ];

                return Column(
                  children: [
                    SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _statusDot('Completed', dist.completed, Colors.green),
                        _statusDot('Pending', dist.pending, Colors.blue),
                        _statusDot('Overdue', dist.overdue, Colors.red),
                        _statusDot('Important', dist.important, Colors.amber),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusDot(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// 9. Expense Category Pie Chart
// ----------------------------------------------------

class ExpenseCategoryChartCard extends ConsumerWidget {
  const ExpenseCategoryChartCard({super.key});

  static const List<Color> _colors = [
    Colors.teal,
    Colors.orange,
    Colors.purple,
    Colors.blue,
    Colors.redAccent,
    Colors.green,
    Colors.amber,
    Colors.indigo,
    Colors.deepOrange,
    Colors.pink,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(expenseCategoryAnalysisProvider);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense Category Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            categoriesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text('Error: $err'),
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No expense records for selected period'),
                    ),
                  );
                }

                final sections = List.generate(list.length, (i) {
                  final cat = list[i];
                  final color = _colors[i % _colors.length];
                  return PieChartSectionData(
                    color: color,
                    value: cat.amount,
                    title: cat.percentage >= 8
                        ? '${cat.percentage.toStringAsFixed(0)}%'
                        : '',
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  );
                });

                return Column(
                  children: [
                    SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: List.generate(list.length, (i) {
                        final cat = list[i];
                        final color = _colors[i % _colors.length];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cat.category,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '₹${cat.amount.toStringAsFixed(0)} (${cat.percentage.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 10. Daily Spending Trend Chart
// ----------------------------------------------------

class DailySpendingChartCard extends ConsumerWidget {
  const DailySpendingChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spendingAsync = ref.watch(dailySpendingTrendProvider);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Spending Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            spendingAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text('Error: $err'),
              data: (points) {
                if (points.isEmpty) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: Text('No daily spending records')),
                  );
                }

                double maxAmt = 100;
                for (final p in points) {
                  if (p.amount > maxAmt) maxAmt = p.amount;
                }

                final spots = List.generate(points.length, (i) {
                  return FlSpot(i.toDouble(), points[i].amount);
                });

                return SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              if (idx >= 0 && idx < points.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    points[idx].label,
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (val, meta) {
                              if (val == 0) return const Text('0');
                              if (val >= 1000) {
                                return Text(
                                  '₹${(val / 1000).toStringAsFixed(0)}k',
                                  style: const TextStyle(fontSize: 9),
                                );
                              }
                              return Text(
                                '₹${val.toInt()}',
                                style: const TextStyle(fontSize: 9),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (points.length - 1).toDouble(),
                      minY: 0,
                      maxY: maxAmt * 1.2,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.redAccent,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.redAccent.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 11. Monthly Expenses Bar Chart
// ----------------------------------------------------

class MonthlyExpensesChartCard extends ConsumerWidget {
  const MonthlyExpensesChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyAsync = ref.watch(monthlySpendingTrendProvider);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Expenses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            monthlyAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text('Error: $err'),
              data: (points) {
                if (points.isEmpty) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: Text('No monthly expense records')),
                  );
                }

                double maxAmt = 100;
                for (final p in points) {
                  if (p.expense > maxAmt) maxAmt = p.expense;
                }

                final groups = List.generate(points.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: points[i].expense,
                        color: Colors.deepOrange,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                });

                return SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxAmt * 1.2,
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              if (idx >= 0 && idx < points.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    points[idx].monthLabel,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (val, meta) {
                              if (val == 0) return const Text('0');
                              if (val >= 1000) {
                                return Text(
                                  '₹${(val / 1000).toStringAsFixed(0)}k',
                                  style: const TextStyle(fontSize: 9),
                                );
                              }
                              return Text(
                                '₹${val.toInt()}',
                                style: const TextStyle(fontSize: 9),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      barGroups: groups,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 13 & 14. Savings & Savings Rate Trend Line Charts
// ----------------------------------------------------

class SavingsTrendChartCard extends ConsumerWidget {
  const SavingsTrendChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsync = ref.watch(savingsTrendProvider);
    final rateAsync = ref.watch(savingsRateTrendProvider);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Savings & Savings Rate Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            savingsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text('Error: $err'),
              data: (points) {
                if (points.isEmpty) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: Text('No savings trend data')),
                  );
                }

                double maxSavings = 100;
                for (final p in points) {
                  if (p.savings > maxSavings) maxSavings = p.savings;
                }

                final spots = List.generate(points.length, (i) {
                  return FlSpot(i.toDouble(), points[i].savings);
                });

                return Column(
                  children: [
                    SizedBox(
                      height: 180,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(
                            show: true,
                            drawVerticalLine: false,
                          ),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  final idx = val.toInt();
                                  if (idx >= 0 && idx < points.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        points[idx].monthLabel,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 36,
                                getTitlesWidget: (val, meta) {
                                  if (val >= 1000) {
                                    return Text(
                                      '₹${(val / 1000).toStringAsFixed(0)}k',
                                      style: const TextStyle(fontSize: 9),
                                    );
                                  }
                                  return Text(
                                    '₹${val.toInt()}',
                                    style: const TextStyle(fontSize: 9),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: (points.length - 1).toDouble(),
                          minY: 0,
                          maxY: maxSavings * 1.2,
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: Colors.teal,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.teal.withValues(alpha: 0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    rateAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (err, stack) => const SizedBox.shrink(),
                      data: (rateList) {
                        return Wrap(
                          spacing: 12,
                          children: rateList.map((r) {
                            return Chip(
                              label: Text(
                                '${r.monthLabel}: ${r.rate.toStringAsFixed(0)}% rate',
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: Colors.teal.withValues(
                                alpha: 0.1,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 15. Budget Analytics Utilization Card
// ----------------------------------------------------

class BudgetAnalyticsCard extends ConsumerWidget {
  const BudgetAnalyticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetSummaryAsync = ref.watch(budgetAnalyticsProvider);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Utilization Analytics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            budgetSummaryAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text('Error: $err'),
              data: (summary) {
                final progress = (summary.utilizationPercentage / 100).clamp(
                  0.0,
                  1.0,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Spent: ₹${summary.totalSpent.toStringAsFixed(0)} / ₹${summary.totalBudget.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${summary.utilizationPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey.withValues(alpha: 0.15),
                        color: summary.utilizationPercentage >= 100
                            ? Colors.red
                            : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statusBadge('Safe', summary.safeCount, Colors.green),
                        _statusBadge(
                          'Warning',
                          summary.warningCount,
                          Colors.orange,
                        ),
                        _statusBadge(
                          'Critical',
                          summary.criticalCount,
                          Colors.deepOrange,
                        ),
                        _statusBadge(
                          'Exceeded',
                          summary.exceededCount,
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ----------------------------------------------------
// 16. Subscription Analytics Card
// ----------------------------------------------------

class SubscriptionAnalyticsCard extends ConsumerWidget {
  const SubscriptionAnalyticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subSummaryAsync = ref.watch(subscriptionAnalyticsProvider);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subscription Analytics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            subSummaryAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text('Error: $err'),
              data: (subSummary) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metricBox(
                          'Active',
                          '${subSummary.activeCount}',
                          Colors.deepPurple,
                        ),
                        _metricBox(
                          'Monthly Cost',
                          '₹${subSummary.monthlyCost.toStringAsFixed(0)}',
                          Colors.indigo,
                        ),
                        _metricBox(
                          'Yearly Cost',
                          '₹${subSummary.yearlyCost.toStringAsFixed(0)}',
                          Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: subSummary.countByCycle.entries.map((e) {
                        return Chip(
                          label: Text('${e.key}: ${e.value}'),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBox(String title, String val, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ----------------------------------------------------
// Focus Trend Line Chart
// ----------------------------------------------------

class FocusTrendChartCard extends ConsumerWidget {
  const FocusTrendChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusTrendAsync = ref.watch(focusAnalyticsTrendProvider);
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Focus Time Trend (Minutes)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.timer, color: theme.colorScheme.primary, size: 20),
              ],
            ),
            const SizedBox(height: 20),
            focusTrendAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text('Error loading focus trend: $err'),
              data: (points) {
                if (points.isEmpty) {
                  return const SizedBox(
                    height: 180,
                    child: Center(
                      child: Text('No focus data available for this period'),
                    ),
                  );
                }

                int maxMins = 30;
                for (final p in points) {
                  if (p.minutes > maxMins) maxMins = p.minutes;
                }

                final spots = List.generate(points.length, (i) {
                  return FlSpot(i.toDouble(), points[i].minutes.toDouble());
                });

                return SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              if (idx >= 0 && idx < points.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    points[idx].label,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: (maxMins * 1.2).toDouble(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: theme.colorScheme.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

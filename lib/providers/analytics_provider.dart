import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import 'budget_provider.dart';
import 'database_provider.dart';
import 'finance_provider.dart';
import 'task_provider.dart';

enum AnalyticsPeriod { today, sevenDays, thirtyDays, twelveMonths }

// ----------------------------------------------------
// Data Models
// ----------------------------------------------------

class ProductivityOverview {
  final int tasksCreated;
  final int tasksCompleted;
  final double completionRate;
  final int overdueCount;
  final double avgCompletedPerDay;
  final int importantCount;

  const ProductivityOverview({
    required this.tasksCreated,
    required this.tasksCompleted,
    required this.completionRate,
    required this.overdueCount,
    required this.avgCompletedPerDay,
    required this.importantCount,
  });
}

class TaskCompletionPoint {
  final String label;
  final int count;
  final DateTime date;

  const TaskCompletionPoint({
    required this.label,
    required this.count,
    required this.date,
  });
}

class CreatedVsCompletedPoint {
  final String label;
  final int created;
  final int completed;

  const CreatedVsCompletedPoint({
    required this.label,
    required this.created,
    required this.completed,
  });
}

class CategoryProductivityInfo {
  final String category;
  final int completedCount;
  final double percentage;

  const CategoryProductivityInfo({
    required this.category,
    required this.completedCount,
    required this.percentage,
  });
}

class PriorityAnalysisInfo {
  final String priority;
  final int totalTasks;
  final int completedTasks;
  final double completionRate;

  const PriorityAnalysisInfo({
    required this.priority,
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
  });
}

class TaskStatusDistribution {
  final int pending;
  final int completed;
  final int overdue;
  final int important;

  const TaskStatusDistribution({
    required this.pending,
    required this.completed,
    required this.overdue,
    required this.important,
  });
}

class FinanceOverviewData {
  final double income;
  final double expenses;
  final double balance;
  final double savingsRate;

  const FinanceOverviewData({
    required this.income,
    required this.expenses,
    required this.balance,
    required this.savingsRate,
  });
}

class ExpenseCategoryData {
  final String category;
  final double amount;
  final double percentage;

  const ExpenseCategoryData({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class SpendingTrendPoint {
  final String label;
  final double amount;
  final DateTime date;

  const SpendingTrendPoint({
    required this.label,
    required this.amount,
    required this.date,
  });
}

class MonthlyExpensePoint {
  final String monthLabel;
  final double expense;

  const MonthlyExpensePoint({required this.monthLabel, required this.expense});
}

class IncomeVsExpensePoint {
  final String monthLabel;
  final double income;
  final double expense;

  const IncomeVsExpensePoint({
    required this.monthLabel,
    required this.income,
    required this.expense,
  });
}

class SavingsTrendPoint {
  final String monthLabel;
  final double savings;

  const SavingsTrendPoint({required this.monthLabel, required this.savings});
}

class SavingsRateTrendPoint {
  final String monthLabel;
  final double rate;

  const SavingsRateTrendPoint({required this.monthLabel, required this.rate});
}

class BudgetAnalyticsSummary {
  final double totalBudget;
  final double totalSpent;
  final double remaining;
  final double utilizationPercentage;
  final int safeCount;
  final int warningCount;
  final int criticalCount;
  final int exceededCount;

  const BudgetAnalyticsSummary({
    required this.totalBudget,
    required this.totalSpent,
    required this.remaining,
    required this.utilizationPercentage,
    required this.safeCount,
    required this.warningCount,
    required this.criticalCount,
    required this.exceededCount,
  });
}

class SubscriptionAnalyticsSummary {
  final int activeCount;
  final double monthlyCost;
  final double yearlyCost;
  final Map<String, int> countByCycle;

  const SubscriptionAnalyticsSummary({
    required this.activeCount,
    required this.monthlyCost,
    required this.yearlyCost,
    required this.countByCycle,
  });
}

class ProductivityHighlightData {
  final String highestSpendingCategory;
  final double highestSpendingAmount;
  final double highestSpendingPercentage;
  final String mostProductiveCategory;
  final int mostProductiveCategoryCount;
  final String bestProductivityDay;
  final int bestProductivityDayCount;
  final double avgDailySpending;

  const ProductivityHighlightData({
    required this.highestSpendingCategory,
    required this.highestSpendingAmount,
    required this.highestSpendingPercentage,
    required this.mostProductiveCategory,
    required this.mostProductiveCategoryCount,
    required this.bestProductivityDay,
    required this.bestProductivityDayCount,
    required this.avgDailySpending,
  });
}

class InsightItem {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String type; // positive, warning, info

  const InsightItem({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.type,
  });
}

// ----------------------------------------------------
// Active Period Notifier
// ----------------------------------------------------

class AnalyticsPeriodNotifier extends Notifier<AnalyticsPeriod> {
  @override
  AnalyticsPeriod build() => AnalyticsPeriod.thirtyDays;

  void setPeriod(AnalyticsPeriod period) => state = period;
}

final analyticsPeriodProvider =
    NotifierProvider<AnalyticsPeriodNotifier, AnalyticsPeriod>(
      AnalyticsPeriodNotifier.new,
    );

// ----------------------------------------------------
// Date Boundary Helper
// ----------------------------------------------------

DateTimeRange _getPeriodRange(AnalyticsPeriod period) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

  switch (period) {
    case AnalyticsPeriod.today:
      return DateTimeRange(start: todayStart, end: todayEnd);

    case AnalyticsPeriod.sevenDays:
      final start = todayStart.subtract(const Duration(days: 6));
      return DateTimeRange(start: start, end: todayEnd);

    case AnalyticsPeriod.thirtyDays:
      final start = todayStart.subtract(const Duration(days: 29));
      return DateTimeRange(start: start, end: todayEnd);

    case AnalyticsPeriod.twelveMonths:
      final mStart = DateTime(now.year, now.month - 11, 1);
      final mEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
      return DateTimeRange(start: mStart, end: mEnd);
  }
}

int _getDaysInRange(DateTimeRange range) {
  return range.end.difference(range.start).inDays + 1;
}

// ----------------------------------------------------
// Productivity Providers
// ----------------------------------------------------

final productivityOverviewProvider = Provider<AsyncValue<ProductivityOverview>>(
  (ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final period = ref.watch(analyticsPeriodProvider);
    final range = _getPeriodRange(period);

    return tasksAsync.whenData((tasks) {
      final periodTasks = tasks.where((t) {
        final createdInPeriod =
            t.createdAt.isAfter(
              range.start.subtract(const Duration(milliseconds: 1)),
            ) &&
            t.createdAt.isBefore(
              range.end.add(const Duration(milliseconds: 1)),
            );
        final completedInPeriod =
            t.completedAt != null &&
            t.completedAt!.isAfter(
              range.start.subtract(const Duration(milliseconds: 1)),
            ) &&
            t.completedAt!.isBefore(
              range.end.add(const Duration(milliseconds: 1)),
            );
        return createdInPeriod || completedInPeriod;
      }).toList();

      final createdCount = tasks
          .where(
            (t) =>
                t.createdAt.isAfter(
                  range.start.subtract(const Duration(milliseconds: 1)),
                ) &&
                t.createdAt.isBefore(
                  range.end.add(const Duration(milliseconds: 1)),
                ),
          )
          .length;

      final completedCount = tasks
          .where(
            (t) =>
                t.status == 'completed' &&
                t.completedAt != null &&
                t.completedAt!.isAfter(
                  range.start.subtract(const Duration(milliseconds: 1)),
                ) &&
                t.completedAt!.isBefore(
                  range.end.add(const Duration(milliseconds: 1)),
                ),
          )
          .length;

      final completionRate = createdCount <= 0
          ? 0.0
          : (completedCount / createdCount) * 100;

      final now = DateTime.now();
      final overdueCount = tasks
          .where(
            (t) =>
                t.status != 'completed' &&
                t.dueDate != null &&
                t.dueDate!.isBefore(now),
          )
          .length;

      final importantCount = periodTasks.where((t) => t.isImportant).length;

      final totalDays = _getDaysInRange(range).clamp(1, 365);
      final avgCompleted = completedCount / totalDays.toDouble();

      return ProductivityOverview(
        tasksCreated: createdCount,
        tasksCompleted: completedCount,
        completionRate: completionRate > 100 ? 100.0 : completionRate,
        overdueCount: overdueCount,
        avgCompletedPerDay: avgCompleted,
        importantCount: importantCount,
      );
    });
  },
);

final taskCompletionTrendProvider =
    Provider<AsyncValue<List<TaskCompletionPoint>>>((ref) {
      final tasksAsync = ref.watch(tasksProvider);
      final period = ref.watch(analyticsPeriodProvider);
      final range = _getPeriodRange(period);

      return tasksAsync.whenData((tasks) {
        List<TaskCompletionPoint> points = [];
        const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        if (period == AnalyticsPeriod.today) {
          // 4-hour intervals
          for (int hour = 0; hour < 24; hour += 4) {
            final slotStart = DateTime(
              range.start.year,
              range.start.month,
              range.start.day,
              hour,
            );
            final slotEnd = DateTime(
              range.start.year,
              range.start.month,
              range.start.day,
              hour + 3,
              59,
              59,
            );

            final count = tasks
                .where(
                  (t) =>
                      t.status == 'completed' &&
                      t.completedAt != null &&
                      t.completedAt!.isAfter(
                        slotStart.subtract(const Duration(milliseconds: 1)),
                      ) &&
                      t.completedAt!.isBefore(
                        slotEnd.add(const Duration(milliseconds: 1)),
                      ),
                )
                .length;

            final label = '${hour.toString().padLeft(2, '0')}:00';
            points.add(
              TaskCompletionPoint(label: label, count: count, date: slotStart),
            );
          }
        } else if (period == AnalyticsPeriod.sevenDays) {
          for (int i = 6; i >= 0; i--) {
            final d = DateTime.now().subtract(Duration(days: i));
            final dayStart = DateTime(d.year, d.month, d.day);
            final dayEnd = DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

            final count = tasks
                .where(
                  (t) =>
                      t.status == 'completed' &&
                      t.completedAt != null &&
                      t.completedAt!.isAfter(
                        dayStart.subtract(const Duration(milliseconds: 1)),
                      ) &&
                      t.completedAt!.isBefore(
                        dayEnd.add(const Duration(milliseconds: 1)),
                      ),
                )
                .length;

            final label = weekdayNames[d.weekday - 1];
            points.add(
              TaskCompletionPoint(label: label, count: count, date: d),
            );
          }
        } else if (period == AnalyticsPeriod.thirtyDays) {
          for (int i = 29; i >= 0; i -= 5) {
            final d = DateTime.now().subtract(Duration(days: i));
            final dayStart = DateTime(d.year, d.month, d.day);
            final dayEnd = dayStart.add(
              const Duration(days: 4, hours: 23, minutes: 59, seconds: 59),
            );

            final count = tasks
                .where(
                  (t) =>
                      t.status == 'completed' &&
                      t.completedAt != null &&
                      t.completedAt!.isAfter(
                        dayStart.subtract(const Duration(milliseconds: 1)),
                      ) &&
                      t.completedAt!.isBefore(
                        dayEnd.add(const Duration(milliseconds: 1)),
                      ),
                )
                .length;

            final label = '${d.day}/${d.month}';
            points.add(
              TaskCompletionPoint(label: label, count: count, date: d),
            );
          }
        } else {
          // 12 Months
          const monthNames = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
          final now = DateTime.now();
          for (int i = 11; i >= 0; i--) {
            final mDate = DateTime(now.year, now.month - i, 1);
            final mStart = DateTime(mDate.year, mDate.month, 1);
            final mEnd = DateTime(
              mDate.year,
              mDate.month + 1,
              0,
              23,
              59,
              59,
              999,
            );

            final count = tasks
                .where(
                  (t) =>
                      t.status == 'completed' &&
                      t.completedAt != null &&
                      t.completedAt!.isAfter(
                        mStart.subtract(const Duration(milliseconds: 1)),
                      ) &&
                      t.completedAt!.isBefore(
                        mEnd.add(const Duration(milliseconds: 1)),
                      ),
                )
                .length;

            final label = monthNames[mDate.month - 1];
            points.add(
              TaskCompletionPoint(label: label, count: count, date: mDate),
            );
          }
        }

        return points;
      });
    });

final tasksCreatedVsCompletedProvider =
    Provider<AsyncValue<List<CreatedVsCompletedPoint>>>((ref) {
      final tasksAsync = ref.watch(tasksProvider);
      final period = ref.watch(analyticsPeriodProvider);

      return tasksAsync.whenData((tasks) {
        List<CreatedVsCompletedPoint> points = [];
        const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        const monthNames = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];

        final now = DateTime.now();

        if (period == AnalyticsPeriod.today ||
            period == AnalyticsPeriod.sevenDays) {
          for (int i = 6; i >= 0; i--) {
            final d = now.subtract(Duration(days: i));
            final dayStart = DateTime(d.year, d.month, d.day);
            final dayEnd = DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

            final created = tasks
                .where(
                  (t) =>
                      t.createdAt.isAfter(
                        dayStart.subtract(const Duration(milliseconds: 1)),
                      ) &&
                      t.createdAt.isBefore(
                        dayEnd.add(const Duration(milliseconds: 1)),
                      ),
                )
                .length;

            final completed = tasks
                .where(
                  (t) =>
                      t.status == 'completed' &&
                      t.completedAt != null &&
                      t.completedAt!.isAfter(
                        dayStart.subtract(const Duration(milliseconds: 1)),
                      ) &&
                      t.completedAt!.isBefore(
                        dayEnd.add(const Duration(milliseconds: 1)),
                      ),
                )
                .length;

            final label = weekdayNames[d.weekday - 1];
            points.add(
              CreatedVsCompletedPoint(
                label: label,
                created: created,
                completed: completed,
              ),
            );
          }
        } else if (period == AnalyticsPeriod.thirtyDays) {
          for (int i = 3; i >= 0; i--) {
            final wEnd = now.subtract(Duration(days: i * 7));
            final wStart = wEnd.subtract(const Duration(days: 6));

            final created = tasks
                .where(
                  (t) =>
                      t.createdAt.isAfter(
                        wStart.subtract(const Duration(days: 1)),
                      ) &&
                      t.createdAt.isBefore(wEnd.add(const Duration(days: 1))),
                )
                .length;

            final completed = tasks
                .where(
                  (t) =>
                      t.status == 'completed' &&
                      t.completedAt != null &&
                      t.completedAt!.isAfter(
                        wStart.subtract(const Duration(days: 1)),
                      ) &&
                      t.completedAt!.isBefore(
                        wEnd.add(const Duration(days: 1)),
                      ),
                )
                .length;

            final label = 'W${4 - i}';
            points.add(
              CreatedVsCompletedPoint(
                label: label,
                created: created,
                completed: completed,
              ),
            );
          }
        } else {
          for (int i = 5; i >= 0; i--) {
            final mDate = DateTime(now.year, now.month - i, 1);
            final mStart = DateTime(mDate.year, mDate.month, 1);
            final mEnd = DateTime(
              mDate.year,
              mDate.month + 1,
              0,
              23,
              59,
              59,
              999,
            );

            final created = tasks
                .where(
                  (t) =>
                      t.createdAt.isAfter(
                        mStart.subtract(const Duration(milliseconds: 1)),
                      ) &&
                      t.createdAt.isBefore(
                        mEnd.add(const Duration(milliseconds: 1)),
                      ),
                )
                .length;

            final completed = tasks
                .where(
                  (t) =>
                      t.status == 'completed' &&
                      t.completedAt != null &&
                      t.completedAt!.isAfter(
                        mStart.subtract(const Duration(milliseconds: 1)),
                      ) &&
                      t.completedAt!.isBefore(
                        mEnd.add(const Duration(milliseconds: 1)),
                      ),
                )
                .length;

            final label = monthNames[mDate.month - 1];
            points.add(
              CreatedVsCompletedPoint(
                label: label,
                created: created,
                completed: completed,
              ),
            );
          }
        }

        return points;
      });
    });

final categoryProductivityProvider =
    Provider<AsyncValue<List<CategoryProductivityInfo>>>((ref) {
      final tasksAsync = ref.watch(tasksProvider);
      final period = ref.watch(analyticsPeriodProvider);
      final range = _getPeriodRange(period);

      return tasksAsync.whenData((tasks) {
        final completedTasks = tasks.where((t) {
          if (t.status != 'completed') return false;
          final d = t.completedAt ?? t.createdAt;
          return d.isAfter(
                range.start.subtract(const Duration(milliseconds: 1)),
              ) &&
              d.isBefore(range.end.add(const Duration(milliseconds: 1)));
        }).toList();

        final totalCompleted = completedTasks.length;
        Map<String, int> countMap = {};

        for (final task in completedTasks) {
          final cat = task.category.isEmpty ? 'Personal' : task.category;
          countMap[cat] = (countMap[cat] ?? 0) + 1;
        }

        List<CategoryProductivityInfo> list = [];
        countMap.forEach((cat, count) {
          final pct = totalCompleted <= 0
              ? 0.0
              : (count / totalCompleted) * 100;
          list.add(
            CategoryProductivityInfo(
              category: cat,
              completedCount: count,
              percentage: pct,
            ),
          );
        });

        list.sort((a, b) => b.completedCount.compareTo(a.completedCount));
        return list;
      });
    });

final priorityAnalysisProvider =
    Provider<AsyncValue<List<PriorityAnalysisInfo>>>((ref) {
      final tasksAsync = ref.watch(tasksProvider);

      return tasksAsync.whenData((tasks) {
        const priorities = ['urgent', 'high', 'medium', 'low'];
        List<PriorityAnalysisInfo> list = [];

        for (final prio in priorities) {
          final prioTasks = tasks
              .where((t) => t.priority.toLowerCase() == prio)
              .toList();
          final total = prioTasks.length;
          final completed = prioTasks
              .where((t) => t.status == 'completed')
              .length;
          final rate = total <= 0 ? 0.0 : (completed / total) * 100;

          final label = prio[0].toUpperCase() + prio.substring(1);
          list.add(
            PriorityAnalysisInfo(
              priority: label,
              totalTasks: total,
              completedTasks: completed,
              completionRate: rate,
            ),
          );
        }

        return list;
      });
    });

final taskStatusDistributionProvider =
    Provider<AsyncValue<TaskStatusDistribution>>((ref) {
      final tasksAsync = ref.watch(tasksProvider);

      return tasksAsync.whenData((tasks) {
        final now = DateTime.now();

        final completed = tasks.where((t) => t.status == 'completed').length;
        final overdue = tasks
            .where(
              (t) =>
                  t.status != 'completed' &&
                  t.dueDate != null &&
                  t.dueDate!.isBefore(now),
            )
            .length;
        final pending = tasks
            .where((t) => t.status != 'completed' && !_isOverdueTask(t, now))
            .length;
        final important = tasks.where((t) => t.isImportant).length;

        return TaskStatusDistribution(
          pending: pending,
          completed: completed,
          overdue: overdue,
          important: important,
        );
      });
    });

bool _isOverdueTask(Task task, DateTime now) {
  if (task.status == 'completed' || task.dueDate == null) return false;
  return task.dueDate!.isBefore(now);
}

// ----------------------------------------------------
// Finance Analytics Providers
// ----------------------------------------------------

final financeAnalyticsOverviewProvider =
    Provider<AsyncValue<FinanceOverviewData>>((ref) {
      final expensesAsync = ref.watch(expensesStreamProvider);
      final incomeAsync = ref.watch(incomeStreamProvider);
      final period = ref.watch(analyticsPeriodProvider);
      final range = _getPeriodRange(period);

      if (expensesAsync.isLoading || incomeAsync.isLoading) {
        return const AsyncValue.loading();
      }

      final expenses = expensesAsync.value ?? [];
      final incomes = incomeAsync.value ?? [];

      final totalInc = incomes
          .where(
            (i) =>
                i.date.isAfter(
                  range.start.subtract(const Duration(milliseconds: 1)),
                ) &&
                i.date.isBefore(range.end.add(const Duration(milliseconds: 1))),
          )
          .fold(0.0, (sum, i) => sum + i.amount);

      final totalExp = expenses
          .where(
            (e) =>
                e.date.isAfter(
                  range.start.subtract(const Duration(milliseconds: 1)),
                ) &&
                e.date.isBefore(range.end.add(const Duration(milliseconds: 1))),
          )
          .fold(0.0, (sum, e) => sum + e.amount);

      final balance = totalInc - totalExp;
      final rate = totalInc <= 0
          ? 0.0
          : ((totalInc - totalExp) / totalInc) * 100;

      return AsyncValue.data(
        FinanceOverviewData(
          income: totalInc,
          expenses: totalExp,
          balance: balance,
          savingsRate: rate < 0 ? 0 : rate,
        ),
      );
    });

final expenseCategoryAnalysisProvider =
    Provider<AsyncValue<List<ExpenseCategoryData>>>((ref) {
      final expensesAsync = ref.watch(expensesStreamProvider);
      final period = ref.watch(analyticsPeriodProvider);
      final range = _getPeriodRange(period);

      return expensesAsync.whenData((expenses) {
        final filtered = expenses
            .where(
              (e) =>
                  e.date.isAfter(
                    range.start.subtract(const Duration(milliseconds: 1)),
                  ) &&
                  e.date.isBefore(
                    range.end.add(const Duration(milliseconds: 1)),
                  ),
            )
            .toList();

        final totalExp = filtered.fold(0.0, (sum, e) => sum + e.amount);
        Map<String, double> map = {};

        for (final exp in filtered) {
          map[exp.category] = (map[exp.category] ?? 0.0) + exp.amount;
        }

        List<ExpenseCategoryData> list = [];
        map.forEach((cat, amt) {
          final pct = totalExp <= 0 ? 0.0 : (amt / totalExp) * 100;
          list.add(
            ExpenseCategoryData(category: cat, amount: amt, percentage: pct),
          );
        });

        list.sort((a, b) => b.amount.compareTo(a.amount));
        return list;
      });
    });

final dailySpendingTrendProvider =
    Provider<AsyncValue<List<SpendingTrendPoint>>>((ref) {
      final expensesAsync = ref.watch(expensesStreamProvider);
      final period = ref.watch(analyticsPeriodProvider);

      return expensesAsync.whenData((expenses) {
        List<SpendingTrendPoint> points = [];
        final now = DateTime.now();

        int days = 7;
        if (period == AnalyticsPeriod.today) days = 1;
        if (period == AnalyticsPeriod.thirtyDays) days = 30;
        if (period == AnalyticsPeriod.twelveMonths) days = 30;

        for (int i = days - 1; i >= 0; i--) {
          final d = now.subtract(Duration(days: i));
          final dayStart = DateTime(d.year, d.month, d.day);
          final dayEnd = DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

          final total = expenses
              .where(
                (e) =>
                    e.date.isAfter(
                      dayStart.subtract(const Duration(milliseconds: 1)),
                    ) &&
                    e.date.isBefore(
                      dayEnd.add(const Duration(milliseconds: 1)),
                    ),
              )
              .fold(0.0, (sum, e) => sum + e.amount);

          final label = '${d.day}/${d.month}';
          points.add(SpendingTrendPoint(label: label, amount: total, date: d));
        }

        return points;
      });
    });

final monthlySpendingTrendProvider =
    Provider<AsyncValue<List<MonthlyExpensePoint>>>((ref) {
      final expensesAsync = ref.watch(expensesStreamProvider);

      return expensesAsync.whenData((expenses) {
        const monthNames = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        final now = DateTime.now();
        List<MonthlyExpensePoint> list = [];

        for (int i = 11; i >= 0; i--) {
          final mDate = DateTime(now.year, now.month - i, 1);
          final mStart = DateTime(mDate.year, mDate.month, 1);
          final mEnd = DateTime(
            mDate.year,
            mDate.month + 1,
            0,
            23,
            59,
            59,
            999,
          );

          final total = expenses
              .where(
                (e) =>
                    e.date.isAfter(
                      mStart.subtract(const Duration(milliseconds: 1)),
                    ) &&
                    e.date.isBefore(mEnd.add(const Duration(milliseconds: 1))),
              )
              .fold(0.0, (sum, e) => sum + e.amount);

          final label = monthNames[mDate.month - 1];
          list.add(MonthlyExpensePoint(monthLabel: label, expense: total));
        }

        return list;
      });
    });

final incomeVsExpenseMonthlyTrendProvider =
    Provider<AsyncValue<List<IncomeVsExpensePoint>>>((ref) {
      final expensesAsync = ref.watch(expensesStreamProvider);
      final incomeAsync = ref.watch(incomeStreamProvider);

      if (expensesAsync.isLoading || incomeAsync.isLoading) {
        return const AsyncValue.loading();
      }

      final expenses = expensesAsync.value ?? [];
      final incomes = incomeAsync.value ?? [];
      const monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final now = DateTime.now();

      List<IncomeVsExpensePoint> list = [];

      for (int i = 5; i >= 0; i--) {
        final mDate = DateTime(now.year, now.month - i, 1);
        final mStart = DateTime(mDate.year, mDate.month, 1);
        final mEnd = DateTime(mDate.year, mDate.month + 1, 0, 23, 59, 59, 999);

        final exp = expenses
            .where(
              (e) =>
                  e.date.isAfter(
                    mStart.subtract(const Duration(milliseconds: 1)),
                  ) &&
                  e.date.isBefore(mEnd.add(const Duration(milliseconds: 1))),
            )
            .fold(0.0, (sum, e) => sum + e.amount);

        final inc = incomes
            .where(
              (i) =>
                  i.date.isAfter(
                    mStart.subtract(const Duration(milliseconds: 1)),
                  ) &&
                  i.date.isBefore(mEnd.add(const Duration(milliseconds: 1))),
            )
            .fold(0.0, (sum, i) => sum + i.amount);

        final label = monthNames[mDate.month - 1];
        list.add(
          IncomeVsExpensePoint(monthLabel: label, income: inc, expense: exp),
        );
      }

      return AsyncValue.data(list);
    });

final savingsTrendProvider = Provider<AsyncValue<List<SavingsTrendPoint>>>((
  ref,
) {
  final comparisonAsync = ref.watch(incomeVsExpenseMonthlyTrendProvider);

  return comparisonAsync.whenData((list) {
    return list.map((item) {
      final savings = item.income - item.expense;
      return SavingsTrendPoint(monthLabel: item.monthLabel, savings: savings);
    }).toList();
  });
});

final savingsRateTrendProvider =
    Provider<AsyncValue<List<SavingsRateTrendPoint>>>((ref) {
      final comparisonAsync = ref.watch(incomeVsExpenseMonthlyTrendProvider);

      return comparisonAsync.whenData((list) {
        return list.map((item) {
          final rate = item.income <= 0
              ? 0.0
              : ((item.income - item.expense) / item.income) * 100;
          return SavingsRateTrendPoint(
            monthLabel: item.monthLabel,
            rate: rate < 0 ? 0 : rate,
          );
        }).toList();
      });
    });

final budgetAnalyticsProvider = Provider<AsyncValue<BudgetAnalyticsSummary>>((
  ref,
) {
  final budgetStatusAsync = ref.watch(budgetStatusListProvider);

  return budgetStatusAsync.whenData((list) {
    double totalBudget = 0.0;
    double totalSpent = 0.0;
    int safeCount = 0;
    int warningCount = 0;
    int criticalCount = 0;
    int exceededCount = 0;

    for (final info in list) {
      totalBudget += info.budget.amount;
      totalSpent += info.spentAmount;

      switch (info.status) {
        case 'Exceeded':
          exceededCount++;
          break;
        case 'Critical':
          criticalCount++;
          break;
        case 'Warning':
          warningCount++;
          break;
        case 'Safe':
        default:
          safeCount++;
          break;
      }
    }

    final remaining = totalBudget - totalSpent;
    final pct = totalBudget <= 0 ? 0.0 : (totalSpent / totalBudget) * 100;

    return BudgetAnalyticsSummary(
      totalBudget: totalBudget,
      totalSpent: totalSpent,
      remaining: remaining,
      utilizationPercentage: pct,
      safeCount: safeCount,
      warningCount: warningCount,
      criticalCount: criticalCount,
      exceededCount: exceededCount,
    );
  });
});

final subscriptionAnalyticsProvider =
    Provider<AsyncValue<SubscriptionAnalyticsSummary>>((ref) {
      final subsAsync = ref.watch(subscriptionsStreamProvider);
      final summaryAsync = ref.watch(subscriptionSummaryProvider);

      if (subsAsync.isLoading || summaryAsync.isLoading) {
        return const AsyncValue.loading();
      }

      final subs = subsAsync.value ?? [];
      final summary =
          summaryAsync.value ??
          const SubscriptionSummary(
            monthlyTotal: 0,
            yearlyTotal: 0,
            activeCount: 0,
          );

      Map<String, int> countMap = {
        'Weekly': 0,
        'Monthly': 0,
        'Quarterly': 0,
        'Yearly': 0,
      };

      for (final sub in subs) {
        if (!sub.active) continue;
        final cycle =
            sub.billingCycle[0].toUpperCase() +
            sub.billingCycle.substring(1).toLowerCase();
        countMap[cycle] = (countMap[cycle] ?? 0) + 1;
      }

      return AsyncValue.data(
        SubscriptionAnalyticsSummary(
          activeCount: summary.activeCount,
          monthlyCost: summary.monthlyTotal,
          yearlyCost: summary.yearlyTotal,
          countByCycle: countMap,
        ),
      );
    });

// ----------------------------------------------------
// Productivity Highlights & Insights
// ----------------------------------------------------

final productivityHighlightProvider =
    Provider<AsyncValue<ProductivityHighlightData>>((ref) {
      final tasksAsync = ref.watch(tasksProvider);
      final expensesAsync = ref.watch(expensesStreamProvider);
      final period = ref.watch(analyticsPeriodProvider);
      final range = _getPeriodRange(period);

      if (tasksAsync.isLoading || expensesAsync.isLoading) {
        return const AsyncValue.loading();
      }

      final tasks = tasksAsync.value ?? [];
      final expenses = expensesAsync.value ?? [];

      // 1. Highest Spending Category
      final filteredExpenses = expenses.where(
        (e) =>
            e.date.isAfter(
              range.start.subtract(const Duration(milliseconds: 1)),
            ) &&
            e.date.isBefore(range.end.add(const Duration(milliseconds: 1))),
      );
      final totalExp = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);

      Map<String, double> catSpentMap = {};
      for (final e in filteredExpenses) {
        catSpentMap[e.category] = (catSpentMap[e.category] ?? 0.0) + e.amount;
      }

      String highestCategory = 'None';
      double highestCategoryAmt = 0.0;
      double highestCategoryPct = 0.0;

      catSpentMap.forEach((cat, amt) {
        if (amt > highestCategoryAmt) {
          highestCategory = cat;
          highestCategoryAmt = amt;
        }
      });
      if (totalExp > 0) {
        highestCategoryPct = (highestCategoryAmt / totalExp) * 100;
      }

      // 2. Most Productive Category
      final completedTasks = tasks.where(
        (t) =>
            t.status == 'completed' &&
            t.completedAt != null &&
            t.completedAt!.isAfter(
              range.start.subtract(const Duration(milliseconds: 1)),
            ) &&
            t.completedAt!.isBefore(
              range.end.add(const Duration(milliseconds: 1)),
            ),
      );

      Map<String, int> catCompletedMap = {};
      for (final t in completedTasks) {
        final cat = t.category.isEmpty ? 'Personal' : t.category;
        catCompletedMap[cat] = (catCompletedMap[cat] ?? 0) + 1;
      }

      String mostProductiveCat = 'None';
      int mostProductiveCatCount = 0;
      catCompletedMap.forEach((cat, count) {
        if (count > mostProductiveCatCount) {
          mostProductiveCat = cat;
          mostProductiveCatCount = count;
        }
      });

      // 3. Best Productivity Day
      const weekdayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      Map<int, int> dayCompletedMap = {};
      for (final t in completedTasks) {
        final weekday = t.completedAt!.weekday;
        dayCompletedMap[weekday] = (dayCompletedMap[weekday] ?? 0) + 1;
      }

      String bestDay = 'None';
      int bestDayCount = 0;
      dayCompletedMap.forEach((weekday, count) {
        if (count > bestDayCount) {
          bestDay = weekdayNames[weekday - 1];
          bestDayCount = count;
        }
      });

      // 4. Average Daily Spending
      final activeDays = _getDaysInRange(range).clamp(1, 365);
      final avgDailySpending = totalExp / activeDays;

      return AsyncValue.data(
        ProductivityHighlightData(
          highestSpendingCategory: highestCategory,
          highestSpendingAmount: highestCategoryAmt,
          highestSpendingPercentage: highestCategoryPct,
          mostProductiveCategory: mostProductiveCat,
          mostProductiveCategoryCount: mostProductiveCatCount,
          bestProductivityDay: bestDay,
          bestProductivityDayCount: bestDayCount,
          avgDailySpending: avgDailySpending,
        ),
      );
    });

final productivityInsightsProvider = Provider<AsyncValue<List<InsightItem>>>((
  ref,
) {
  final overviewAsync = ref.watch(productivityOverviewProvider);
  final highlightsAsync = ref.watch(productivityHighlightProvider);
  final financeOverviewAsync = ref.watch(financeAnalyticsOverviewProvider);

  if (overviewAsync.isLoading ||
      highlightsAsync.isLoading ||
      financeOverviewAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final overview =
      overviewAsync.value ??
      const ProductivityOverview(
        tasksCreated: 0,
        tasksCompleted: 0,
        completionRate: 0,
        overdueCount: 0,
        avgCompletedPerDay: 0,
        importantCount: 0,
      );
  final highlights =
      highlightsAsync.value ??
      const ProductivityHighlightData(
        highestSpendingCategory: 'None',
        highestSpendingAmount: 0,
        highestSpendingPercentage: 0,
        mostProductiveCategory: 'None',
        mostProductiveCategoryCount: 0,
        bestProductivityDay: 'None',
        bestProductivityDayCount: 0,
        avgDailySpending: 0,
      );
  final finance =
      financeOverviewAsync.value ??
      const FinanceOverviewData(
        income: 0,
        expenses: 0,
        balance: 0,
        savingsRate: 0,
      );

  List<InsightItem> insights = [];

  // Productivity Insights
  if (overview.completionRate >= 70 && overview.tasksCompleted > 0) {
    insights.add(
      InsightItem(
        title: 'Strong productivity',
        message:
            'You completed ${overview.completionRate.toStringAsFixed(0)}% of your tasks during this period!',
        icon: Icons.workspace_premium_outlined,
        color: Colors.green,
        type: 'positive',
      ),
    );
  } else if (overview.overdueCount >= 3) {
    insights.add(
      InsightItem(
        title: 'Overdue tasks are increasing',
        message:
            'You have ${overview.overdueCount} overdue tasks. Consider reviewing your upcoming deadlines.',
        icon: Icons.warning_amber_rounded,
        color: Colors.red,
        type: 'warning',
      ),
    );
  }

  if (highlights.mostProductiveCategory != 'None' &&
      highlights.mostProductiveCategoryCount > 0) {
    insights.add(
      InsightItem(
        title:
            '${highlights.mostProductiveCategory} is your most active category',
        message:
            'You completed ${highlights.mostProductiveCategoryCount} tasks in ${highlights.mostProductiveCategory}.',
        icon: Icons.star_outline_rounded,
        color: Colors.blue,
        type: 'info',
      ),
    );
  }

  // Financial Insights
  if (highlights.highestSpendingCategory != 'None' &&
      highlights.highestSpendingAmount > 0) {
    insights.add(
      InsightItem(
        title:
            '${highlights.highestSpendingCategory} is your highest spending category',
        message:
            'You spent ₹${highlights.highestSpendingAmount.toStringAsFixed(0)} (${highlights.highestSpendingPercentage.toStringAsFixed(0)}% of total expenses).',
        icon: Icons.pie_chart_outline,
        color: Colors.orange,
        type: 'warning',
      ),
    );
  }

  if (finance.savingsRate >= 40 && finance.income > 0) {
    insights.add(
      InsightItem(
        title: 'Healthy Savings Rate',
        message:
            'Your savings rate reached ${finance.savingsRate.toStringAsFixed(0)}% with a net balance of ₹${finance.balance.toStringAsFixed(0)}.',
        icon: Icons.trending_up_rounded,
        color: Colors.teal,
        type: 'positive',
      ),
    );
  }

  if (highlights.bestProductivityDay != 'None' &&
      highlights.bestProductivityDayCount > 0) {
    insights.add(
      InsightItem(
        title:
            '${highlights.bestProductivityDay} is your peak productivity day',
        message:
            'You completed the highest number of tasks (${highlights.bestProductivityDayCount}) on ${highlights.bestProductivityDay}s.',
        icon: Icons.calendar_month_outlined,
        color: Colors.purple,
        type: 'info',
      ),
    );
  }

  return AsyncValue.data(insights);
});

// ----------------------------------------------------
// Focus Analytics
// ----------------------------------------------------

class FocusAnalyticsPoint {
  final String label;
  final int minutes;
  final DateTime date;

  const FocusAnalyticsPoint({
    required this.label,
    required this.minutes,
    required this.date,
  });
}

final focusAnalyticsTrendProvider = StreamProvider<List<FocusAnalyticsPoint>>((
  ref,
) {
  final period = ref.watch(analyticsPeriodProvider);
  final db = ref.watch(databaseProvider);

  return db.watchAllFocusSessions().map((sessions) {
    final now = DateTime.now();
    final List<FocusAnalyticsPoint> result = [];

    if (period == AnalyticsPeriod.today) {
      final todaySessions = sessions.where(
        (s) =>
            s.startedAt.year == now.year &&
            s.startedAt.month == now.month &&
            s.startedAt.day == now.day &&
            s.completed,
      );
      for (int i = 0; i < 24; i += 4) {
        final blockSecs = todaySessions
            .where((s) => s.startedAt.hour >= i && s.startedAt.hour < i + 4)
            .fold<int>(0, (sum, s) => sum + s.durationSeconds);
        result.add(
          FocusAnalyticsPoint(
            label: '${i}h',
            minutes: blockSecs ~/ 60,
            date: now,
          ),
        );
      }
    } else if (period == AnalyticsPeriod.sevenDays) {
      final startDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 6));
      for (int i = 0; i < 7; i++) {
        final d = startDate.add(Duration(days: i));
        final daySecs = sessions
            .where(
              (s) =>
                  s.startedAt.year == d.year &&
                  s.startedAt.month == d.month &&
                  s.startedAt.day == d.day &&
                  s.completed,
            )
            .fold<int>(0, (sum, s) => sum + s.durationSeconds);
        const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        result.add(
          FocusAnalyticsPoint(
            label: dayNames[d.weekday - 1],
            minutes: daySecs ~/ 60,
            date: d,
          ),
        );
      }
    } else if (period == AnalyticsPeriod.thirtyDays) {
      final startDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 29));
      for (int i = 0; i < 30; i += 3) {
        final d = startDate.add(Duration(days: i));
        int totalSecs = 0;
        for (int j = 0; j < 3; j++) {
          final targetD = d.add(Duration(days: j));
          totalSecs += sessions
              .where(
                (s) =>
                    s.startedAt.year == targetD.year &&
                    s.startedAt.month == targetD.month &&
                    s.startedAt.day == targetD.day &&
                    s.completed,
              )
              .fold<int>(0, (sum, s) => sum + s.durationSeconds);
        }
        result.add(
          FocusAnalyticsPoint(
            label: '${d.day}/${d.month}',
            minutes: totalSecs ~/ 60,
            date: d,
          ),
        );
      }
    } else {
      for (int i = 11; i >= 0; i--) {
        final mDate = DateTime(now.year, now.month - i, 1);
        final monthSecs = sessions
            .where(
              (s) =>
                  s.startedAt.year == mDate.year &&
                  s.startedAt.month == mDate.month &&
                  s.completed,
            )
            .fold<int>(0, (sum, s) => sum + s.durationSeconds);
        const monthNames = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        result.add(
          FocusAnalyticsPoint(
            label: monthNames[mDate.month - 1],
            minutes: monthSecs ~/ 60,
            date: mDate,
          ),
        );
      }
    }

    return result;
  });
});

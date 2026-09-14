import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import 'database_provider.dart';
import 'finance_provider.dart';

class BudgetStatusInfo {
  final Budget budget;
  final double spentAmount;
  final double percentage;
  final String status; // Safe, Warning, Critical, Exceeded

  const BudgetStatusInfo({
    required this.budget,
    required this.spentAmount,
    required this.percentage,
    required this.status,
  });
}

class SubscriptionSummary {
  final double monthlyTotal;
  final double yearlyTotal;
  final int activeCount;

  const SubscriptionSummary({
    required this.monthlyTotal,
    required this.yearlyTotal,
    required this.activeCount,
  });
}

// ----------------------------------------------------
// Streams
// ----------------------------------------------------

final budgetsStreamProvider = StreamProvider<List<Budget>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllBudgets();
});

final savingsGoalsStreamProvider = StreamProvider<List<SavingsGoal>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllSavingsGoals();
});

final subscriptionsStreamProvider = StreamProvider<List<Subscription>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllSubscriptions();
});

// ----------------------------------------------------
// Budget Status List Provider
// ----------------------------------------------------

final budgetStatusListProvider =
    Provider<AsyncValue<List<BudgetStatusInfo>>>((ref) {
  final budgetsAsync = ref.watch(budgetsStreamProvider);
  final expensesAsync = ref.watch(expensesStreamProvider);

  if (budgetsAsync.isLoading || expensesAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (budgetsAsync.hasError) {
    return AsyncValue.error(budgetsAsync.error!, budgetsAsync.stackTrace!);
  }

  final budgets = budgetsAsync.value ?? [];
  final expenses = expensesAsync.value ?? [];

  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);

  // Filter current month expenses
  final currentMonthExpenses = expenses.where((e) =>
      e.date.isAfter(monthStart.subtract(const Duration(milliseconds: 1))) &&
      e.date.isBefore(monthEnd.add(const Duration(milliseconds: 1))));

  List<BudgetStatusInfo> result = [];

  for (final budget in budgets) {
    final categorySpent = currentMonthExpenses
        .where((e) => e.category.toLowerCase() == budget.category.toLowerCase())
        .fold(0.0, (sum, e) => sum + e.amount);

    final percentage = budget.amount <= 0 ? 0.0 : (categorySpent / budget.amount) * 100;

    String status;
    if (percentage >= 100) {
      status = 'Exceeded';
    } else if (percentage >= 90) {
      status = 'Critical';
    } else if (percentage >= 70) {
      status = 'Warning';
    } else {
      status = 'Safe';
    }

    result.add(
      BudgetStatusInfo(
        budget: budget,
        spentAmount: categorySpent,
        percentage: percentage,
        status: status,
      ),
    );
  }

  return AsyncValue.data(result);
});

// ----------------------------------------------------
// Subscription Summary Provider
// ----------------------------------------------------

final subscriptionSummaryProvider =
    Provider<AsyncValue<SubscriptionSummary>>((ref) {
  final subsAsync = ref.watch(subscriptionsStreamProvider);

  return subsAsync.whenData((subs) {
    double monthlyTotal = 0.0;
    int activeCount = 0;

    for (final sub in subs) {
      if (!sub.active) continue;
      activeCount++;

      final cycle = sub.billingCycle.toLowerCase();
      if (cycle == 'weekly') {
        monthlyTotal += sub.amount * 4.33;
      } else if (cycle == 'quarterly') {
        monthlyTotal += sub.amount / 3.0;
      } else if (cycle == 'yearly') {
        monthlyTotal += sub.amount / 12.0;
      } else {
        // Default monthly
        monthlyTotal += sub.amount;
      }
    }

    final yearlyTotal = monthlyTotal * 12.0;

    return SubscriptionSummary(
      monthlyTotal: monthlyTotal,
      yearlyTotal: yearlyTotal,
      activeCount: activeCount,
    );
  });
});

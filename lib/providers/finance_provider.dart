import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import 'database_provider.dart';

enum FinanceDateFilter {
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  customRange,
}

enum TrendPeriod {
  daily,
  weekly,
  monthly,
}

const List<String> expenseCategories = [
  'Food',
  'Travel',
  'Shopping',
  'Bills',
  'Entertainment',
  'Health',
  'Education',
  'Subscriptions',
  'Rent',
  'Other',
];

const List<String> paymentMethods = [
  'Cash',
  'UPI',
  'Debit Card',
  'Credit Card',
  'Bank Transfer',
  'Other',
];

const List<String> incomeSources = [
  'Salary',
  'Freelance',
  'Business',
  'Investment',
  'Gift',
  'Other',
];

class TransactionItem {
  final int id;
  final bool isIncome;
  final double amount;
  final String title; // category or source
  final String note;
  final DateTime date;
  final String? paymentMethod;
  final bool isRecurring;
  final dynamic rawItem;

  const TransactionItem({
    required this.id,
    required this.isIncome,
    required this.amount,
    required this.title,
    required this.note,
    required this.date,
    this.paymentMethod,
    required this.isRecurring,
    required this.rawItem,
  });
}

class FinanceSummary {
  final double income;
  final double expenses;
  final double balance;
  final double savingsRate;

  const FinanceSummary({
    required this.income,
    required this.expenses,
    required this.balance,
    required this.savingsRate,
  });
}

class TrendDataPoint {
  final String label;
  final double amount;
  final DateTime date;

  const TrendDataPoint({
    required this.label,
    required this.amount,
    required this.date,
  });
}

class MonthlyComparison {
  final String monthLabel;
  final double income;
  final double expense;

  const MonthlyComparison({
    required this.monthLabel,
    required this.income,
    required this.expense,
  });
}

// ----------------------------------------------------
// Base Streams
// ----------------------------------------------------

final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllExpenses();
});

final incomeStreamProvider = StreamProvider<List<IncomeData>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllIncome();
});

// ----------------------------------------------------
// Filter Notifiers
// ----------------------------------------------------

class FinanceDateFilterNotifier extends Notifier<FinanceDateFilter> {
  @override
  FinanceDateFilter build() => FinanceDateFilter.thisMonth;

  void setFilter(FinanceDateFilter filter) => state = filter;
}

class FinanceCustomDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;

  void setRange(DateTimeRange? range) => state = range;
}

class FinanceCategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setCategory(String category) => state = category;
}

class FinanceSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

class SpendingTrendPeriodNotifier extends Notifier<TrendPeriod> {
  @override
  TrendPeriod build() => TrendPeriod.daily;

  void setPeriod(TrendPeriod period) => state = period;
}

final financeDateFilterProvider =
    NotifierProvider<FinanceDateFilterNotifier, FinanceDateFilter>(
        FinanceDateFilterNotifier.new);

final financeCustomDateRangeProvider =
    NotifierProvider<FinanceCustomDateRangeNotifier, DateTimeRange?>(
        FinanceCustomDateRangeNotifier.new);

final financeCategoryFilterProvider =
    NotifierProvider<FinanceCategoryFilterNotifier, String>(
        FinanceCategoryFilterNotifier.new);

final financeSearchQueryProvider =
    NotifierProvider<FinanceSearchQueryNotifier, String>(
        FinanceSearchQueryNotifier.new);

final spendingTrendPeriodProvider =
    NotifierProvider<SpendingTrendPeriodNotifier, TrendPeriod>(
        SpendingTrendPeriodNotifier.new);

// ----------------------------------------------------
// Helper Function for Date Filtering
// ----------------------------------------------------

bool _isDateInFilter(
  DateTime date,
  FinanceDateFilter filter,
  DateTimeRange? customRange,
) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

  switch (filter) {
    case FinanceDateFilter.today:
      return date.isAfter(todayStart.subtract(const Duration(milliseconds: 1))) &&
          date.isBefore(todayEnd.add(const Duration(milliseconds: 1)));

    case FinanceDateFilter.thisWeek:
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart
          .add(const Duration(days: 7))
          .subtract(const Duration(milliseconds: 1));
      return date.isAfter(weekStart.subtract(const Duration(milliseconds: 1))) &&
          date.isBefore(weekEnd.add(const Duration(milliseconds: 1)));

    case FinanceDateFilter.thisMonth:
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
      return date.isAfter(monthStart.subtract(const Duration(milliseconds: 1))) &&
          date.isBefore(monthEnd.add(const Duration(milliseconds: 1)));

    case FinanceDateFilter.lastMonth:
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59, 999);
      return date
              .isAfter(lastMonthStart.subtract(const Duration(milliseconds: 1))) &&
          date.isBefore(lastMonthEnd.add(const Duration(milliseconds: 1)));

    case FinanceDateFilter.customRange:
      if (customRange == null) return true;
      final rangeStart = DateTime(
          customRange.start.year, customRange.start.month, customRange.start.day);
      final rangeEnd = DateTime(
          customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59, 999);
      return date.isAfter(rangeStart.subtract(const Duration(milliseconds: 1))) &&
          date.isBefore(rangeEnd.add(const Duration(milliseconds: 1)));
  }
}

// ----------------------------------------------------
// Derived Providers
// ----------------------------------------------------

final filteredTransactionsProvider =
    Provider<AsyncValue<List<TransactionItem>>>((ref) {
  final expensesAsync = ref.watch(expensesStreamProvider);
  final incomeAsync = ref.watch(incomeStreamProvider);

  final dateFilter = ref.watch(financeDateFilterProvider);
  final customRange = ref.watch(financeCustomDateRangeProvider);
  final categoryFilter = ref.watch(financeCategoryFilterProvider);
  final searchQuery = ref.watch(financeSearchQueryProvider).trim().toLowerCase();

  if (expensesAsync.isLoading || incomeAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (expensesAsync.hasError) {
    return AsyncValue.error(expensesAsync.error!, expensesAsync.stackTrace!);
  }

  if (incomeAsync.hasError) {
    return AsyncValue.error(incomeAsync.error!, incomeAsync.stackTrace!);
  }

  final expenses = expensesAsync.value ?? [];
  final incomes = incomeAsync.value ?? [];

  List<TransactionItem> items = [];

  for (final exp in expenses) {
    items.add(
      TransactionItem(
        id: exp.id,
        isIncome: false,
        amount: exp.amount,
        title: exp.category,
        note: exp.note,
        date: exp.date,
        paymentMethod: exp.paymentMethod,
        isRecurring: exp.isRecurring,
        rawItem: exp,
      ),
    );
  }

  for (final inc in incomes) {
    items.add(
      TransactionItem(
        id: inc.id,
        isIncome: true,
        amount: inc.amount,
        title: inc.source,
        note: inc.note,
        date: inc.date,
        isRecurring: inc.isRecurring,
        rawItem: inc,
      ),
    );
  }

  // 1. Date Filter
  items = items
      .where((item) => _isDateInFilter(item.date, dateFilter, customRange))
      .toList();

  // 2. Category Filter
  if (categoryFilter != 'All') {
    items = items.where((item) {
      if (!item.isIncome) {
        return item.title.toLowerCase() == categoryFilter.toLowerCase();
      }
      return false;
    }).toList();
  }

  // 3. Search Query (category, note, income source)
  if (searchQuery.isNotEmpty) {
    items = items.where((item) {
      final titleMatch = item.title.toLowerCase().contains(searchQuery);
      final noteMatch = item.note.toLowerCase().contains(searchQuery);
      return titleMatch || noteMatch;
    }).toList();
  }

  // Sort descending by date
  items.sort((a, b) => b.date.compareTo(a.date));

  return AsyncValue.data(items);
});

final financeSummaryProvider = Provider<AsyncValue<FinanceSummary>>((ref) {
  final filteredAsync = ref.watch(filteredTransactionsProvider);

  return filteredAsync.whenData((items) {
    double totalIncome = 0;
    double totalExpenses = 0;

    for (final item in items) {
      if (item.isIncome) {
        totalIncome += item.amount;
      } else {
        totalExpenses += item.amount;
      }
    }

    final balance = totalIncome - totalExpenses;
    final savingsRate =
        totalIncome <= 0 ? 0.0 : ((totalIncome - totalExpenses) / totalIncome) * 100;

    return FinanceSummary(
      income: totalIncome,
      expenses: totalExpenses,
      balance: balance,
      savingsRate: savingsRate < 0 ? 0 : savingsRate,
    );
  });
});

final categorySpendingProvider = Provider<AsyncValue<Map<String, double>>>((ref) {
  final filteredAsync = ref.watch(filteredTransactionsProvider);

  return filteredAsync.whenData((items) {
    final Map<String, double> totals = {};

    for (final item in items) {
      if (!item.isIncome) {
        totals[item.title] = (totals[item.title] ?? 0.0) + item.amount;
      }
    }

    return totals;
  });
});

final spendingTrendDataProvider = Provider<AsyncValue<List<TrendDataPoint>>>((ref) {
  final expensesAsync = ref.watch(expensesStreamProvider);
  final period = ref.watch(spendingTrendPeriodProvider);

  return expensesAsync.whenData((expenses) {
    final now = DateTime.now();
    List<TrendDataPoint> result = [];

    if (period == TrendPeriod.daily) {
      // Last 7 days
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final dayStart = DateTime(d.year, d.month, d.day);
        final dayEnd = DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

        final total = expenses
            .where((e) =>
                e.date.isAfter(dayStart.subtract(const Duration(milliseconds: 1))) &&
                e.date.isBefore(dayEnd.add(const Duration(milliseconds: 1))))
            .fold(0.0, (sum, e) => sum + e.amount);

        const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final label = weekdayNames[d.weekday - 1];

        result.add(TrendDataPoint(label: label, amount: total, date: d));
      }
    } else if (period == TrendPeriod.weekly) {
      // Last 4 weeks
      for (int i = 3; i >= 0; i--) {
        final weekEnd = now.subtract(Duration(days: i * 7));
        final weekStart = weekEnd.subtract(const Duration(days: 6));

        final total = expenses
            .where((e) =>
                e.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                e.date.isBefore(weekEnd.add(const Duration(days: 1))))
            .fold(0.0, (sum, e) => sum + e.amount);

        final label = 'W${4 - i}';
        result.add(TrendDataPoint(label: label, amount: total, date: weekStart));
      }
    } else {
      // Monthly (Last 6 months)
      for (int i = 5; i >= 0; i--) {
        final mDate = DateTime(now.year, now.month - i, 1);
        final mStart = DateTime(mDate.year, mDate.month, 1);
        final mEnd = DateTime(mDate.year, mDate.month + 1, 0, 23, 59, 59, 999);

        final total = expenses
            .where((e) =>
                e.date.isAfter(mStart.subtract(const Duration(milliseconds: 1))) &&
                e.date.isBefore(mEnd.add(const Duration(milliseconds: 1))))
            .fold(0.0, (sum, e) => sum + e.amount);

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
          'Dec'
        ];
        final label = monthNames[mDate.month - 1];

        result.add(TrendDataPoint(label: label, amount: total, date: mDate));
      }
    }

    return result;
  });
});

final incomeVsExpenseMonthlyProvider =
    Provider<AsyncValue<List<MonthlyComparison>>>((ref) {
  final expensesAsync = ref.watch(expensesStreamProvider);
  final incomeAsync = ref.watch(incomeStreamProvider);

  if (expensesAsync.isLoading || incomeAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final expenses = expensesAsync.value ?? [];
  final incomes = incomeAsync.value ?? [];
  final now = DateTime.now();

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
    'Dec'
  ];

  List<MonthlyComparison> result = [];

  for (int i = 5; i >= 0; i--) {
    final mDate = DateTime(now.year, now.month - i, 1);
    final mStart = DateTime(mDate.year, mDate.month, 1);
    final mEnd = DateTime(mDate.year, mDate.month + 1, 0, 23, 59, 59, 999);

    final expTotal = expenses
        .where((e) =>
            e.date.isAfter(mStart.subtract(const Duration(milliseconds: 1))) &&
            e.date.isBefore(mEnd.add(const Duration(milliseconds: 1))))
        .fold(0.0, (sum, e) => sum + e.amount);

    final incTotal = incomes
        .where((inc) =>
            inc.date.isAfter(mStart.subtract(const Duration(milliseconds: 1))) &&
            inc.date.isBefore(mEnd.add(const Duration(milliseconds: 1))))
        .fold(0.0, (sum, inc) => sum + inc.amount);

    final label = '${monthNames[mDate.month - 1]} ${mDate.year % 100}';
    result.add(
      MonthlyComparison(
        monthLabel: label,
        income: incTotal,
        expense: expTotal,
      ),
    );
  }

  return AsyncValue.data(result);
});

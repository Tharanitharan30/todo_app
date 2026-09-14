import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../utils/currency_formatter.dart';
import 'database_provider.dart';

enum SearchCategory {
  all,
  tasks,
  expenses,
  income,
  budgets,
  savings,
  subscriptions,
  notifications;

  String get label {
    switch (this) {
      case SearchCategory.all:
        return 'All';
      case SearchCategory.tasks:
        return 'Tasks';
      case SearchCategory.expenses:
        return 'Expenses';
      case SearchCategory.income:
        return 'Income';
      case SearchCategory.budgets:
        return 'Budgets';
      case SearchCategory.savings:
        return 'Savings';
      case SearchCategory.subscriptions:
        return 'Subscriptions';
      case SearchCategory.notifications:
        return 'Notifications';
    }
  }
}

class SearchResultItem {
  final String id;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final SearchCategory category;
  final IconData icon;
  final DateTime? date;
  final dynamic rawData;

  const SearchResultItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.badgeColor,
    required this.category,
    required this.icon,
    this.date,
    required this.rawData,
  });
}

class SearchState {
  final String query;
  final SearchCategory categoryFilter;
  final List<SearchResultItem> results;
  final bool isSearching;
  final List<String> recentSearches;

  const SearchState({
    this.query = '',
    this.categoryFilter = SearchCategory.all,
    this.results = const [],
    this.isSearching = false,
    this.recentSearches = const [],
  });

  SearchState copyWith({
    String? query,
    SearchCategory? categoryFilter,
    List<SearchResultItem>? results,
    bool? isSearching,
    List<String>? recentSearches,
  }) {
    return SearchState(
      query: query ?? this.query,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);

class SearchNotifier extends Notifier<SearchState> {
  static const String _recentKey = 'recent_search_terms';

  @override
  SearchState build() {
    _loadRecentSearches();
    return const SearchState();
  }

  AppDatabase get _db => ref.read(databaseProvider);

  Future<void> _loadRecentSearches() async {
    try {
      final raw = await _db.getSetting(_recentKey);
      if (raw != null && raw.isNotEmpty) {
        final history = raw.split('|||').where((s) => s.isNotEmpty).toList();
        state = state.copyWith(recentSearches: history);
      }
    } catch (_) {}
  }

  Future<void> _saveRecentSearches(List<String> history) async {
    try {
      final raw = history.join('|||');
      await _db.setSetting(_recentKey, raw);
    } catch (_) {}
  }

  void addRecentSearch(String term) {
    final clean = term.trim();
    if (clean.isEmpty) {
      return;
    }

    final updated = [
      clean,
      ...state.recentSearches.where(
        (s) => s.toLowerCase() != clean.toLowerCase(),
      ),
    ];
    if (updated.length > 10) {
      updated.removeRange(10, updated.length);
    }
    state = state.copyWith(recentSearches: updated);
    _saveRecentSearches(updated);
  }

  void removeRecentSearch(String term) {
    final updated = state.recentSearches.where((s) => s != term).toList();
    state = state.copyWith(recentSearches: updated);
    _saveRecentSearches(updated);
  }

  void clearRecentSearches() {
    state = state.copyWith(recentSearches: []);
    _saveRecentSearches([]);
  }

  void setCategoryFilter(SearchCategory category) {
    state = state.copyWith(categoryFilter: category);
    if (state.query.isNotEmpty) {
      search(state.query);
    }
  }

  Future<void> search(String rawQuery) async {
    final q = rawQuery.trim().toLowerCase();
    if (q.isEmpty) {
      state = state.copyWith(query: '', results: [], isSearching: false);
      return;
    }

    state = state.copyWith(query: rawQuery, isSearching: true);

    final results = <SearchResultItem>[];
    final selectedCat = state.categoryFilter;

    // 1. TASKS
    if (selectedCat == SearchCategory.all ||
        selectedCat == SearchCategory.tasks) {
      final tasks = await _db.getAllTasks();
      for (final t in tasks) {
        if (t.title.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q) ||
            t.category.toLowerCase().contains(q) ||
            t.tags.toLowerCase().contains(q) ||
            t.notes.toLowerCase().contains(q)) {
          Color priorityColor = Colors.grey;
          if (t.priority.toLowerCase() == 'high') priorityColor = Colors.red;
          if (t.priority.toLowerCase() == 'medium') {
            priorityColor = Colors.orange;
          }
          if (t.priority.toLowerCase() == 'low') priorityColor = Colors.blue;

          results.add(
            SearchResultItem(
              id: 'task_${t.id}',
              title: t.title,
              subtitle: 'Task · ${t.priority.toUpperCase()} · ${t.category}',
              badgeText: t.status == 'completed' ? 'Done' : 'Pending',
              badgeColor: t.status == 'completed'
                  ? Colors.green
                  : priorityColor,
              category: SearchCategory.tasks,
              icon: Icons.check_circle_outline,
              date: t.dueDate,
              rawData: t,
            ),
          );
        }
      }
    }

    // 2. EXPENSES
    if (selectedCat == SearchCategory.all ||
        selectedCat == SearchCategory.expenses) {
      final expenses = await _db.getAllExpenses();
      for (final e in expenses) {
        final amtStr = CurrencyFormatter.format(e.amount);
        if (e.category.toLowerCase().contains(q) ||
            e.note.toLowerCase().contains(q) ||
            e.paymentMethod.toLowerCase().contains(q) ||
            amtStr.toLowerCase().contains(q) ||
            e.amount.toString().contains(q)) {
          results.add(
            SearchResultItem(
              id: 'expense_${e.id}',
              title: e.note.isNotEmpty ? e.note : e.category,
              subtitle:
                  'Expense · ${e.category} · ${e.paymentMethod.toUpperCase()}',
              badgeText: amtStr,
              badgeColor: Colors.red,
              category: SearchCategory.expenses,
              icon: Icons.account_balance_wallet_outlined,
              date: e.date,
              rawData: e,
            ),
          );
        }
      }
    }

    // 3. INCOME
    if (selectedCat == SearchCategory.all ||
        selectedCat == SearchCategory.income) {
      final incomeList = await _db.getAllIncome();
      for (final inc in incomeList) {
        final amtStr = CurrencyFormatter.format(inc.amount);
        if (inc.source.toLowerCase().contains(q) ||
            inc.note.toLowerCase().contains(q) ||
            amtStr.toLowerCase().contains(q) ||
            inc.amount.toString().contains(q)) {
          results.add(
            SearchResultItem(
              id: 'income_${inc.id}',
              title: inc.source,
              subtitle: 'Income${inc.note.isNotEmpty ? ' · ${inc.note}' : ''}',
              badgeText: '+ $amtStr',
              badgeColor: Colors.green,
              category: SearchCategory.income,
              icon: Icons.attach_money,
              date: inc.date,
              rawData: inc,
            ),
          );
        }
      }
    }

    // 4. BUDGETS
    if (selectedCat == SearchCategory.all ||
        selectedCat == SearchCategory.budgets) {
      final budgets = await _db.getAllBudgets();
      final expenses = await _db.getAllExpenses();

      for (final b in budgets) {
        if (b.category.toLowerCase().contains(q) ||
            b.amount.toString().contains(q)) {
          final spent = expenses
              .where(
                (e) => e.category.toLowerCase() == b.category.toLowerCase(),
              )
              .fold<double>(0, (sum, e) => sum + e.amount);

          results.add(
            SearchResultItem(
              id: 'budget_${b.id}',
              title: '${b.category} Budget',
              subtitle:
                  'Budget · ${CurrencyFormatter.format(spent)} / ${CurrencyFormatter.format(b.amount)}',
              badgeText:
                  '${((spent / (b.amount == 0 ? 1 : b.amount)) * 100).toInt()}%',
              badgeColor: spent >= b.amount ? Colors.red : Colors.blue,
              category: SearchCategory.budgets,
              icon: Icons.pie_chart_outline,
              rawData: b,
            ),
          );
        }
      }
    }

    // 5. SAVINGS
    if (selectedCat == SearchCategory.all ||
        selectedCat == SearchCategory.savings) {
      final savings = await _db.getAllSavingsGoals();
      for (final s in savings) {
        if (s.name.toLowerCase().contains(q) ||
            s.targetAmount.toString().contains(q) ||
            s.currentAmount.toString().contains(q)) {
          results.add(
            SearchResultItem(
              id: 'savings_${s.id}',
              title: s.name,
              subtitle:
                  'Savings Goal · ${CurrencyFormatter.format(s.currentAmount)} / ${CurrencyFormatter.format(s.targetAmount)}',
              badgeText:
                  '${((s.currentAmount / (s.targetAmount == 0 ? 1 : s.targetAmount)) * 100).toInt()}%',
              badgeColor: Colors.teal,
              category: SearchCategory.savings,
              icon: Icons.savings_outlined,
              rawData: s,
            ),
          );
        }
      }
    }

    // 6. SUBSCRIPTIONS
    if (selectedCat == SearchCategory.all ||
        selectedCat == SearchCategory.subscriptions) {
      final subs = await _db.getAllSubscriptions();
      for (final sub in subs) {
        final amtStr = CurrencyFormatter.format(sub.amount);
        if (sub.name.toLowerCase().contains(q) ||
            sub.billingCycle.toLowerCase().contains(q) ||
            amtStr.toLowerCase().contains(q) ||
            sub.amount.toString().contains(q)) {
          results.add(
            SearchResultItem(
              id: 'sub_${sub.id}',
              title: sub.name,
              subtitle: 'Subscription · ${sub.billingCycle}',
              badgeText: '$amtStr / ${sub.billingCycle}',
              badgeColor: Colors.purple,
              category: SearchCategory.subscriptions,
              icon: Icons.subscriptions_outlined,
              date: sub.nextBillingDate,
              rawData: sub,
            ),
          );
        }
      }
    }

    // 7. NOTIFICATIONS
    if (selectedCat == SearchCategory.all ||
        selectedCat == SearchCategory.notifications) {
      final notifications = await _db.getAllNotifications();
      for (final n in notifications) {
        if (n.title.toLowerCase().contains(q) ||
            n.body.toLowerCase().contains(q) ||
            n.type.toLowerCase().contains(q)) {
          results.add(
            SearchResultItem(
              id: 'notification_${n.id}',
              title: n.title,
              subtitle: 'Notification · ${n.body}',
              badgeText: n.type,
              badgeColor: Colors.orange,
              category: SearchCategory.notifications,
              icon: Icons.notifications_outlined,
              date: n.scheduledAt,
              rawData: n,
            ),
          );
        }
      }
    }

    // Cap results to maximum 50
    final cappedResults = results.take(50).toList();

    state = state.copyWith(
      query: rawQuery,
      results: cappedResults,
      isSearching: false,
    );
  }
}

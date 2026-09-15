import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/finance_provider.dart';
import '../widgets/add_expense_dialog.dart';
import '../widgets/add_income_dialog.dart';
import '../widgets/chart_card.dart';
import '../widgets/finance_summary_card.dart';
import '../widgets/neumorphic_button.dart';
import '../widgets/neumorphic_container.dart';
import '../widgets/neumorphic_icon_button.dart';
import '../widgets/neumorphic_input.dart';
import '../widgets/transaction_card.dart';
import 'budget_screen.dart';
import 'savings_screen.dart';
import 'subscriptions_screen.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAddExpense() {
    showDialog(context: context, builder: (_) => const AddExpenseDialog());
  }

  void _openAddIncome() {
    showDialog(context: context, builder: (_) => const AddIncomeDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Transactions'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Charts'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Budgets'),
            Tab(icon: Icon(Icons.savings), text: 'Savings'),
            Tab(icon: Icon(Icons.subscriptions), text: 'Subscriptions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionsTab(),
          const ChartCard(),
          const BudgetScreen(),
          const SavingsScreen(),
          const SubscriptionsScreen(),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final activeCategory = ref.watch(financeCategoryFilterProvider);
    final theme = Theme.of(context);

    final categories = ['All', ...expenseCategories];

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(expensesStreamProvider);
        ref.invalidate(incomeStreamProvider);
      },
      child: CustomScrollView(
        slivers: [
          // 1. Finance Summary Header
          const SliverToBoxAdapter(child: FinanceSummaryCard()),

          // 2. Action Buttons (+ Expense, + Income)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: NeumorphicButton(
                      icon: Icons.add_circle_outline,
                      label: '+ Expense',
                      color: Colors.red,
                      textColor: Colors.white,
                      onPressed: _openAddExpense,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeumorphicButton(
                      icon: Icons.add_circle_outline,
                      label: '+ Income',
                      color: Colors.green,
                      textColor: Colors.white,
                      onPressed: _openAddIncome,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: NeumorphicInput(
                controller: _searchController,
                hintText: 'Search transactions...',
                prefixIcon: Icons.search,
                suffixIcon: _searchController.text.isNotEmpty
                    ? NeumorphicIconButton(
                        icon: Icons.clear,
                        size: 32,
                        iconSize: 16,
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(financeSearchQueryProvider.notifier)
                              .setQuery('');
                        },
                      )
                    : null,
                onChanged: (val) {
                  ref.read(financeSearchQueryProvider.notifier).setQuery(val);
                },
              ),
            ),
          ),

          // 4. Category Filter Bar
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: categories.map((cat) {
                  final isSelected =
                      activeCategory.toLowerCase() == cat.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        ref
                            .read(financeCategoryFilterProvider.notifier)
                            .setCategory(isSelected ? 'All' : cat);
                      },
                      child: NeumorphicContainer(
                        style: isSelected
                            ? NeumorphicStyle.inset
                            : NeumorphicStyle.raised,
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.15)
                            : null,
                        borderColor: isSelected
                            ? theme.colorScheme.primary
                            : null,
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 5. Recent Transactions Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 6. Chronological Transaction List
          transactionsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading transactions: $err'),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions found for selected period',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Group items chronologically by Date
              final Map<String, List<TransactionItem>> grouped = {};
              final now = DateTime.now();
              final todayStart = DateTime(now.year, now.month, now.day);
              final yesterdayStart = todayStart.subtract(
                const Duration(days: 1),
              );

              for (final item in items) {
                final itemDateStart = DateTime(
                  item.date.year,
                  item.date.month,
                  item.date.day,
                );
                String header;
                if (itemDateStart == todayStart) {
                  header = 'Today';
                } else if (itemDateStart == yesterdayStart) {
                  header = 'Yesterday';
                } else {
                  header =
                      '${item.date.day}/${item.date.month}/${item.date.year}';
                }
                grouped.putIfAbsent(header, () => []).add(item);
              }

              final entries = grouped.entries.toList();

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final entry = entries[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ),
                      ...entry.value.map((item) => TransactionCard(item: item)),
                    ],
                  );
                }, childCount: entries.length),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/finance_provider.dart';
import '../widgets/add_expense_dialog.dart';
import '../widgets/add_income_dialog.dart';
import '../widgets/chart_card.dart';
import '../widgets/finance_summary_card.dart';
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
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: _openAddExpense,
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.red,
                      ),
                      label: const Text(
                        '+ Expense',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                      onPressed: _openAddIncome,
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.green,
                      ),
                      label: const Text(
                        '+ Income',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(financeSearchQueryProvider.notifier)
                                .setQuery('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
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
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(cat),
                      onSelected: (selected) {
                        ref
                            .read(financeCategoryFilterProvider.notifier)
                            .setCategory(selected ? cat : 'All');
                      },
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
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No transactions found for selected period',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
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
                            color: Colors.grey[700],
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

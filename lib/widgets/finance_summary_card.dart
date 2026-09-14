import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/finance_provider.dart';

class FinanceSummaryCard extends ConsumerWidget {
  const FinanceSummaryCard({super.key});

  String _filterLabel(FinanceDateFilter filter) {
    switch (filter) {
      case FinanceDateFilter.today:
        return 'Today';
      case FinanceDateFilter.thisWeek:
        return 'This Week';
      case FinanceDateFilter.thisMonth:
        return 'This Month';
      case FinanceDateFilter.lastMonth:
        return 'Last Month';
      case FinanceDateFilter.customRange:
        return 'Custom Range';
    }
  }

  Future<void> _selectCustomRange(BuildContext context, WidgetRef ref) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: ref.read(financeCustomDateRangeProvider),
    );
    if (picked != null) {
      ref.read(financeCustomDateRangeProvider.notifier).setRange(picked);
      ref
          .read(financeDateFilterProvider.notifier)
          .setFilter(FinanceDateFilter.customRange);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(financeSummaryProvider);
    final activeFilter = ref.watch(financeDateFilterProvider);
    final customRange = ref.watch(financeCustomDateRangeProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Period Selector Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Finance',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                PopupMenuButton<FinanceDateFilter>(
                  initialValue: activeFilter,
                  onSelected: (filter) {
                    if (filter == FinanceDateFilter.customRange) {
                      _selectCustomRange(context, ref);
                    } else {
                      ref
                          .read(financeDateFilterProvider.notifier)
                          .setFilter(filter);
                    }
                  },
                  child: Chip(
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      activeFilter == FinanceDateFilter.customRange &&
                              customRange != null
                          ? '${customRange.start.day}/${customRange.start.month} - ${customRange.end.day}/${customRange.end.month}'
                          : _filterLabel(activeFilter),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: FinanceDateFilter.today,
                      child: Text('Today'),
                    ),
                    const PopupMenuItem(
                      value: FinanceDateFilter.thisWeek,
                      child: Text('This Week'),
                    ),
                    const PopupMenuItem(
                      value: FinanceDateFilter.thisMonth,
                      child: Text('This Month'),
                    ),
                    const PopupMenuItem(
                      value: FinanceDateFilter.lastMonth,
                      child: Text('Last Month'),
                    ),
                    const PopupMenuItem(
                      value: FinanceDateFilter.customRange,
                      child: Text('Custom Range'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            summaryAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text(
                'Error loading summary: $err',
                style: const TextStyle(color: Colors.red),
              ),
              data: (summary) {
                final balanceColor = summary.balance >= 0
                    ? Colors.green[700]
                    : Colors.red[700];

                return Column(
                  children: [
                    // Grid 2x2 of metrics
                    Row(
                      children: [
                        Expanded(
                          child: _summaryTile(
                            context,
                            title: 'Income',
                            amount: '₹ ${summary.income.toStringAsFixed(0)}',
                            color: Colors.green,
                            icon: Icons.arrow_downward,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _summaryTile(
                            context,
                            title: 'Expenses',
                            amount: '₹ ${summary.expenses.toStringAsFixed(0)}',
                            color: Colors.red,
                            icon: Icons.arrow_upward,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _summaryTile(
                            context,
                            title: 'Balance',
                            amount: '₹ ${summary.balance.toStringAsFixed(0)}',
                            color: balanceColor!,
                            icon: Icons.account_balance_wallet,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _summaryTile(
                            context,
                            title: 'Savings',
                            amount:
                                '₹ ${summary.balance > 0 ? summary.balance.toStringAsFixed(0) : "0"} (${summary.savingsRate.toStringAsFixed(0)}%)',
                            color: Colors.blue,
                            icon: Icons.savings_outlined,
                          ),
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

  Widget _summaryTile(
    BuildContext context, {
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

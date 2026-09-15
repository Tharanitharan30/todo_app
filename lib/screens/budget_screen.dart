import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/budget_provider.dart';
import '../providers/database_provider.dart';
import '../providers/finance_provider.dart';
import '../widgets/neumorphic_button.dart';
import '../widgets/neumorphic_card.dart';
import '../widgets/neumorphic_icon_button.dart';
import '../widgets/neumorphic_progress.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  void _showAddEditBudgetDialog(
    BuildContext context,
    WidgetRef ref, [
    Budget? existing,
  ]) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(
      text: existing != null ? existing.amount.toString() : '',
    );
    String selectedCategory = existing?.category ?? expenseCategories.first;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existing == null ? 'Set Budget' : 'Edit Budget'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: expenseCategories.contains(selectedCategory)
                          ? selectedCategory
                          : expenseCategories.first,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: expenseCategories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedCategory = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Budget Amount (₹)',
                        prefixText: '₹ ',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter budget amount';
                        }
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid amount > 0';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final amt = double.parse(amountController.text.trim());
                    final db = ref.read(databaseProvider);

                    if (existing != null) {
                      final updated = existing.copyWith(
                        category: selectedCategory,
                        amount: amt,
                      );
                      await db.updateBudget(updated);
                    } else {
                      final companion = BudgetsCompanion(
                        category: drift.Value(selectedCategory),
                        amount: drift.Value(amt),
                      );
                      await db.addBudget(companion);
                    }

                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Save Budget'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteBudget(
    BuildContext context,
    WidgetRef ref,
    Budget budget,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Budget'),
          content: Text(
            'Delete the monthly budget for ${budget.category} (₹${budget.amount.toStringAsFixed(0)})?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(databaseProvider).deleteBudget(budget.id);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'exceeded':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'on track':
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetStatusAsync = ref.watch(budgetStatusListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Budgets'),
        actions: [
          NeumorphicIconButton(
            tooltip: 'Add Budget',
            onPressed: () => _showAddEditBudgetDialog(context, ref),
            icon: Icons.add_chart,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: NeumorphicButton(
        icon: Icons.add,
        label: 'Add Budget',
        isPrimary: true,
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        onPressed: () => _showAddEditBudgetDialog(context, ref),
      ),
      body: budgetStatusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (infoList) {
          if (infoList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No budgets set for this month',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  NeumorphicButton(
                    icon: Icons.add,
                    label: 'Set First Budget',
                    isPrimary: true,
                    onPressed: () => _showAddEditBudgetDialog(context, ref),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: infoList.length,
            itemBuilder: (context, index) {
              final info = infoList[index];
              final statusColor = _getStatusColor(info.status);
              final progress = (info.percentage / 100).clamp(0.0, 1.0);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: NeumorphicCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 14,
                  borderColor: statusColor.withValues(alpha: 0.4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            info.budget.category,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Text(
                                  info.status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  size: 20,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    _showAddEditBudgetDialog(
                                      context,
                                      ref,
                                      info.budget,
                                    );
                                  } else if (val == 'delete') {
                                    _deleteBudget(context, ref, info.budget);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit Budget'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${info.spentAmount.toStringAsFixed(0)} / ₹${info.budget.amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${info.percentage.toStringAsFixed(1)}% used',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      NeumorphicProgress(
                        progress: progress,
                        height: 10,
                        color: statusColor,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

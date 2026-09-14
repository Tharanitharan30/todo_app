import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/budget_provider.dart';
import '../providers/database_provider.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  void _showGoalDialog(
    BuildContext context,
    WidgetRef ref, [
    SavingsGoal? existing,
  ]) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.name ?? '');
    final targetController = TextEditingController(
      text: existing != null ? existing.targetAmount.toString() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            existing == null ? 'Create Savings Goal' : 'Edit Savings Goal',
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter goal name' : null,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: targetController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Target Amount (₹)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter target amount';
                    }
                    final parsed = double.tryParse(v.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Enter valid target > 0';
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
                final name = nameController.text.trim();
                final target = double.parse(targetController.text.trim());
                final db = ref.read(databaseProvider);

                if (existing != null) {
                  final updated = existing.copyWith(
                    name: name,
                    targetAmount: target,
                  );
                  await db.updateSavingsGoal(updated);
                } else {
                  final companion = SavingsGoalsCompanion(
                    name: drift.Value(name),
                    targetAmount: drift.Value(target),
                    currentAmount: const drift.Value(0),
                  );
                  await db.addSavingsGoal(companion);
                }

                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        existing == null ? 'Goal created' : 'Goal updated',
                      ),
                    ),
                  );
                }
              },
              child: Text(existing == null ? 'Create' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddRemoveMoneyDialog(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
    bool isAdd,
  ) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('${isAdd ? 'Add' : 'Remove'} Money: ${goal.name}'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                prefixText: '₹ ',
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter amount';
                final parsed = double.tryParse(v.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Enter valid amount > 0';
                }
                if (!isAdd && parsed > goal.currentAmount) {
                  return 'Cannot remove more than saved amount (₹${goal.currentAmount.toStringAsFixed(0)})';
                }
                return null;
              },
              autofocus: true,
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
                final delta = double.parse(amountController.text.trim());
                final newAmount = isAdd
                    ? goal.currentAmount + delta
                    : goal.currentAmount - delta;

                final db = ref.read(databaseProvider);
                await db.updateSavingsGoalAmount(goal.id, newAmount);

                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${isAdd ? 'Added' : 'Removed'} ₹${delta.toStringAsFixed(0)}',
                      ),
                    ),
                  );
                }
              },
              child: Text(isAdd ? 'Add Money' : 'Remove Money'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteGoal(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Savings Goal'),
        content: Text('Are you sure you want to delete "${goal.name}"?'),
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
      ),
    );

    if (confirmed == true) {
      final db = ref.read(databaseProvider);
      await db.deleteSavingsGoal(goal.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Savings goal deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            tooltip: 'Add Goal',
            onPressed: () => _showGoalDialog(context, ref),
            icon: const Icon(Icons.savings),
          ),
        ],
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.savings_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No savings goals created yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showGoalDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Goal'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              final pct = goal.targetAmount <= 0
                  ? 0.0
                  : ((goal.currentAmount / goal.targetAmount) * 100).clamp(
                      0.0,
                      100.0,
                    );
              final progress = pct / 100.0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            goal.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (val) {
                              if (val == 'edit') {
                                _showGoalDialog(context, ref, goal);
                              } else if (val == 'add') {
                                _showAddRemoveMoneyDialog(
                                  context,
                                  ref,
                                  goal,
                                  true,
                                );
                              } else if (val == 'remove') {
                                _showAddRemoveMoneyDialog(
                                  context,
                                  ref,
                                  goal,
                                  false,
                                );
                              } else if (val == 'delete') {
                                _deleteGoal(context, ref, goal);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'add',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Add money'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Remove money'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined),
                                    SizedBox(width: 8),
                                    Text('Edit goal'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saved',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '₹${goal.currentAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Target',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '₹${goal.targetAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${pct.toStringAsFixed(2)}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Colors.grey.withValues(alpha: 0.15),
                          color: pct >= 100 ? Colors.green : Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showAddRemoveMoneyDialog(
                              context,
                              ref,
                              goal,
                              true,
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Money'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGoalDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Goal'),
      ),
    );
  }
}

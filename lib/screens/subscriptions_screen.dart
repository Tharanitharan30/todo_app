import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/budget_provider.dart';
import '../providers/database_provider.dart';
import '../services/notification_service.dart';

const List<String> billingCycles = ['Weekly', 'Monthly', 'Quarterly', 'Yearly'];

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  void _showSubscriptionDialog(
    BuildContext context,
    WidgetRef ref, [
    Subscription? existing,
  ]) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.name ?? '');
    final amountController = TextEditingController(
      text: existing != null ? existing.amount.toString() : '',
    );
    String selectedCycle = existing?.billingCycle ?? 'Monthly';
    DateTime selectedNextDate =
        existing?.nextBillingDate ??
        DateTime.now().add(const Duration(days: 30));
    bool isActive = existing?.active ?? true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Add Subscription' : 'Edit Subscription',
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Subscription Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter subscription name'
                              : null,
                          autofocus: true,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Amount (₹)',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter amount';
                            }
                            final parsed = double.tryParse(v.trim());
                            if (parsed == null || parsed <= 0) {
                              return 'Enter valid amount > 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: billingCycles.contains(selectedCycle)
                              ? selectedCycle
                              : 'Monthly',
                          decoration: const InputDecoration(
                            labelText: 'Billing Cycle',
                            border: OutlineInputBorder(),
                          ),
                          items: billingCycles.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                selectedCycle = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedNextDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 3650),
                              ),
                            );
                            if (picked != null) {
                              setState(() {
                                selectedNextDate = picked;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Next Billing Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              '${selectedNextDate.day}/${selectedNextDate.month}/${selectedNextDate.year}',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Active Subscription'),
                          value: isActive,
                          onChanged: (val) {
                            setState(() {
                              isActive = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
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
                    final amount = double.parse(amountController.text.trim());
                    final db = ref.read(databaseProvider);

                    if (existing != null) {
                      final updated = existing.copyWith(
                        name: name,
                        amount: amount,
                        billingCycle: selectedCycle,
                        nextBillingDate: selectedNextDate,
                        active: isActive,
                      );
                      await db.updateSubscription(updated);

                      if (isActive) {
                        await NotificationService()
                            .scheduleSubscriptionReminder(
                              subscriptionId: updated.id,
                              subscriptionName: updated.name,
                              nextBillingDate: updated.nextBillingDate,
                            );
                      } else {
                        await NotificationService().cancelSubscriptionReminder(
                          updated.id,
                        );
                      }
                    } else {
                      final companion = SubscriptionsCompanion(
                        name: drift.Value(name),
                        amount: drift.Value(amount),
                        billingCycle: drift.Value(selectedCycle),
                        nextBillingDate: drift.Value(selectedNextDate),
                        active: drift.Value(isActive),
                      );
                      final newId = await db.addSubscription(companion);

                      if (isActive) {
                        await NotificationService()
                            .scheduleSubscriptionReminder(
                              subscriptionId: newId,
                              subscriptionName: name,
                              nextBillingDate: selectedNextDate,
                            );
                      }
                    }

                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            existing == null
                                ? 'Subscription added'
                                : 'Subscription updated',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(existing == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteSubscription(
    BuildContext context,
    WidgetRef ref,
    Subscription sub,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subscription'),
        content: Text('Delete subscription for "${sub.name}"?'),
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
      await db.deleteSubscription(sub.id);
      await NotificationService().cancelSubscriptionReminder(sub.id);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Subscription deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(subscriptionsStreamProvider);
    final summaryAsync = ref.watch(subscriptionSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          IconButton(
            tooltip: 'Add Subscription',
            onPressed: () => _showSubscriptionDialog(context, ref),
            icon: const Icon(Icons.subscriptions),
          ),
        ],
      ),
      body: Column(
        children: [
          // 17. Subscription Summary Card
          summaryAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (err, _) => const SizedBox.shrink(),
            data: (summary) {
              return Card(
                margin: const EdgeInsets.all(16),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Subscriptions',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${summary.monthlyTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yearly Subscriptions',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${summary.yearlyTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Subscription List
          Expanded(
            child: subsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (subs) {
                if (subs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.subscriptions_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No subscriptions tracked yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () =>
                              _showSubscriptionDialog(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Subscription'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: subs.length,
                  itemBuilder: (context, index) {
                    final sub = subs[index];
                    final dateStr =
                        '${sub.nextBillingDate.day}/${sub.nextBillingDate.month}/${sub.nextBillingDate.year}';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: sub.active
                              ? Colors.deepPurple.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.12),
                          child: Icon(
                            Icons.subscriptions,
                            color: sub.active ? Colors.deepPurple : Colors.grey,
                          ),
                        ),
                        title: Text(
                          sub.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: sub.active
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                        ),
                        subtitle: Text(
                          '${sub.billingCycle} • Next payment: $dateStr',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${sub.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: sub.active,
                              onChanged: (val) async {
                                final db = ref.read(databaseProvider);
                                await db.toggleSubscriptionActive(sub.id, val);
                                if (val) {
                                  await NotificationService()
                                      .scheduleSubscriptionReminder(
                                        subscriptionId: sub.id,
                                        subscriptionName: sub.name,
                                        nextBillingDate: sub.nextBillingDate,
                                      );
                                } else {
                                  await NotificationService()
                                      .cancelSubscriptionReminder(sub.id);
                                }
                              },
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showSubscriptionDialog(context, ref, sub);
                                } else if (val == 'delete') {
                                  _deleteSubscription(context, ref, sub);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
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
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubscriptionDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Subscription'),
      ),
    );
  }
}

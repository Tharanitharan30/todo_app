import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/currency_formatter.dart';
import 'add_expense_dialog.dart';
import 'add_income_dialog.dart';
import 'neumorphic_card.dart';

class TransactionCard extends ConsumerWidget {
  final TransactionItem item;

  const TransactionCard({super.key, required this.item});

  IconData _getCategoryIcon(String category, bool isIncome) {
    if (isIncome) return Icons.arrow_downward_rounded;
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.fastfood_outlined;
      case 'travel':
        return Icons.directions_car_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'bills':
        return Icons.receipt_long_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'health':
        return Icons.medical_services_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'subscriptions':
        return Icons.subscriptions_outlined;
      case 'rent':
        return Icons.home_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: item.isIncome
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.red.withValues(alpha: 0.15),
                child: Icon(
                  _getCategoryIcon(item.title, item.isIncome),
                  color: item.isIncome ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Type', item.isIncome ? 'Income' : 'Expense'),
              _detailRow(
                'Amount',
                '${item.isIncome ? '+' : '-'} ₹${item.amount.toStringAsFixed(2)}',
              ),
              _detailRow(
                'Date',
                '${item.date.day}/${item.date.month}/${item.date.year}',
              ),
              if (item.paymentMethod != null && item.paymentMethod!.isNotEmpty)
                _detailRow('Payment Method', item.paymentMethod!),
              _detailRow('Recurring', item.isRecurring ? 'Yes' : 'No'),
              if (item.note.isNotEmpty) _detailRow('Note', item.note),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _onEdit(BuildContext context, WidgetRef ref) {
    if (item.isIncome) {
      showDialog(
        context: context,
        builder: (_) => AddIncomeDialog(income: item.rawItem as IncomeData),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AddExpenseDialog(expense: item.rawItem as Expense),
      );
    }
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: Text(
            'Are you sure you want to delete this ${item.isIncome ? 'income' : 'expense'} of ₹${item.amount.toStringAsFixed(0)}?',
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
      final db = ref.read(databaseProvider);
      if (item.isIncome) {
        await db.deleteIncome(item.id);
      } else {
        await db.deleteExpense(item.id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);
    final isIncome = item.isIncome;
    final color = isIncome ? Colors.green : Colors.red;
    final iconData = _getCategoryIcon(item.title, isIncome);
    final formattedAmount = CurrencyFormatter.format(
      item.amount,
      currencyCode: settings.currency,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: NeumorphicCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        borderRadius: 12,
        onTap: () => _showDetails(context),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(iconData, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (item.note.isNotEmpty)
                    Text(
                      item.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 13,
                      ),
                    ),
                  Row(
                    children: [
                      Text(
                        '${item.date.day}/${item.date.month}/${item.date.year}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: 12,
                        ),
                      ),
                      if (item.paymentMethod != null &&
                          item.paymentMethod!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.paymentMethod!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isIncome ? '+' : '-'} $formattedAmount',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  onSelected: (val) {
                    if (val == 'details') {
                      _showDetails(context);
                    } else if (val == 'edit') {
                      _onEdit(context, ref);
                    } else if (val == 'delete') {
                      _onDelete(context, ref);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18),
                          SizedBox(width: 8),
                          Text('View details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
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
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

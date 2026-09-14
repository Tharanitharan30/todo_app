import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'add_expense_dialog.dart';
import 'add_income_dialog.dart';
import 'add_task_dialog.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildActionButton(
            context,
            icon: Icons.check_circle_outline,
            label: '+ Task',
            color: Colors.blue,
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const AddTaskDialog(),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            context,
            icon: Icons.account_balance_wallet_outlined,
            label: '+ Expense',
            color: Colors.red,
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const AddExpenseDialog(),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            context,
            icon: Icons.attach_money,
            label: '+ Income',
            color: Colors.green,
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const AddIncomeDialog(),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            context,
            icon: Icons.timer_outlined,
            label: 'Start Focus',
            color: Colors.deepPurple,
            onTap: () {
              context.go('/focus');
            },
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            context,
            icon: Icons.calendar_month_outlined,
            label: 'Open Calendar',
            color: Colors.orange,
            onTap: () {
              context.go('/calendar');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: onTap,
    );
  }
}

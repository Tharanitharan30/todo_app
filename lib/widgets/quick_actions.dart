import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'add_expense_dialog.dart';
import 'add_income_dialog.dart';
import 'add_task_dialog.dart';
import 'neumorphic_button.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _buildActionButton(
            context,
            icon: Icons.check_circle_outline,
            label: '+ Task',
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const AddTaskDialog(),
              );
            },
          ),
          const SizedBox(width: 10),
          _buildActionButton(
            context,
            icon: Icons.account_balance_wallet_outlined,
            label: '+ Expense',
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const AddExpenseDialog(),
              );
            },
          ),
          const SizedBox(width: 10),
          _buildActionButton(
            context,
            icon: Icons.attach_money,
            label: '+ Income',
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const AddIncomeDialog(),
              );
            },
          ),
          const SizedBox(width: 10),
          _buildActionButton(
            context,
            icon: Icons.timer_outlined,
            label: 'Start Focus',
            onTap: () {
              context.go('/focus');
            },
          ),
          const SizedBox(width: 10),
          _buildActionButton(
            context,
            icon: Icons.calendar_month_outlined,
            label: 'Open Calendar',
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
    required VoidCallback onTap,
  }) {
    return NeumorphicButton(
      icon: icon,
      label: label,
      onPressed: onTap,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );
  }
}

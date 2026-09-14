import 'package:flutter/material.dart';

import '../database/database.dart';
import '../providers/finance_provider.dart';
import 'transaction_card.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;

  const ExpenseCard({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final item = TransactionItem(
      id: expense.id,
      isIncome: false,
      amount: expense.amount,
      title: expense.category,
      note: expense.note,
      date: expense.date,
      paymentMethod: expense.paymentMethod,
      isRecurring: expense.isRecurring,
      rawItem: expense,
    );

    return TransactionCard(item: item);
  }
}

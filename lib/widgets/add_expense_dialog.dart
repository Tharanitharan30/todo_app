import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../utils/currency_formatter.dart';

class AddExpenseDialog extends ConsumerStatefulWidget {
  final Expense? expense;

  const AddExpenseDialog({super.key, this.expense});

  @override
  ConsumerState<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late String _selectedCategory;
  late String _selectedPaymentMethod;
  late DateTime _selectedDate;
  late bool _isRecurring;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    if (widget.expense != null) {
      _amountController.text = widget.expense!.amount.toString();
      _noteController.text = widget.expense!.note;
      _selectedCategory = widget.expense!.category;
      _selectedPaymentMethod = widget.expense!.paymentMethod;
      _selectedDate = widget.expense!.date;
      _isRecurring = widget.expense!.isRecurring;
    } else {
      _selectedCategory = expenseCategories.first;
      _selectedPaymentMethod =
          paymentMethods.contains(settings.defaultPaymentMethod)
              ? settings.defaultPaymentMethod
              : paymentMethods.first;
      _selectedDate = DateTime.now();
      _isRecurring = false;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an amount';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Please enter a valid number';
    }
    if (parsed <= 0) {
      return 'Amount must be greater than zero';
    }
    return null;
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final amount = double.parse(_amountController.text.trim());
    final note = _noteController.text.trim();
    final db = ref.read(databaseProvider);

    try {
      if (widget.expense != null) {
        final updated = widget.expense!.copyWith(
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          paymentMethod: _selectedPaymentMethod,
          note: note,
          isRecurring: _isRecurring,
        );
        await db.updateExpense(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense updated successfully')),
          );
          Navigator.of(context).pop();
        }
      } else {
        final companion = ExpensesCompanion(
          amount: drift.Value(amount),
          category: drift.Value(_selectedCategory),
          date: drift.Value(_selectedDate),
          paymentMethod: drift.Value(_selectedPaymentMethod),
          note: drift.Value(note),
          isRecurring: drift.Value(_isRecurring),
        );
        await db.addExpense(companion);

        // Check budget thresholds for notifications
        await _checkBudgetAlert(_selectedCategory, amount);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense added successfully')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Error saving expense: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save expense: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkBudgetAlert(String category, double addedAmount) async {
    try {
      final db = ref.read(databaseProvider);
      final budgets = await db.getAllBudgets();
      final budget = budgets
          .where((b) => b.category.toLowerCase() == category.toLowerCase())
          .firstOrNull;

      if (budget == null || budget.amount <= 0) return;

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);

      final expenses = await db.getAllExpenses();
      final totalSpent = expenses
          .where((e) =>
              e.category.toLowerCase() == category.toLowerCase() &&
              e.date.isAfter(monthStart.subtract(const Duration(milliseconds: 1))) &&
              e.date.isBefore(monthEnd.add(const Duration(milliseconds: 1))))
          .fold(0.0, (sum, e) => sum + e.amount);

      final percentage = (totalSpent / budget.amount) * 100;
      if (percentage >= 80) {
        await NotificationService().showBudgetAlert(
          category: category,
          percentage: percentage,
          spent: totalSpent,
          budget: budget.amount,
        );
      }
    } catch (e) {
      debugPrint('Error checking budget alert: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.expense != null;
    final settings = ref.watch(appSettingsProvider);
    final symbol = CurrencyFormatter.getSymbol(settings.currency);

    return AlertDialog(
      title: Text(isEdit ? 'Edit Expense' : 'Add Expense'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount ($symbol)',
                    prefixText: '$symbol ',
                    border: const OutlineInputBorder(),
                  ),
                  validator: _validateAmount,
                  autofocus: true,
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: expenseCategories.contains(_selectedCategory)
                      ? _selectedCategory
                      : expenseCategories.first,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: expenseCategories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Date Picker Row
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Method Dropdown
                DropdownButtonFormField<String>(
                  initialValue: paymentMethods.contains(_selectedPaymentMethod)
                      ? _selectedPaymentMethod
                      : paymentMethods.first,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                  ),
                  items: paymentMethods.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedPaymentMethod = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Note Field
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // Recurring Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Recurring Expense'),
                  subtitle: const Text('Repeats periodically'),
                  value: _isRecurring,
                  onChanged: (val) {
                    setState(() {
                      _isRecurring = val;
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
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveExpense,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Update' : 'Add Expense'),
        ),
      ],
    );
  }
}

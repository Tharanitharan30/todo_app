import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/finance_provider.dart';

class AddIncomeDialog extends ConsumerStatefulWidget {
  final IncomeData? income;

  const AddIncomeDialog({super.key, this.income});

  @override
  ConsumerState<AddIncomeDialog> createState() => _AddIncomeDialogState();
}

class _AddIncomeDialogState extends ConsumerState<AddIncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late String _selectedSource;
  late DateTime _selectedDate;
  late bool _isRecurring;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.income != null) {
      _amountController.text = widget.income!.amount.toString();
      _noteController.text = widget.income!.note;
      _selectedSource = widget.income!.source;
      _selectedDate = widget.income!.date;
      _isRecurring = widget.income!.isRecurring;
    } else {
      _selectedSource = incomeSources.first;
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

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final amount = double.parse(_amountController.text.trim());
    final note = _noteController.text.trim();
    final db = ref.read(databaseProvider);

    try {
      if (widget.income != null) {
        final updated = widget.income!.copyWith(
          amount: amount,
          source: _selectedSource,
          date: _selectedDate,
          note: note,
          isRecurring: _isRecurring,
        );
        await db.updateIncome(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Income updated successfully')),
          );
          Navigator.of(context).pop();
        }
      } else {
        final companion = IncomeCompanion(
          amount: drift.Value(amount),
          source: drift.Value(_selectedSource),
          date: drift.Value(_selectedDate),
          note: drift.Value(note),
          isRecurring: drift.Value(_isRecurring),
        );
        await db.addIncome(companion);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Income added successfully')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Error saving income: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save income: $e')),
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.income != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Income' : 'Add Income'),
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
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateAmount,
                  autofocus: true,
                ),
                const SizedBox(height: 16),

                // Source Dropdown
                DropdownButtonFormField<String>(
                  initialValue: incomeSources.contains(_selectedSource)
                      ? _selectedSource
                      : incomeSources.first,
                  decoration: const InputDecoration(
                    labelText: 'Income Source',
                    border: OutlineInputBorder(),
                  ),
                  items: incomeSources.map((src) {
                    return DropdownMenuItem(
                      value: src,
                      child: Text(src),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedSource = val;
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
                  title: const Text('Recurring Income'),
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
          onPressed: _isLoading ? null : _saveIncome,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Update' : 'Add Income'),
        ),
      ],
    );
  }
}

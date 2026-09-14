import 'package:flutter/material.dart';

import '../services/backup_service.dart';

class RestoreConfirmationDialog extends StatelessWidget {
  final BackupValidationResult validationResult;
  final StorageInfo currentStorage;
  final VoidCallback onConfirmRestore;

  const RestoreConfirmationDialog({
    super.key,
    required this.validationResult,
    required this.currentStorage,
    required this.onConfirmRestore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Restore Backup'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will replace your current local data with data from the backup file.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildComparisonHeader(),
                  const Divider(),
                  _buildComparisonRow(
                      'Tasks', currentStorage.taskCount, validationResult.taskCount),
                  _buildComparisonRow('Subtasks', currentStorage.subtaskCount,
                      validationResult.subtaskCount),
                  _buildComparisonRow('Expenses', currentStorage.expenseCount,
                      validationResult.expenseCount),
                  _buildComparisonRow('Income', currentStorage.incomeCount,
                      validationResult.incomeCount),
                  _buildComparisonRow('Budgets', currentStorage.budgetCount,
                      validationResult.budgetCount),
                  _buildComparisonRow('Savings Goals', currentStorage.savingsCount,
                      validationResult.savingsCount),
                  _buildComparisonRow('Subscriptions',
                      currentStorage.subscriptionCount, validationResult.subscriptionCount),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'A safety backup of your current state will be created automatically before restoring.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
            onConfirmRestore();
          },
          child: const Text('Restore Data'),
        ),
      ],
    );
  }

  Widget _buildComparisonHeader() {
    return const Row(
      children: [
        Expanded(
          flex: 2,
          child: Text('Data Type',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        Expanded(
          child: Text('Current',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        Expanded(
          child: Text('Backup',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildComparisonRow(String label, int current, int backup) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: Text('$current',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text('$backup',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../services/backup_service.dart';
import 'clear_data_dialog.dart';
import 'csv_import_dialog.dart';
import 'restore_dialog.dart';

class DataManagementSection extends ConsumerStatefulWidget {
  const DataManagementSection({super.key});

  @override
  ConsumerState<DataManagementSection> createState() =>
      _DataManagementSectionState();
}

class _DataManagementSectionState
    extends ConsumerState<DataManagementSection> {
  StorageInfo? _storageInfo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshStorageInfo();
  }

  Future<void> _refreshStorageInfo() async {
    final info = await BackupService.getStorageInfo(ref);
    if (mounted) {
      setState(() {
        _storageInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);

    final lastBackupText = settings.lastBackupTime != null
        ? '${settings.lastBackupTime!.day}/${settings.lastBackupTime!.month}/${settings.lastBackupTime!.year} at ${settings.lastBackupTime!.hour}:${settings.lastBackupTime!.minute.toString().padLeft(2, '0')}'
        : 'Never';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Data Management',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // STORAGE INFO GRID
            if (_storageInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Database Storage Size',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          _storageInfo!.dbFileSizeFormatted,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                    const Divider(),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        _buildCountChip('Tasks', _storageInfo!.taskCount),
                        _buildCountChip('Subtasks', _storageInfo!.subtaskCount),
                        _buildCountChip('Expenses', _storageInfo!.expenseCount),
                        _buildCountChip('Income', _storageInfo!.incomeCount),
                        _buildCountChip('Budgets', _storageInfo!.budgetCount),
                        _buildCountChip('Savings', _storageInfo!.savingsCount),
                        _buildCountChip('Subscriptions', _storageInfo!.subscriptionCount),
                        _buildCountChip('Notifications', _storageInfo!.notificationCount),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // BACKUP SETTINGS & TIMESTAMP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Last Backup',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(lastBackupText,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Switch(
                  value: settings.autoBackupEnabled,
                  onChanged: (val) {
                    ref.read(appSettingsProvider.notifier).updateSettings(
                          settings.copyWith(autoBackupEnabled: val),
                        );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // BACKUP & RESTORE BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleExportBackup,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Backup Data'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleRestoreBackup,
                    icon: const Icon(Icons.upload_rounded, size: 18),
                    label: const Text('Restore Backup'),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // CSV EXPORT / IMPORT
            const Text(
              'CSV Export & Import',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _handleExportCsv('tasks'),
                  icon: const Icon(Icons.file_present_rounded, size: 16),
                  label: const Text('Export Tasks CSV'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _handleExportCsv('expenses'),
                  icon: const Icon(Icons.file_present_rounded, size: 16),
                  label: const Text('Export Expenses CSV'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _handleExportCsv('income'),
                  icon: const Icon(Icons.file_present_rounded, size: 16),
                  label: const Text('Export Income CSV'),
                ),
                ElevatedButton.icon(
                  onPressed: _handleImportCsv,
                  icon: const Icon(Icons.file_upload_outlined, size: 16),
                  label: const Text('Import CSV Data'),
                ),
              ],
            ),
            const Divider(height: 32),

            // CLEAR DATA OPTIONS
            const Text(
              'Clear Data',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14, color: Colors.red),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _showClearConfirmation(
                    title: 'Clear Tasks',
                    description:
                        'Are you sure you want to clear all task and subtask records?',
                    affectedItemsText: 'All Tasks & Subtasks',
                    onConfirm: () => BackupService.clearData(ref, clearTasks: true)
                        .then((_) => _refreshStorageInfo()),
                  ),
                  child: const Text('Clear Tasks'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _showClearConfirmation(
                    title: 'Clear Finance Data',
                    description:
                        'Are you sure you want to clear expenses, income, budgets, savings, and subscriptions?',
                    affectedItemsText:
                        'Expenses, Income, Budgets, Savings Goals, Subscriptions',
                    onConfirm: () =>
                        BackupService.clearData(ref, clearFinance: true)
                            .then((_) => _refreshStorageInfo()),
                  ),
                  child: const Text('Clear Finance'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _showClearConfirmation(
                    title: 'Clear Notifications',
                    description:
                        'Are you sure you want to clear notification history?',
                    affectedItemsText: 'All App Notifications',
                    onConfirm: () =>
                        BackupService.clearData(ref, clearNotifications: true)
                            .then((_) => _refreshStorageInfo()),
                  ),
                  child: const Text('Clear Notifications'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showClearConfirmation(
                    title: 'Clear All Data',
                    description:
                        'This will permanently delete all tasks, finance items, notifications, and reset app data.',
                    affectedItemsText:
                        'Tasks, Subtasks, Expenses, Income, Budgets, Savings Goals, Subscriptions, Notifications',
                    requireDeleteText: true,
                    onConfirm: () => BackupService.clearData(ref, clearAll: true)
                        .then((_) => _refreshStorageInfo()),
                  ),
                  child: const Text('Clear All Data'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountChip(String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text('$count',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _handleExportBackup() async {
    setState(() => _isLoading = true);
    try {
      final path = await BackupService.exportBackupJson(ref);
      await _refreshStorageInfo();
      if (mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup exported successfully to: $path'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Backup JSON File',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      final file = File(filePath);
      final content = await file.readAsString();

      final validation = BackupService.validateBackupJson(content);
      if (!validation.isValid || validation.backupJson == null) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Invalid Backup File'),
              content: Text(validation.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final currentStorage = await BackupService.getStorageInfo(ref);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => RestoreConfirmationDialog(
            validationResult: validation,
            currentStorage: currentStorage,
            onConfirmRestore: () async {
              setState(() => _isLoading = true);
              try {
                final success = await BackupService.restoreBackup(
                    ref, validation.backupJson!);
                await _refreshStorageInfo();
                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Backup restored successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Restore failed. Your data has been kept safe: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading backup file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleExportCsv(String type) async {
    setState(() => _isLoading = true);
    try {
      String? savePath;
      if (type == 'tasks') {
        savePath = await BackupService.exportTasksCsv(ref);
      } else if (type == 'expenses') {
        savePath = await BackupService.exportExpensesCsv(ref);
      } else if (type == 'income') {
        savePath = await BackupService.exportIncomeCsv(ref);
      }

      if (mounted && savePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exported successfully to $savePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export CSV failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleImportCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select CSV File to Import',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      final file = File(filePath);
      final content = await file.readAsString();

      // Ask user which type to import if filename doesn't contain type
      final lowerPath = filePath.toLowerCase();
      String type = 'expenses';
      if (lowerPath.contains('task')) {
        type = 'tasks';
      } else if (lowerPath.contains('income')) {
        type = 'income';
      }

      final preview = BackupService.previewCsvImport(content, type);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => CsvImportDialog(
            preview: preview,
            onConfirmImport: () async {
              setState(() => _isLoading = true);
              try {
                final count =
                    await BackupService.processCsvImport(ref, preview);
                await _refreshStorageInfo();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully imported $count rows!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Import CSV failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading CSV file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearConfirmation({
    required String title,
    required String description,
    required String affectedItemsText,
    bool requireDeleteText = false,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => ClearDataDialog(
        title: title,
        description: description,
        affectedItemsText: affectedItemsText,
        requireDeleteText: requireDeleteText,
        onConfirm: () async {
          onConfirm();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title completed successfully.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
      ),
    );
  }
}

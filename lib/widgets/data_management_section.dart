import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../services/backup_service.dart';
import 'clear_data_dialog.dart';
import 'neumorphic_button.dart';
import 'neumorphic_card.dart';
import 'neumorphic_container.dart';
import 'restore_dialog.dart';

class DataManagementSection extends ConsumerStatefulWidget {
  const DataManagementSection({super.key});

  @override
  ConsumerState<DataManagementSection> createState() =>
      _DataManagementSectionState();
}

class _DataManagementSectionState extends ConsumerState<DataManagementSection> {
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

    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.storage_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Data Management',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
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
            NeumorphicContainer(
              style: NeumorphicStyle.inset,
              borderRadius: 12,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Database Storage Size',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _storageInfo!.dbFileSizeFormatted,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tasks (${_storageInfo!.taskCount}) • Expenses (${_storageInfo!.expenseCount}) • Income (${_storageInfo!.incomeCount})',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last Full Backup',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    lastBackupText,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // BACKUP & RESTORE ACTIONS
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              NeumorphicButton(
                icon: Icons.backup_outlined,
                label: 'Backup JSON',
                onPressed: _isLoading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isLoading = true);
                        try {
                          final path = await BackupService.exportBackupJson(
                            ref,
                          );
                          await _refreshStorageInfo();
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Backup saved to $path')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Backup failed: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
              ),
              NeumorphicButton(
                icon: Icons.restore_outlined,
                label: 'Restore JSON',
                onPressed: _isLoading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['json'],
                        );
                        if (result != null &&
                            result.files.single.path != null) {
                          final file = File(result.files.single.path!);
                          final jsonStr = await file.readAsString();
                          final validation = BackupService.validateBackupJson(
                            jsonStr,
                          );
                          if (!validation.isValid) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Invalid backup file: ${validation.message}',
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                          final currentStorage =
                              await BackupService.getStorageInfo(ref);
                          if (!mounted) return;
                          showDialog(
                            context: this.context,
                            builder: (_) => RestoreConfirmationDialog(
                              validationResult: validation,
                              currentStorage: currentStorage,
                              onConfirmRestore: () async {
                                await BackupService.restoreBackup(
                                  ref,
                                  validation.backupJson!,
                                );
                              },
                            ),
                          );
                        }
                      },
              ),
              NeumorphicButton(
                icon: Icons.file_upload_outlined,
                label: 'Export Tasks CSV',
                onPressed: _isLoading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isLoading = true);
                        try {
                          final path = await BackupService.exportTasksCsv(ref);
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Exported CSV file to $path'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('CSV Export failed: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
              ),
            ],
          ),

          const Divider(height: 32),

          // DANGER ZONE / CLEAR DATA
          NeumorphicButton(
            icon: Icons.delete_forever_outlined,
            label: 'Clear All Data',
            color: Colors.red,
            textColor: Colors.white,
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => ClearDataDialog(
                  title: 'Clear All Application Data',
                  description:
                      'Are you sure you want to delete all local tasks, expenses, budgets, and settings?',
                  affectedItemsText:
                      'All tasks, subtasks, expenses, income, budgets, savings goals, subscriptions, and settings will be permanently deleted.',
                  requireDeleteText: true,
                  onConfirm: () async {
                    await BackupService.clearData(ref, clearAll: true);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

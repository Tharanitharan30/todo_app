import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/focus_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import 'notification_service.dart';

class BackupValidationResult {
  final bool isValid;
  final String message;
  final int taskCount;
  final int subtaskCount;
  final int expenseCount;
  final int incomeCount;
  final int budgetCount;
  final int savingsCount;
  final int subscriptionCount;
  final int notificationCount;
  final int settingsCount;
  final Map<String, dynamic>? backupJson;

  BackupValidationResult({
    required this.isValid,
    required this.message,
    this.taskCount = 0,
    this.subtaskCount = 0,
    this.expenseCount = 0,
    this.incomeCount = 0,
    this.budgetCount = 0,
    this.savingsCount = 0,
    this.subscriptionCount = 0,
    this.notificationCount = 0,
    this.settingsCount = 0,
    this.backupJson,
  });
}

class StorageInfo {
  final int taskCount;
  final int subtaskCount;
  final int expenseCount;
  final int incomeCount;
  final int budgetCount;
  final int savingsCount;
  final int subscriptionCount;
  final int notificationCount;
  final String dbFileSizeFormatted;

  StorageInfo({
    required this.taskCount,
    required this.subtaskCount,
    required this.expenseCount,
    required this.incomeCount,
    required this.budgetCount,
    required this.savingsCount,
    required this.subscriptionCount,
    required this.notificationCount,
    required this.dbFileSizeFormatted,
  });
}

class CsvImportPreview {
  final int totalRows;
  final int validRows;
  final int invalidRows;
  final List<Map<String, dynamic>> validItems;
  final String type;

  CsvImportPreview({
    required this.totalRows,
    required this.validRows,
    required this.invalidRows,
    required this.validItems,
    required this.type,
  });
}

class BackupService {
  // ==========================================
  // EXPORT BACKUP JSON
  // ==========================================
  static Future<String?> exportBackupJson(WidgetRef ref) async {
    final db = ref.read(databaseProvider);

    final tasksList = await db.getAllTasks();
    final subtasksList = await db.select(db.subtasks).get();
    final expensesList = await db.getAllExpenses();
    final incomeList = await db.getAllIncome();
    final budgetsList = await db.getAllBudgets();
    final savingsList = await db.getAllSavingsGoals();
    final subscriptionsList = await db.getAllSubscriptions();
    final notificationsList = await db.select(db.appNotifications).get();
    final focusSessionsList = await db.getAllFocusSessions();
    final settingsList = await db.getAllSettings();

    final backupMap = {
      'app': 'Personal Command Center',
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'data': {
        'tasks': tasksList
            .map(
              (t) => {
                'id': t.id,
                'title': t.title,
                'description': t.description,
                'dueDate': t.dueDate?.toIso8601String(),
                'dueTime': t.dueTime?.toIso8601String(),
                'priority': t.priority,
                'category': t.category,
                'status': t.status,
                'isRecurring': t.isRecurring,
                'recurrenceRule': t.recurrenceRule,
                'isImportant': t.isImportant,
                'createdAt': t.createdAt.toIso8601String(),
                'completedAt': t.completedAt?.toIso8601String(),
                'tags': t.tags,
                'reminderAt': t.reminderAt?.toIso8601String(),
                'notes': t.notes,
              },
            )
            .toList(),
        'subtasks': subtasksList
            .map(
              (s) => {
                'id': s.id,
                'taskId': s.taskId,
                'title': s.title,
                'completed': s.completed,
              },
            )
            .toList(),
        'expenses': expensesList
            .map(
              (e) => {
                'id': e.id,
                'amount': e.amount,
                'category': e.category,
                'date': e.date.toIso8601String(),
                'paymentMethod': e.paymentMethod,
                'note': e.note,
                'isRecurring': e.isRecurring,
                'createdAt': e.createdAt.toIso8601String(),
              },
            )
            .toList(),
        'income': incomeList
            .map(
              (i) => {
                'id': i.id,
                'amount': i.amount,
                'source': i.source,
                'date': i.date.toIso8601String(),
                'note': i.note,
                'isRecurring': i.isRecurring,
                'createdAt': i.createdAt.toIso8601String(),
              },
            )
            .toList(),
        'budgets': budgetsList
            .map(
              (b) => {
                'id': b.id,
                'category': b.category,
                'amount': b.amount,
                'createdAt': b.createdAt.toIso8601String(),
              },
            )
            .toList(),
        'savingsGoals': savingsList
            .map(
              (s) => {
                'id': s.id,
                'name': s.name,
                'targetAmount': s.targetAmount,
                'currentAmount': s.currentAmount,
                'targetDate': s.targetDate?.toIso8601String(),
                'createdAt': s.createdAt.toIso8601String(),
              },
            )
            .toList(),
        'subscriptions': subscriptionsList
            .map(
              (s) => {
                'id': s.id,
                'name': s.name,
                'amount': s.amount,
                'billingCycle': s.billingCycle,
                'nextBillingDate': s.nextBillingDate.toIso8601String(),
                'active': s.active,
                'createdAt': s.createdAt.toIso8601String(),
              },
            )
            .toList(),
        'notifications': notificationsList
            .map(
              (n) => {
                'id': n.id,
                'type': n.type,
                'referenceId': n.referenceId,
                'title': n.title,
                'body': n.body,
                'scheduledAt': n.scheduledAt.toIso8601String(),
                'enabled': n.enabled,
                'read': n.read,
                'payload': n.payload,
                'createdAt': n.createdAt.toIso8601String(),
              },
            )
            .toList(),
        'focusSessions': focusSessionsList
            .map(
              (f) => {
                'id': f.id,
                'taskId': f.taskId,
                'startedAt': f.startedAt.toIso8601String(),
                'endedAt': f.endedAt?.toIso8601String(),
                'durationSeconds': f.durationSeconds,
                'type': f.type,
                'completed': f.completed,
                'createdAt': f.createdAt.toIso8601String(),
              },
            )
            .toList(),
        'settings': settingsList
            .map((s) => {'key': s.key, 'value': s.value})
            .toList(),
      },
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupMap);
    final nowStr = DateTime.now().toIso8601String().split('T').first;
    final fileName = 'personal_command_center_backup_$nowStr.json';

    String? savePath;
    try {
      savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup JSON File',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
    } catch (e) {
      debugPrint('FilePicker save error: $e');
    }

    if (savePath == null) {
      final docDir = await getApplicationDocumentsDirectory();
      savePath = path.join(docDir.path, fileName);
    }

    final file = File(savePath);
    await file.writeAsString(jsonString);

    // Update last backup time setting
    final currentSettings = ref.read(appSettingsProvider);
    await ref
        .read(appSettingsProvider.notifier)
        .updateSettings(
          currentSettings.copyWith(lastBackupTime: DateTime.now()),
        );

    return savePath;
  }

  // ==========================================
  // VALIDATE BACKUP JSON
  // ==========================================
  static BackupValidationResult validateBackupJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return BackupValidationResult(
          isValid: false,
          message: 'Invalid JSON structure. Root element must be an object.',
        );
      }

      if (decoded['app'] != 'Personal Command Center') {
        return BackupValidationResult(
          isValid: false,
          message:
              'Invalid backup file.\nThis file does not appear to be a valid Personal Command Center backup.',
        );
      }

      final data = decoded['data'];
      if (data == null || data is! Map<String, dynamic>) {
        return BackupValidationResult(
          isValid: false,
          message: 'Invalid backup file: Missing "data" section.',
        );
      }

      final tasks = data['tasks'] as List? ?? [];
      final subtasks = data['subtasks'] as List? ?? [];
      final expenses = data['expenses'] as List? ?? [];
      final income = data['income'] as List? ?? [];
      final budgets = data['budgets'] as List? ?? [];
      final savingsGoals = data['savingsGoals'] as List? ?? [];
      final subscriptions = data['subscriptions'] as List? ?? [];
      final notifications = data['notifications'] as List? ?? [];
      final settings = data['settings'] as List? ?? [];

      return BackupValidationResult(
        isValid: true,
        message: 'Valid Personal Command Center backup file.',
        taskCount: tasks.length,
        subtaskCount: subtasks.length,
        expenseCount: expenses.length,
        incomeCount: income.length,
        budgetCount: budgets.length,
        savingsCount: savingsGoals.length,
        subscriptionCount: subscriptions.length,
        notificationCount: notifications.length,
        settingsCount: settings.length,
        backupJson: decoded,
      );
    } catch (e) {
      return BackupValidationResult(
        isValid: false,
        message: 'Error reading JSON file: $e',
      );
    }
  }

  // ==========================================
  // RESTORE BACKUP JSON WITH SAFETY & ROLLBACK
  // ==========================================
  static Future<bool> restoreBackup(
    WidgetRef ref,
    Map<String, dynamic> backupJson,
  ) async {
    final db = ref.read(databaseProvider);
    final appSupportDir = await getApplicationSupportDirectory();
    final safetyBackupFile = File(
      path.join(appSupportDir.path, 'safety_backup_temp.json'),
    );

    // Step 1: Create local safety backup
    try {
      final currentBackupPath = await exportBackupJson(ref);
      if (currentBackupPath != null) {
        final currentFile = File(currentBackupPath);
        if (await currentFile.exists()) {
          await currentFile.copy(safetyBackupFile.path);
        }
      }
    } catch (e) {
      debugPrint('Warning creating safety backup: $e');
    }

    // Step 2: Transactional database restore
    try {
      await db.transaction(() async {
        // Clear existing tables
        await db.delete(db.subtasks).go();
        await db.delete(db.focusSessions).go();
        await db.delete(db.tasks).go();
        await db.delete(db.expenses).go();
        await db.delete(db.income).go();
        await db.delete(db.budgets).go();
        await db.delete(db.savingsGoals).go();
        await db.delete(db.subscriptions).go();
        await db.delete(db.appNotifications).go();
        await db.delete(db.settings).go();

        final data = backupJson['data'] as Map<String, dynamic>;

        // Insert Tasks & Map IDs for Subtasks
        final Map<int, int> taskIdMapping = {};
        final rawTasks = data['tasks'] as List? ?? [];
        for (final rawT in rawTasks) {
          final t = rawT as Map<String, dynamic>;
          final oldId = t['id'] as int?;
          final newId = await db
              .into(db.tasks)
              .insert(
                TasksCompanion.insert(
                  title: t['title'] ?? 'Untitled',
                  description: Value(t['description'] ?? ''),
                  dueDate: Value(
                    t['dueDate'] != null
                        ? DateTime.tryParse(t['dueDate'])
                        : null,
                  ),
                  dueTime: Value(
                    t['dueTime'] != null
                        ? DateTime.tryParse(t['dueTime'])
                        : null,
                  ),
                  priority: Value(t['priority'] ?? 'medium'),
                  category: Value(t['category'] ?? 'personal'),
                  status: Value(t['status'] ?? 'pending'),
                  isRecurring: Value(t['isRecurring'] ?? false),
                  recurrenceRule: Value(t['recurrenceRule']),
                  isImportant: Value(t['isImportant'] ?? false),
                  createdAt: Value(
                    t['createdAt'] != null
                        ? DateTime.parse(t['createdAt'])
                        : DateTime.now(),
                  ),
                  completedAt: Value(
                    t['completedAt'] != null
                        ? DateTime.tryParse(t['completedAt'])
                        : null,
                  ),
                  tags: Value(t['tags'] ?? ''),
                  reminderAt: Value(
                    t['reminderAt'] != null
                        ? DateTime.tryParse(t['reminderAt'])
                        : null,
                  ),
                  notes: Value(t['notes'] ?? ''),
                ),
              );
          if (oldId != null) {
            taskIdMapping[oldId] = newId;
          }
        }

        // Insert Subtasks
        final rawSubtasks = data['subtasks'] as List? ?? [];
        for (final rawS in rawSubtasks) {
          final s = rawS as Map<String, dynamic>;
          final oldTaskId = s['taskId'] as int;
          final mappedTaskId = taskIdMapping[oldTaskId] ?? oldTaskId;
          await db
              .into(db.subtasks)
              .insert(
                SubtasksCompanion.insert(
                  taskId: mappedTaskId,
                  title: s['title'] ?? '',
                  completed: Value(s['completed'] ?? false),
                ),
              );
        }

        // Insert Expenses
        final rawExpenses = data['expenses'] as List? ?? [];
        for (final rawE in rawExpenses) {
          final e = rawE as Map<String, dynamic>;
          await db
              .into(db.expenses)
              .insert(
                ExpensesCompanion.insert(
                  amount: (e['amount'] as num).toDouble(),
                  category: e['category'] ?? 'Other',
                  date: DateTime.parse(e['date']),
                  paymentMethod: Value(e['paymentMethod'] ?? 'cash'),
                  note: Value(e['note'] ?? ''),
                  isRecurring: Value(e['isRecurring'] ?? false),
                  createdAt: Value(
                    e['createdAt'] != null
                        ? DateTime.parse(e['createdAt'])
                        : DateTime.now(),
                  ),
                ),
              );
        }

        // Insert Income
        final rawIncome = data['income'] as List? ?? [];
        for (final rawI in rawIncome) {
          final i = rawI as Map<String, dynamic>;
          await db
              .into(db.income)
              .insert(
                IncomeCompanion.insert(
                  amount: (i['amount'] as num).toDouble(),
                  source: i['source'] ?? 'Other',
                  date: DateTime.parse(i['date']),
                  note: Value(i['note'] ?? ''),
                  isRecurring: Value(i['isRecurring'] ?? false),
                  createdAt: Value(
                    i['createdAt'] != null
                        ? DateTime.parse(i['createdAt'])
                        : DateTime.now(),
                  ),
                ),
              );
        }

        // Insert Budgets
        final rawBudgets = data['budgets'] as List? ?? [];
        for (final rawB in rawBudgets) {
          final b = rawB as Map<String, dynamic>;
          await db
              .into(db.budgets)
              .insert(
                BudgetsCompanion.insert(
                  category: b['category'] ?? 'Other',
                  amount: (b['amount'] as num).toDouble(),
                  createdAt: Value(
                    b['createdAt'] != null
                        ? DateTime.parse(b['createdAt'])
                        : DateTime.now(),
                  ),
                ),
              );
        }

        // Insert Savings Goals
        final rawSavings = data['savingsGoals'] as List? ?? [];
        for (final rawS in rawSavings) {
          final s = rawS as Map<String, dynamic>;
          await db
              .into(db.savingsGoals)
              .insert(
                SavingsGoalsCompanion.insert(
                  name: s['name'] ?? 'Savings Goal',
                  targetAmount: (s['targetAmount'] as num).toDouble(),
                  currentAmount: Value((s['currentAmount'] as num).toDouble()),
                  targetDate: Value(
                    s['targetDate'] != null
                        ? DateTime.tryParse(s['targetDate'])
                        : null,
                  ),
                  createdAt: Value(
                    s['createdAt'] != null
                        ? DateTime.parse(s['createdAt'])
                        : DateTime.now(),
                  ),
                ),
              );
        }

        // Insert Subscriptions
        final rawSubscriptions = data['subscriptions'] as List? ?? [];
        for (final rawSub in rawSubscriptions) {
          final sub = rawSub as Map<String, dynamic>;
          await db
              .into(db.subscriptions)
              .insert(
                SubscriptionsCompanion.insert(
                  name: sub['name'] ?? 'Subscription',
                  amount: (sub['amount'] as num).toDouble(),
                  billingCycle: Value(sub['billingCycle'] ?? 'monthly'),
                  nextBillingDate: DateTime.parse(sub['nextBillingDate']),
                  active: Value(sub['active'] ?? true),
                  createdAt: Value(
                    sub['createdAt'] != null
                        ? DateTime.parse(sub['createdAt'])
                        : DateTime.now(),
                  ),
                ),
              );
        }

        // Insert Notifications
        final rawNotifications = data['notifications'] as List? ?? [];
        for (final rawN in rawNotifications) {
          final n = rawN as Map<String, dynamic>;
          await db
              .into(db.appNotifications)
              .insert(
                AppNotificationsCompanion.insert(
                  type: n['type'] ?? 'general',
                  referenceId: Value(n['referenceId']),
                  title: n['title'] ?? 'Notification',
                  body: n['body'] ?? '',
                  scheduledAt: DateTime.parse(n['scheduledAt']),
                  enabled: Value(n['enabled'] ?? true),
                  read: Value(n['read'] ?? false),
                  payload: Value(n['payload']),
                  createdAt: Value(
                    n['createdAt'] != null
                        ? DateTime.parse(n['createdAt'])
                        : DateTime.now(),
                  ),
                ),
              );
        }

        // Insert Focus Sessions
        final rawFocusSessions = data['focusSessions'] as List? ?? [];
        for (final rawF in rawFocusSessions) {
          final f = rawF as Map<String, dynamic>;
          final oldTaskId = f['taskId'] as int?;
          final mappedTaskId = oldTaskId != null
              ? taskIdMapping[oldTaskId] ?? oldTaskId
              : null;
          await db
              .into(db.focusSessions)
              .insert(
                FocusSessionsCompanion.insert(
                  taskId: Value(mappedTaskId),
                  startedAt: DateTime.parse(f['startedAt']),
                  endedAt: Value(
                    f['endedAt'] != null
                        ? DateTime.tryParse(f['endedAt'])
                        : null,
                  ),
                  durationSeconds: Value(f['durationSeconds'] ?? 0),
                  type: Value(f['type'] ?? 'focus'),
                  completed: Value(f['completed'] ?? true),
                  createdAt: Value(
                    f['createdAt'] != null
                        ? DateTime.parse(f['createdAt'])
                        : DateTime.now(),
                  ),
                ),
              );
        }

        // Insert Settings
        final rawSettings = data['settings'] as List? ?? [];
        for (final rawSt in rawSettings) {
          final st = rawSt as Map<String, dynamic>;
          final key = st['key'] as String?;
          final val = st['value'] as String?;
          if (key != null && val != null) {
            await db.setSetting(key, val);
          }
        }
      });

      // Reload settings provider
      await ref.read(appSettingsProvider.notifier).reloadSettings();

      // Reschedule all local notifications
      await NotificationService().rescheduleAllNotifications(ref);

      // Refresh Riverpod providers
      _invalidateAllProviders(ref);

      return true;
    } catch (e) {
      debugPrint('Restore failed: $e. Attempting rollback to safety backup...');
      try {
        if (await safetyBackupFile.exists()) {
          final safetyContent = await safetyBackupFile.readAsString();
          final validation = validateBackupJson(safetyContent);
          if (validation.isValid && validation.backupJson != null) {
            await restoreBackup(ref, validation.backupJson!);
          }
        }
      } catch (rollbackError) {
        debugPrint('Rollback error: $rollbackError');
      }
      rethrow;
    }
  }

  // ==========================================
  // CSV EXPORT (TASKS, EXPENSES, INCOME)
  // ==========================================
  static Future<String?> exportTasksCsv(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final tasksList = await db.getAllTasks();

    final List<List<dynamic>> rows = [
      [
        'title',
        'priority',
        'category',
        'status',
        'dueDate',
        'dueTime',
        'isImportant',
        'createdAt',
        'notes',
      ],
    ];

    for (final t in tasksList) {
      rows.add([
        t.title,
        t.priority,
        t.category,
        t.status,
        t.dueDate?.toIso8601String() ?? '',
        t.dueTime?.toIso8601String() ?? '',
        t.isImportant,
        t.createdAt.toIso8601String(),
        t.notes,
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    return _saveCsvFile('tasks_export_${_dateStamp()}.csv', csvData);
  }

  static Future<String?> exportExpensesCsv(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final expensesList = await db.getAllExpenses();

    final List<List<dynamic>> rows = [
      ['date', 'amount', 'category', 'paymentMethod', 'note', 'isRecurring'],
    ];

    for (final e in expensesList) {
      rows.add([
        e.date.toIso8601String().split('T').first,
        e.amount,
        e.category,
        e.paymentMethod,
        e.note,
        e.isRecurring,
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    return _saveCsvFile('expenses_export_${_dateStamp()}.csv', csvData);
  }

  static Future<String?> exportIncomeCsv(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final incomeList = await db.getAllIncome();

    final List<List<dynamic>> rows = [
      ['date', 'amount', 'source', 'note', 'isRecurring'],
    ];

    for (final i in incomeList) {
      rows.add([
        i.date.toIso8601String().split('T').first,
        i.amount,
        i.source,
        i.note,
        i.isRecurring,
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    return _saveCsvFile('income_export_${_dateStamp()}.csv', csvData);
  }

  static Future<String?> _saveCsvFile(
    String fileName,
    String csvContent,
  ) async {
    String? savePath;
    try {
      savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV File',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
    } catch (e) {
      debugPrint('FilePicker save CSV error: $e');
    }

    if (savePath == null) {
      final docDir = await getApplicationDocumentsDirectory();
      savePath = path.join(docDir.path, fileName);
    }

    final file = File(savePath);
    await file.writeAsString(csvContent);
    return savePath;
  }

  // ==========================================
  // CSV IMPORT PREVIEW & PROCESS
  // ==========================================
  static CsvImportPreview previewCsvImport(String csvContent, String type) {
    final List<List<dynamic>> rows = const CsvToListConverter().convert(
      csvContent,
    );
    if (rows.isEmpty || rows.length == 1) {
      return CsvImportPreview(
        totalRows: 0,
        validRows: 0,
        invalidRows: 0,
        validItems: [],
        type: type,
      );
    }

    final header = rows[0]
        .map((e) => e.toString().trim().toLowerCase())
        .toList();
    final dataRows = rows.sublist(1);

    List<Map<String, dynamic>> validItems = [];
    int invalidCount = 0;

    for (final row in dataRows) {
      if (row.isEmpty ||
          row.every((element) => element.toString().trim().isEmpty)) {
        continue;
      }
      final map = <String, dynamic>{};
      for (int i = 0; i < header.length && i < row.length; i++) {
        map[header[i]] = row[i];
      }

      bool isValid = false;
      if (type == 'expenses') {
        final amount = double.tryParse(map['amount']?.toString() ?? '');
        final category = map['category']?.toString();
        if (amount != null && category != null && category.isNotEmpty) {
          map['amount'] = amount;
          map['category'] = category;
          map['date'] =
              DateTime.tryParse(map['date']?.toString() ?? '') ??
              DateTime.now();
          map['paymentmethod'] = map['paymentmethod']?.toString() ?? 'cash';
          map['note'] = map['note']?.toString() ?? '';
          isValid = true;
        }
      } else if (type == 'income') {
        final amount = double.tryParse(map['amount']?.toString() ?? '');
        final source = map['source']?.toString();
        if (amount != null && source != null && source.isNotEmpty) {
          map['amount'] = amount;
          map['source'] = source;
          map['date'] =
              DateTime.tryParse(map['date']?.toString() ?? '') ??
              DateTime.now();
          map['note'] = map['note']?.toString() ?? '';
          isValid = true;
        }
      } else if (type == 'tasks') {
        final title = map['title']?.toString();
        if (title != null && title.isNotEmpty) {
          map['title'] = title;
          map['priority'] = map['priority']?.toString() ?? 'medium';
          map['category'] = map['category']?.toString() ?? 'personal';
          map['status'] = map['status']?.toString() ?? 'pending';
          isValid = true;
        }
      }

      if (isValid) {
        validItems.add(map);
      } else {
        invalidCount++;
      }
    }

    return CsvImportPreview(
      totalRows: dataRows.length,
      validRows: validItems.length,
      invalidRows: invalidCount,
      validItems: validItems,
      type: type,
    );
  }

  static Future<int> processCsvImport(
    WidgetRef ref,
    CsvImportPreview preview,
  ) async {
    final db = ref.read(databaseProvider);
    int count = 0;

    if (preview.type == 'expenses') {
      for (final item in preview.validItems) {
        await db.addExpense(
          ExpensesCompanion.insert(
            amount: item['amount'] as double,
            category: item['category'] as String,
            date: item['date'] as DateTime,
            paymentMethod: Value(item['paymentmethod'] ?? 'cash'),
            note: Value(item['note'] ?? ''),
          ),
        );
        count++;
      }
    } else if (preview.type == 'income') {
      for (final item in preview.validItems) {
        await db.addIncome(
          IncomeCompanion.insert(
            amount: item['amount'] as double,
            source: item['source'] as String,
            date: item['date'] as DateTime,
            note: Value(item['note'] ?? ''),
          ),
        );
        count++;
      }
    } else if (preview.type == 'tasks') {
      for (final item in preview.validItems) {
        await db.addTask(
          TasksCompanion.insert(
            title: item['title'] as String,
            priority: Value(item['priority'] ?? 'medium'),
            category: Value(item['category'] ?? 'personal'),
            status: Value(item['status'] ?? 'pending'),
          ),
        );
        count++;
      }
    }

    _invalidateAllProviders(ref);
    return count;
  }

  // ==========================================
  // DATA CLEARING
  // ==========================================
  static Future<void> clearData(
    WidgetRef ref, {
    bool clearTasks = false,
    bool clearFinance = false,
    bool clearNotifications = false,
    bool clearAll = false,
  }) async {
    final db = ref.read(databaseProvider);

    await db.transaction(() async {
      if (clearAll || clearTasks) {
        await db.delete(db.subtasks).go();
        await db.delete(db.focusSessions).go();
        await db.delete(db.tasks).go();
      }
      if (clearAll || clearFinance) {
        await db.delete(db.expenses).go();
        await db.delete(db.income).go();
        await db.delete(db.budgets).go();
        await db.delete(db.savingsGoals).go();
        await db.delete(db.subscriptions).go();
      }
      if (clearAll || clearNotifications) {
        await db.delete(db.appNotifications).go();
      }
    });

    if (clearAll || clearNotifications || clearTasks) {
      await NotificationService().rescheduleAllNotifications(ref);
    }

    _invalidateAllProviders(ref);
  }

  // ==========================================
  // STORAGE INFO
  // ==========================================
  static Future<StorageInfo> getStorageInfo(WidgetRef ref) async {
    final db = ref.read(databaseProvider);

    final tasks = await db.getAllTasks();
    final subtasks = await db.select(db.subtasks).get();
    final expenses = await db.getAllExpenses();
    final income = await db.getAllIncome();
    final budgets = await db.getAllBudgets();
    final savings = await db.getAllSavingsGoals();
    final subscriptions = await db.getAllSubscriptions();
    final notifications = await db.select(db.appNotifications).get();

    String formattedSize = 'Unknown';
    try {
      final appSupportDir = await getApplicationSupportDirectory();
      final dbFile = File(
        path.join(appSupportDir.path, 'personal_command_center.sqlite'),
      );
      if (await dbFile.exists()) {
        final bytes = await dbFile.length();
        if (bytes < 1024 * 1024) {
          formattedSize = '${(bytes / 1024).toStringAsFixed(1)} KB';
        } else {
          formattedSize = '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
        }
      }
    } catch (e) {
      debugPrint('Error getting DB file size: $e');
    }

    return StorageInfo(
      taskCount: tasks.length,
      subtaskCount: subtasks.length,
      expenseCount: expenses.length,
      incomeCount: income.length,
      budgetCount: budgets.length,
      savingsCount: savings.length,
      subscriptionCount: subscriptions.length,
      notificationCount: notifications.length,
      dbFileSizeFormatted: formattedSize,
    );
  }

  static void _invalidateAllProviders(WidgetRef ref) {
    ref.invalidate(appNotificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
    ref.invalidate(todayFocusSessionsProvider);
    ref.invalidate(todayFocusTimeSecondsProvider);
    ref.invalidate(weeklyFocusTimeSecondsProvider);
  }

  static String _dateStamp() {
    return DateTime.now().toIso8601String().split('T').first;
  }
}

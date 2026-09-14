import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';

class AddTaskDialog extends ConsumerStatefulWidget {
  final Task? taskToEdit;
  final DateTime? initialDueDate;
  final TimeOfDay? initialDueTime;

  const AddTaskDialog({
    super.key,
    this.taskToEdit,
    this.initialDueDate,
    this.initialDueTime,
  });

  @override
  ConsumerState<AddTaskDialog> createState() {
    return _AddTaskDialogState();
  }
}

class _AddTaskDialogState extends ConsumerState<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController notesController;
  late TextEditingController tagsController;

  late String priority;
  late String category;
  late bool isImportant;
  late bool isRecurring;
  late String recurrenceRule;

  DateTime? dueDate;
  TimeOfDay? dueTime;
  DateTime? reminderAt;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.taskToEdit;
    final settings = ref.read(appSettingsProvider);

    titleController = TextEditingController(text: t?.title ?? '');
    descriptionController = TextEditingController(text: t?.description ?? '');
    notesController = TextEditingController(text: t?.notes ?? '');
    tagsController = TextEditingController(text: t?.tags ?? '');

    priority = t?.priority ?? settings.defaultTaskPriority;
    category = t?.category ?? settings.defaultTaskCategory;
    isImportant = t?.isImportant ?? false;
    isRecurring = t?.isRecurring ?? false;
    recurrenceRule = t?.recurrenceRule ?? 'daily';

    dueDate = t?.dueDate ?? widget.initialDueDate;
    if (t?.dueTime != null) {
      dueTime = TimeOfDay(hour: t!.dueTime!.hour, minute: t.dueTime!.minute);
    } else if (widget.initialDueTime != null) {
      dueTime = widget.initialDueTime;
    }
    reminderAt = t?.reminderAt;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    notesController.dispose();
    tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        dueDate = picked;
      });
    }
  }

  Future<void> _pickDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        dueTime = picked;
      });
    }
  }

  Future<void> _pickReminder() async {
    if (dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Due Date before setting a reminder.'),
        ),
      );
      return;
    }

    final selection = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              title: Text(
                'Select Reminder Option',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('10 minutes before'),
              onTap: () => Navigator.pop(ctx, '10m'),
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('30 minutes before'),
              onTap: () => Navigator.pop(ctx, '30m'),
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('1 hour before'),
              onTap: () => Navigator.pop(ctx, '1h'),
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('1 day before'),
              onTap: () => Navigator.pop(ctx, '1d'),
            ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('Clear reminder'),
              onTap: () => Navigator.pop(ctx, 'clear'),
            ),
          ],
        ),
      ),
    );

    if (selection == null) return;
    if (selection == 'clear') {
      setState(() {
        reminderAt = null;
      });
      return;
    }

    DateTime dueDateTime = dueDate!;
    if (dueTime != null) {
      dueDateTime = DateTime(
        dueDate!.year,
        dueDate!.month,
        dueDate!.day,
        dueTime!.hour,
        dueTime!.minute,
      );
    }

    DateTime computedReminder;
    switch (selection) {
      case '10m':
        computedReminder = dueDateTime.subtract(const Duration(minutes: 10));
        break;
      case '30m':
        computedReminder = dueDateTime.subtract(const Duration(minutes: 30));
        break;
      case '1h':
        computedReminder = dueDateTime.subtract(const Duration(hours: 1));
        break;
      case '1d':
        computedReminder = dueDateTime.subtract(const Duration(days: 1));
        break;
      default:
        computedReminder = dueDateTime;
    }

    setState(() {
      reminderAt = computedReminder;
    });
  }

  Future<void> saveTask() async {
    final title = titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final database = ref.read(databaseProvider);
      DateTime? dueTimeDateTime;
      if (dueTime != null) {
        dueTimeDateTime = DateTime(2000, 1, 1, dueTime!.hour, dueTime!.minute);
      }

      if (widget.taskToEdit == null) {
        debugPrint('Attempting to add task: $title');
        final companion = TasksCompanion.insert(
          title: title,
          description: drift.Value(descriptionController.text.trim()),
          dueDate: drift.Value(dueDate),
          dueTime: drift.Value(dueTimeDateTime),
          priority: drift.Value(priority),
          category: drift.Value(category),
          status: const drift.Value('pending'),
          isRecurring: drift.Value(isRecurring),
          recurrenceRule: drift.Value(isRecurring ? recurrenceRule : null),
          isImportant: drift.Value(isImportant),
          tags: drift.Value(tagsController.text.trim()),
          reminderAt: drift.Value(reminderAt),
          notes: drift.Value(notesController.text.trim()),
        );

        final id = await database.addTask(companion);
        debugPrint('Task inserted successfully. ID: $id');

        if (reminderAt != null) {
          await NotificationService().scheduleTaskReminder(
            taskId: id,
            title: title,
            body: descriptionController.text.trim().isNotEmpty
                ? descriptionController.text.trim()
                : 'Task due soon!',
            scheduledDate: reminderAt!,
          );
          await database.addAppNotification(
            AppNotificationsCompanion(
              type: const drift.Value('task_reminder'),
              referenceId: drift.Value(id),
              title: drift.Value('Task Reminder: $title'),
              body: drift.Value('Scheduled reminder for task'),
              scheduledAt: drift.Value(reminderAt!),
              payload: drift.Value('task:$id'),
            ),
          );
        }
      } else {
        final existing = widget.taskToEdit!;
        final updated = existing.copyWith(
          title: title,
          description: descriptionController.text.trim(),
          dueDate: drift.Value(dueDate),
          dueTime: drift.Value(dueTimeDateTime),
          priority: priority,
          category: category,
          isRecurring: isRecurring,
          recurrenceRule: drift.Value(isRecurring ? recurrenceRule : null),
          isImportant: isImportant,
        );

        // Update task with tags, reminderAt, notes
        final companion = updated
            .toCompanion(true)
            .copyWith(
              tags: drift.Value(tagsController.text.trim()),
              reminderAt: drift.Value(reminderAt),
              notes: drift.Value(notesController.text.trim()),
            );

        await database.updateTask(updated.copyWithCompanion(companion));

        if (reminderAt != null) {
          await NotificationService().scheduleTaskReminder(
            taskId: existing.id,
            title: title,
            body: descriptionController.text.trim().isNotEmpty
                ? descriptionController.text.trim()
                : 'Task due soon!',
            scheduledDate: reminderAt!,
          );
          await database.addAppNotification(
            AppNotificationsCompanion(
              type: const drift.Value('task_reminder'),
              referenceId: drift.Value(existing.id),
              title: drift.Value('Task Reminder: $title'),
              body: drift.Value('Updated reminder for task'),
              scheduledAt: drift.Value(reminderAt!),
              payload: drift.Value('task:${existing.id}'),
            ),
          );
        } else {
          await NotificationService().cancelTaskNotifications(existing.id);
        }
      }

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.taskToEdit == null
                ? 'Task added successfully'
                : 'Task updated successfully',
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('TASK SAVE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Could not save task'),
            content: SingleChildScrollView(child: Text('$error')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.taskToEdit != null;

    return AlertDialog(
      title: Text(
        isEditing ? 'Edit Task' : 'Add Task',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextFormField(
                  controller: titleController,
                  autofocus: !isEditing,
                  decoration: const InputDecoration(
                    labelText: 'Task title *',
                    hintText: 'What needs to be done?',
                    prefixIcon: Icon(Icons.task_alt),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Title is required'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // Description
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional summary or details',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                // Priority & Category Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'urgent',
                            child: Text('Urgent'),
                          ),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                          DropdownMenuItem(
                            value: 'medium',
                            child: Text('Medium'),
                          ),
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                        ],
                        onChanged: isSaving
                            ? null
                            : (val) {
                                if (val != null) setState(() => priority = val);
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'personal',
                            child: Text('Personal'),
                          ),
                          DropdownMenuItem(value: 'work', child: Text('Work')),
                          DropdownMenuItem(
                            value: 'study',
                            child: Text('Study'),
                          ),
                          DropdownMenuItem(
                            value: 'project',
                            child: Text('Project'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: isSaving
                            ? null
                            : (val) {
                                if (val != null) setState(() => category = val);
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Date & Time Pickers
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSaving ? null : _pickDueDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          dueDate == null
                              ? 'Set Due Date'
                              : '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                        ),
                      ),
                    ),
                    if (dueDate != null) ...[
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() {
                          dueDate = null;
                          dueTime = null;
                          reminderAt = null;
                        }),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSaving ? null : _pickDueTime,
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(
                          dueTime == null
                              ? 'Set Due Time'
                              : dueTime!.format(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Reminder button
                OutlinedButton.icon(
                  onPressed: isSaving ? null : _pickReminder,
                  icon: const Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                  ),
                  label: Text(
                    reminderAt == null
                        ? 'Set Reminder'
                        : 'Reminder: ${reminderAt!.day}/${reminderAt!.month} at ${reminderAt!.hour}:${reminderAt!.minute.toString().padLeft(2, '0')}',
                  ),
                ),
                const SizedBox(height: 14),

                // Tags Input
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags',
                    hintText: 'Comma separated e.g. urgent, home, feature',
                    prefixIcon: Icon(Icons.label_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                // Notes Input
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Additional reference notes',
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                ),
                const SizedBox(height: 10),

                // Toggles: Important & Recurring
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mark as Important'),
                  secondary: const Icon(Icons.star_outline),
                  value: isImportant,
                  onChanged: (val) => setState(() => isImportant = val),
                ),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Recurring Task'),
                  secondary: const Icon(Icons.repeat),
                  value: isRecurring,
                  onChanged: (val) => setState(() => isRecurring = val),
                ),

                if (isRecurring) ...[
                  DropdownButtonFormField<String>(
                    initialValue: recurrenceRule,
                    decoration: const InputDecoration(
                      labelText: 'Recurrence Rule',
                      prefixIcon: Icon(Icons.update),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'daily',
                        child: Text('Every day'),
                      ),
                      DropdownMenuItem(
                        value: 'weekly',
                        child: Text('Every week'),
                      ),
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text('Every month'),
                      ),
                      DropdownMenuItem(value: 'custom', child: Text('Custom')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => recurrenceRule = val);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: isSaving ? null : saveTask,
          icon: isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(isEditing ? Icons.save : Icons.add),
          label: Text(
            isSaving ? 'Saving...' : (isEditing ? 'Save Changes' : 'Add Task'),
          ),
        ),
      ],
    );
  }
}

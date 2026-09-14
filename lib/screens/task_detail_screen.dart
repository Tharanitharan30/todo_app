import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/focus_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/common_widgets.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final int taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final subtaskController = TextEditingController();

  @override
  void dispose() {
    subtaskController.dispose();
    super.dispose();
  }

  Future<void> _addSubtask(AppDatabase database) async {
    final title = subtaskController.text.trim();
    if (title.isEmpty) return;

    await database.addSubtask(
      SubtasksCompanion.insert(taskId: widget.taskId, title: title),
    );
    subtaskController.clear();
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final subtasksAsync = ref.watch(subtasksForTaskProvider(widget.taskId));

    return tasksAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Task Details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Task Details')),
        body: Center(child: Text('Error loading task: $err')),
      ),
      data: (allTasks) {
        final taskList = allTasks.where((t) => t.id == widget.taskId).toList();
        if (taskList.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Task Details')),
            body: const Center(child: Text('Task not found or deleted.')),
          );
        }

        final task = taskList.first;
        final completed = task.status == 'completed';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Task Details'),
            actions: [
              IconButton(
                icon: Icon(
                  task.isImportant ? Icons.star : Icons.star_border,
                  color: task.isImportant ? Colors.amber : null,
                ),
                onPressed: () {
                  database.toggleTaskImportant(task.id, !task.isImportant);
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddTaskDialog(taskToEdit: task),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Task'),
                      content: const Text(
                        'Are you sure you want to delete this task?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await database.deleteTask(task.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: completed,
                      onChanged: (val) {
                        if (completed) {
                          database.uncompleteTask(task.id);
                        } else {
                          database.completeTask(task.id);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              decoration: completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              PriorityChip(priority: task.priority),
                              const SizedBox(width: 8),
                              CategoryBadge(category: task.category),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(),

                // Metadata cards
                if (task.description.isNotEmpty) ...[
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(task.description, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 16),
                ],

                if (task.notes.isNotEmpty) ...[
                  const Text(
                    'Notes',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(task.notes, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 16),
                ],

                // Dates & Reminders
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    if (task.dueDate != null)
                      _buildInfoTile(
                        Icons.event,
                        'Due Date',
                        '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                      ),
                    if (task.dueTime != null)
                      _buildInfoTile(
                        Icons.access_time,
                        'Due Time',
                        '${task.dueTime!.hour}:${task.dueTime!.minute.toString().padLeft(2, '0')}',
                      ),
                    if (task.reminderAt != null)
                      _buildInfoTile(
                        Icons.notifications_active_outlined,
                        'Reminder',
                        _formatDateTime(task.reminderAt!),
                      ),
                    if (task.isRecurring && task.recurrenceRule != null)
                      _buildInfoTile(
                        Icons.repeat,
                        'Recurring',
                        task.recurrenceRule!.toUpperCase(),
                      ),
                    _buildInfoTile(
                      Icons.calendar_month_outlined,
                      'Created',
                      _formatDateTime(task.createdAt),
                    ),
                    if (task.completedAt != null)
                      _buildInfoTile(
                        Icons.check_circle_outline,
                        'Completed',
                        _formatDateTime(task.completedAt!),
                      ),
                  ],
                ),

                if (task.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Tags',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: task.tags
                        .split(',')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .map(
                          (tag) => Chip(
                            label: Text(
                              tag,
                              style: const TextStyle(fontSize: 12),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ],

                const SizedBox(height: 16),
                _buildFocusCard(context, task),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),

                // Subtasks Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtasks',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtasksAsync.when(
                      data: (subs) => Text(
                        '${subs.where((s) => s.completed).length} / ${subs.length} completed',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Subtasks Progress Bar
                subtasksAsync.when(
                  data: (subs) {
                    if (subs.isEmpty) return const SizedBox.shrink();
                    final doneCount = subs.where((s) => s.completed).length;
                    final progress = doneCount / subs.length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                // Add Subtask Field
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: subtaskController,
                        decoration: const InputDecoration(
                          hintText: 'Add a subtask...',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addSubtask(database),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: () => _addSubtask(database),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Subtasks List
                subtasksAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (err, _) => Text('Error: $err'),
                  data: (subtasks) {
                    if (subtasks.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No subtasks added yet.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: subtasks.length,
                      itemBuilder: (ctx, index) {
                        final sub = subtasks[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Checkbox(
                            value: sub.completed,
                            onChanged: (val) {
                              database.toggleSubtask(sub.id, val ?? false);
                            },
                          ),
                          title: Text(
                            sub.title,
                            style: TextStyle(
                              decoration: sub.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              database.deleteSubtask(sub.id);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFocusCard(BuildContext context, Task task) {
    final theme = Theme.of(context);
    final seconds = ref.watch(taskFocusTimeProvider(task.id));
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final formattedText = seconds == 0
        ? 'No sessions yet'
        : (h > 0 ? '${h}h ${m}m' : '${m}m');

    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.timer_outlined,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Time Spent Focusing',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                ref.read(focusProvider.notifier).selectTask(task);
                context.go('/focus');
              },
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Focus'),
            ),
          ],
        ),
      ),
    );
  }
}

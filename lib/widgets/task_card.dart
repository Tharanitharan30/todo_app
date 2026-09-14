import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/task_provider.dart';
import '../screens/task_detail_screen.dart';
import 'add_task_dialog.dart';
import 'common_widgets.dart';

class TaskCard extends ConsumerWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onDelete,
  });

  bool _isOverdue(Task task) {
    if (task.status == 'completed' || task.dueDate == null) return false;
    final now = DateTime.now();
    DateTime due = task.dueDate!;
    if (task.dueTime != null) {
      due = DateTime(due.year, due.month, due.day, task.dueTime!.hour, task.dueTime!.minute);
    } else {
      due = DateTime(due.year, due.month, due.day, 23, 59, 59);
    }
    return due.isBefore(now);
  }

  String _formatDueDate(DateTime date, DateTime? time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    String dateStr;
    if (taskDate.isAtSameMomentAs(today)) {
      dateStr = 'Today';
    } else if (taskDate.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      dateStr = 'Tomorrow';
    } else if (taskDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      dateStr = 'Yesterday';
    } else {
      dateStr = '${date.day}/${date.month}/${date.year}';
    }

    if (time != null) {
      final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';
      dateStr += ' $hour:$minute $period';
    }

    return dateStr;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = task.status == 'completed';
    final overdue = _isOverdue(task);
    final database = ref.read(databaseProvider);
    final subtasksAsync = ref.watch(subtasksForTaskProvider(task.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: completed ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: overdue
              ? Colors.red.withAlpha(120)
              : Theme.of(context).colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(taskId: task.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Checkbox
                  Checkbox(
                    value: completed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (_) => onComplete(),
                  ),
                  const SizedBox(width: 4),

                  // Title & Subtitle info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: completed
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withAlpha(120)
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),

                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            task.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],

                        const SizedBox(height: 6),

                        // Subtitle info row: Category, Due date, Subtasks progress
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (task.category.isNotEmpty)
                              CategoryBadge(category: task.category),

                            if (task.dueDate != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_outlined,
                                    size: 13,
                                    color: overdue
                                        ? Colors.red
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _formatDueDate(task.dueDate!, task.dueTime),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: overdue ? FontWeight.bold : FontWeight.normal,
                                      color: overdue
                                          ? Colors.red
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),

                            // Subtask progress
                            subtasksAsync.when(
                              data: (subtasks) {
                                if (subtasks.isEmpty) return const SizedBox.shrink();
                                final done =
                                    subtasks.where((s) => s.completed).length;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_box_outlined,
                                      size: 13,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$done/${subtasks.length}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Important Star toggle button
                  IconButton(
                    icon: Icon(
                      task.isImportant ? Icons.star : Icons.star_border,
                      color: task.isImportant
                          ? Colors.amber
                          : Theme.of(context).colorScheme.outline,
                    ),
                    onPressed: () {
                      database.toggleTaskImportant(task.id, !task.isImportant);
                    },
                  ),

                  // Priority indicator & Popup Menu
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PriorityChip(priority: task.priority),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          switch (value) {
                            case 'edit':
                              showDialog(
                                context: context,
                                builder: (_) => AddTaskDialog(taskToEdit: task),
                              );
                              break;
                            case 'toggle':
                              onComplete();
                              break;
                            case 'important':
                              database.toggleTaskImportant(
                                  task.id, !task.isImportant);
                              break;
                            case 'duplicate':
                              final newId = await database.duplicateTask(task.id);
                              if (context.mounted && newId > 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Task duplicated successfully'),
                                  ),
                                );
                              }
                              break;
                            case 'delete':
                              onDelete();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(
                              children: [
                                Icon(
                                  completed
                                      ? Icons.undo
                                      : Icons.check_circle_outline,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(completed
                                    ? 'Mark incomplete'
                                    : 'Mark complete'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'important',
                            child: Row(
                              children: [
                                Icon(
                                  task.isImportant
                                      ? Icons.star_border
                                      : Icons.star,
                                  size: 18,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 8),
                                Text(task.isImportant
                                    ? 'Remove star'
                                    : 'Mark important'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Duplicate'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
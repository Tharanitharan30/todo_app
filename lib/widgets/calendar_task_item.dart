import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/focus_provider.dart';
import 'add_task_dialog.dart';
import 'common_widgets.dart';

class CalendarTaskItem extends ConsumerWidget {
  final Task task;

  const CalendarTaskItem({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final database = ref.read(databaseProvider);
    final isCompleted = task.status == 'completed';

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final isOverdue =
        !isCompleted &&
        task.dueDate != null &&
        task.dueDate!.isBefore(todayStart);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue
              ? Colors.red.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant,
          width: isOverdue ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.go('/tasks');
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Checkbox(
                value: isCompleted,
                onChanged: (val) {
                  if (isCompleted) {
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
                    Row(
                      children: [
                        if (task.isImportant) ...[
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted
                                  ? theme.colorScheme.onSurfaceVariant
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        PriorityChip(priority: task.priority),
                        CategoryBadge(category: task.category),
                        if (task.dueTime != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  TimeOfDay(
                                    hour: task.dueTime!.hour,
                                    minute: task.dueTime!.minute,
                                  ).format(context),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'OVERDUE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.timer_outlined, size: 20),
                    tooltip: 'Start Focus',
                    onPressed: () {
                      ref.read(focusProvider.notifier).selectTask(task);
                      context.go('/focus');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit Task',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AddTaskDialog(taskToEdit: task),
                      );
                    },
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

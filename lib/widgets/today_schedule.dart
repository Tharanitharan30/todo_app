import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_provider.dart';
import '../providers/task_provider.dart';
import '../screens/task_detail_screen.dart';

class TodaySchedule extends ConsumerWidget {
  const TodaySchedule({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();

    final allTasks = tasksAsync.value ?? [];

    // Filter tasks due today
    final todayTasks = allTasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == now.year &&
          t.dueDate!.month == now.month &&
          t.dueDate!.day == now.day;
    }).toList();

    // Sort: timed tasks first (by dueTime hour/minute), then all-day tasks
    todayTasks.sort((a, b) {
      if (a.dueTime != null && b.dueTime != null) {
        return a.dueTime!.compareTo(b.dueTime!);
      }
      if (a.dueTime != null && b.dueTime == null) return -1;
      if (a.dueTime == null && b.dueTime != null) return 1;
      return a.createdAt.compareTo(b.createdAt);
    });

    if (todayTasks.isEmpty) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No tasks scheduled for today',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: todayTasks.length,
        separatorBuilder: (ctx, idx) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final task = todayTasks[index];
          final isCompleted = task.status == 'completed';

          String timeLabel = 'All Day';
          if (task.dueTime != null) {
            final dt = task.dueTime!;
            final hour = dt.hour.toString().padLeft(2, '0');
            final minute = dt.minute.toString().padLeft(2, '0');
            timeLabel = '$hour:$minute';
          }

          return ListTile(
            leading: SizedBox(
              width: 54,
              child: Text(
                timeLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isCompleted
                      ? theme.disabledColor
                      : (task.dueTime != null
                            ? theme.colorScheme.primary
                            : Colors.grey),
                ),
              ),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? theme.disabledColor : null,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: isCompleted ? Colors.green : Colors.grey,
                size: 20,
              ),
              onPressed: () {
                final db = ref.read(databaseProvider);
                if (isCompleted) {
                  db.uncompleteTask(task.id);
                } else {
                  db.completeTask(task.id);
                }
              },
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(taskId: task.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

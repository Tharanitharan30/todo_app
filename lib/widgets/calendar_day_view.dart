import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/calendar_provider.dart';
import 'add_task_dialog.dart';
import 'calendar_task_item.dart';

class CalendarDayView extends ConsumerWidget {
  const CalendarDayView({super.key});

  String _formatFullDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final calState = ref.watch(calendarStateProvider);
    final selectedDate = calState.selectedDate;

    final tasksForDay = ref.watch(calendarTasksForSelectedDateProvider);
    final allDayTasks = tasksForDay.where((t) => t.dueTime == null).toList();
    final timedTasks = tasksForDay.where((t) => t.dueTime != null).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Date Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatFullDate(selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton.filledTonal(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddTaskDialog(initialDueDate: selectedDate),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                tooltip: 'Add Task for this Day',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ALL DAY SECTION
          if (allDayTasks.isNotEmpty) ...[
            const Text(
              'All Day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            ...allDayTasks.map((t) => CalendarTaskItem(task: t)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
          ],

          // 24-HOUR TIMELINE SCHEDULER
          const Text(
            'Schedule',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),

          ...List.generate(24, (hour) {
            final hourStr = hour.toString().padLeft(2, '0');
            final tasksForHour = timedTasks
                .where((t) => t.dueTime!.hour == hour)
                .toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: tasksForHour.isNotEmpty
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: tasksForHour.isNotEmpty ? 3 : 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.only(left: 12),
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddTaskDialog(
                      initialDueDate: selectedDate,
                      initialDueTime: TimeOfDay(hour: hour, minute: 0),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$hourStr:00',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: tasksForHour.isNotEmpty
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (tasksForHour.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'No events scheduled',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      )
                    else
                      ...tasksForHour.map((t) => CalendarTaskItem(task: t)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

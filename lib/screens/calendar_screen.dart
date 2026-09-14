import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';

enum CalendarViewMode { day, week, month }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime selectedDate = DateTime.now();
  CalendarViewMode viewMode = CalendarViewMode.month;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          SegmentedButton<CalendarViewMode>(
            segments: const [
              ButtonSegment(
                value: CalendarViewMode.day,
                label: Text('Day'),
              ),
              ButtonSegment(
                value: CalendarViewMode.week,
                label: Text('Week'),
              ),
              ButtonSegment(
                value: CalendarViewMode.month,
                label: Text('Month'),
              ),
            ],
            selected: {viewMode},
            onSelectionChanged: (set) {
              setState(() {
                viewMode = set.first;
              });
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (tasks) {
          final tasksWithDueDate =
              tasks.where((t) => t.dueDate != null).toList();

          return Column(
            children: [
              // Date picker / selector area based on view mode
              _buildDateSelector(),

              const Divider(height: 1),

              // Selected date header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tasks for ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_getTasksForSelectedDate(tasksWithDueDate).length} tasks',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

              // Tasks list for selected date
              Expanded(
                child: _buildTaskList(_getTasksForSelectedDate(tasksWithDueDate)),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Task> _getTasksForSelectedDate(List<Task> tasksWithDueDate) {
    switch (viewMode) {
      case CalendarViewMode.day:
        return tasksWithDueDate
            .where((t) => _isSameDay(t.dueDate!, selectedDate))
            .toList();
      case CalendarViewMode.week:
        final startOfWeek =
            selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));
        return tasksWithDueDate
            .where((t) =>
                t.dueDate!.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
                t.dueDate!.isBefore(endOfWeek))
            .toList();
      case CalendarViewMode.month:
        return tasksWithDueDate
            .where((t) =>
                t.dueDate!.year == selectedDate.year &&
                t.dueDate!.month == selectedDate.month)
            .toList();
    }
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                if (viewMode == CalendarViewMode.day) {
                  selectedDate = selectedDate.subtract(const Duration(days: 1));
                } else if (viewMode == CalendarViewMode.week) {
                  selectedDate = selectedDate.subtract(const Duration(days: 7));
                } else {
                  selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
                }
              });
            },
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() {
                  selectedDate = picked;
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_getMonthName(selectedDate.month)} ${selectedDate.year}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                if (viewMode == CalendarViewMode.day) {
                  selectedDate = selectedDate.add(const Duration(days: 1));
                } else if (viewMode == CalendarViewMode.week) {
                  selectedDate = selectedDate.add(const Duration(days: 7));
                } else {
                  selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
                }
              });
            },
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const names = [
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
      'December'
    ];
    return names[month - 1];
  }

  Widget _buildTaskList(List<Task> dayTasks) {
    if (dayTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            const Text(
              'No tasks scheduled',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final database = ref.read(databaseProvider);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: dayTasks.length,
      itemBuilder: (context, index) {
        final task = dayTasks[index];
        return TaskCard(
          task: task,
          onComplete: () {
            if (task.status == 'completed') {
              database.uncompleteTask(task.id);
            } else {
              database.completeTask(task.id);
            }
          },
          onDelete: () {
            database.deleteTask(task.id);
          },
        );
      },
    );
  }
}

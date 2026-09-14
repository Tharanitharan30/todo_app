import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/calendar_provider.dart';
import '../providers/settings_provider.dart';
import 'add_task_dialog.dart';

class CalendarMonthView extends ConsumerWidget {
  const CalendarMonthView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final calState = ref.watch(calendarStateProvider);
    final settings = ref.watch(appSettingsProvider);
    final monthTasksMap = ref.watch(calendarTasksForMonthProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final focused = calState.focusedDate;
    final selected = calState.selectedDate;

    final weekStartsSunday = settings.weekStartsOn.toLowerCase() == 'sunday';
    final weekdayNames = weekStartsSunday
        ? const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final firstOfMonth = DateTime(focused.year, focused.month, 1);
    final daysInMonth = DateTime(focused.year, focused.month + 1, 0).day;

    final startWeekday = firstOfMonth.weekday; // Mon=1..Sun=7
    int leadingDays;
    if (weekStartsSunday) {
      leadingDays = startWeekday == DateTime.sunday ? 0 : startWeekday;
    } else {
      leadingDays = startWeekday - 1;
    }

    final totalGridCells = ((leadingDays + daysInMonth) / 7).ceil() * 7;

    return Column(
      children: [
        // WEEKDAY HEADERS
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: theme.colorScheme.surfaceContainerLow,
          child: Row(
            children: weekdayNames
                .map(
                  (name) => Expanded(
                    child: Center(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: name == 'Sun' || name == 'Sat'
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        const Divider(height: 1),

        // MONTH GRID
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: totalGridCells,
            itemBuilder: (context, index) {
              final dayOffset = index - leadingDays + 1;

              if (dayOffset < 1 || dayOffset > daysInMonth) {
                // Out-of-month cell
                final isPrevMonth = dayOffset < 1;
                final date = isPrevMonth
                    ? DateTime(focused.year, focused.month, dayOffset)
                    : DateTime(
                        focused.year,
                        focused.month + 1,
                        dayOffset - daysInMonth,
                      );

                return _buildCell(
                  context: context,
                  ref: ref,
                  date: date,
                  isCurrentMonth: false,
                  isToday: false,
                  isSelected: false,
                  tasks: const [],
                  theme: theme,
                );
              }

              final cellDate = DateTime(focused.year, focused.month, dayOffset);
              final isToday =
                  cellDate.year == today.year &&
                  cellDate.month == today.month &&
                  cellDate.day == today.day;
              final isSelected =
                  cellDate.year == selected.year &&
                  cellDate.month == selected.month &&
                  cellDate.day == selected.day;

              final tasksForDay = monthTasksMap[cellDate] ?? const [];

              return _buildCell(
                context: context,
                ref: ref,
                date: cellDate,
                isCurrentMonth: true,
                isToday: isToday,
                isSelected: isSelected,
                tasks: tasksForDay,
                theme: theme,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCell({
    required BuildContext context,
    required WidgetRef ref,
    required DateTime date,
    required bool isCurrentMonth,
    required bool isToday,
    required bool isSelected,
    required List<Task> tasks,
    required ThemeData theme,
  }) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final completedCount = tasks.where((t) => t.status == 'completed').length;
    final overdueCount = tasks
        .where(
          (t) =>
              t.status != 'completed' &&
              t.dueDate != null &&
              t.dueDate!.isBefore(todayStart),
        )
        .length;
    final importantCount = tasks.where((t) => t.isImportant).length;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        ref.read(calendarStateProvider.notifier).setSelectedDate(date);
      },
      onDoubleTap: () {
        showDialog(
          context: context,
          builder: (_) => AddTaskDialog(initialDueDate: date),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isToday
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
              : (isSelected
                    ? theme.colorScheme.surfaceContainerHighest
                    : (isCurrentMonth
                          ? null
                          : theme.colorScheme.surfaceContainerLowest)),
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : (isToday
                    ? Border.all(color: theme.colorScheme.primary, width: 1)
                    : null),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Date Number Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: isToday
                      ? BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        )
                      : null,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday || isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isToday
                          ? theme.colorScheme.onPrimary
                          : (isCurrentMonth
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.outline),
                    ),
                  ),
                ),
              ],
            ),

            // Task Indicators
            if (isCurrentMonth && tasks.isNotEmpty) ...[
              if (tasks.length > 3)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${tasks.length}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (overdueCount > 0)
                      _dot(Colors.red)
                    else if (importantCount > 0)
                      _dot(Colors.amber)
                    else if (completedCount > 0)
                      _dot(Colors.green)
                    else
                      _dot(theme.colorScheme.primary),
                    if (tasks.length > 1) ...[
                      const SizedBox(width: 2),
                      _dot(theme.colorScheme.outline),
                    ],
                    if (tasks.length > 2) ...[
                      const SizedBox(width: 2),
                      _dot(theme.colorScheme.outline),
                    ],
                  ],
                ),
            ] else
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

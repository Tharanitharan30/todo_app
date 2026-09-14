import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/calendar_provider.dart';
import '../providers/task_provider.dart';
import 'add_task_dialog.dart';

class CalendarWeekView extends ConsumerWidget {
  const CalendarWeekView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final weekDates = ref.watch(calendarTasksForWeekProvider);
    final calState = ref.watch(calendarStateProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final allTasks = tasksAsync.value ?? [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = calState.selectedDate;

    const weekdayShorts = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        // WEEK DAY HEADERS
        Container(
          color: theme.colorScheme.surfaceContainerLow,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 50), // Time column padding
              ...weekDates.map((date) {
                final isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final isSelected =
                    date.year == selected.year &&
                    date.month == selected.month &&
                    date.day == selected.day;

                final dayLabel = weekdayShorts[date.weekday - 1];

                return Expanded(
                  child: InkWell(
                    onTap: () {
                      ref
                          .read(calendarStateProvider.notifier)
                          .setSelectedDate(date);
                    },
                    child: Column(
                      children: [
                        Text(
                          dayLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isToday
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: isToday
                              ? BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                )
                              : (isSelected
                                    ? BoxDecoration(
                                        border: Border.all(
                                          color: theme.colorScheme.primary,
                                          width: 2,
                                        ),
                                        shape: BoxShape.circle,
                                      )
                                    : null),
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isToday
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        const Divider(height: 1),

        // ALL DAY SECTION
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          color: theme.colorScheme.surfaceContainerLowest,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 42,
                child: Text(
                  'All Day',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: weekDates.map((date) {
                    final dayAllDayTasks = allTasks
                        .where(
                          (t) =>
                              taskMatchesDate(t, date) &&
                              t.dueTime == null &&
                              filterTask(t, calState),
                        )
                        .toList();

                    return Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          children: dayAllDayTasks.map((t) {
                            return GestureDetector(
                              onTap: () {
                                ref
                                    .read(calendarStateProvider.notifier)
                                    .setSelectedDate(date);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  t.title,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // 24-HOUR TIMELINE SCHEDULER
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hours label column
                SizedBox(
                  width: 50,
                  child: Column(
                    children: List.generate(24, (hour) {
                      final hStr = hour.toString().padLeft(2, '0');
                      return Container(
                        height: 50,
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '$hStr:00',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // 7 Day Grid Columns
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: weekDates.map((date) {
                      final dayTimedTasks = allTasks
                          .where(
                            (t) =>
                                taskMatchesDate(t, date) &&
                                t.dueTime != null &&
                                filterTask(t, calState),
                          )
                          .toList();

                      return Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: theme.colorScheme.outlineVariant,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Column(
                            children: List.generate(24, (hour) {
                              final hourTasks = dayTimedTasks
                                  .where((t) => t.dueTime!.hour == hour)
                                  .toList();

                              return InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AddTaskDialog(
                                      initialDueDate: date,
                                      initialDueTime: TimeOfDay(
                                        hour: hour,
                                        minute: 0,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: theme.colorScheme.outlineVariant
                                            .withValues(alpha: 0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(1),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: hourTasks.map((t) {
                                      final isDone = t.status == 'completed';
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 2,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDone
                                              ? theme
                                                    .colorScheme
                                                    .surfaceContainerHighest
                                              : theme
                                                    .colorScheme
                                                    .secondaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          t.title,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            decoration: isDone
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: theme
                                                .colorScheme
                                                .onSecondaryContainer,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

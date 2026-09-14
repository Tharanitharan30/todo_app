import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import 'focus_provider.dart';
import 'settings_provider.dart';
import 'task_provider.dart';

enum CalendarViewMode { month, week, day, agenda }

enum CalendarStatusFilter { all, pending, completed, important, overdue }

class CalendarState {
  final CalendarViewMode viewMode;
  final DateTime selectedDate;
  final DateTime focusedDate;
  final CalendarStatusFilter statusFilter;
  final String categoryFilter;
  final String searchQuery;

  const CalendarState({
    required this.viewMode,
    required this.selectedDate,
    required this.focusedDate,
    this.statusFilter = CalendarStatusFilter.all,
    this.categoryFilter = 'all',
    this.searchQuery = '',
  });

  CalendarState copyWith({
    CalendarViewMode? viewMode,
    DateTime? selectedDate,
    DateTime? focusedDate,
    CalendarStatusFilter? statusFilter,
    String? categoryFilter,
    String? searchQuery,
  }) {
    return CalendarState(
      viewMode: viewMode ?? this.viewMode,
      selectedDate: selectedDate ?? this.selectedDate,
      focusedDate: focusedDate ?? this.focusedDate,
      statusFilter: statusFilter ?? this.statusFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CalendarNotifier extends Notifier<CalendarState> {
  @override
  CalendarState build() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return CalendarState(
      viewMode: CalendarViewMode.month,
      selectedDate: today,
      focusedDate: today,
    );
  }

  void setViewMode(CalendarViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void setSelectedDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    state = state.copyWith(selectedDate: normalized, focusedDate: normalized);
  }

  void setFocusedDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    state = state.copyWith(focusedDate: normalized);
  }

  void setStatusFilter(CalendarStatusFilter filter) {
    state = state.copyWith(statusFilter: filter);
  }

  void setCategoryFilter(String category) {
    state = state.copyWith(categoryFilter: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void goToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    state = state.copyWith(selectedDate: today, focusedDate: today);
  }

  void previousPeriod(String weekStartsOn) {
    final f = state.focusedDate;
    switch (state.viewMode) {
      case CalendarViewMode.month:
        state = state.copyWith(focusedDate: DateTime(f.year, f.month - 1, 1));
        break;
      case CalendarViewMode.week:
        state = state.copyWith(
          focusedDate: f.subtract(const Duration(days: 7)),
        );
        break;
      case CalendarViewMode.day:
        final prevDay = f.subtract(const Duration(days: 1));
        state = state.copyWith(focusedDate: prevDay, selectedDate: prevDay);
        break;
      case CalendarViewMode.agenda:
        state = state.copyWith(
          focusedDate: f.subtract(const Duration(days: 7)),
        );
        break;
    }
  }

  void nextPeriod(String weekStartsOn) {
    final f = state.focusedDate;
    switch (state.viewMode) {
      case CalendarViewMode.month:
        state = state.copyWith(focusedDate: DateTime(f.year, f.month + 1, 1));
        break;
      case CalendarViewMode.week:
        state = state.copyWith(focusedDate: f.add(const Duration(days: 7)));
        break;
      case CalendarViewMode.day:
        final nextDay = f.add(const Duration(days: 1));
        state = state.copyWith(focusedDate: nextDay, selectedDate: nextDay);
        break;
      case CalendarViewMode.agenda:
        state = state.copyWith(focusedDate: f.add(const Duration(days: 7)));
        break;
    }
  }
}

final calendarStateProvider = NotifierProvider<CalendarNotifier, CalendarState>(
  CalendarNotifier.new,
);

// Recurrence & Filter Helpers
bool taskMatchesDate(Task task, DateTime targetDate) {
  if (task.dueDate == null) return false;

  final due = DateTime(
    task.dueDate!.year,
    task.dueDate!.month,
    task.dueDate!.day,
  );
  final target = DateTime(targetDate.year, targetDate.month, targetDate.day);

  if (due.year == target.year &&
      due.month == target.month &&
      due.day == target.day) {
    return true;
  }

  if (task.isRecurring && target.isAfter(due)) {
    final rule = (task.recurrenceRule ?? 'daily').toLowerCase();
    if (rule == 'daily') {
      return true;
    } else if (rule == 'weekly') {
      return target.weekday == due.weekday;
    } else if (rule == 'monthly') {
      return target.day == due.day;
    } else if (rule == 'custom') {
      return target.weekday == due.weekday;
    }
  }

  return false;
}

bool filterTask(Task t, CalendarState state) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final isDone = t.status == 'completed';
  final isOverdue =
      !isDone && t.dueDate != null && t.dueDate!.isBefore(todayStart);

  switch (state.statusFilter) {
    case CalendarStatusFilter.pending:
      if (isDone) return false;
      break;
    case CalendarStatusFilter.completed:
      if (!isDone) return false;
      break;
    case CalendarStatusFilter.important:
      if (!t.isImportant) return false;
      break;
    case CalendarStatusFilter.overdue:
      if (!isOverdue) return false;
      break;
    case CalendarStatusFilter.all:
      break;
  }

  if (state.categoryFilter != 'all' &&
      t.category.toLowerCase() != state.categoryFilter.toLowerCase()) {
    return false;
  }

  if (state.searchQuery.trim().isNotEmpty) {
    final q = state.searchQuery.trim().toLowerCase();
    final inTitle = t.title.toLowerCase().contains(q);
    final inDesc = t.description.toLowerCase().contains(q);
    final inCat = t.category.toLowerCase().contains(q);
    final inTags = t.tags.toLowerCase().contains(q);
    if (!inTitle && !inDesc && !inCat && !inTags) return false;
  }

  return true;
}

// Tasks for Selected Date
final calendarTasksForSelectedDateProvider = Provider<List<Task>>((ref) {
  final tasksAsync = ref.watch(tasksProvider);
  final calState = ref.watch(calendarStateProvider);
  final allTasks = tasksAsync.value ?? [];

  final matched = allTasks
      .where(
        (t) =>
            taskMatchesDate(t, calState.selectedDate) &&
            filterTask(t, calState),
      )
      .toList();

  matched.sort((a, b) {
    if (a.dueTime != null && b.dueTime != null) {
      final aMins = a.dueTime!.hour * 60 + a.dueTime!.minute;
      final bMins = b.dueTime!.hour * 60 + b.dueTime!.minute;
      return aMins.compareTo(bMins);
    } else if (a.dueTime != null) {
      return -1;
    } else if (b.dueTime != null) {
      return 1;
    }
    return a.createdAt.compareTo(b.createdAt);
  });

  return matched;
});

// Tasks for Target Date
final calendarTasksForDateProvider = Provider.family<List<Task>, DateTime>((
  ref,
  targetDate,
) {
  final tasksAsync = ref.watch(tasksProvider);
  final calState = ref.watch(calendarStateProvider);
  final allTasks = tasksAsync.value ?? [];

  final matched = allTasks
      .where((t) => taskMatchesDate(t, targetDate) && filterTask(t, calState))
      .toList();

  matched.sort((a, b) {
    if (a.dueTime != null && b.dueTime != null) {
      final aMins = a.dueTime!.hour * 60 + a.dueTime!.minute;
      final bMins = b.dueTime!.hour * 60 + b.dueTime!.minute;
      return aMins.compareTo(bMins);
    } else if (a.dueTime != null) {
      return -1;
    } else if (b.dueTime != null) {
      return 1;
    }
    return a.createdAt.compareTo(b.createdAt);
  });

  return matched;
});

// Week Start Helper
DateTime getStartOfWeek(DateTime date, String weekStartsOn) {
  final isSunday = weekStartsOn.toLowerCase() == 'sunday';
  final targetWeekday = isSunday ? DateTime.sunday : DateTime.monday;
  int diff = date.weekday - targetWeekday;
  if (diff < 0) diff += 7;
  final start = date.subtract(Duration(days: diff));
  return DateTime(start.year, start.month, start.day);
}

// Tasks for Focused Week
final calendarTasksForWeekProvider = Provider<List<DateTime>>((ref) {
  final calState = ref.watch(calendarStateProvider);
  final settings = ref.watch(appSettingsProvider);
  final startOfWeek = getStartOfWeek(
    calState.focusedDate,
    settings.weekStartsOn,
  );

  return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
});

// Map of Tasks for Month Grid
final calendarTasksForMonthProvider = Provider<Map<DateTime, List<Task>>>((
  ref,
) {
  final calState = ref.watch(calendarStateProvider);
  final tasksAsync = ref.watch(tasksProvider);
  final allTasks = tasksAsync.value ?? [];
  final monthDate = calState.focusedDate;

  final lastOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);

  final Map<DateTime, List<Task>> resultMap = {};

  for (int day = 1; day <= lastOfMonth.day; day++) {
    final d = DateTime(monthDate.year, monthDate.month, day);
    final dayTasks = allTasks
        .where((t) => taskMatchesDate(t, d) && filterTask(t, calState))
        .toList();
    resultMap[d] = dayTasks;
  }

  return resultMap;
});

// Grouped Agenda Tasks
final calendarAgendaTasksProvider = Provider<Map<DateTime, List<Task>>>((ref) {
  final calState = ref.watch(calendarStateProvider);
  final tasksAsync = ref.watch(tasksProvider);
  final allTasks = tasksAsync.value ?? [];

  final startDate = calState.focusedDate;
  final Map<DateTime, List<Task>> map = {};

  for (int i = 0; i < 30; i++) {
    final d = DateTime(startDate.year, startDate.month, startDate.day + i);
    final dayTasks = allTasks
        .where((t) => taskMatchesDate(t, d) && filterTask(t, calState))
        .toList();
    if (dayTasks.isNotEmpty) {
      dayTasks.sort((a, b) {
        if (a.dueTime != null && b.dueTime != null) {
          final aMins = a.dueTime!.hour * 60 + a.dueTime!.minute;
          final bMins = b.dueTime!.hour * 60 + b.dueTime!.minute;
          return aMins.compareTo(bMins);
        } else if (a.dueTime != null) {
          return -1;
        } else if (b.dueTime != null) {
          return 1;
        }
        return 0;
      });
      map[d] = dayTasks;
    }
  }

  return map;
});

// Today Plan Summary
class TodayPlanSummary {
  final int totalTasks;
  final int highPriorityCount;
  final int overdueCount;
  final int completedCount;
  final double completionRate;

  const TodayPlanSummary({
    required this.totalTasks,
    required this.highPriorityCount,
    required this.overdueCount,
    required this.completedCount,
    required this.completionRate,
  });
}

final todayPlanSummaryProvider = Provider<TodayPlanSummary>((ref) {
  final now = DateTime.now();
  final todayDate = DateTime(now.year, now.month, now.day);
  final tasksAsync = ref.watch(tasksProvider);
  final allTasks = tasksAsync.value ?? [];

  final todayTasks = allTasks
      .where((t) => taskMatchesDate(t, todayDate))
      .toList();
  final completedCount = todayTasks
      .where((t) => t.status == 'completed')
      .length;
  final highPriorityCount = todayTasks
      .where((t) => t.priority == 'high' || t.priority == 'urgent')
      .length;
  final overdueCount = allTasks
      .where(
        (t) =>
            t.status != 'completed' &&
            t.dueDate != null &&
            t.dueDate!.isBefore(todayDate),
      )
      .length;
  final totalTasks = todayTasks.length;
  final completionRate = totalTasks == 0
      ? 0.0
      : (completedCount / totalTasks) * 100;

  return TodayPlanSummary(
    totalTasks: totalTasks,
    highPriorityCount: highPriorityCount,
    overdueCount: overdueCount,
    completedCount: completedCount,
    completionRate: completionRate,
  );
});

// Week Statistics
class WeekStatistics {
  final int totalTasks;
  final int completedTasks;
  final double completionRate;
  final int focusTimeSeconds;

  const WeekStatistics({
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.focusTimeSeconds,
  });
}

final weekStatisticsProvider = Provider<WeekStatistics>((ref) {
  final calState = ref.watch(calendarStateProvider);
  final settings = ref.watch(appSettingsProvider);
  final startOfWeek = getStartOfWeek(
    calState.focusedDate,
    settings.weekStartsOn,
  );
  final tasksAsync = ref.watch(tasksProvider);
  final weeklyFocusSecs = ref.watch(weeklyFocusTimeSecondsProvider);
  final allTasks = tasksAsync.value ?? [];

  int total = 0;
  int completed = 0;

  for (int i = 0; i < 7; i++) {
    final d = startOfWeek.add(Duration(days: i));
    final dayTasks = allTasks.where((t) => taskMatchesDate(t, d)).toList();
    total += dayTasks.length;
    completed += dayTasks.where((t) => t.status == 'completed').length;
  }

  final rate = total == 0 ? 0.0 : (completed / total) * 100;

  return WeekStatistics(
    totalTasks: total,
    completedTasks: completed,
    completionRate: rate,
    focusTimeSeconds: weeklyFocusSecs,
  );
});

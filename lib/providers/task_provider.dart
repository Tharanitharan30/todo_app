import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import 'database_provider.dart';

enum TaskFilter {
  all,
  pending,
  completed,
  important,
  overdue,
  today,
  upcoming,
}

enum TaskSort {
  dueDate,
  priority,
  createdDate,
  alphabetical,
}

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

class TaskFilterNotifier extends Notifier<TaskFilter> {
  @override
  TaskFilter build() => TaskFilter.all;

  void setFilter(TaskFilter filter) => state = filter;
}

class TaskSortNotifier extends Notifier<TaskSort> {
  @override
  TaskSort build() => TaskSort.dueDate;

  void setSort(TaskSort sort) => state = sort;
}

final tasksProvider = StreamProvider<List<Task>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.watchAllTasks();
});

final subtasksProvider = StreamProvider<List<Subtask>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.watchAllSubtasks();
});

final subtasksForTaskProvider =
    StreamProvider.family<List<Subtask>, int>((ref, taskId) {
  final database = ref.watch(databaseProvider);
  return database.watchSubtasksForTask(taskId);
});

final taskSearchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final taskFilterProvider =
    NotifierProvider<TaskFilterNotifier, TaskFilter>(TaskFilterNotifier.new);

final taskSortProvider =
    NotifierProvider<TaskSortNotifier, TaskSort>(TaskSortNotifier.new);

final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(tasksProvider);
  final searchQuery = ref.watch(taskSearchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(taskFilterProvider);
  final sort = ref.watch(taskSortProvider);

  return tasksAsync.whenData((tasks) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // 1. Search filtering
    var filtered = tasks.where((task) {
      if (searchQuery.isEmpty) return true;
      final titleMatch = task.title.toLowerCase().contains(searchQuery);
      final descMatch = task.description.toLowerCase().contains(searchQuery);
      final catMatch = task.category.toLowerCase().contains(searchQuery);
      final tagsMatch = task.tags.toLowerCase().contains(searchQuery);
      return titleMatch || descMatch || catMatch || tagsMatch;
    }).toList();

    // 2. Status & Category filtering
    filtered = filtered.where((task) {
      final isCompleted = task.status == 'completed';

      switch (filter) {
        case TaskFilter.all:
          return true;
        case TaskFilter.pending:
          return !isCompleted;
        case TaskFilter.completed:
          return isCompleted;
        case TaskFilter.important:
          return task.isImportant;
        case TaskFilter.overdue:
          if (isCompleted || task.dueDate == null) return false;
          final taskDateTime = _combineDateTime(task.dueDate, task.dueTime);
          return taskDateTime.isBefore(now);
        case TaskFilter.today:
          if (task.dueDate == null) return false;
          return task.dueDate!.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
              task.dueDate!.isBefore(todayEnd.add(const Duration(seconds: 1)));
        case TaskFilter.upcoming:
          if (task.dueDate == null) return false;
          return task.dueDate!.isAfter(todayEnd);
      }
    }).toList();

    // 3. Sorting
    filtered.sort((a, b) {
      switch (sort) {
        case TaskSort.dueDate:
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          final dateA = _combineDateTime(a.dueDate, a.dueTime);
          final dateB = _combineDateTime(b.dueDate, b.dueTime);
          return dateA.compareTo(dateB);

        case TaskSort.priority:
          const priorityOrder = {'urgent': 0, 'high': 1, 'medium': 2, 'low': 3};
          final pA = priorityOrder[a.priority.toLowerCase()] ?? 4;
          final pB = priorityOrder[b.priority.toLowerCase()] ?? 4;
          return pA.compareTo(pB);

        case TaskSort.createdDate:
          return b.createdAt.compareTo(a.createdAt);

        case TaskSort.alphabetical:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    return filtered;
  });
});

DateTime _combineDateTime(DateTime? date, DateTime? time) {
  if (date == null) return DateTime.now();
  if (time == null) return date;
  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}
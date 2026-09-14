import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/task_card.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  Future<void> deleteTask(WidgetRef ref, int id) async {
    final database = ref.read(databaseProvider);
    await database.deleteTask(id);
  }

  Future<void> toggleTask(WidgetRef ref, int id, bool completed) async {
    final database = ref.read(databaseProvider);
    if (completed) {
      await database.uncompleteTask(id);
    } else {
      await database.completeTask(id);
    }
  }

  void showAddTask(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const AddTaskDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTasksAsync = ref.watch(tasksProvider);
    final filteredTasksAsync = ref.watch(filteredTasksProvider);
    final searchController = TextEditingController(
      text: ref.watch(taskSearchQueryProvider),
    );

    final currentFilter = ref.watch(taskFilterProvider);
    final currentSort = ref.watch(taskSortProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
            allTasksAsync.when(
              data: (allTasks) {
                final pendingCount = allTasks
                    .where((t) => t.status != 'completed')
                    .length;
                final completedCount = allTasks
                    .where((t) => t.status == 'completed')
                    .length;
                return Text(
                  '$pendingCount pending • $completedCount completed',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<TaskSort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort tasks',
            initialValue: currentSort,
            onSelected: (sort) {
              ref.read(taskSortProvider.notifier).setSort(sort);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: TaskSort.dueDate,
                child: Text('Sort by Due Date'),
              ),
              PopupMenuItem(
                value: TaskSort.priority,
                child: Text('Sort by Priority'),
              ),
              PopupMenuItem(
                value: TaskSort.createdDate,
                child: Text('Sort by Created Date'),
              ),
              PopupMenuItem(
                value: TaskSort.alphabetical,
                child: Text('Sort Alphabetically'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddTask(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          ref
                              .read(taskSearchQueryProvider.notifier)
                              .setQuery('');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) {
                ref.read(taskSearchQueryProvider.notifier).setQuery(val);
              },
            ),
          ),

          // Filters Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: TaskFilter.values.map((filter) {
                final isSelected = currentFilter == filter;
                String label;
                switch (filter) {
                  case TaskFilter.all:
                    label = 'All';
                    break;
                  case TaskFilter.pending:
                    label = 'Pending';
                    break;
                  case TaskFilter.completed:
                    label = 'Completed';
                    break;
                  case TaskFilter.important:
                    label = 'Important';
                    break;
                  case TaskFilter.overdue:
                    label = 'Overdue';
                    break;
                  case TaskFilter.today:
                    label = 'Today';
                    break;
                  case TaskFilter.upcoming:
                    label = 'Upcoming';
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(taskFilterProvider.notifier).setFilter(filter);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Task List
          Expanded(
            child: filteredTasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Database Error',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('$error', textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 80,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No tasks yet',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create your first task to get started.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => showAddTask(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Task'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(tasksProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskCard(
                        task: task,
                        onComplete: () {
                          toggleTask(ref, task.id, task.status == 'completed');
                        },
                        onDelete: () {
                          deleteTask(ref, task.id);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

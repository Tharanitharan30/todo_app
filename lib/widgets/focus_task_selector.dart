import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/task_provider.dart';

class FocusTaskSelector extends ConsumerStatefulWidget {
  final Task? selectedTask;
  final ValueChanged<Task?> onTaskSelected;

  const FocusTaskSelector({
    super.key,
    required this.selectedTask,
    required this.onTaskSelected,
  });

  @override
  ConsumerState<FocusTaskSelector> createState() => _FocusTaskSelectorState();
}

class _FocusTaskSelectorState extends ConsumerState<FocusTaskSelector> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Task for Focus',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 12),

              // General Focus (No Task) Option
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                tileColor: widget.selectedTask == null
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : theme.colorScheme.surfaceContainerHighest,
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(
                    Icons.center_focus_strong,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'General Focus Session',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Focus without associating a specific task',
                ),
                trailing: widget.selectedTask == null
                    ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  widget.onTaskSelected(null);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 12),

              const Text(
                'Incomplete Tasks',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),

              // Task List
              Expanded(
                child: tasksAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error loading tasks: $err'),
                  data: (allTasks) {
                    final incompleteTasks = allTasks
                        .where(
                          (t) =>
                              t.status != 'completed' &&
                              (_searchQuery.isEmpty ||
                                  t.title.toLowerCase().contains(
                                    _searchQuery,
                                  ) ||
                                  t.category.toLowerCase().contains(
                                    _searchQuery,
                                  )),
                        )
                        .toList();

                    if (incompleteTasks.isEmpty) {
                      return const Center(
                        child: Text(
                          'No matching incomplete tasks found.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: incompleteTasks.length,
                      itemBuilder: (context, index) {
                        final task = incompleteTasks[index];
                        final isSelected = widget.selectedTask?.id == task.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                              ),
                            ),
                            tileColor: isSelected
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.08,
                                  )
                                : theme.cardColor,
                            leading: Icon(
                              Icons.task_alt,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.grey,
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${task.category[0].toUpperCase()}${task.category.substring(1)} • Priority: ${task.priority}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                            onTap: () {
                              widget.onTaskSelected(task);
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/task_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  bool _isOverdue(Task task) {
    if (task.status == 'completed' || task.dueDate == null) return false;
    final now = DateTime.now();
    return task.dueDate!.isBefore(now);
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final financeSummaryAsync = ref.watch(financeSummaryProvider);
    final database = ref.read(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wb_sunny_outlined),
            tooltip: 'Daily Briefing',
            onPressed: () => context.go('/briefing'),
          ),
          Consumer(
            builder: (context, ref, child) {
              final unreadAsync = ref.watch(unreadNotificationCountProvider);
              final count = unreadAsync.value ?? 0;
              return Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifications',
                  onPressed: () => context.go('/notifications'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Task',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AddTaskDialog(),
              );
            },
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading dashboard: $err')),
        data: (allTasks) {
          final total = allTasks.length;
          final pending = allTasks.where((t) => t.status != 'completed').length;
          final completed = allTasks.where((t) => t.status == 'completed').length;
          final overdue = allTasks.where((t) => _isOverdue(t)).length;
          final important = allTasks.where((t) => t.isImportant).length;
          final todayTasks =
              allTasks.where((t) => _isToday(t.dueDate)).toList();
          final todayTotal = todayTasks.length;
          final todayCompleted =
              todayTasks.where((t) => t.status == 'completed').length;
          final todayProgress =
              todayTotal == 0 ? 0.0 : todayCompleted / todayTotal;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 30. Analytics Summary Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.analytics, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Analytics Summary',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () => context.go('/analytics'),
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: const Text('View Analytics'),
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Today's Productivity
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Today's Productivity",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$todayCompleted / $todayTotal completed',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: todayProgress,
                                      minHeight: 6,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Monthly Finance Summary
                            Expanded(
                              child: financeSummaryAsync.when(
                                loading: () => const SizedBox.shrink(),
                                error: (err, stack) => const SizedBox.shrink(),
                                data: (summary) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'This Month Finance',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Income',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                          Text(
                                            '₹${summary.income.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Expenses',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                          Text(
                                            '₹${summary.expenses.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Savings',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                          Text(
                                            '₹${summary.balance.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Statistics Grid
                const Text(
                  'Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      context,
                      'Total Tasks',
                      '$total',
                      Icons.task_alt,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      context,
                      'Pending',
                      '$pending',
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      context,
                      'Completed',
                      '$completed',
                      Icons.check_circle_outline,
                      Colors.green,
                    ),
                    _buildStatCard(
                      context,
                      'Overdue',
                      '$overdue',
                      Icons.warning_amber_rounded,
                      Colors.red,
                    ),
                    _buildStatCard(
                      context,
                      'Important',
                      '$important',
                      Icons.star_outline,
                      Colors.amber,
                    ),
                    _buildStatCard(
                      context,
                      'Due Today',
                      '$todayTotal',
                      Icons.today,
                      Colors.purple,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Today's Tasks Header & Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today's Tasks",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => context.go('/tasks'),
                      child: const Text('View all'),
                    ),
                  ],
                ),

                if (todayTotal > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Completed: $todayCompleted / $todayTotal',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${(todayProgress * 100).toInt()}%',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: todayProgress,
                      minHeight: 8,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Today's Tasks List
                if (todayTasks.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.wb_sunny_outlined,
                                size: 48, color: Colors.orange),
                            const SizedBox(height: 8),
                            const Text(
                              'No tasks scheduled for today',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enjoy your free day or add a new task!',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todayTasks.length,
                    itemBuilder: (context, index) {
                      final task = todayTasks[index];
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
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(35),
              radius: 18,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
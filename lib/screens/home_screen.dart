import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/focus_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/add_expense_dialog.dart';
import '../widgets/add_income_dialog.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/task_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
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
    final dayName = weekdays[now.weekday - 1];
    final monthName = months[now.month - 1];
    return '$dayName, $monthName ${now.day}';
  }

  bool _isOverdue(Task task) {
    if (task.status == 'completed' || task.dueDate == null) return false;
    final now = DateTime.now();
    return task.dueDate!.isBefore(now);
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final financeSummaryAsync = ref.watch(financeSummaryProvider);
    final settings = ref.watch(appSettingsProvider);
    final database = ref.read(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              _getFormattedDate(),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
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
          const SizedBox(width: 8),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Loading dashboard...',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.red),
              const SizedBox(height: 8),
              const Text(
                'Unable to load dashboard',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: () => ref.refresh(tasksProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (allTasks) {
          final total = allTasks.length;
          final completed = allTasks
              .where((t) => t.status == 'completed')
              .length;
          final todayTasks = allTasks
              .where((t) => _isToday(t.dueDate))
              .toList();
          final todayTotal = todayTasks.length;
          final todayCompleted = todayTasks
              .where((t) => t.status == 'completed')
              .length;
          final todayProgress = todayTotal == 0
              ? 0.0
              : todayCompleted / todayTotal;
          final overallRate = total == 0
              ? 0
              : ((completed / total) * 100).round();

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // QUICK STATS OVERVIEW CARDS
                    _buildOverviewRow(
                      context,
                      todayCompleted: todayCompleted,
                      todayTotal: todayTotal,
                      todayProgress: todayProgress,
                      overallRate: overallRate,
                      financeSummaryAsync: financeSummaryAsync,
                      currency: settings.currency,
                    ),

                    const SizedBox(height: 20),

                    // QUICK ACTIONS BAR
                    _buildQuickActionsBar(context),

                    const SizedBox(height: 24),

                    // MAIN DASHBOARD GRID
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Today's Tasks
                          Expanded(
                            flex: 3,
                            child: _buildTodayTasksSection(
                              context,
                              database: database,
                              todayTasks: todayTasks,
                              todayCompleted: todayCompleted,
                              todayTotal: todayTotal,
                              todayProgress: todayProgress,
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Right Column: Focus, Finance & Analytics Summary
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildFocusSummaryCard(context, ref),
                                const SizedBox(height: 16),
                                _buildFinanceSummaryCard(
                                  context,
                                  financeSummaryAsync: financeSummaryAsync,
                                  currency: settings.currency,
                                ),
                                const SizedBox(height: 16),
                                _buildAllTasksOverviewCard(context, allTasks),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildTodayTasksSection(
                            context,
                            database: database,
                            todayTasks: todayTasks,
                            todayCompleted: todayCompleted,
                            todayTotal: todayTotal,
                            todayProgress: todayProgress,
                          ),
                          const SizedBox(height: 20),
                          _buildFocusSummaryCard(context, ref),
                          const SizedBox(height: 16),
                          _buildFinanceSummaryCard(
                            context,
                            financeSummaryAsync: financeSummaryAsync,
                            currency: settings.currency,
                          ),
                          const SizedBox(height: 16),
                          _buildAllTasksOverviewCard(context, allTasks),
                        ],
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOverviewRow(
    BuildContext context, {
    required int todayCompleted,
    required int todayTotal,
    required double todayProgress,
    required int overallRate,
    required AsyncValue<FinanceSummary> financeSummaryAsync,
    required String currency,
  }) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        final taskCard = Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Tasks',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$todayCompleted / $todayTotal',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
        );

        final financeCard = Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Net Balance',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 18,
                      color: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                financeSummaryAsync.when(
                  loading: () => const Text(
                    '...',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  error: (err, _) => const Text(
                    '₹0',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  data: (summary) => Text(
                    CurrencyFormatter.format(
                      summary.balance,
                      currencyCode: currency,
                    ),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: summary.balance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Current month balance',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );

        final productivityCard = Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Productivity',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Icon(
                      Icons.speed_rounded,
                      size: 18,
                      color: Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$overallRate%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total completion rate',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );

        if (isCompact) {
          return Column(
            children: [
              taskCard,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: financeCard),
                  const SizedBox(width: 8),
                  Expanded(child: productivityCard),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: taskCard),
            const SizedBox(width: 12),
            Expanded(child: financeCard),
            const SizedBox(width: 12),
            Expanded(child: productivityCard),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionsBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AddTaskDialog(),
                  );
                },
                icon: const Icon(Icons.add_task, size: 18),
                label: const Text('Task'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/focus'),
                icon: const Icon(Icons.timer_outlined, size: 18),
                label: const Text('Focus'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AddExpenseDialog(),
                  );
                },
                icon: const Icon(Icons.remove_circle_outline, size: 18),
                label: const Text('Expense'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AddIncomeDialog(),
                  );
                },
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Income'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayTasksSection(
    BuildContext context, {
    required AppDatabase database,
    required List<Task> todayTasks,
    required int todayCompleted,
    required int todayTotal,
    required double todayProgress,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Schedule",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.go('/tasks'),
              child: const Text('View All Tasks'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (todayTasks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.wb_sunny_outlined,
                      size: 40,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No tasks scheduled for today',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enjoy your day or add a task to get started!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TaskCard(
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
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFinanceSummaryCard(
    BuildContext context, {
    required AsyncValue<FinanceSummary> financeSummaryAsync,
    required String currency,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Finance Summary',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => context.go('/analytics'),
                  icon: const Icon(Icons.bar_chart, size: 16),
                  label: const Text('View Analytics'),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            financeSummaryAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Text('Error loading finance summary: $err'),
              data: (summary) {
                return Column(
                  children: [
                    _buildFinanceRow(
                      context,
                      label: 'Income',
                      amount: summary.income,
                      color: Colors.green,
                      currency: currency,
                    ),
                    const SizedBox(height: 8),
                    _buildFinanceRow(
                      context,
                      label: 'Expenses',
                      amount: summary.expenses,
                      color: Colors.red,
                      currency: currency,
                    ),
                    const Divider(height: 16),
                    _buildFinanceRow(
                      context,
                      label: 'Monthly Savings',
                      amount: summary.balance,
                      color: theme.colorScheme.primary,
                      currency: currency,
                      isBold: true,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceRow(
    BuildContext context, {
    required String label,
    required double amount,
    required Color color,
    required String currency,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          CurrencyFormatter.format(amount, currencyCode: currency),
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAllTasksOverviewCard(BuildContext context, List<Task> allTasks) {
    final pending = allTasks.where((t) => t.status != 'completed').length;
    final overdue = allTasks.where((t) => _isOverdue(t)).length;
    final important = allTasks.where((t) => t.isImportant).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tasks Overview',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatPill('Pending', '$pending', Colors.orange),
                _buildStatPill('Overdue', '$overdue', Colors.red),
                _buildStatPill('Important', '$important', Colors.amber),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildFocusSummaryCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totalSeconds = ref.watch(todayFocusTimeSecondsProvider);
    final sessions = ref.watch(todayFocusSessionsProvider);
    final settings = ref.watch(appSettingsProvider);
    final completedSessions = sessions.where((s) => s.completed).length;

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final formattedTime = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    final goalHours = settings.dailyFocusGoalHours;
    final goalSeconds = (goalHours * 3600).toInt();
    final progress = goalSeconds > 0
        ? (totalSeconds / goalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Today\'s Focus',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.go('/focus'),
                  child: const Text(
                    'Start Focus',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  formattedTime,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$completedSessions sessions completed',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Daily Goal: ${goalHours.toStringAsFixed(1)}h (${(progress * 100).toInt()}%)',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../database/database.dart';
import '../providers/budget_provider.dart';
import '../providers/database_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/focus_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/dashboard_section.dart';
import '../widgets/neumorphic_button.dart';
import '../widgets/neumorphic_card.dart';
import '../widgets/neumorphic_container.dart';
import '../widgets/neumorphic_icon_button.dart';
import '../widgets/notification_settings_section.dart';
import '../widgets/quick_actions.dart';
import '../widgets/today_overview.dart';
import '../widgets/today_schedule.dart';
import 'task_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 22) return 'Good evening';
    return 'Good night';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final financeSummaryAsync = ref.watch(financeSummaryProvider);
    final settings = ref.watch(appSettingsProvider);
    final budgetStatusAsync = ref.watch(budgetStatusListProvider);
    final subscriptionsAsync = ref.watch(subscriptionsStreamProvider);
    final focusSeconds = ref.watch(todayFocusTimeSecondsProvider);
    final focusSessions = ref.watch(todayFocusSessionsProvider);
    final unreadAsync = ref.watch(unreadNotificationCountProvider);
    final unreadCount = unreadAsync.value ?? 0;

    final theme = Theme.of(context);
    final now = DateTime.now();

    final allTasks = tasksAsync.value ?? [];
    final overdueTasks = allTasks
        .where(
          (t) =>
              t.status != 'completed' &&
              t.dueDate != null &&
              t.dueDate!.isBefore(DateTime(now.year, now.month, now.day)),
        )
        .toList();

    final upcomingTasks = allTasks.where((t) {
      if (t.status == 'completed' || t.dueDate == null) return false;
      final dateOnly = DateTime(
        t.dueDate!.year,
        t.dueDate!.month,
        t.dueDate!.day,
      );
      final todayOnly = DateTime(now.year, now.month, now.day);
      return dateOnly.isAfter(todayOnly);
    }).toList();
    upcomingTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    final isNewUser = allTasks.isEmpty;

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
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          NeumorphicIconButton(
            icon: Icons.search,
            tooltip: 'Search everything',
            onPressed: () => context.go('/search'),
          ),
          const SizedBox(width: 8),
          NeumorphicIconButton(
            icon: Icons.wb_sunny_outlined,
            tooltip: 'Daily Briefing',
            onPressed: () => context.go('/briefing'),
          ),
          const SizedBox(width: 8),
          Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: NeumorphicIconButton(
              icon: Icons.notifications_outlined,
              tooltip: 'Notifications',
              onPressed: () => context.go('/notifications'),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar Button Trigger (Inset Neumorphic Input Style)
            GestureDetector(
              onTap: () => context.go('/search'),
              child: NeumorphicContainer(
                style: NeumorphicStyle.inset,
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Search everything... (Ctrl + F)',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Ctrl + K',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (isNewUser) ...[
              // EMPTY DASHBOARD STATE FOR NEW USER
              _buildNewUserWelcomeCard(context),
              const SizedBox(height: 20),
            ],

            // 1. TODAY OVERVIEW CARDS
            DashboardSection(
              title: 'Today\'s Overview',
              icon: Icons.grid_view_rounded,
              child: const TodayOverview(),
            ),

            // 2. QUICK ACTIONS
            DashboardSection(
              title: 'Quick Actions',
              icon: Icons.flash_on_outlined,
              child: const QuickActions(),
            ),

            // 3. TODAY'S SCHEDULE
            DashboardSection(
              title: 'Today\'s Schedule',
              icon: Icons.schedule_outlined,
              actionLabel: 'View Calendar',
              onAction: () => context.go('/calendar'),
              child: const TodaySchedule(),
            ),

            // 4. OVERDUE TASKS (if any)
            if (overdueTasks.isNotEmpty)
              DashboardSection(
                title: 'Overdue Tasks (${overdueTasks.length})',
                icon: Icons.warning_amber_rounded,
                actionLabel: 'View All',
                onAction: () => context.go('/tasks'),
                child: _buildOverdueTasksCard(context, ref, overdueTasks),
              ),

            // UPCOMING TASKS (if any)
            if (upcomingTasks.isNotEmpty)
              DashboardSection(
                title: 'Upcoming Tasks',
                icon: Icons.upcoming_outlined,
                actionLabel: 'View Tasks',
                onAction: () => context.go('/tasks'),
                child: _buildUpcomingTasksCard(
                  context,
                  upcomingTasks.take(3).toList(),
                ),
              ),

            // 5. DAILY BRIEFING COMPACT CARD
            DashboardSection(
              title: 'Daily Briefing',
              icon: Icons.wb_sunny_outlined,
              actionLabel: 'Open Briefing',
              onAction: () => context.go('/briefing'),
              child: _buildDailyBriefingCard(
                context,
                ref,
                allTasks: allTasks,
                focusSeconds: focusSeconds,
              ),
            ),

            // 6. CONDITIONAL BUDGET & SUBSCRIPTION WARNINGS
            _buildConditionalAlertsSection(
              context,
              budgetStatusAsync: budgetStatusAsync,
              subscriptionsAsync: subscriptionsAsync,
            ),

            // 7. FINANCE SNAPSHOT
            DashboardSection(
              title: 'Finance Snapshot',
              icon: Icons.account_balance_wallet_outlined,
              actionLabel: 'View Finance',
              onAction: () => context.go('/finance'),
              child: _buildFinanceSnapshotCard(
                context,
                financeSummaryAsync: financeSummaryAsync,
                currency: settings.currency,
              ),
            ),

            // 8. FOCUS SNAPSHOT
            DashboardSection(
              title: 'Focus Snapshot',
              icon: Icons.timer_outlined,
              actionLabel: 'Start Focus',
              onAction: () => context.go('/focus'),
              child: _buildFocusSnapshotCard(
                context,
                focusSeconds: focusSeconds,
                sessionCount: focusSessions.length,
                dailyGoalHours: settings.dailyFocusGoalHours,
              ),
            ),

            // 9. PRODUCTIVITY SNAPSHOT
            DashboardSection(
              title: 'Productivity',
              icon: Icons.bar_chart_outlined,
              actionLabel: 'View Analytics',
              onAction: () => context.go('/analytics'),
              child: _buildProductivitySnapshotCard(
                context,
                allTasks: allTasks,
                focusSeconds: focusSeconds,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewUserWelcomeCard(BuildContext context) {
    final theme = Theme.of(context);
    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              const Text(
                'Welcome to Personal Command Center',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding your first task or logging your daily spending. Your data remains 100% private and stored locally on your device.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          NeumorphicButton(
            icon: Icons.add,
            label: 'Add First Task',
            isPrimary: true,
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AddTaskDialog(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueTasksCard(
    BuildContext context,
    WidgetRef ref,
    List<Task> overdueTasks,
  ) {
    return NeumorphicCard(
      padding: EdgeInsets.zero,
      borderColor: Colors.red.withValues(alpha: 0.5),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: overdueTasks.length > 3 ? 3 : overdueTasks.length,
        separatorBuilder: (ctx, idx) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final task = overdueTasks[index];
          return ListTile(
            leading: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 20,
            ),
            title: Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Due: ${task.dueDate.toString().split(' ')[0]}'),
            trailing: NeumorphicIconButton(
              icon: Icons.check,
              size: 34,
              iconSize: 18,
              iconColor: Colors.green,
              onPressed: () {
                ref.read(databaseProvider).completeTask(task.id);
              },
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(taskId: task.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUpcomingTasksCard(BuildContext context, List<Task> upcoming) {
    return NeumorphicCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: upcoming.length,
        separatorBuilder: (ctx, idx) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final task = upcoming[index];
          final dateStr = task.dueDate != null
              ? '${task.dueDate!.day}/${task.dueDate!.month}'
              : '';
          return ListTile(
            leading: const Icon(Icons.event_outlined, size: 20),
            title: Text(task.title),
            subtitle: Text('Due $dateStr · ${task.category}'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(taskId: task.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDailyBriefingCard(
    BuildContext context,
    WidgetRef ref, {
    required List<Task> allTasks,
    required int focusSeconds,
  }) {
    final settings = ref.watch(appSettingsProvider);
    final now = DateTime.now();

    String nextBriefingStr = 'Disabled';
    if (settings.dailyBriefingEnabled) {
      var briefingDt = DateTime(
        now.year,
        now.month,
        now.day,
        settings.dailyBriefingHour,
        settings.dailyBriefingMinute,
      );
      final isToday = briefingDt.isAfter(now);
      final timeStr = NotificationSettingsSection.formatTimeOfDay(
        settings.dailyBriefingTime,
      );
      nextBriefingStr = isToday ? 'Today at $timeStr' : 'Tomorrow at $timeStr';
    }

    final todayTasks = allTasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == now.year &&
          t.dueDate!.month == now.month &&
          t.dueDate!.day == now.day;
    }).toList();

    final highPriority = todayTasks.where((t) => t.priority == 'high').length;
    final overdueCount = allTasks
        .where(
          (t) =>
              t.status != 'completed' &&
              t.dueDate != null &&
              t.dueDate!.isBefore(DateTime(now.year, now.month, now.day)),
        )
        .length;

    final focusMins = focusSeconds ~/ 60;
    final theme = Theme.of(context);

    return NeumorphicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next briefing: $nextBriefingStr',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: settings.dailyBriefingEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              NeumorphicButton(
                icon: Icons.open_in_new,
                label: 'Open',
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                onPressed: () => context.go('/briefing'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'You have ${todayTasks.length} tasks scheduled for today.',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            '• $highPriority are high priority.\n'
            '• $overdueCount task(s) overdue.\n'
            '• Focused for ${focusMins}m today.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionalAlertsSection(
    BuildContext context, {
    required AsyncValue<List<BudgetStatusInfo>> budgetStatusAsync,
    required AsyncValue<List<Subscription>> subscriptionsAsync,
  }) {
    final budgetAlerts = <BudgetStatusInfo>[];
    final budgetList = budgetStatusAsync.value ?? [];
    for (final b in budgetList) {
      if (b.percentage >= 80) {
        budgetAlerts.add(b);
      }
    }

    final upcomingSubs = <Subscription>[];
    final subList = subscriptionsAsync.value ?? [];
    final now = DateTime.now();
    for (final s in subList) {
      if (s.active) {
        final days = s.nextBillingDate.difference(now).inDays;
        if (days >= 0 && days <= 3) {
          upcomingSubs.add(s);
        }
      }
    }

    if (budgetAlerts.isEmpty && upcomingSubs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (budgetAlerts.isNotEmpty) ...[
          DashboardSection(
            title: 'Budget Alert',
            icon: Icons.warning_amber_rounded,
            actionLabel: 'View Budget',
            onAction: () => context.go('/finance'),
            child: NeumorphicCard(
              padding: const EdgeInsets.all(14),
              borderColor: Colors.orange.withValues(alpha: 0.6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${budgetAlerts.first.budget.category} Budget Alert',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${budgetAlerts.first.percentage.toInt()}% used · ${CurrencyFormatter.format(budgetAlerts.first.spentAmount)} / ${CurrencyFormatter.format(budgetAlerts.first.budget.amount)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const Icon(Icons.warning, color: Colors.orange),
                ],
              ),
            ),
          ),
        ],
        if (upcomingSubs.isNotEmpty) ...[
          DashboardSection(
            title: 'Upcoming Subscription Payment',
            icon: Icons.subscriptions_outlined,
            actionLabel: 'View Subscriptions',
            onAction: () => context.go('/finance'),
            child: NeumorphicCard(
              padding: const EdgeInsets.all(14),
              borderColor: Colors.purple.withValues(alpha: 0.6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        upcomingSubs.first.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${CurrencyFormatter.format(upcomingSubs.first.amount)} · Due in ${upcomingSubs.first.nextBillingDate.difference(now).inDays} days',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const Icon(Icons.payment, color: Colors.purple),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFinanceSnapshotCard(
    BuildContext context, {
    required AsyncValue<FinanceSummary> financeSummaryAsync,
    required String currency,
  }) {
    final summary =
        financeSummaryAsync.value ??
        const FinanceSummary(
          income: 0,
          expenses: 0,
          balance: 0,
          savingsRate: 0,
        );

    return NeumorphicCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFinanceMetric(
            context,
            'Income',
            CurrencyFormatter.format(summary.income),
            Colors.green,
          ),
          _buildFinanceMetric(
            context,
            'Expenses',
            CurrencyFormatter.format(summary.expenses),
            Colors.red,
          ),
          _buildFinanceMetric(
            context,
            'Savings',
            CurrencyFormatter.format(summary.balance),
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceMetric(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFocusSnapshotCard(
    BuildContext context, {
    required int focusSeconds,
    required int sessionCount,
    required double dailyGoalHours,
  }) {
    final theme = Theme.of(context);
    final focusHours = focusSeconds / 3600.0;
    final goalPercentage =
        (focusHours / (dailyGoalHours <= 0 ? 1 : dailyGoalHours) * 100)
            .clamp(0, 100)
            .toInt();

    final mins = (focusSeconds % 3600) ~/ 60;
    final hrs = focusSeconds ~/ 3600;
    final timeStr = hrs > 0 ? '${hrs}h ${mins}m' : '${mins}m';

    return NeumorphicCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Focus Today: $timeStr',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$sessionCount completed sessions · Daily Goal: ${dailyGoalHours.toInt()}h ($goalPercentage%)',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          CircularProgressIndicator(
            value: (focusHours / (dailyGoalHours <= 0 ? 1 : dailyGoalHours))
                .clamp(0.0, 1.0),
            backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildProductivitySnapshotCard(
    BuildContext context, {
    required List<Task> allTasks,
    required int focusSeconds,
  }) {
    final theme = Theme.of(context);
    final completed = allTasks.where((t) => t.status == 'completed').length;
    final total = allTasks.length;
    final rate = total == 0 ? 0 : ((completed / total) * 100).toInt();

    final hrs = focusSeconds ~/ 3600;
    final mins = (focusSeconds % 3600) ~/ 60;
    final timeStr = hrs > 0 ? '${hrs}h ${mins}m' : '${mins}m';

    return NeumorphicCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                'Completion',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$rate%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$completed / $total tasks',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                'Focus Time',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              Text(
                'today',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/notification_provider.dart';
import 'screens/analytics_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/daily_briefing_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/focus_history_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tasks_screen.dart';
import 'widgets/add_expense_dialog.dart';
import 'widgets/add_income_dialog.dart';
import 'widgets/add_task_dialog.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppNavigation(child: child);
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/tasks',
          builder: (context, state) => const TasksScreen(),
        ),
        GoRoute(
          path: '/focus',
          builder: (context, state) => const FocusScreen(),
        ),
        GoRoute(
          path: '/focus-history',
          builder: (context, state) => const FocusHistoryScreen(),
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/finance',
          builder: (context, state) => const FinanceScreen(),
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/briefing',
          builder: (context, state) => const DailyBriefingScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
    ),
  ],
);

class AppNavigation extends ConsumerStatefulWidget {
  final Widget child;

  const AppNavigation({super.key, required this.child});

  @override
  ConsumerState<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends ConsumerState<AppNavigation> {
  int desktopIndex(String location) {
    if (location == '/tasks') return 1;
    if (location == '/calendar') return 2;
    if (location == '/focus' || location == '/focus-history') return 3;
    if (location == '/finance') return 4;
    if (location == '/analytics') return 5;
    if (location == '/settings') return 6;
    return 0; // Default to Home for '/', '/briefing', '/notifications'
  }

  int mobileIndex(String location) {
    if (location == '/tasks') return 1;
    if (location == '/calendar') return 2;
    if (location == '/finance') return 3;
    if (location == '/focus' ||
        location == '/focus-history' ||
        location == '/analytics' ||
        location == '/settings' ||
        location == '/notifications') {
      return 4; // 'More' selected for nested routes
    }
    return 0;
  }

  void navigateDesktopTo(int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/tasks');
        break;
      case 2:
        context.go('/calendar');
        break;
      case 3:
        context.go('/focus');
        break;
      case 4:
        context.go('/finance');
        break;
      case 5:
        context.go('/analytics');
        break;
      case 6:
        context.go('/settings');
        break;
    }
  }

  void navigateMobileTo(int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/tasks');
        break;
      case 2:
        context.go('/calendar');
        break;
      case 3:
        context.go('/finance');
        break;
      case 4:
        _showMoreSheet();
        break;
    }
  }

  void _showMoreSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'More Options',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('Focus / Pomodoro'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/focus');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart_outlined),
                  title: const Text('Analytics & Insights'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/analytics');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/notifications');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/settings');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showQuickAdd() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Add',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // ADD TASK
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Add Task',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Create a new task or reminder'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Future.delayed(const Duration(milliseconds: 150), () {
                      if (!mounted) return;
                      showDialog(
                        context: context,
                        builder: (_) => const AddTaskDialog(),
                      );
                    });
                  },
                ),
                const SizedBox(height: 10),

                // ADD EXPENSE
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Add Expense',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Log a new daily transaction'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Future.delayed(const Duration(milliseconds: 150), () {
                      if (!mounted) return;
                      showDialog(
                        context: context,
                        builder: (_) => const AddExpenseDialog(),
                      );
                    });
                  },
                ),
                const SizedBox(height: 10),

                // ADD INCOME
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.attach_money,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Add Income',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Record earnings or incoming funds'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Future.delayed(const Duration(milliseconds: 150), () {
                      if (!mounted) return;
                      showDialog(
                        context: context,
                        builder: (_) => const AddIncomeDialog(),
                      );
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationBellIcon(int unreadCount) {
    return Badge(
      isLabelVisible: unreadCount > 0,
      label: Text('$unreadCount'),
      child: IconButton(
        tooltip: 'Notifications',
        onPressed: () => context.go('/notifications'),
        icon: const Icon(Icons.notifications_outlined),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final location = GoRouterState.of(context).uri.path;
    final unreadAsync = ref.watch(unreadNotificationCountProvider);
    final unreadCount = unreadAsync.value ?? 0;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: desktopIndex(location),
              onDestinationSelected: navigateDesktopTo,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      tooltip: 'Quick Add',
                      elevation: 0,
                      onPressed: showQuickAdd,
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 12),
                    _buildNotificationBellIcon(unreadCount),
                    const SizedBox(height: 8),
                    IconButton(
                      tooltip: 'Daily Briefing',
                      onPressed: () => context.go('/briefing'),
                      icon: const Icon(Icons.wb_sunny_outlined, size: 22),
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.check_circle_outline),
                  selectedIcon: Icon(Icons.check_circle),
                  label: Text('Tasks'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: Text('Calendar'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.timer_outlined),
                  selectedIcon: Icon(Icons.timer),
                  label: Text('Focus'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: Text('Finance'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: Text('Analytics'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    return Scaffold(
      body: widget.child,
      floatingActionButton: FloatingActionButton(
        onPressed: showQuickAdd,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: mobileIndex(location),
        onDestinationSelected: navigateMobileTo,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Finance',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

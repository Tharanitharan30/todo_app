import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/notification_provider.dart';
import 'screens/analytics_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/daily_briefing_screen.dart';
import 'screens/finance_screen.dart';
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
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/tasks',
          builder: (context, state) => const TasksScreen(),
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

  const AppNavigation({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends ConsumerState<AppNavigation> {
  int get currentIndex {
    final location = GoRouterState.of(context).uri.path;

    if (location.startsWith('/tasks')) {
      return 1;
    }
    if (location.startsWith('/calendar')) {
      return 2;
    }
    if (location.startsWith('/finance')) {
      return 3;
    }
    if (location.startsWith('/analytics')) {
      return 4;
    }
    if (location.startsWith('/settings')) {
      return 5;
    }

    return 0;
  }

  void navigateTo(int index) {
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
        context.go('/analytics');
        break;
      case 5:
        context.go('/settings');
        break;
    }
  }

  void showQuickAdd() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Quick Add',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // ADD TASK
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.check_circle_outline),
                  ),
                  title: const Text(
                    'Add Task',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('Create a new task'),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    Future.delayed(
                      const Duration(milliseconds: 150),
                      () {
                        if (!mounted) return;

                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (dialogContext) {
                            return const AddTaskDialog();
                          },
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 8),

                // ADD EXPENSE
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  title: const Text(
                    'Add Expense',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Record a new expense'),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    Future.delayed(
                      const Duration(milliseconds: 150),
                      () {
                        if (!mounted) return;

                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (dialogContext) {
                            return const AddExpenseDialog();
                          },
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 8),

                // ADD INCOME
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.attach_money),
                  ),
                  title: const Text(
                    'Add Income',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Record new income'),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    Future.delayed(
                      const Duration(milliseconds: 150),
                      () {
                        if (!mounted) return;

                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (dialogContext) {
                            return const AddIncomeDialog();
                          },
                        );
                      },
                    );
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
    final unreadAsync = ref.watch(unreadNotificationCountProvider);
    final unreadCount = unreadAsync.value ?? 0;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: navigateTo,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                child: Column(
                  children: [
                    IconButton(
                      tooltip: 'Quick Add',
                      onPressed: showQuickAdd,
                      icon: const Icon(Icons.add_circle_outline, size: 28),
                    ),
                    const SizedBox(height: 8),
                    _buildNotificationBellIcon(unreadCount),
                    const SizedBox(height: 8),
                    IconButton(
                      tooltip: 'Daily Briefing',
                      onPressed: () => context.go('/briefing'),
                      icon: const Icon(Icons.wb_sunny_outlined, size: 24),
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
      appBar: AppBar(
        toolbarHeight: 0,
      ),
      body: widget.child,
      floatingActionButton: FloatingActionButton(
        onPressed: showQuickAdd,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: navigateTo,
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
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
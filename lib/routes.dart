import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tasks_screen.dart';
import 'widgets/add_expense_dialog.dart';
import 'widgets/add_income_dialog.dart';
import 'widgets/add_task_dialog.dart';
import 'widgets/command_palette.dart';
import 'widgets/neumorphic_card.dart';
import 'widgets/neumorphic_container.dart';
import 'widgets/neumorphic_icon_button.dart';

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
          path: '/daily-briefing',
          builder: (context, state) => const DailyBriefingScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
      ],
    ),
  ],
);

// Global Intent Definitions
class _IntentCommandPalette extends Intent {
  const _IntentCommandPalette();
}

class _IntentAddTask extends Intent {
  const _IntentAddTask();
}

class _IntentAddExpense extends Intent {
  const _IntentAddExpense();
}

class _IntentAddIncome extends Intent {
  const _IntentAddIncome();
}

class _IntentSearch extends Intent {
  const _IntentSearch();
}

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
    return 0; // Default to Home for '/', '/briefing', '/notifications', '/search'
  }

  int mobileIndex(String location) {
    if (location == '/tasks') return 1;
    if (location == '/calendar') return 2;
    if (location == '/finance') return 3;
    if (location == '/focus' ||
        location == '/focus-history' ||
        location == '/analytics' ||
        location == '/settings' ||
        location == '/notifications' ||
        location == '/search') {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                const SizedBox(height: 16),
                _buildMoreTile(
                  icon: Icons.search,
                  title: 'Global Search',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/search');
                  },
                ),
                const SizedBox(height: 8),
                _buildMoreTile(
                  icon: Icons.timer_outlined,
                  title: 'Focus / Pomodoro',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/focus');
                  },
                ),
                const SizedBox(height: 8),
                _buildMoreTile(
                  icon: Icons.bar_chart_outlined,
                  title: 'Analytics & Insights',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/analytics');
                  },
                ),
                const SizedBox(height: 8),
                _buildMoreTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/notifications');
                  },
                ),
                const SizedBox(height: 8),
                _buildMoreTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
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

  Widget _buildMoreTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return NeumorphicCard(
      style: NeumorphicStyle.raised,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    );
  }

  void showQuickAdd() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                NeumorphicCard(
                  padding: const EdgeInsets.all(14),
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
                  child: Row(
                    children: [
                      Container(
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
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Task',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Create a new task or reminder',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ADD EXPENSE
                NeumorphicCard(
                  padding: const EdgeInsets.all(14),
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
                  child: Row(
                    children: [
                      Container(
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
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Expense',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Log a new daily transaction',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ADD INCOME
                NeumorphicCard(
                  padding: const EdgeInsets.all(14),
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
                  child: Row(
                    children: [
                      Container(
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
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Income',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Record earnings or incoming funds',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
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
      child: NeumorphicIconButton(
        tooltip: 'Notifications',
        onPressed: () => context.go('/notifications'),
        icon: Icons.notifications_outlined,
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

    final childWidget = isDesktop
        ? Scaffold(
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
                        NeumorphicIconButton(
                          tooltip: 'Quick Add',
                          onPressed: showQuickAdd,
                          icon: Icons.add,
                          size: 46,
                          iconSize: 22,
                          color: Theme.of(context).colorScheme.primary,
                          iconColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                        const SizedBox(height: 14),
                        NeumorphicIconButton(
                          tooltip: 'Search (Ctrl + F)',
                          onPressed: () => context.go('/search'),
                          icon: Icons.search,
                        ),
                        const SizedBox(height: 10),
                        _buildNotificationBellIcon(unreadCount),
                        const SizedBox(height: 10),
                        NeumorphicIconButton(
                          tooltip: 'Daily Briefing',
                          onPressed: () => context.go('/briefing'),
                          icon: Icons.wb_sunny_outlined,
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
          )
        : Scaffold(
            body: widget.child,
            floatingActionButton: NeumorphicIconButton(
              tooltip: 'Quick Add',
              onPressed: showQuickAdd,
              icon: Icons.add,
              size: 56,
              iconSize: 26,
              borderRadius: 28,
              color: Theme.of(context).colorScheme.primary,
              iconColor: Theme.of(context).colorScheme.onPrimary,
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

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
            const _IntentCommandPalette(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyT):
            const _IntentAddTask(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyE):
            const _IntentAddExpense(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI):
            const _IntentAddIncome(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const _IntentSearch(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _IntentCommandPalette: CallbackAction<_IntentCommandPalette>(
            onInvoke: (_) {
              CommandPaletteDialog.show(context);
              return null;
            },
          ),
          _IntentAddTask: CallbackAction<_IntentAddTask>(
            onInvoke: (_) {
              showDialog(
                context: context,
                builder: (_) => const AddTaskDialog(),
              );
              return null;
            },
          ),
          _IntentAddExpense: CallbackAction<_IntentAddExpense>(
            onInvoke: (_) {
              showDialog(
                context: context,
                builder: (_) => const AddExpenseDialog(),
              );
              return null;
            },
          ),
          _IntentAddIncome: CallbackAction<_IntentAddIncome>(
            onInvoke: (_) {
              showDialog(
                context: context,
                builder: (_) => const AddIncomeDialog(),
              );
              return null;
            },
          ),
          _IntentSearch: CallbackAction<_IntentSearch>(
            onInvoke: (_) {
              context.go('/search');
              return null;
            },
          ),
        },
        child: childWidget,
      ),
    );
  }
}

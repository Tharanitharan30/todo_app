import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/calendar_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/calendar_agenda.dart';
import '../widgets/calendar_day_view.dart';
import '../widgets/calendar_month_view.dart';
import '../widgets/calendar_task_item.dart';
import '../widgets/calendar_week_view.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String _formatFocusedPeriod(DateTime date, CalendarViewMode mode) {
    const months = [
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

    switch (mode) {
      case CalendarViewMode.month:
        return '${months[date.month - 1]} ${date.year}';
      case CalendarViewMode.week:
        return 'Week of ${months[date.month - 1]} ${date.day}, ${date.year}';
      case CalendarViewMode.day:
        return '${months[date.month - 1]} ${date.day}, ${date.year}';
      case CalendarViewMode.agenda:
        return 'Agenda (${months[date.month - 1]} ${date.year})';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calState = ref.watch(calendarStateProvider);
    final settings = ref.watch(appSettingsProvider);
    final calNotifier = ref.read(calendarStateProvider.notifier);

    final selectedTasks = ref.watch(calendarTasksForSelectedDateProvider);
    final todaySummary = ref.watch(todayPlanSummaryProvider);
    final weekStats = ref.watch(weekStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calendar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to Today',
            onPressed: calNotifier.goToToday,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          return Column(
            children: [
              // TOP HEADER & NAVIGATION BAR
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: theme.colorScheme.surfaceContainerLow,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Focused Period Header & Navigation Arrows
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () => calNotifier.previousPeriod(
                                settings.weekStartsOn,
                              ),
                            ),
                            Text(
                              _formatFocusedPeriod(
                                calState.focusedDate,
                                calState.viewMode,
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () =>
                                  calNotifier.nextPeriod(settings.weekStartsOn),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: calNotifier.goToToday,
                              child: const Text('Today'),
                            ),
                          ],
                        ),

                        // View Mode Switcher
                        SegmentedButton<CalendarViewMode>(
                          segments: const [
                            ButtonSegment(
                              value: CalendarViewMode.month,
                              label: Text('Month'),
                            ),
                            ButtonSegment(
                              value: CalendarViewMode.week,
                              label: Text('Week'),
                            ),
                            ButtonSegment(
                              value: CalendarViewMode.day,
                              label: Text('Day'),
                            ),
                            ButtonSegment(
                              value: CalendarViewMode.agenda,
                              label: Text('Agenda'),
                            ),
                          ],
                          selected: {calState.viewMode},
                          onSelectionChanged: (set) {
                            calNotifier.setViewMode(set.first);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // STATUS & SEARCH FILTER BAR
                    Row(
                      children: [
                        // Search bar input
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText: 'Search calendar tasks...',
                              prefixIcon: const Icon(Icons.search, size: 18),
                              suffixIcon: searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        searchController.clear();
                                        calNotifier.setSearchQuery('');
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (val) {
                              calNotifier.setSearchQuery(val);
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Status Filter Dropdown
                        DropdownButton<CalendarStatusFilter>(
                          value: calState.statusFilter,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: CalendarStatusFilter.all,
                              child: Text('All Tasks'),
                            ),
                            DropdownMenuItem(
                              value: CalendarStatusFilter.pending,
                              child: Text('Pending'),
                            ),
                            DropdownMenuItem(
                              value: CalendarStatusFilter.completed,
                              child: Text('Completed'),
                            ),
                            DropdownMenuItem(
                              value: CalendarStatusFilter.important,
                              child: Text('Important ★'),
                            ),
                            DropdownMenuItem(
                              value: CalendarStatusFilter.overdue,
                              child: Text('Overdue'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) calNotifier.setStatusFilter(val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // MAIN CONTENT BODY (DESKTOP MULTI-COLUMN VS MOBILE SINGLE COLUMN)
              Expanded(
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Selected Calendar View
                          Expanded(
                            flex: 3,
                            child: _buildCalendarViewContent(calState.viewMode),
                          ),

                          const VerticalDivider(width: 1),

                          // Right Column: Planning Summaries & Selected Date Tasks
                          Expanded(
                            flex: 2,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // TODAY'S PLAN SUMMARY CARD
                                  _buildTodayPlanCard(context, todaySummary),

                                  const SizedBox(height: 16),

                                  // WEEK STATISTICS CARD
                                  _buildWeekStatsCard(context, weekStats),

                                  const SizedBox(height: 20),

                                  // SELECTED DATE TASKS HEADER
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Selected Date Tasks',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${calState.selectedDate.day}/${calState.selectedDate.month}/${calState.selectedDate.year}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      FilledButton.icon(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AddTaskDialog(
                                              initialDueDate:
                                                  calState.selectedDate,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Add Task'),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // SELECTED DATE TASKS LIST
                                  if (selectedTasks.isEmpty)
                                    Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.event_note,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'No tasks scheduled',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Your schedule is clear for this date.',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: theme
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
                                    ...selectedTasks.map(
                                      (t) => CalendarTaskItem(task: t),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: _buildCalendarViewContent(calState.viewMode),
                          ),
                          if (calState.viewMode == CalendarViewMode.month) ...[
                            const Divider(height: 1),
                            // Mobile Selected Date Tasks Drawer Section
                            Container(
                              height: 220,
                              padding: const EdgeInsets.all(12),
                              color: theme.colorScheme.surfaceContainerLow,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Tasks for ${calState.selectedDate.day}/${calState.selectedDate.month}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton.filledTonal(
                                        icon: const Icon(Icons.add, size: 18),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AddTaskDialog(
                                              initialDueDate:
                                                  calState.selectedDate,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: selectedTasks.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'No tasks on this date',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            itemCount: selectedTasks.length,
                                            itemBuilder: (ctx, idx) {
                                              return CalendarTaskItem(
                                                task: selectedTasks[idx],
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendarViewContent(CalendarViewMode mode) {
    switch (mode) {
      case CalendarViewMode.month:
        return const CalendarMonthView();
      case CalendarViewMode.week:
        return const CalendarWeekView();
      case CalendarViewMode.day:
        return const CalendarDayView();
      case CalendarViewMode.agenda:
        return const CalendarAgendaView();
    }
  }

  Widget _buildTodayPlanCard(BuildContext context, TodayPlanSummary summary) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Today\'s Plan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _planStatItem('Total', '${summary.totalTasks}', Colors.blue),
                _planStatItem(
                  'High Priority',
                  '${summary.highPriorityCount}',
                  Colors.amber,
                ),
                _planStatItem('Overdue', '${summary.overdueCount}', Colors.red),
                _planStatItem(
                  'Completed',
                  '${summary.completedCount}/${summary.totalTasks}',
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (summary.completionRate / 100).clamp(0.0, 1.0),
                minHeight: 6,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Progress: ${summary.completionRate.toStringAsFixed(1)}%',
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

  Widget _buildWeekStatsCard(BuildContext context, WeekStatistics stats) {
    final theme = Theme.of(context);
    final focusHours = (stats.focusTimeSeconds / 3600).toStringAsFixed(1);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.date_range,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Week Statistics',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _planStatItem(
                  'Week Tasks',
                  '${stats.totalTasks}',
                  theme.colorScheme.primary,
                ),
                _planStatItem(
                  'Completed',
                  '${stats.completedTasks}',
                  Colors.green,
                ),
                _planStatItem(
                  'Rate',
                  '${stats.completionRate.toStringAsFixed(0)}%',
                  Colors.purple,
                ),
                _planStatItem('Focus Time', '${focusHours}h', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _planStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

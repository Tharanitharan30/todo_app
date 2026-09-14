import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/focus_provider.dart';
import '../providers/task_provider.dart';

enum HistoryPeriod { today, sevenDays, thirtyDays, all }

class FocusHistoryScreen extends ConsumerStatefulWidget {
  const FocusHistoryScreen({super.key});

  @override
  ConsumerState<FocusHistoryScreen> createState() => _FocusHistoryScreenState();
}

class _FocusHistoryScreenState extends ConsumerState<FocusHistoryScreen> {
  HistoryPeriod selectedPeriod = HistoryPeriod.sevenDays;

  String _formatHoursMinutes(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  List<FocusSession> _filterSessions(List<FocusSession> sessions) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    switch (selectedPeriod) {
      case HistoryPeriod.today:
        return sessions
            .where(
              (s) =>
                  s.completed &&
                  s.type == 'focus' &&
                  s.startedAt.isAfter(
                    todayStart.subtract(const Duration(milliseconds: 1)),
                  ),
            )
            .toList();
      case HistoryPeriod.sevenDays:
        final start = todayStart.subtract(const Duration(days: 6));
        return sessions
            .where(
              (s) =>
                  s.completed &&
                  s.type == 'focus' &&
                  s.startedAt.isAfter(
                    start.subtract(const Duration(milliseconds: 1)),
                  ),
            )
            .toList();
      case HistoryPeriod.thirtyDays:
        final start = todayStart.subtract(const Duration(days: 29));
        return sessions
            .where(
              (s) =>
                  s.completed &&
                  s.type == 'focus' &&
                  s.startedAt.isAfter(
                    start.subtract(const Duration(milliseconds: 1)),
                  ),
            )
            .toList();
      case HistoryPeriod.all:
        return sessions.where((s) => s.completed && s.type == 'focus').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(allFocusSessionsProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final theme = Theme.of(context);

    final allTasksMap = <int, Task>{
      if (tasksAsync.value != null)
        for (final t in tasksAsync.value!) t.id: t,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Focus History')),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading history: $err')),
        data: (allSessions) {
          final filtered = _filterSessions(allSessions);
          final totalSecs = filtered.fold(
            0,
            (sum, s) => sum + s.durationSeconds,
          );
          final sessionCount = filtered.length;
          final avgSecs = sessionCount > 0
              ? (totalSecs / sessionCount).round()
              : 0;

          // Productivity by Task
          final Map<String, int> taskSecsMap = {};
          for (final s in filtered) {
            String title = 'General Focus';
            if (s.taskId != null && allTasksMap.containsKey(s.taskId)) {
              title = allTasksMap[s.taskId]!.title;
            }
            taskSecsMap[title] = (taskSecsMap[title] ?? 0) + s.durationSeconds;
          }
          final sortedTasks = taskSecsMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // Productivity by Category
          final Map<String, int> catSecsMap = {};
          for (final s in filtered) {
            String cat = 'general';
            if (s.taskId != null && allTasksMap.containsKey(s.taskId)) {
              cat = allTasksMap[s.taskId]!.category;
            }
            catSecsMap[cat] = (catSecsMap[cat] ?? 0) + s.durationSeconds;
          }
          final sortedCategories = catSecsMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<HistoryPeriod>(
                    segments: const [
                      ButtonSegment(
                        value: HistoryPeriod.today,
                        label: Text('Today'),
                      ),
                      ButtonSegment(
                        value: HistoryPeriod.sevenDays,
                        label: Text('7 Days'),
                      ),
                      ButtonSegment(
                        value: HistoryPeriod.thirtyDays,
                        label: Text('30 Days'),
                      ),
                      ButtonSegment(
                        value: HistoryPeriod.all,
                        label: Text('All Time'),
                      ),
                    ],
                    selected: {selectedPeriod},
                    onSelectionChanged: (set) {
                      setState(() {
                        selectedPeriod = set.first;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Stat Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Focus Time',
                        _formatHoursMinutes(totalSecs),
                        Icons.timer_outlined,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        'Sessions',
                        '$sessionCount',
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        'Avg Session',
                        _formatHoursMinutes(avgSecs),
                        Icons.speed_rounded,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (filtered.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.history_toggle_off_rounded,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No focus sessions recorded for this period',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start a focus session to build your history.',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  // Productivity by Task
                  if (sortedTasks.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Most Focused Tasks',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...sortedTasks.take(5).map((e) {
                              final pct = totalSecs > 0
                                  ? (e.value / totalSecs)
                                  : 0.0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          e.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          _formatHoursMinutes(e.value),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        minHeight: 6,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Productivity by Category
                  if (sortedCategories.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Focus by Category',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...sortedCategories.map((e) {
                              final catName =
                                  '${e.key[0].toUpperCase()}${e.key.substring(1)}';
                              final pct = totalSecs > 0
                                  ? (e.value / totalSecs)
                                  : 0.0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          catName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          _formatHoursMinutes(e.value),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        minHeight: 6,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Chronological Session Log
                  const Text(
                    'Session History',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final s = filtered[index];
                      String taskTitle = 'General Focus';
                      if (s.taskId != null &&
                          allTasksMap.containsKey(s.taskId)) {
                        taskTitle = allTasksMap[s.taskId]!.title;
                      }

                      final timeStr =
                          '${s.startedAt.hour}:${s.startedAt.minute.toString().padLeft(2, '0')}';
                      final dateStr =
                          '${s.startedAt.day}/${s.startedAt.month}/${s.startedAt.year}';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withValues(
                              alpha: 0.12,
                            ),
                            child: const Icon(
                              Icons.timer_outlined,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            taskTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '$dateStr at $timeStr',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatHoursMinutes(s.durationSeconds),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

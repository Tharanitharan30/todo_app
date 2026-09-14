import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../database/database.dart';
import '../providers/focus_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/focus_task_selector.dart';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  String _formatDurationSeconds(int totalSeconds) {
    final mins = (totalSeconds / 60).floor();
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatHoursMinutes(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusState = ref.watch(focusProvider);
    final focusNotifier = ref.read(focusProvider.notifier);
    final settings = ref.watch(appSettingsProvider);

    final todaySessions = ref.watch(todayFocusSessionsProvider);
    final todayFocusSecs = ref.watch(todayFocusTimeSecondsProvider);

    final goalSecs = (settings.dailyFocusGoalHours * 3600).round();
    final goalProgress = goalSecs > 0
        ? (todayFocusSecs / goalSecs).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Focus History',
            onPressed: () => context.go('/focus-history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.go('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          if (isWide) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Timer & Controls
                  Expanded(
                    flex: 3,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            _buildSessionHeader(context, focusState, settings),
                            const SizedBox(height: 32),
                            _buildTimerDisplay(context, focusState),
                            const SizedBox(height: 32),
                            _buildTimerControls(
                              context,
                              focusState,
                              focusNotifier,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right Column: Task Selection & Today's Summary
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildTaskSelectionCard(
                          context,
                          focusState: focusState,
                          onSelectTask: () => _openTaskSelector(
                            context,
                            ref,
                            focusState.selectedTask,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTodaySummaryCard(
                          context,
                          todaySessionsCount: todaySessions.length,
                          todayFocusSecs: todayFocusSecs,
                          goalSecs: goalSecs,
                          goalProgress: goalProgress,
                          dailyGoalHours: settings.dailyFocusGoalHours,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTaskSelectionCard(
                  context,
                  focusState: focusState,
                  onSelectTask: () =>
                      _openTaskSelector(context, ref, focusState.selectedTask),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildSessionHeader(context, focusState, settings),
                        const SizedBox(height: 24),
                        _buildTimerDisplay(context, focusState),
                        const SizedBox(height: 24),
                        _buildTimerControls(context, focusState, focusNotifier),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTodaySummaryCard(
                  context,
                  todaySessionsCount: todaySessions.length,
                  todayFocusSecs: todayFocusSecs,
                  goalSecs: goalSecs,
                  goalProgress: goalProgress,
                  dailyGoalHours: settings.dailyFocusGoalHours,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionHeader(
    BuildContext context,
    FocusState focusState,
    AppSettings settings,
  ) {
    String title;
    Color color;

    switch (focusState.sessionType) {
      case FocusSessionType.focus:
        title = 'Focus Session';
        color = Colors.blue;
        break;
      case FocusSessionType.shortBreak:
        title = 'Short Break';
        color = Colors.green;
        break;
      case FocusSessionType.longBreak:
        title = 'Long Break';
        color = Colors.purple;
        break;
    }

    final cycleNum =
        (focusState.completedPomodoros % settings.sessionsBeforeLongBreak) + 1;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                focusState.sessionType == FocusSessionType.focus
                    ? Icons.timer_outlined
                    : Icons.coffee_outlined,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (focusState.sessionType == FocusSessionType.focus)
          Text(
            'Session $cycleNum of ${settings.sessionsBeforeLongBreak}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          )
        else
          Text(
            'Take a moment to relax and recharge',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildTimerDisplay(BuildContext context, FocusState focusState) {
    final theme = Theme.of(context);
    final progress = focusState.totalSeconds > 0
        ? (focusState.remainingSeconds / focusState.totalSeconds).clamp(
            0.0,
            1.0,
          )
        : 0.0;

    Color progressColor;
    switch (focusState.sessionType) {
      case FocusSessionType.focus:
        progressColor = theme.colorScheme.primary;
        break;
      case FocusSessionType.shortBreak:
        progressColor = Colors.green;
        break;
      case FocusSessionType.longBreak:
        progressColor = Colors.purple;
        break;
    }

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 210,
            height: 210,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: progressColor,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatDurationSeconds(focusState.remainingSeconds),
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              if (focusState.isPaused)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'PAUSED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerControls(
    BuildContext context,
    FocusState focusState,
    FocusNotifier focusNotifier,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        if (!focusState.isRunning)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: () => focusNotifier.startFocusSession(),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start'),
          )
        else if (focusState.isPaused)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: () => focusNotifier.resumeTimer(),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Resume'),
          )
        else
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: () => focusNotifier.pauseTimer(),
            icon: const Icon(Icons.pause_rounded),
            label: const Text('Pause'),
          ),
        OutlinedButton.icon(
          onPressed: () => focusNotifier.resetTimer(),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Reset'),
        ),
        TextButton.icon(
          onPressed: () => focusNotifier.skipSession(),
          icon: const Icon(Icons.skip_next_rounded, size: 18),
          label: const Text('Skip'),
        ),
      ],
    );
  }

  Widget _buildTaskSelectionCard(
    BuildContext context, {
    required FocusState focusState,
    required VoidCallback onSelectTask,
  }) {
    final theme = Theme.of(context);
    final task = focusState.selectedTask;

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
                  'Current Task',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                TextButton(
                  onPressed: focusState.isRunning ? null : onSelectTask,
                  child: Text(task == null ? 'Select Task' : 'Change'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (task == null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.12,
                  ),
                  child: Icon(
                    Icons.center_focus_strong,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'General Focus',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('No specific task selected'),
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.task_alt,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                title: Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${task.category[0].toUpperCase()}${task.category.substring(1)} • Priority: ${task.priority}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummaryCard(
    BuildContext context, {
    required int todaySessionsCount,
    required int todayFocusSecs,
    required int goalSecs,
    required double goalProgress,
    required double dailyGoalHours,
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
                  'Today\'s Focus Summary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                TextButton.icon(
                  onPressed: () => context.go('/focus-history'),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('History'),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryStat(
                    'Sessions Today',
                    '$todaySessionsCount',
                    Icons.check_circle_outline,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryStat(
                    'Focus Time',
                    _formatHoursMinutes(todayFocusSecs),
                    Icons.timer_outlined,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daily Goal',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '${_formatHoursMinutes(todayFocusSecs)} / ${dailyGoalHours.toStringAsFixed(1)}h (${(goalProgress * 100).round()}%)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goalProgress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            radius: 16,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openTaskSelector(
    BuildContext context,
    WidgetRef ref,
    Task? selectedTask,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => FocusTaskSelector(
        selectedTask: selectedTask,
        onTaskSelected: (task) {
          ref.read(focusProvider.notifier).selectTask(task);
        },
      ),
    );
  }
}

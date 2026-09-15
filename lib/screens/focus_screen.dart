import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../database/database.dart';
import '../providers/focus_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/focus_task_selector.dart';
import '../widgets/neumorphic_button.dart';
import '../widgets/neumorphic_card.dart';
import '../widgets/neumorphic_container.dart';
import '../widgets/neumorphic_icon_button.dart';
import '../widgets/neumorphic_progress.dart';

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
          NeumorphicIconButton(
            icon: Icons.history_rounded,
            tooltip: 'Focus History',
            onPressed: () => context.go('/focus-history'),
          ),
          const SizedBox(width: 8),
          NeumorphicIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            onPressed: () => context.go('/settings'),
          ),
          const SizedBox(width: 12),
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
                    child: NeumorphicCard(
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
                NeumorphicCard(
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
    final theme = Theme.of(context);

    return Column(
      children: [
        NeumorphicContainer(
          style: NeumorphicStyle.inset,
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                focusState.sessionType == FocusSessionType.focus
                    ? Icons.timer_outlined
                    : Icons.coffee_outlined,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          )
        else
          Text(
            'Take a moment to relax and recharge',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
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

    return NeumorphicContainer(
      style: NeumorphicStyle.inset,
      borderRadius: 110,
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.05,
              ),
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
                    color: Colors.orange.withValues(alpha: 0.2),
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
          NeumorphicButton(
            icon: Icons.play_arrow_rounded,
            label: 'Start',
            isPrimary: true,
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            onPressed: () => focusNotifier.startFocusSession(),
          )
        else if (focusState.isPaused)
          NeumorphicButton(
            icon: Icons.play_arrow_rounded,
            label: 'Resume',
            isPrimary: true,
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            onPressed: () => focusNotifier.resumeTimer(),
          )
        else
          NeumorphicButton(
            icon: Icons.pause_rounded,
            label: 'Pause',
            color: Colors.orange,
            textColor: Colors.white,
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            onPressed: () => focusNotifier.pauseTimer(),
          ),
        NeumorphicButton(
          icon: Icons.refresh_rounded,
          label: 'Reset',
          borderRadius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          onPressed: () => focusNotifier.resetTimer(),
        ),
        NeumorphicButton(
          icon: Icons.skip_next_rounded,
          label: 'Skip',
          borderRadius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          onPressed: () => focusNotifier.skipSession(),
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

    return NeumorphicCard(
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
              NeumorphicButton(
                label: task == null ? 'Select Task' : 'Change',
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                onPressed: focusState.isRunning ? null : onSelectTask,
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
                child: Icon(Icons.task_alt, color: theme.colorScheme.primary),
              ),
              title: const Text(
                'No task selected',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Select a task to link your focus session to a specific project',
                style: TextStyle(fontSize: 12),
              ),
            )
          else
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.12,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: Text(
                task.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${task.category.isNotEmpty ? task.category : "General"} • ${task.priority.toUpperCase()} priority',
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
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

    return NeumorphicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Today\'s Progress',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'Sessions',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$todaySessionsCount',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
                    _formatHoursMinutes(todayFocusSecs),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Goal: ${dailyGoalHours.toInt()}h',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Text(
                '${(goalProgress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          NeumorphicProgress(progress: goalProgress, height: 10),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => FocusTaskSelector(
        selectedTask: selectedTask,
        onTaskSelected: (t) {
          ref.read(focusProvider.notifier).selectTask(t);
        },
      ),
    );
  }
}

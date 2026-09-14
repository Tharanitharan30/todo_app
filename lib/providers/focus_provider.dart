import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../services/notification_service.dart';
import 'database_provider.dart';
import 'settings_provider.dart';

enum FocusSessionType { focus, shortBreak, longBreak }

class FocusState {
  final Task? selectedTask;
  final bool isRunning;
  final bool isPaused;
  final FocusSessionType sessionType;
  final int completedPomodoros;
  final DateTime? sessionStart;
  final DateTime? expectedEnd;
  final int remainingSeconds;
  final int totalSeconds;
  final int? activeSessionDbId;

  const FocusState({
    this.selectedTask,
    this.isRunning = false,
    this.isPaused = false,
    this.sessionType = FocusSessionType.focus,
    this.completedPomodoros = 0,
    this.sessionStart,
    this.expectedEnd,
    this.remainingSeconds = 1500, // 25 min default
    this.totalSeconds = 1500,
    this.activeSessionDbId,
  });

  FocusState copyWith({
    Task? selectedTask,
    bool clearSelectedTask = false,
    bool? isRunning,
    bool? isPaused,
    FocusSessionType? sessionType,
    int? completedPomodoros,
    DateTime? sessionStart,
    DateTime? expectedEnd,
    int? remainingSeconds,
    int? totalSeconds,
    int? activeSessionDbId,
    bool clearActiveSessionDbId = false,
  }) {
    return FocusState(
      selectedTask: clearSelectedTask
          ? null
          : (selectedTask ?? this.selectedTask),
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      sessionType: sessionType ?? this.sessionType,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      sessionStart: sessionStart ?? this.sessionStart,
      expectedEnd: expectedEnd ?? this.expectedEnd,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      activeSessionDbId: clearActiveSessionDbId
          ? null
          : (activeSessionDbId ?? this.activeSessionDbId),
    );
  }
}

class FocusNotifier extends Notifier<FocusState> {
  Timer? _timer;

  @override
  FocusState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return _buildInitialState();
  }

  FocusState _buildInitialState() {
    final settings = ref.read(appSettingsProvider);
    final focusSecs = settings.focusDurationMinutes * 60;
    return FocusState(remainingSeconds: focusSecs, totalSeconds: focusSecs);
  }

  void selectTask(Task? task) {
    if (state.isRunning) return; // Prevent changing task mid-running
    state = state.copyWith(selectedTask: task, clearSelectedTask: task == null);
  }

  void startFocusSession({Task? task}) {
    if (state.isRunning) return;

    final settings = ref.read(appSettingsProvider);
    final selectedT = task ?? state.selectedTask;

    int durationMinutes;
    switch (state.sessionType) {
      case FocusSessionType.focus:
        durationMinutes = settings.focusDurationMinutes;
        break;
      case FocusSessionType.shortBreak:
        durationMinutes = settings.shortBreakMinutes;
        break;
      case FocusSessionType.longBreak:
        durationMinutes = settings.longBreakMinutes;
        break;
    }

    final totalSecs = durationMinutes * 60;
    final now = DateTime.now();
    final expectedEnd = now.add(Duration(seconds: totalSecs));

    state = state.copyWith(
      selectedTask: selectedT,
      isRunning: true,
      isPaused: false,
      sessionStart: now,
      expectedEnd: expectedEnd,
      remainingSeconds: totalSecs,
      totalSeconds: totalSecs,
    );

    _startTimerTicks();
  }

  void pauseTimer() {
    if (!state.isRunning || state.isPaused) return;
    _timer?.cancel();
    state = state.copyWith(isRunning: true, isPaused: true);
  }

  void resumeTimer() {
    if (!state.isRunning || !state.isPaused) return;
    final now = DateTime.now();
    final expectedEnd = now.add(Duration(seconds: state.remainingSeconds));

    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      expectedEnd: expectedEnd,
    );

    _startTimerTicks();
  }

  void resetTimer() {
    _timer?.cancel();
    final settings = ref.read(appSettingsProvider);

    int durationMinutes;
    switch (state.sessionType) {
      case FocusSessionType.focus:
        durationMinutes = settings.focusDurationMinutes;
        break;
      case FocusSessionType.shortBreak:
        durationMinutes = settings.shortBreakMinutes;
        break;
      case FocusSessionType.longBreak:
        durationMinutes = settings.longBreakMinutes;
        break;
    }

    final totalSecs = durationMinutes * 60;
    state = state.copyWith(
      isRunning: false,
      isPaused: false,
      remainingSeconds: totalSecs,
      totalSeconds: totalSecs,
    );
  }

  void skipSession() {
    _timer?.cancel();
    final settings = ref.read(appSettingsProvider);

    if (state.sessionType == FocusSessionType.focus) {
      // Skip to break
      final nextPomodoro = state.completedPomodoros + 1;
      final isLongBreak = nextPomodoro % settings.sessionsBeforeLongBreak == 0;
      final nextType = isLongBreak
          ? FocusSessionType.longBreak
          : FocusSessionType.shortBreak;
      final durationMins = isLongBreak
          ? settings.longBreakMinutes
          : settings.shortBreakMinutes;
      final totalSecs = durationMins * 60;

      state = state.copyWith(
        isRunning: false,
        isPaused: false,
        sessionType: nextType,
        remainingSeconds: totalSecs,
        totalSeconds: totalSecs,
      );
    } else {
      // Skip break to focus
      final totalSecs = settings.focusDurationMinutes * 60;
      state = state.copyWith(
        isRunning: false,
        isPaused: false,
        sessionType: FocusSessionType.focus,
        remainingSeconds: totalSecs,
        totalSeconds: totalSecs,
      );
    }
  }

  void _startTimerTicks() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!state.isRunning || state.isPaused || state.expectedEnd == null) {
        return;
      }

      final diff = state.expectedEnd!.difference(DateTime.now()).inSeconds;
      if (diff <= 0) {
        _timer?.cancel();
        _onSessionComplete();
      } else {
        state = state.copyWith(remainingSeconds: diff);
      }
    });
  }

  Future<void> _onSessionComplete() async {
    final db = ref.read(databaseProvider);
    final settings = ref.read(appSettingsProvider);

    final completedType = state.sessionType;
    final sessionStart = state.sessionStart ?? DateTime.now();
    final endedAt = DateTime.now();
    final durationSecs = state.totalSeconds;
    final task = state.selectedTask;

    String dbTypeStr;
    switch (completedType) {
      case FocusSessionType.focus:
        dbTypeStr = 'focus';
        break;
      case FocusSessionType.shortBreak:
        dbTypeStr = 'short_break';
        break;
      case FocusSessionType.longBreak:
        dbTypeStr = 'long_break';
        break;
    }

    // Insert FocusSession into SQLite
    try {
      await db.addFocusSession(
        FocusSessionsCompanion.insert(
          taskId: drift.Value(task?.id),
          startedAt: sessionStart,
          endedAt: drift.Value(endedAt),
          durationSeconds: drift.Value(durationSecs),
          type: drift.Value(dbTypeStr),
          completed: const drift.Value(true),
        ),
      );
    } catch (e) {
      debugPrint('Error recording focus session: $e');
    }

    // Trigger Notification
    try {
      if (completedType == FocusSessionType.focus) {
        await NotificationService().showImmediateNotification(
          id: 90001,
          title: 'Focus Complete! 🎯',
          body:
              'Great work! Your ${(durationSecs / 60).round()} minute focus session is complete.',
          payload: 'briefing',
        );
      } else {
        await NotificationService().showImmediateNotification(
          id: 90002,
          title: 'Break Complete! ☕',
          body: 'Ready for another productive focus session?',
          payload: 'briefing',
        );
      }
    } catch (e) {
      debugPrint('Error triggering notification: $e');
    }

    // Update state to next stage
    if (completedType == FocusSessionType.focus) {
      final newCompletedCount = state.completedPomodoros + 1;
      final isLongBreak =
          newCompletedCount % settings.sessionsBeforeLongBreak == 0;
      final nextType = isLongBreak
          ? FocusSessionType.longBreak
          : FocusSessionType.shortBreak;
      final breakMins = isLongBreak
          ? settings.longBreakMinutes
          : settings.shortBreakMinutes;
      final breakSecs = breakMins * 60;

      state = state.copyWith(
        isRunning: false,
        isPaused: false,
        sessionType: nextType,
        completedPomodoros: newCompletedCount,
        remainingSeconds: breakSecs,
        totalSeconds: breakSecs,
      );

      if (settings.autoStartBreaks) {
        startFocusSession();
      }
    } else {
      final focusSecs = settings.focusDurationMinutes * 60;
      state = state.copyWith(
        isRunning: false,
        isPaused: false,
        sessionType: FocusSessionType.focus,
        remainingSeconds: focusSecs,
        totalSeconds: focusSecs,
      );

      if (settings.autoStartFocus) {
        startFocusSession();
      }
    }
  }
}

final focusProvider = NotifierProvider<FocusNotifier, FocusState>(
  FocusNotifier.new,
);

// Stream of all Focus Sessions from SQLite
final allFocusSessionsProvider = StreamProvider<List<FocusSession>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllFocusSessions();
});

// Focus Sessions today
final todayFocusSessionsProvider = Provider<List<FocusSession>>((ref) {
  final sessionsAsync = ref.watch(allFocusSessionsProvider);
  final list = sessionsAsync.value ?? [];
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  return list
      .where(
        (s) =>
            s.completed &&
            s.type == 'focus' &&
            s.startedAt.isAfter(
              todayStart.subtract(const Duration(milliseconds: 1)),
            ),
      )
      .toList();
});

// Today's total focus time in seconds
final todayFocusTimeSecondsProvider = Provider<int>((ref) {
  final todayList = ref.watch(todayFocusSessionsProvider);
  return todayList.fold(0, (sum, s) => sum + s.durationSeconds);
});

// This week's total focus time in seconds
final weeklyFocusTimeSecondsProvider = Provider<int>((ref) {
  final sessionsAsync = ref.watch(allFocusSessionsProvider);
  final list = sessionsAsync.value ?? [];
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final weekStart = DateTime(
    startOfWeek.year,
    startOfWeek.month,
    startOfWeek.day,
  );

  return list
      .where(
        (s) =>
            s.completed &&
            s.type == 'focus' &&
            s.startedAt.isAfter(
              weekStart.subtract(const Duration(milliseconds: 1)),
            ),
      )
      .fold(0, (sum, s) => sum + s.durationSeconds);
});

// Task focus time provider
final taskFocusTimeProvider = Provider.family<int, int>((ref, taskId) {
  final sessionsAsync = ref.watch(allFocusSessionsProvider);
  final list = sessionsAsync.value ?? [];
  return list
      .where((s) => s.completed && s.type == 'focus' && s.taskId == taskId)
      .fold(0, (sum, s) => sum + s.durationSeconds);
});

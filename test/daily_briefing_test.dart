import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/database/database.dart';
import 'package:todo_app/providers/database_provider.dart';
import 'package:todo_app/providers/settings_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    // Allow initial async settings load to finish
    await Future.delayed(const Duration(milliseconds: 50));
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('Daily Briefing Settings & Time Persistence', () {
    test('Default Daily Briefing settings', () {
      final settings = container.read(appSettingsProvider);
      expect(settings.dailyBriefingEnabled, isTrue);
      expect(settings.dailyBriefingTime, const TimeOfDay(hour: 8, minute: 0));
      expect(settings.dailyBriefingOpenApp, isTrue);
    });

    test('Updating briefing time persists to SQLite database', () async {
      final notifier = container.read(appSettingsProvider.notifier);
      await notifier.setDailyBriefingTime(const TimeOfDay(hour: 9, minute: 30));
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(appSettingsProvider);
      expect(state.dailyBriefingHour, 9);
      expect(state.dailyBriefingMinute, 30);
      expect(state.dailyBriefingTime, const TimeOfDay(hour: 9, minute: 30));

      final hourStr = await db.getSetting('daily_briefing_hour');
      final minStr = await db.getSetting('daily_briefing_minute');
      expect(hourStr, '9');
      expect(minStr, '30');
    });

    test('Disabling daily briefing persists to SQLite database', () async {
      final notifier = container.read(appSettingsProvider.notifier);
      await notifier.setDailyBriefingEnabled(false);
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(appSettingsProvider);
      expect(state.dailyBriefingEnabled, isFalse);

      final enabledStr = await db.getSetting('daily_briefing_enabled');
      expect(enabledStr, 'false');
    });
  });
}

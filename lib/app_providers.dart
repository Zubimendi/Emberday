import 'package:emberday/core/clock.dart';
import 'package:emberday/core/logger.dart';
import 'package:emberday/data/db/app_database.dart' show AppDatabase;
import 'package:emberday/data/repositories/check_in_repository.dart';
import 'package:emberday/data/repositories/habit_repository.dart';
import 'package:emberday/data/repositories/outbox_repository.dart';
import 'package:emberday/data/repositories/settings_repository.dart';
import 'package:emberday/domain/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final loggerProvider = Provider<Logger>((ref) => const ConsoleLogger());

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseProvider));
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(
    database: ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
    settings: ref.watch(settingsRepositoryProvider),
  );
});

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CheckInRepository(
    database: ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
    settings: ref.watch(settingsRepositoryProvider),
  );
});

final outboxRepositoryProvider = Provider<OutboxRepository>((ref) {
  return OutboxRepository(ref.watch(databaseProvider));
});

final settingsMapProvider = StreamProvider<Map<String, String>>((ref) {
  return ref.watch(settingsRepositoryProvider).watchAll();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsMapProvider).value ?? {};
  return switch (settings['theme']) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});

final onboardingDoneProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsMapProvider).value ?? {};
  return settings['onboarding_done'] == 'true';
});

final selectedDateProvider = StateProvider<String?>((ref) => null);

final habitsStreamProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(habitRepositoryProvider).watchActiveHabits();
});

final allHabitsStreamProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(habitRepositoryProvider).watchAllHabits();
});

final checkInsForDateProvider =
    StreamProvider.family<List<CheckIn>, String>((ref, date) {
  return ref.watch(checkInRepositoryProvider).watchForDate(date);
});

final habitStatsProvider =
    StreamProvider.family<StreakStats?, String>((ref, habitId) {
  return ref.watch(habitRepositoryProvider).watchStats(habitId);
});

final replanRemindersProvider = Provider<Future<void> Function()>((ref) {
  return () async {};
});

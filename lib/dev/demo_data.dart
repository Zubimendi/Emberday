import 'package:emberday/core/clock.dart';
import 'package:emberday/core/dates.dart';
import 'package:emberday/data/repositories/check_in_repository.dart';
import 'package:emberday/data/repositories/habit_repository.dart';
import 'package:emberday/domain/models.dart';
import 'package:flutter/foundation.dart';

/// Dev-only seed. No-op in release.
Future<void> loadDemoData({
  required HabitRepository habits,
  required CheckInRepository checkIns,
  required Clock clock,
}) async {
  if (kReleaseMode) return;
  final today = formatLocalDate(clock.now());
  final created = await habits.create(
    name: 'Drink water',
    icon: '💧',
    colorKey: 'habit5',
    schedule: const Daily(),
    startDate: addDaysYmd(today, -14),
  );
  final habit = created.valueOrNull;
  if (habit == null) return;
  for (var i = 1; i <= 10; i++) {
    await checkIns.setStatus(
      habitId: habit.id,
      localDate: addDaysYmd(today, -i),
      status: i == 3 ? CheckInStatus.skipped : CheckInStatus.done,
    );
  }
}

import 'package:emberday/core/clock.dart';
import 'package:emberday/core/dates.dart';
import 'package:emberday/core/ids.dart';
import 'package:emberday/data/db/app_database.dart' show AppDatabase;
import 'package:emberday/data/repositories/check_in_repository.dart';
import 'package:emberday/data/repositories/habit_repository.dart';
import 'package:emberday/data/repositories/settings_repository.dart';
import 'package:emberday/domain/models.dart';
import 'package:emberday/domain/streak_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cached stats match recomputation after random ops', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final clock = FakeClock(DateTime(2026, 11, 18, 12));
    final settings = SettingsRepository(db);
    final habits = HabitRepository(
      database: db,
      clock: clock,
      settings: settings,
    );
    final checkIns = CheckInRepository(
      database: db,
      clock: clock,
      settings: settings,
    );

    final created = await habits.create(
      name: 'Water',
      icon: '💧',
      colorKey: 'habit1',
      schedule: const Daily(),
      startDate: '2026-11-10',
    );
    final habit = created.valueOrNull!;
    final today = '2026-11-18';

    for (var i = 0; i < 8; i++) {
      final date = addDaysYmd(today, -i);
      if (i.isEven) {
        await checkIns.setStatus(
          habitId: habit.id,
          localDate: date,
          status: CheckInStatus.done,
        );
      } else if (i % 3 == 0) {
        await checkIns.setStatus(
          habitId: habit.id,
          localDate: date,
          status: CheckInStatus.skipped,
        );
      }
    }

    final cached = await habits.watchStats(habit.id).first;
    final map = await checkIns.mapForHabit(habit.id);
    final recomputed = computeStats(
      schedule: habit.schedule,
      startDate: habit.startDate,
      checkIns: map,
      referenceDate: today,
    );
    expect(cached!.currentStreak, recomputed.currentStreak);
    expect(cached.bestStreak, recomputed.bestStreak);
    expect(cached.totalDone, recomputed.totalDone);
    expect(checkInId(habit.id, today), startsWith('ci'));
  });
}

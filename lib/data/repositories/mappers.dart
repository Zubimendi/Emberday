import 'package:emberday/data/db/app_database.dart' as db;
import 'package:emberday/domain/models.dart';
import 'package:emberday/domain/schedule.dart';

Habit habitFromRow(db.Habit row) {
  return Habit(
    id: row.id,
    name: row.name,
    icon: row.icon,
    colorKey: row.colorKey,
    schedule: scheduleFromDb(
      type: row.scheduleType,
      weekdaysMask: row.weekdaysMask,
      weeklyTarget: row.weeklyTarget,
    ),
    startDate: row.startDate,
    reminderEnabled: row.reminderEnabled == 1,
    reminderMinutes: row.reminderMinutes,
    reminderWeekdaysMask: row.reminderWeekdaysMask,
    sortOrder: row.sortOrder,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    archivedAt: row.archivedAt,
    deletedAt: row.deletedAt,
  );
}

CheckIn checkInFromRow(db.CheckIn row) {
  return CheckIn(
    id: row.id,
    habitId: row.habitId,
    localDate: row.localDate,
    status: row.status == 'skipped' ? CheckInStatus.skipped : CheckInStatus.done,
    note: row.note,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  );
}

StreakStats statsFromRow(db.HabitStat row) {
  return StreakStats(
    currentStreak: row.currentStreak,
    bestStreak: row.bestStreak,
    totalDone: row.totalDone,
    lastDoneDate: row.lastDoneDate,
    completionRate30: row.completionRate30,
    computedForDate: row.computedForDate,
  );
}

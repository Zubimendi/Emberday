import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:emberday/core/clock.dart';
import 'package:emberday/core/dates.dart';
import 'package:emberday/core/errors.dart';
import 'package:emberday/core/ids.dart';
import 'package:emberday/core/result.dart';
import 'package:emberday/data/db/app_database.dart' as db;
import 'package:emberday/data/repositories/mappers.dart';
import 'package:emberday/data/repositories/settings_repository.dart';
import 'package:emberday/domain/models.dart';
import 'package:emberday/domain/schedule.dart';
import 'package:emberday/domain/streak_engine.dart';

class HabitRepository {
  HabitRepository({
    required db.AppDatabase database,
    required Clock clock,
    required SettingsRepository settings,
  })  : _db = database,
        _clock = clock,
        _settings = settings;

  final db.AppDatabase _db;
  final Clock _clock;
  final SettingsRepository _settings;

  Stream<List<Habit>> watchActiveHabits() {
    final q = _db.select(_db.habits)
      ..where((t) => t.deletedAt.isNull() & t.archivedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return q.watch().map((rows) => rows.map(habitFromRow).toList());
  }

  Stream<List<Habit>> watchAllHabits() {
    final q = _db.select(_db.habits)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return q.watch().map((rows) => rows.map(habitFromRow).toList());
  }

  Stream<Habit?> watchHabit(String id) {
    final q = _db.select(_db.habits)..where((t) => t.id.equals(id));
    return q.watchSingleOrNull().map((r) => r == null ? null : habitFromRow(r));
  }

  Stream<StreakStats?> watchStats(String habitId) {
    final q = _db.select(_db.habitStats)
      ..where((t) => t.habitId.equals(habitId));
    return q.watchSingleOrNull().map((r) => r == null ? null : statsFromRow(r));
  }

  Future<Result<Habit>> create({
    required String name,
    required String icon,
    required String colorKey,
    required Schedule schedule,
    required String startDate,
    bool reminderEnabled = false,
    int? reminderMinutes,
    int? reminderWeekdaysMask,
  }) async {
    try {
      final now = _clock.now().millisecondsSinceEpoch;
      final id = newId();
      final sched = scheduleToDb(schedule);
      final count = await _db.select(_db.habits).get();
      final habit = Habit(
        id: id,
        name: name.trim(),
        icon: icon,
        colorKey: colorKey,
        schedule: schedule,
        startDate: startDate,
        reminderEnabled: reminderEnabled,
        reminderMinutes: reminderMinutes,
        reminderWeekdaysMask: reminderWeekdaysMask ?? sched.weekdaysMask,
        sortOrder: count.length.toDouble(),
        createdAt: now,
        updatedAt: now,
      );

      await _db.transaction(() async {
        await _db.into(_db.habits).insert(_toCompanion(habit, sched));
        await _recomputeStats(habit.id);
        await _maybeOutbox('habit', habit.id, 'create', habit);
      });
      return Ok(habit);
    } on Object catch (e) {
      return Err(AppError(klass: ErrorClass.local, message: 'create failed', cause: e));
    }
  }

  Future<Result<Habit>> update(Habit habit) async {
    try {
      final updated = habit.copyWith(
        updatedAt: _clock.now().millisecondsSinceEpoch,
      );
      final sched = scheduleToDb(updated.schedule);
      await _db.transaction(() async {
        await (_db.update(_db.habits)..where((t) => t.id.equals(habit.id)))
            .write(_toCompanion(updated, sched));
        await _recomputeStats(habit.id);
        await _maybeOutbox('habit', habit.id, 'update', updated);
      });
      return Ok(updated);
    } on Object catch (e) {
      return Err(AppError(klass: ErrorClass.local, message: 'update failed', cause: e));
    }
  }

  Future<Result<void>> archive(String id) async {
    try {
      final now = _clock.now().millisecondsSinceEpoch;
      await _db.transaction(() async {
        await (_db.update(_db.habits)..where((t) => t.id.equals(id))).write(
              db.HabitsCompanion(
                archivedAt: Value(now),
                updatedAt: Value(now),
              ),
            );
        await _recomputeStats(id);
        final row = await (_db.select(_db.habits)..where((t) => t.id.equals(id)))
            .getSingle();
        await _maybeOutbox('habit', id, 'update', habitFromRow(row));
      });
      return const Ok(null);
    } on Object catch (e) {
      return Err(AppError(klass: ErrorClass.local, message: 'archive failed', cause: e));
    }
  }

  Future<Result<void>> softDelete(String id) async {
    try {
      final now = _clock.now().millisecondsSinceEpoch;
      await _db.transaction(() async {
        await (_db.update(_db.habits)..where((t) => t.id.equals(id))).write(
              db.HabitsCompanion(
                deletedAt: Value(now),
                updatedAt: Value(now),
              ),
            );
        final row = await (_db.select(_db.habits)..where((t) => t.id.equals(id)))
            .getSingle();
        await _maybeOutbox('habit', id, 'delete', habitFromRow(row));
      });
      return const Ok(null);
    } on Object catch (e) {
      return Err(AppError(klass: ErrorClass.local, message: 'delete failed', cause: e));
    }
  }

  Future<void> recomputeAllIfDateChanged() async {
    final rollover = await _settings.rolloverHours();
    final today = effectiveLocalDate(_clock.now(), rollover);
    final habits = await (_db.select(_db.habits)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    for (final h in habits) {
      final stats = await (_db.select(_db.habitStats)
            ..where((t) => t.habitId.equals(h.id)))
          .getSingleOrNull();
      if (stats == null || stats.computedForDate != today) {
        await _db.transaction(() => _recomputeStats(h.id));
      }
    }
  }

  Future<void> _recomputeStats(String habitId) async {
    final row = await (_db.select(_db.habits)..where((t) => t.id.equals(habitId)))
        .getSingleOrNull();
    if (row == null) return;
    final habit = habitFromRow(row);
    final checkInRows = await (_db.select(_db.checkIns)
          ..where((t) => t.habitId.equals(habitId) & t.deletedAt.isNull()))
        .get();
    final map = <String, CheckInStatus>{
      for (final c in checkInRows)
        c.localDate:
            c.status == 'skipped' ? CheckInStatus.skipped : CheckInStatus.done,
    };
    final rollover = await _settings.rolloverHours();
    final today = effectiveLocalDate(_clock.now(), rollover);
    final stats = computeStats(
      schedule: habit.schedule,
      startDate: habit.startDate,
      checkIns: map,
      referenceDate: today,
    );
    await _db.into(_db.habitStats).insertOnConflictUpdate(
          db.HabitStatsCompanion.insert(
            habitId: habitId,
            currentStreak: stats.currentStreak,
            bestStreak: stats.bestStreak,
            totalDone: stats.totalDone,
            lastDoneDate: Value(stats.lastDoneDate),
            completionRate30: Value(stats.completionRate30),
            computedForDate: stats.computedForDate,
            computedAt: _clock.now().millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> _maybeOutbox(
    String entity,
    String entityId,
    String op,
    Habit habit,
  ) async {
    final signedIn = await _settings.isSignedIn();
    if (!signedIn) return;
    final sched = scheduleToDb(habit.schedule);
    final payload = jsonEncode({
      'id': habit.id,
      'name': habit.name,
      'icon': habit.icon,
      'color_key': habit.colorKey,
      'schedule_type': sched.type,
      'weekdays_mask': sched.weekdaysMask,
      'weekly_target': sched.weeklyTarget,
      'start_date': habit.startDate,
      'reminder_enabled': habit.reminderEnabled,
      'reminder_minutes': habit.reminderMinutes,
      'reminder_weekdays_mask': habit.reminderWeekdaysMask,
      'sort_order': habit.sortOrder,
      'archived_at': habit.archivedAt,
      'updated_at': habit.updatedAt,
      'deleted_at': habit.deletedAt,
    });
    await _db.into(_db.outbox).insert(
          db.OutboxCompanion.insert(
            entity: entity,
            entityId: entityId,
            op: op,
            payload: payload,
            createdAt: _clock.now().millisecondsSinceEpoch,
          ),
        );
  }

  db.HabitsCompanion _toCompanion(
    Habit habit,
    ({String type, int weekdaysMask, int weeklyTarget}) sched,
  ) {
    return db.HabitsCompanion.insert(
      id: habit.id,
      name: habit.name,
      icon: habit.icon,
      colorKey: habit.colorKey,
      scheduleType: sched.type,
      weekdaysMask: Value(sched.weekdaysMask),
      weeklyTarget: Value(sched.weeklyTarget),
      startDate: habit.startDate,
      reminderEnabled: Value(habit.reminderEnabled ? 1 : 0),
      reminderMinutes: Value(habit.reminderMinutes),
      reminderWeekdaysMask: Value(habit.reminderWeekdaysMask),
      sortOrder: Value(habit.sortOrder),
      archivedAt: Value(habit.archivedAt),
      createdAt: habit.createdAt,
      updatedAt: habit.updatedAt,
      deletedAt: Value(habit.deletedAt),
    );
  }
}

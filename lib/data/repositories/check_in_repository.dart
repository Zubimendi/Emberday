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
import 'package:emberday/domain/streak_engine.dart';

class CheckInRepository {
  CheckInRepository({
    required db.AppDatabase database,
    required Clock clock,
    required SettingsRepository settings,
  })  : _db = database,
        _clock = clock,
        _settings = settings;

  final db.AppDatabase _db;
  final Clock _clock;
  final SettingsRepository _settings;

  Stream<List<CheckIn>> watchForDate(String localDate) {
    final q = _db.select(_db.checkIns)
      ..where((t) => t.localDate.equals(localDate) & t.deletedAt.isNull());
    return q.watch().map((rows) => rows.map(checkInFromRow).toList());
  }

  Stream<List<CheckIn>> watchForHabit(String habitId) {
    final q = _db.select(_db.checkIns)
      ..where((t) => t.habitId.equals(habitId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.localDate)]);
    return q.watch().map((rows) => rows.map(checkInFromRow).toList());
  }

  Future<Map<String, CheckInStatus>> mapForHabit(String habitId) async {
    final rows = await (_db.select(_db.checkIns)
          ..where((t) => t.habitId.equals(habitId) & t.deletedAt.isNull()))
        .get();
    return {
      for (final r in rows)
        r.localDate:
            r.status == 'skipped' ? CheckInStatus.skipped : CheckInStatus.done,
    };
  }

  Future<Result<void>> setStatus({
    required String habitId,
    required String localDate,
    required CheckInStatus? status,
    String? note,
  }) async {
    try {
      final rollover = await _settings.rolloverHours();
      final today = effectiveLocalDate(_clock.now(), rollover);
      if (daysBetween(today, localDate) > 0) {
        return const Err(
          AppError(klass: ErrorClass.validation, message: 'Future dates are not editable'),
        );
      }

      final now = _clock.now().millisecondsSinceEpoch;
      final id = checkInId(habitId, localDate);

      await _db.transaction(() async {
        final existing = await (_db.select(_db.checkIns)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();

        if (status == null) {
          // Soft-delete / clear
          if (existing != null) {
            await (_db.update(_db.checkIns)..where((t) => t.id.equals(id)))
                .write(
              db.CheckInsCompanion(
                deletedAt: Value(now),
                updatedAt: Value(now),
              ),
            );
            final row = await (_db.select(_db.checkIns)
                  ..where((t) => t.id.equals(id)))
                .getSingle();
            await _maybeOutbox('delete', checkInFromRow(row));
          }
        } else {
          final statusStr =
              status == CheckInStatus.skipped ? 'skipped' : 'done';
          if (existing == null) {
            await _db.into(_db.checkIns).insert(
                  db.CheckInsCompanion.insert(
                    id: id,
                    habitId: habitId,
                    localDate: localDate,
                    status: statusStr,
                    note: Value(note),
                    createdAt: now,
                    updatedAt: now,
                  ),
                );
          } else {
            await (_db.update(_db.checkIns)..where((t) => t.id.equals(id)))
                .write(
              db.CheckInsCompanion(
                status: Value(statusStr),
                note: Value(note ?? existing.note),
                updatedAt: Value(now),
                deletedAt: const Value(null),
              ),
            );
          }
          final row = await (_db.select(_db.checkIns)
                ..where((t) => t.id.equals(id)))
              .getSingle();
          await _maybeOutbox(
            existing == null ? 'create' : 'update',
            checkInFromRow(row),
          );
        }

        await _recomputeStats(habitId);
      });
      return const Ok(null);
    } on Object catch (e) {
      return Err(
        AppError(klass: ErrorClass.local, message: 'check-in failed', cause: e),
      );
    }
  }

  Future<Result<void>> toggleDone({
    required String habitId,
    required String localDate,
  }) async {
    final map = await mapForHabit(habitId);
    final current = map[localDate];
    if (current == CheckInStatus.done) {
      return setStatus(habitId: habitId, localDate: localDate, status: null);
    }
    return setStatus(
      habitId: habitId,
      localDate: localDate,
      status: CheckInStatus.done,
    );
  }

  Future<void> _recomputeStats(String habitId) async {
    final row = await (_db.select(_db.habits)..where((t) => t.id.equals(habitId)))
        .getSingleOrNull();
    if (row == null) return;
    final habit = habitFromRow(row);
    final map = await mapForHabit(habitId);
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

  Future<void> _maybeOutbox(String op, CheckIn checkIn) async {
    final signedIn = await _settings.isSignedIn();
    if (!signedIn) return;
    final payload = jsonEncode({
      'id': checkIn.id,
      'habit': checkIn.habitId,
      'local_date': checkIn.localDate,
      'status': checkIn.status == CheckInStatus.skipped ? 'skipped' : 'done',
      'note': checkIn.note,
      'updated_at': checkIn.updatedAt,
      'deleted_at': checkIn.deletedAt,
    });
    await _db.into(_db.outbox).insert(
          db.OutboxCompanion.insert(
            entity: 'check_in',
            entityId: checkIn.id,
            op: op,
            payload: payload,
            createdAt: _clock.now().millisecondsSinceEpoch,
          ),
        );
  }
}

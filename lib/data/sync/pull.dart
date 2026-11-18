import 'package:drift/drift.dart';
import 'package:emberday/core/clock.dart';
import 'package:emberday/core/result.dart';
import 'package:emberday/data/api/error_mapper.dart';
import 'package:emberday/data/api/pb_client.dart';
import 'package:emberday/data/db/app_database.dart';
import 'package:emberday/data/repositories/outbox_repository.dart';

class SyncPull {
  SyncPull({
    required this.client,
    required this.db,
    required this.outbox,
    required this.clock,
  });

  final PbClient client;
  final AppDatabase db;
  final OutboxRepository outbox;
  final Clock clock;

  Future<Result<Set<String>>> pull() async {
    final affected = <String>{};
    try {
      await _pullCollection('habits', affected);
      await _pullCollection('check_ins', affected);
      return Ok(affected);
    } on Object catch (e) {
      return Err(mapApiError(e));
    }
  }

  Future<void> _pullCollection(String collection, Set<String> affected) async {
    final cursorKey = 'cursor_$collection';
    final cursorRow = await (db.select(db.syncState)
          ..where((t) => t.key.equals(cursorKey)))
        .getSingleOrNull();
    var cursor = cursorRow?.value ?? '';
    final pending = await outbox.pending();
    final pendingIds = pending.map((p) => p.entityId).toSet();

    while (true) {
      final filter = cursor.isEmpty
          ? ''
          : 'updated >= "$cursor"';
      final records = await client.pb.collection(collection).getList(
            page: 1,
            perPage: 200,
            filter: filter.isEmpty ? null : filter,
            sort: 'updated,id',
          );
      if (records.items.isEmpty) break;

      await db.transaction(() async {
        for (final item in records.items) {
          final id = item.id;
          if (pendingIds.contains(id)) continue;
          final data = item.data;
          if (collection == 'habits') {
            affected.add(id);
            await _applyHabit(id, data);
          } else {
            final habitId = data['habit']?.toString() ?? '';
            affected.add(habitId);
            await _applyCheckIn(id, data);
          }
          cursor = item.getStringValue('updated');
        }
        await db.into(db.syncState).insertOnConflictUpdate(
              SyncStateCompanion.insert(key: cursorKey, value: cursor),
            );
      });

      if (records.items.length < 200) break;
    }
  }

  Future<void> _applyHabit(String id, Map<String, dynamic> data) async {
    final deletedAt = data['deleted_at'] as int?;
    await db.into(db.habits).insertOnConflictUpdate(
          HabitsCompanion.insert(
            id: id,
            name: data['name']?.toString() ?? '',
            icon: data['icon']?.toString() ?? '🔥',
            colorKey: data['color_key']?.toString() ?? 'habit1',
            scheduleType: data['schedule_type']?.toString() ?? 'daily',
            weekdaysMask: Value((data['weekdays_mask'] as int?) ?? 127),
            weeklyTarget: Value((data['weekly_target'] as int?) ?? 0),
            startDate: data['start_date']?.toString() ??
                DateTime.now().toIso8601String().substring(0, 10),
            reminderEnabled:
                Value((data['reminder_enabled'] == true) ? 1 : 0),
            reminderMinutes: Value(data['reminder_minutes'] as int?),
            reminderWeekdaysMask:
                Value((data['reminder_weekdays_mask'] as int?) ?? 127),
            sortOrder: Value((data['sort_order'] as num?)?.toDouble() ?? 0),
            archivedAt: Value(data['archived_at'] as int?),
            createdAt: (data['created_at'] as int?) ??
                clock.now().millisecondsSinceEpoch,
            updatedAt: (data['client_updated_at'] as int?) ??
                clock.now().millisecondsSinceEpoch,
            deletedAt: Value(deletedAt),
          ),
        );
  }

  Future<void> _applyCheckIn(String id, Map<String, dynamic> data) async {
    await db.into(db.checkIns).insertOnConflictUpdate(
          CheckInsCompanion.insert(
            id: id,
            habitId: data['habit']?.toString() ?? '',
            localDate: data['local_date']?.toString() ?? '',
            status: data['status']?.toString() ?? 'done',
            note: Value(data['note']?.toString()),
            createdAt: (data['created_at'] as int?) ??
                clock.now().millisecondsSinceEpoch,
            updatedAt: (data['client_updated_at'] as int?) ??
                clock.now().millisecondsSinceEpoch,
            deletedAt: Value(data['deleted_at'] as int?),
          ),
        );
  }
}

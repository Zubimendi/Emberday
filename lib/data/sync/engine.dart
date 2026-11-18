import 'dart:async';
import 'dart:convert';

import 'package:emberday/core/clock.dart';
import 'package:emberday/core/logger.dart';
import 'package:emberday/data/api/pb_client.dart';
import 'package:emberday/data/db/app_database.dart' show AppDatabase, OutboxCompanion;
import 'package:emberday/data/repositories/outbox_repository.dart';
import 'package:emberday/data/repositories/settings_repository.dart';
import 'package:emberday/data/sync/pull.dart';
import 'package:emberday/data/sync/push.dart';

class SyncEngine {
  SyncEngine({
    required AppDatabase database,
    required SettingsRepository settings,
    required OutboxRepository outbox,
    required Clock clock,
    required Logger logger,
    required PbClient pbClient,
  })  : _db = database,
        _settings = settings,
        _outbox = outbox,
        _clock = clock,
        _logger = logger,
        _client = pbClient;

  final AppDatabase _db;
  final SettingsRepository _settings;
  final OutboxRepository _outbox;
  final Clock _clock;
  final Logger _logger;
  final PbClient _client;

  Timer? _debounce;
  var _running = false;

  void requestSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(runOnce());
    });
  }

  Future<void> runOnce() async {
    if (_running) return;
    final signedIn = await _settings.isSignedIn();
    if (!signedIn) return;
    _running = true;
    await _settings.set('sync_ui', 'syncing');
    try {
      final push = SyncPush(_client, _outbox);
      final pushResult = await push.drain();
      if (pushResult.isErr) {
        final err = pushResult.errorOrNull!;
        await _settings.set(
          'sync_ui',
          err.klass.name == 'network' ? 'offline' : 'pending',
        );
        return;
      }
      final pull = SyncPull(
        client: _client,
        db: _db,
        outbox: _outbox,
        clock: _clock,
      );
      final pullResult = await pull.pull();
      if (pullResult.isErr) {
        await _settings.set('sync_ui', 'pending');
        return;
      }
      final parked = await _outbox.parkedCount();
      final pending = await _outbox.pendingCount();
      if (parked > 0) {
        await _settings.set('sync_ui', 'issue');
      } else if (pending > 0) {
        await _settings.set('sync_ui', 'pending');
      } else {
        await _settings.set('sync_ui', 'up_to_date');
      }
      _logger.info('sync pass complete', data: {
        'pending': pending,
        'parked': parked,
      });
    } finally {
      _running = false;
    }
  }

  Future<void> enqueueInitialAndSync() async {
    final now = _clock.now().millisecondsSinceEpoch;
    final habits = await (_db.select(_db.habits)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    for (final h in habits) {
      await _db.into(_db.outbox).insert(
            OutboxCompanion.insert(
              entity: 'habit',
              entityId: h.id,
              op: 'create',
              payload: jsonEncode({
                'id': h.id,
                'name': h.name,
                'icon': h.icon,
                'color_key': h.colorKey,
                'schedule_type': h.scheduleType,
                'weekdays_mask': h.weekdaysMask,
                'weekly_target': h.weeklyTarget,
                'start_date': h.startDate,
                'reminder_enabled': h.reminderEnabled == 1,
                'reminder_minutes': h.reminderMinutes,
                'reminder_weekdays_mask': h.reminderWeekdaysMask,
                'sort_order': h.sortOrder,
                'archived_at': h.archivedAt,
                'updated_at': h.updatedAt,
              }),
              createdAt: now,
            ),
          );
    }
    final checkIns = await (_db.select(_db.checkIns)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    for (final c in checkIns) {
      await _db.into(_db.outbox).insert(
            OutboxCompanion.insert(
              entity: 'check_in',
              entityId: c.id,
              op: 'create',
              payload: jsonEncode({
                'id': c.id,
                'habit': c.habitId,
                'local_date': c.localDate,
                'status': c.status,
                'note': c.note,
                'updated_at': c.updatedAt,
              }),
              createdAt: now,
            ),
          );
    }
    await runOnce();
  }
}

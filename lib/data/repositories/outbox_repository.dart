import 'package:drift/drift.dart';
import 'package:emberday/data/db/app_database.dart';

class OutboxRow {
  const OutboxRow({
    required this.seq,
    required this.entity,
    required this.entityId,
    required this.op,
    required this.payload,
    required this.attempts,
    required this.nextAttemptAt,
    required this.status,
    this.lastError,
  });

  final int seq;
  final String entity;
  final String entityId;
  final String op;
  final String payload;
  final int attempts;
  final int nextAttemptAt;
  final String status;
  final String? lastError;
}

class OutboxRepository {
  OutboxRepository(this._db);

  final AppDatabase _db;

  Future<List<OutboxRow>> pending() async {
    final rows = await (_db.select(_db.outbox)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
        .get();
    return rows
        .map(
          (r) => OutboxRow(
            seq: r.seq,
            entity: r.entity,
            entityId: r.entityId,
            op: r.op,
            payload: r.payload,
            attempts: r.attempts,
            nextAttemptAt: r.nextAttemptAt,
            status: r.status,
            lastError: r.lastError,
          ),
        )
        .toList();
  }

  Future<int> pendingCount() async {
    final rows = await pending();
    return rows.length;
  }

  Future<int> parkedCount() async {
    final rows = await (_db.select(_db.outbox)
          ..where((t) => t.status.equals('parked')))
        .get();
    return rows.length;
  }

  Future<void> deleteSeq(int seq) async {
    await (_db.delete(_db.outbox)..where((t) => t.seq.equals(seq))).go();
  }

  Future<void> markAttempt({
    required int seq,
    required int attempts,
    required int nextAttemptAt,
    String? lastError,
    bool park = false,
  }) async {
    await (_db.update(_db.outbox)..where((t) => t.seq.equals(seq))).write(
          OutboxCompanion(
            attempts: Value(attempts),
            nextAttemptAt: Value(nextAttemptAt),
            lastError: Value(lastError),
            status: Value(park ? 'parked' : 'pending'),
          ),
        );
  }
}

import 'package:emberday/core/errors.dart';
import 'package:emberday/core/result.dart';
import 'package:emberday/data/api/error_mapper.dart';
import 'package:emberday/data/api/pb_client.dart';
import 'package:emberday/data/repositories/outbox_repository.dart';
import 'package:emberday/data/sync/backoff.dart';
import 'package:emberday/data/sync/merge.dart';

class SyncPush {
  SyncPush(this._client, this._outbox);

  final PbClient _client;
  final OutboxRepository _outbox;

  Future<Result<void>> drain() async {
    final pending = await _outbox.pending();
    final ops = coalesce(
      pending
          .map(
            (r) => {
              'seq': r.seq,
              'entity': r.entity,
              'entityId': r.entityId,
              'op': r.op,
              'payload': r.payload,
            },
          )
          .toList(),
    );

    for (final op in ops) {
      final seq = op['seq'] as int;
      final entity = op['entity'] as String;
      final entityId = op['entityId'] as String;
      final action = op['op'] as String;
      final payload = decodePayload(op['payload'] as String);
      final collection = entity == 'habit' ? 'habits' : 'check_ins';

      try {
        if (action == 'delete') {
          await _client.pb.collection(collection).update(
            entityId,
            body: {
              'deleted_at': payload['deleted_at'] ??
                  DateTime.now().millisecondsSinceEpoch,
              'client_updated_at': payload['updated_at'],
            },
          );
        } else if (action == 'create') {
          try {
            await _client.pb.collection(collection).create(
                  body: {
                    ...payload,
                    'id': entityId,
                    'owner': _client.pb.authStore.record?.id,
                    'client_updated_at': payload['updated_at'],
                  },
                );
          } on Object catch (e) {
            // Duplicate create: GET and treat as success.
            final mapped = mapApiError(e);
            if (mapped.klass == ErrorClass.validation ||
                mapped.klass == ErrorClass.conflict) {
              await _client.pb.collection(collection).getOne(entityId);
            } else {
              rethrow;
            }
          }
        } else {
          await _client.pb.collection(collection).update(
                entityId,
                body: {
                  ...payload,
                  'client_updated_at': payload['updated_at'],
                },
              );
        }
        await _outbox.deleteSeq(seq);
      } on Object catch (e) {
        final err = mapApiError(e);
        final row = pending.firstWhere((r) => r.seq == seq);
        if (err.klass == ErrorClass.network ||
            err.klass == ErrorClass.transient) {
          final delay = nextBackoff(row.attempts);
          await _outbox.markAttempt(
            seq: seq,
            attempts: row.attempts + 1,
            nextAttemptAt:
                DateTime.now().millisecondsSinceEpoch + delay.inMilliseconds,
            lastError: err.klass.name,
          );
          return Err(err); // stop drain to preserve order
        }
        if (err.klass == ErrorClass.conflict) {
          // Caller applies server record.
          await _outbox.deleteSeq(seq);
          continue;
        }
        if (err.klass == ErrorClass.notFound && action == 'delete') {
          await _outbox.deleteSeq(seq);
          continue;
        }
        await _outbox.markAttempt(
          seq: seq,
          attempts: row.attempts + 1,
          nextAttemptAt: 0,
          lastError: err.klass.name,
          park: true,
        );
      }
    }
    return const Ok(null);
  }
}

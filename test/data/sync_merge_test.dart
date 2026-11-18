import 'package:emberday/data/sync/backoff.dart';
import 'package:emberday/data/sync/merge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('coalesce create then updates => one create', () {
    final result = coalesce([
      {
        'seq': 1,
        'entity': 'habit',
        'entityId': 'a',
        'op': 'create',
        'payload': '{}',
      },
      {
        'seq': 2,
        'entity': 'habit',
        'entityId': 'a',
        'op': 'update',
        'payload': '{"n":1}',
      },
    ]);
    expect(result.length, 1);
    expect(result.first['op'], 'create');
  });

  test('coalesce create then delete drops both', () {
    final result = coalesce([
      {
        'seq': 1,
        'entity': 'habit',
        'entityId': 'a',
        'op': 'create',
        'payload': '{}',
      },
      {
        'seq': 2,
        'entity': 'habit',
        'entityId': 'a',
        'op': 'delete',
        'payload': '{}',
      },
    ]);
    expect(result, isEmpty);
  });

  test('habits before check_ins', () {
    final result = coalesce([
      {
        'seq': 2,
        'entity': 'check_in',
        'entityId': 'c',
        'op': 'create',
        'payload': '{}',
      },
      {
        'seq': 1,
        'entity': 'habit',
        'entityId': 'h',
        'op': 'create',
        'payload': '{}',
      },
    ]);
    expect(result.first['entity'], 'habit');
  });

  test('backoff caps at 300s', () {
    final d = nextBackoff(20);
    expect(d.inSeconds, lessThanOrEqualTo(300));
  });
}

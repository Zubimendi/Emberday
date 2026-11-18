import 'package:emberday/core/errors.dart';
import 'package:emberday/data/sync/backoff.dart';
import 'package:emberday/data/sync/merge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('coalesce handles update then delete', () {
    final result = coalesce([
      {
        'seq': 1,
        'entity': 'habit',
        'entityId': 'a',
        'op': 'update',
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
    expect(result.length, 1);
    expect(result.first['op'], 'delete');
  });

  test('error classes cover sync taxonomy', () {
    expect(ErrorClass.values, contains(ErrorClass.conflict));
    expect(ErrorClass.values, contains(ErrorClass.transient));
  });

  test('backoff grows then caps', () {
    final early = nextBackoff(0);
    final late = nextBackoff(12);
    expect(early.inMilliseconds, lessThan(late.inMilliseconds + 1));
    expect(late.inSeconds, lessThanOrEqualTo(300));
  });
}

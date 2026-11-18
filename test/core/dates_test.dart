import 'package:emberday/core/dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('effectiveLocalDate respects rollover', () {
    final now = DateTime(2026, 11, 18, 1, 30);
    expect(effectiveLocalDate(now, 0), '2026-11-18');
    expect(effectiveLocalDate(now, 3), '2026-11-17');
  });

  test('weekKey monday start', () {
    // Wednesday 18 Nov 2026
    expect(weekKey(DateTime(2026, 11, 18)).startsWith('2026-W'), isTrue);
  });

  test('maskContainsWeekday', () {
    final mon = DateTime(2026, 11, 16); // Monday
    expect(maskContainsWeekday(1, mon), isTrue);
    expect(maskContainsWeekday(2, mon), isFalse);
  });
}

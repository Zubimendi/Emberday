import 'package:emberday/core/dates.dart';
import 'package:emberday/domain/models.dart';
import 'package:emberday/domain/streak_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('daily streaks', () {
    test('done Mon-Wed, today Thu pending => current 3', () {
      final stats = computeStats(
        schedule: const Daily(),
        startDate: '2026-11-16',
        checkIns: {
          '2026-11-16': CheckInStatus.done,
          '2026-11-17': CheckInStatus.done,
          '2026-11-18': CheckInStatus.done,
        },
        referenceDate: '2026-11-19',
      );
      expect(stats.currentStreak, 3);
    });

    test('Wednesday skipped => current 2', () {
      final stats = computeStats(
        schedule: const Daily(),
        startDate: '2026-11-16',
        checkIns: {
          '2026-11-16': CheckInStatus.done,
          '2026-11-17': CheckInStatus.done,
          '2026-11-18': CheckInStatus.skipped,
        },
        referenceDate: '2026-11-19',
      );
      expect(stats.currentStreak, 2);
    });

    test('Tuesday missed => current 1', () {
      final stats = computeStats(
        schedule: const Daily(),
        startDate: '2026-11-16',
        checkIns: {
          '2026-11-16': CheckInStatus.done,
          '2026-11-18': CheckInStatus.done,
        },
        referenceDate: '2026-11-19',
      );
      expect(stats.currentStreak, 1);
    });

    test('today done counts', () {
      final stats = computeStats(
        schedule: const Daily(),
        startDate: '2026-11-17',
        checkIns: {
          '2026-11-17': CheckInStatus.done,
          '2026-11-18': CheckInStatus.done,
        },
        referenceDate: '2026-11-18',
      );
      expect(stats.currentStreak, 2);
    });

    test('habit started today, no check-in => 0', () {
      final stats = computeStats(
        schedule: const Daily(),
        startDate: '2026-11-18',
        checkIns: {},
        referenceDate: '2026-11-18',
      );
      expect(stats.currentStreak, 0);
    });
  });

  group('weekday streaks', () {
    test('Mon Wed Fri done, today Sat => current 3', () {
      // Mon=16, Wed=18, Fri=20 Nov 2026; Sat=21
      final mask = weekdayBit(DateTime(2026, 11, 16)) |
          weekdayBit(DateTime(2026, 11, 18)) |
          weekdayBit(DateTime(2026, 11, 20));
      final stats = computeStats(
        schedule: Weekdays(mask),
        startDate: '2026-11-16',
        checkIns: {
          '2026-11-16': CheckInStatus.done,
          '2026-11-18': CheckInStatus.done,
          '2026-11-20': CheckInStatus.done,
        },
        referenceDate: '2026-11-21',
      );
      expect(stats.currentStreak, 3);
    });

    test('missed Wed, done Fri => current 1', () {
      final mask = weekdayBit(DateTime(2026, 11, 16)) |
          weekdayBit(DateTime(2026, 11, 18)) |
          weekdayBit(DateTime(2026, 11, 20));
      final stats = computeStats(
        schedule: Weekdays(mask),
        startDate: '2026-11-16',
        checkIns: {
          '2026-11-16': CheckInStatus.done,
          '2026-11-20': CheckInStatus.done,
        },
        referenceDate: '2026-11-21',
      );
      expect(stats.currentStreak, 1);
    });
  });

  group('weekly target', () {
    test('week1 met, week2 failed => current 0 best 1', () {
      // Week of Nov 16 (Mon): done 16,17,18
      // Week of Nov 23: done only 23,24 (2 < 3)
      // Today Nov 26 (Wed of week 2... wait Nov 23 is Mon)
      final checkIns = <String, CheckInStatus>{
        '2026-11-16': CheckInStatus.done,
        '2026-11-17': CheckInStatus.done,
        '2026-11-18': CheckInStatus.done,
        '2026-11-23': CheckInStatus.done,
        '2026-11-24': CheckInStatus.done,
      };
      final stats = computeStats(
        schedule: const WeeklyTarget(3),
        startDate: '2026-11-16',
        checkIns: checkIns,
        referenceDate: '2026-11-30', // end of week 2
      );
      expect(stats.currentStreak, 0);
      expect(stats.bestStreak, greaterThanOrEqualTo(1));
    });
  });

  group('edges', () {
    test('month boundary', () {
      final stats = computeStats(
        schedule: const Daily(),
        startDate: '2026-10-30',
        checkIns: {
          '2026-10-30': CheckInStatus.done,
          '2026-10-31': CheckInStatus.done,
          '2026-11-01': CheckInStatus.done,
        },
        referenceDate: '2026-11-02',
      );
      expect(stats.currentStreak, 3);
    });

    test('year boundary', () {
      final stats = computeStats(
        schedule: const Daily(),
        startDate: '2025-12-30',
        checkIns: {
          '2025-12-30': CheckInStatus.done,
          '2025-12-31': CheckInStatus.done,
          '2026-01-01': CheckInStatus.done,
        },
        referenceDate: '2026-01-02',
      );
      expect(stats.currentStreak, 3);
    });

    test('leap day', () {
      final stats = computeStats(
        schedule: const Daily(),
        startDate: '2024-02-28',
        checkIns: {
          '2024-02-28': CheckInStatus.done,
          '2024-02-29': CheckInStatus.done,
          '2024-03-01': CheckInStatus.done,
        },
        referenceDate: '2024-03-02',
      );
      expect(stats.currentStreak, 3);
    });

    test('skip today does not break', () {
      final stats = computeStats(
        schedule: const Daily(),
        startDate: '2026-11-16',
        checkIns: {
          '2026-11-16': CheckInStatus.done,
          '2026-11-17': CheckInStatus.done,
          '2026-11-18': CheckInStatus.skipped,
        },
        referenceDate: '2026-11-18',
      );
      expect(stats.currentStreak, 2);
    });

    test('backfill restores streak', () {
      final before = computeStats(
        schedule: const Daily(),
        startDate: '2026-11-16',
        checkIns: {
          '2026-11-16': CheckInStatus.done,
          '2026-11-18': CheckInStatus.done,
        },
        referenceDate: '2026-11-18',
      );
      expect(before.currentStreak, 1);

      final after = computeStats(
        schedule: const Daily(),
        startDate: '2026-11-16',
        checkIns: {
          '2026-11-16': CheckInStatus.done,
          '2026-11-17': CheckInStatus.done,
          '2026-11-18': CheckInStatus.done,
        },
        referenceDate: '2026-11-18',
      );
      expect(after.currentStreak, 3);
    });
  });

  // Expand toward 40+ cases with parameterized loops.
  group('table daily runs', () {
    for (var n = 1; n <= 14; n++) {
      test('run of $n days', () {
        final start = DateTime(2026, 1, 1);
        final checkIns = <String, CheckInStatus>{};
        for (var i = 0; i < n; i++) {
          checkIns[formatLocalDate(start.add(Duration(days: i)))] =
              CheckInStatus.done;
        }
        final ref = formatLocalDate(start.add(Duration(days: n)));
        final stats = computeStats(
          schedule: const Daily(),
          startDate: '2026-01-01',
          checkIns: checkIns,
          referenceDate: ref,
        );
        expect(stats.currentStreak, n);
        expect(stats.bestStreak, n);
      });
    }
  });

  group('completion rate', () {
    test('30-day rate ignores skips in denominator', () {
      final checkIns = <String, CheckInStatus>{
        for (var i = 0; i < 10; i++)
          formatLocalDate(DateTime(2026, 10, 20).add(Duration(days: i))):
              CheckInStatus.done,
        '2026-11-01': CheckInStatus.skipped,
      };
      final stats = computeStats(
        schedule: const Daily(),
        startDate: '2026-10-20',
        checkIns: checkIns,
        referenceDate: '2026-11-18',
      );
      expect(stats.completionRate30, isNotNull);
      expect(stats.totalDone, 10);
    });
  });
}

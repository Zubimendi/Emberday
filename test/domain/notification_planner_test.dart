import 'package:emberday/core/ids.dart';
import 'package:emberday/domain/models.dart';
import 'package:emberday/domain/notification_planner.dart';
import 'package:flutter_test/flutter_test.dart';

Habit _habit({
  required String id,
  int? minutes = 9 * 60,
  bool enabled = true,
  Schedule schedule = const Daily(),
  int mask = 127,
}) {
  return Habit(
    id: id,
    name: 'Water',
    icon: '💧',
    colorKey: 'habit1',
    schedule: schedule,
    startDate: '2026-11-01',
    reminderEnabled: enabled,
    reminderMinutes: minutes,
    reminderWeekdaysMask: mask,
    sortOrder: 0,
    createdAt: 0,
    updatedAt: 0,
  );
}

void main() {
  final now = DateTime(2026, 11, 18, 8, 0);

  test('skips past times today', () {
    final plan = planReminders(
      habits: [_habit(id: 'h1', minutes: 7 * 60)],
      checkInsByHabit: {},
      now: now,
      rolloverHours: 0,
    );
    expect(plan.every((p) => p.fireAt.isAfter(now)), isTrue);
  });

  test('skips done days', () {
    final plan = planReminders(
      habits: [_habit(id: 'h1')],
      checkInsByHabit: {
        'h1': {'2026-11-18': CheckInStatus.done},
      },
      now: now,
      rolloverHours: 0,
    );
    expect(plan.any((p) => p.localDate == '2026-11-18'), isFalse);
  });

  test('skips skipped days', () {
    final plan = planReminders(
      habits: [_habit(id: 'h1')],
      checkInsByHabit: {
        'h1': {'2026-11-18': CheckInStatus.skipped},
      },
      now: now,
      rolloverHours: 0,
    );
    expect(plan.any((p) => p.localDate == '2026-11-18'), isFalse);
  });

  test('respects cap', () {
    final habits = List.generate(20, (i) => _habit(id: 'h$i'));
    final plan = planReminders(
      habits: habits,
      checkInsByHabit: {},
      now: now,
      rolloverHours: 0,
      cap: 10,
    );
    expect(plan.length, 10);
  });

  test('id stability', () {
    final a = notificationId('habit', '2026-11-18');
    final b = notificationId('habit', '2026-11-18');
    expect(a, b);
    expect(a & 0x80000000, 0);
  });

  test('hide names', () {
    final plan = planReminders(
      habits: [_habit(id: 'h1')],
      checkInsByHabit: {},
      now: now,
      rolloverHours: 0,
      hideNames: true,
    );
    expect(plan.first.body, 'Time for your habit');
  });

  test('shows names by default', () {
    final plan = planReminders(
      habits: [_habit(id: 'h1')],
      checkInsByHabit: {},
      now: now,
      rolloverHours: 0,
    );
    expect(plan.first.body, contains('Water'));
  });

  test('weekday mask filters', () {
    // Only Monday reminders; now is Wednesday.
    final plan = planReminders(
      habits: [_habit(id: 'h1', mask: 1)],
      checkInsByHabit: {},
      now: now,
      rolloverHours: 0,
    );
    expect(plan.every((p) => p.fireAt.weekday == DateTime.monday), isTrue);
  });
}

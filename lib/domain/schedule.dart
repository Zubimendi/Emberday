import 'package:emberday/core/dates.dart';
import 'package:emberday/domain/models.dart';

bool isScheduledOn(Schedule schedule, DateTime date) {
  return switch (schedule) {
    Daily() => true,
    Weekdays(:final mask) => maskContainsWeekday(mask, date),
    WeeklyTarget() => true,
  };
}

int weekdaysMaskFromSchedule(Schedule schedule) {
  return switch (schedule) {
    Daily() => 127,
    Weekdays(:final mask) => mask,
    WeeklyTarget() => 127,
  };
}

Schedule scheduleFromDb({
  required String type,
  required int weekdaysMask,
  required int weeklyTarget,
}) {
  return switch (type) {
    'daily' => const Daily(),
    'weekdays' => Weekdays(weekdaysMask),
    'weekly_target' => WeeklyTarget(weeklyTarget.clamp(1, 7)),
    _ => const Daily(),
  };
}

({String type, int weekdaysMask, int weeklyTarget}) scheduleToDb(
  Schedule schedule,
) {
  return switch (schedule) {
    Daily() => (type: 'daily', weekdaysMask: 127, weeklyTarget: 0),
    Weekdays(:final mask) => (
        type: 'weekdays',
        weekdaysMask: mask,
        weeklyTarget: 0,
      ),
    WeeklyTarget(:final n) => (
        type: 'weekly_target',
        weekdaysMask: 127,
        weeklyTarget: n,
      ),
  };
}

String scheduleSummary(Schedule schedule) {
  return switch (schedule) {
    Daily() => 'Every day',
    Weekdays(:final mask) => _weekdaySummary(mask),
    WeeklyTarget(:final n) => '$n times a week',
  };
}

String _weekdaySummary(int mask) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final selected = <String>[];
  for (var i = 0; i < 7; i++) {
    if ((mask & (1 << i)) != 0) selected.add(names[i]);
  }
  if (selected.length == 7) return 'Every day';
  if (mask == 31) return 'Weekdays';
  if (selected.isEmpty) return 'No days';
  return selected.join(', ');
}

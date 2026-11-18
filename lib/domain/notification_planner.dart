import 'package:emberday/core/dates.dart';
import 'package:emberday/core/ids.dart';
import 'package:emberday/domain/models.dart';
import 'package:emberday/domain/schedule.dart';

/// Pure reminder planner. Returns up to [cap] notifications sorted by fireAt.
List<PlannedNotification> planReminders({
  required List<Habit> habits,
  required Map<String, Map<String, CheckInStatus>> checkInsByHabit,
  required DateTime now,
  required int rolloverHours,
  int horizonDays = 7,
  int cap = 60,
  bool hideNames = false,
}) {
  final planned = <PlannedNotification>[];
  final todayYmd = formatLocalDate(now);

  for (final habit in habits) {
    if (!habit.reminderEnabled || habit.reminderMinutes == null) continue;
    if (habit.isArchived || habit.isDeleted) continue;

    for (var offset = 0; offset < horizonDays; offset++) {
      final day = addDays(parseLocalDate(todayYmd), offset);
      final dayYmd = formatLocalDate(day);

      if (!maskContainsWeekday(habit.reminderWeekdaysMask, day)) continue;

      final scheduleOk = switch (habit.schedule) {
        WeeklyTarget() => true,
        _ => isScheduledOn(habit.schedule, day),
      };
      if (!scheduleOk) continue;

      // Done/skipped uses effective date correspondence for today;
      // for planning we key by calendar day of the fire.
      final status = checkInsByHabit[habit.id]?[dayYmd];
      if (status == CheckInStatus.done || status == CheckInStatus.skipped) {
        continue;
      }

      final minutes = habit.reminderMinutes!;
      final fireAt = DateTime(
        day.year,
        day.month,
        day.day,
        minutes ~/ 60,
        minutes % 60,
      );
      if (!fireAt.isAfter(now)) continue;

      final body = hideNames
          ? 'Time for your habit'
          : 'Time for: ${habit.name}';

      planned.add(
        PlannedNotification(
          id: notificationId(habit.id, dayYmd),
          habitId: habit.id,
          fireAt: fireAt,
          title: 'Emberday',
          body: body,
          localDate: dayYmd,
        ),
      );
    }
  }

  planned.sort((a, b) => a.fireAt.compareTo(b.fireAt));
  if (planned.length <= cap) return planned;
  return planned.sublist(0, cap);
}

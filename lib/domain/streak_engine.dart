import 'package:emberday/core/dates.dart';
import 'package:emberday/domain/models.dart';
import 'package:emberday/domain/schedule.dart';

/// Pure streak computation. No Flutter/Drift imports.
StreakStats computeStats({
  required Schedule schedule,
  required String startDate,
  required Map<String, CheckInStatus> checkIns,
  required String referenceDate,
}) {
  if (schedule is WeeklyTarget) {
    return _computeWeeklyTarget(
      n: schedule.n,
      startDate: startDate,
      checkIns: checkIns,
      referenceDate: referenceDate,
    );
  }
  return _computeDayBased(
    schedule: schedule,
    startDate: startDate,
    checkIns: checkIns,
    referenceDate: referenceDate,
  );
}

DayClass classifyDay({
  required Schedule schedule,
  required String startDate,
  required String date,
  required String referenceDate,
  required Map<String, CheckInStatus> checkIns,
}) {
  if (daysBetween(date, startDate) > 0) return DayClass.neutral;
  if (daysBetween(referenceDate, date) > 0) return DayClass.neutral;

  final dt = parseLocalDate(date);
  if (schedule is WeeklyTarget) {
    // Day-level for weekly target: only done/skipped matter for heatmaps.
    final status = checkIns[date];
    if (status == CheckInStatus.done) return DayClass.done;
    if (status == CheckInStatus.skipped) return DayClass.skipped;
    if (date == referenceDate) return DayClass.pending;
    return DayClass.missed;
  }

  if (!isScheduledOn(schedule, dt)) return DayClass.neutral;

  final status = checkIns[date];
  if (status == CheckInStatus.done) return DayClass.done;
  if (status == CheckInStatus.skipped) return DayClass.skipped;
  if (date == referenceDate) return DayClass.pending;
  return DayClass.missed;
}

StreakStats _computeDayBased({
  required Schedule schedule,
  required String startDate,
  required Map<String, CheckInStatus> checkIns,
  required String referenceDate,
}) {
  DayClass classOf(String date) => classifyDay(
        schedule: schedule,
        startDate: startDate,
        date: date,
        referenceDate: referenceDate,
        checkIns: checkIns,
      );

  // Current streak reference: today if done, else day before.
  final todayClass = classOf(referenceDate);
  String walkStart;
  if (todayClass == DayClass.done) {
    walkStart = referenceDate;
  } else {
    walkStart = addDaysYmd(referenceDate, -1);
  }

  var current = 0;
  var cursor = walkStart;
  while (true) {
    if (daysBetween(cursor, startDate) > 0) break;
    final c = classOf(cursor);
    if (c == DayClass.done) {
      current++;
      cursor = addDaysYmd(cursor, -1);
      continue;
    }
    if (c == DayClass.skipped || c == DayClass.neutral) {
      cursor = addDaysYmd(cursor, -1);
      continue;
    }
    // missed or pending (shouldn't hit pending on walkStart after adjust)
    break;
  }

  // Best streak: walk entire history.
  var best = 0;
  var run = 0;
  var d = startDate;
  while (daysBetween(referenceDate, d) <= 0) {
    final c = classOf(d);
    if (c == DayClass.done) {
      run++;
      if (run > best) best = run;
    } else if (c == DayClass.missed) {
      run = 0;
    }
    // skipped/neutral: continue run without increment
    d = addDaysYmd(d, 1);
  }

  // Totals and 30-day rate.
  var totalDone = 0;
  String? lastDone;
  var scheduledNonSkipped = 0;
  var doneInWindow = 0;
  final windowStart = addDaysYmd(referenceDate, -29);

  d = startDate;
  while (daysBetween(referenceDate, d) <= 0) {
    final c = classOf(d);
    if (c == DayClass.done) {
      totalDone++;
      lastDone = d;
    }
    if (!daysBetween(d, windowStart).isNegative &&
        daysBetween(windowStart, d) >= 0) {
      if (c == DayClass.done) {
        doneInWindow++;
        scheduledNonSkipped++;
      } else if (c == DayClass.missed || c == DayClass.pending) {
        scheduledNonSkipped++;
      }
    }
    d = addDaysYmd(d, 1);
  }

  final rate =
      scheduledNonSkipped == 0 ? null : doneInWindow / scheduledNonSkipped;

  return StreakStats(
    currentStreak: current,
    bestStreak: best > current ? best : (best == 0 ? current : best),
    totalDone: totalDone,
    lastDoneDate: lastDone,
    completionRate30: rate,
    computedForDate: referenceDate,
  );
}

StreakStats _computeWeeklyTarget({
  required int n,
  required String startDate,
  required Map<String, CheckInStatus> checkIns,
  required String referenceDate,
}) {
  final start = parseLocalDate(startDate);
  final ref = parseLocalDate(referenceDate);
  final firstMonday = mondayOfWeek(start);
  final currentMonday = mondayOfWeek(ref);

  // Build week outcomes from firstMonday through currentMonday.
  final weeks = <_WeekOutcome>[];
  var monday = firstMonday;
  var isFirst = true;
  while (!monday.isAfter(currentMonday)) {
    final sunday = addDays(monday, 6);
    var doneCount = 0;
    var d = monday;
    while (!d.isAfter(sunday) && !d.isAfter(ref)) {
      if (daysBetween(formatLocalDate(d), startDate) <= 0) {
        if (checkIns[formatLocalDate(d)] == CheckInStatus.done) {
          doneCount++;
        }
      }
      d = addDays(d, 1);
    }
    final met = doneCount >= n;
    final isCurrent = monday == currentMonday;
    final weekEnded = sunday.isBefore(ref) || sunday == ref;
    _WeekStatus status;
    if (met) {
      status = _WeekStatus.met;
    } else if (isCurrent && !weekEnded) {
      status = _WeekStatus.pending;
    } else if (isFirst && !met) {
      status = _WeekStatus.neutral;
    } else {
      status = _WeekStatus.failed;
    }
    weeks.add(_WeekOutcome(monday: monday, status: status, doneCount: doneCount));
    monday = addDays(monday, 7);
    isFirst = false;
  }

  // Current streak: consecutive met ending at latest completed week, + current if met.
  var current = 0;
  if (weeks.isNotEmpty) {
    final last = weeks.last;
    var i = weeks.length - 1;
    if (last.status == _WeekStatus.pending || last.status == _WeekStatus.neutral) {
      i = weeks.length - 2;
    } else if (last.status == _WeekStatus.met) {
      current = 1;
      i = weeks.length - 2;
    } else {
      i = -1; // failed current completed week
    }
    while (i >= 0) {
      if (weeks[i].status == _WeekStatus.met) {
        current++;
        i--;
      } else if (weeks[i].status == _WeekStatus.neutral) {
        i--;
      } else {
        break;
      }
    }
  }

  // Best streak
  var best = 0;
  var run = 0;
  for (final w in weeks) {
    if (w.status == _WeekStatus.met) {
      run++;
      if (run > best) best = run;
    } else if (w.status == _WeekStatus.failed) {
      run = 0;
    }
  }

  var totalDone = 0;
  String? lastDone;
  for (final e in checkIns.entries) {
    if (e.value == CheckInStatus.done) {
      totalDone++;
      if (lastDone == null || daysBetween(lastDone, e.key) > 0) {
        lastDone = e.key;
      }
    }
  }

  // Completion: met / completed weeks over last 12 weeks
  final completed = weeks
      .where((w) =>
          w.status == _WeekStatus.met || w.status == _WeekStatus.failed)
      .toList();
  final last12 = completed.length > 12
      ? completed.sublist(completed.length - 12)
      : completed;
  final metCount = last12.where((w) => w.status == _WeekStatus.met).length;
  final rate = last12.isEmpty ? null : metCount / last12.length;

  return StreakStats(
    currentStreak: current,
    bestStreak: best > current ? best : (best == 0 ? current : best),
    totalDone: totalDone,
    lastDoneDate: lastDone,
    completionRate30: rate,
    computedForDate: referenceDate,
  );
}

enum _WeekStatus { met, failed, pending, neutral }

class _WeekOutcome {
  _WeekOutcome({
    required this.monday,
    required this.status,
    required this.doneCount,
  });
  final DateTime monday;
  final _WeekStatus status;
  final int doneCount;
}

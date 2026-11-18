sealed class Schedule {
  const Schedule();
}

final class Daily extends Schedule {
  const Daily();
}

final class Weekdays extends Schedule {
  const Weekdays(this.mask);
  /// Bit 0 = Monday … bit 6 = Sunday.
  final int mask;
}

final class WeeklyTarget extends Schedule {
  const WeeklyTarget(this.n);
  final int n;
}

enum CheckInStatus { done, skipped }

class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorKey,
    required this.schedule,
    required this.startDate,
    required this.reminderEnabled,
    required this.reminderMinutes,
    required this.reminderWeekdaysMask,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final String icon;
  final String colorKey;
  final Schedule schedule;
  final String startDate;
  final bool reminderEnabled;
  final int? reminderMinutes;
  final int reminderWeekdaysMask;
  final double sortOrder;
  final int createdAt;
  final int updatedAt;
  final int? archivedAt;
  final int? deletedAt;

  bool get isArchived => archivedAt != null;
  bool get isDeleted => deletedAt != null;

  Habit copyWith({
    String? name,
    String? icon,
    String? colorKey,
    Schedule? schedule,
    String? startDate,
    bool? reminderEnabled,
    int? reminderMinutes,
    bool clearReminderMinutes = false,
    int? reminderWeekdaysMask,
    double? sortOrder,
    int? updatedAt,
    int? archivedAt,
    bool clearArchivedAt = false,
    int? deletedAt,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorKey: colorKey ?? this.colorKey,
      schedule: schedule ?? this.schedule,
      startDate: startDate ?? this.startDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutes: clearReminderMinutes
          ? null
          : (reminderMinutes ?? this.reminderMinutes),
      reminderWeekdaysMask:
          reminderWeekdaysMask ?? this.reminderWeekdaysMask,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

class CheckIn {
  const CheckIn({
    required this.id,
    required this.habitId,
    required this.localDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.deletedAt,
  });

  final String id;
  final String habitId;
  final String localDate;
  final CheckInStatus status;
  final String? note;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;

  bool get isDeleted => deletedAt != null;
}

class StreakStats {
  const StreakStats({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalDone,
    required this.lastDoneDate,
    required this.completionRate30,
    required this.computedForDate,
  });

  final int currentStreak;
  final int bestStreak;
  final int totalDone;
  final String? lastDoneDate;
  final double? completionRate30;
  final String computedForDate;

  static const empty = StreakStats(
    currentStreak: 0,
    bestStreak: 0,
    totalDone: 0,
    lastDoneDate: null,
    completionRate30: null,
    computedForDate: '',
  );
}

enum DayClass { done, skipped, missed, pending, neutral }

class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.habitId,
    required this.fireAt,
    required this.title,
    required this.body,
    required this.localDate,
  });

  final int id;
  final String habitId;
  final DateTime fireAt;
  final String title;
  final String body;
  final String localDate;
}

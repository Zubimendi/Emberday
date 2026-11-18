import 'package:drift/drift.dart';

class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get colorKey => text()();
  TextColumn get scheduleType => text()();
  IntColumn get weekdaysMask => integer().withDefault(const Constant(127))();
  IntColumn get weeklyTarget => integer().withDefault(const Constant(0))();
  TextColumn get startDate => text()();
  IntColumn get reminderEnabled => integer().withDefault(const Constant(0))();
  IntColumn get reminderMinutes => integer().nullable()();
  IntColumn get reminderWeekdaysMask =>
      integer().withDefault(const Constant(127))();
  RealColumn get sortOrder => real().withDefault(const Constant(0.0))();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CheckIns extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text().references(Habits, #id)();
  TextColumn get localDate => text()();
  TextColumn get status => text()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {habitId, localDate},
      ];
}

class HabitStats extends Table {
  TextColumn get habitId => text()();
  IntColumn get currentStreak => integer()();
  IntColumn get bestStreak => integer()();
  IntColumn get totalDone => integer()();
  TextColumn get lastDoneDate => text().nullable()();
  RealColumn get completionRate30 => real().nullable()();
  TextColumn get computedForDate => text()();
  IntColumn get computedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {habitId};
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class Outbox extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get op => text()();
  TextColumn get payload => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get nextAttemptAt => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get lastError => text().nullable()();
  IntColumn get createdAt => integer()();
}

class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

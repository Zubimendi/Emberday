import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:emberday/data/db/tables.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Habits,
  CheckIns,
  HabitStats,
  Settings,
  Outbox,
  SyncState,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement('PRAGMA foreign_keys = ON');
          await into(settings).insert(
            SettingsCompanion.insert(key: 'rollover_hours', value: '0'),
          );
          await into(settings).insert(
            SettingsCompanion.insert(key: 'theme', value: 'system'),
          );
          await into(settings).insert(
            SettingsCompanion.insert(key: 'hide_names', value: 'false'),
          );
          await into(settings).insert(
            SettingsCompanion.insert(key: 'onboarding_done', value: 'false'),
          );
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
        },
      );

  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'emberday.sqlite'));
    return AppDatabase(NativeDatabase.createInBackground(file));
  }

  /// In-memory DB for tests.
  static AppDatabase memory() {
    return AppDatabase(NativeDatabase.memory());
  }

  /// Separate connection for background isolate (same file, WAL).
  static Future<AppDatabase> openFile(String path) async {
    return AppDatabase(NativeDatabase(File(path)));
  }
}

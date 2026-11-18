import 'package:emberday/data/db/app_database.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Stream<Map<String, String>> watchAll() {
    return (_db.select(_db.settings)).watch().map((rows) {
      return {for (final r in rows) r.key: r.value};
    });
  }

  Future<String?> get(String key) async {
    final row = await (_db.select(_db.settings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) async {
    await _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: key, value: value),
        );
  }

  Future<int> rolloverHours() async {
    final v = await get('rollover_hours');
    return int.tryParse(v ?? '0') ?? 0;
  }

  Future<bool> onboardingDone() async {
    final v = await get('onboarding_done');
    return v == 'true';
  }

  Future<void> setOnboardingDone() => set('onboarding_done', 'true');

  Future<String> themeMode() async => (await get('theme')) ?? 'system';

  Future<bool> hideNames() async => (await get('hide_names')) == 'true';

  Future<String?> syncOwnerId() => get('sync_owner_id');

  Future<bool> isSignedIn() async {
    final token = await get('has_session');
    return token == 'true';
  }
}

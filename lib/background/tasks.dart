import 'package:emberday/core/clock.dart';
import 'package:emberday/core/logger.dart';
import 'package:emberday/data/db/app_database.dart';
import 'package:emberday/data/repositories/check_in_repository.dart';
import 'package:emberday/data/repositories/habit_repository.dart';
import 'package:emberday/data/repositories/settings_repository.dart';
import 'package:emberday/domain/models.dart';
import 'package:emberday/domain/notification_planner.dart';
import 'package:emberday/notifications/scheduler.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const topUpTaskName = 'emberday_top_up';

Future<void> topUp() async {
  const logger = ConsoleLogger();
  final dir = await getApplicationDocumentsDirectory();
  final path = p.join(dir.path, 'emberday.sqlite');
  final db = await AppDatabase.openFile(path);
  try {
    const clock = SystemClock();
    final settings = SettingsRepository(db);
    final habitRepo = HabitRepository(
      database: db,
      clock: clock,
      settings: settings,
    );
    final checkInRepo = CheckInRepository(
      database: db,
      clock: clock,
      settings: settings,
    );

    final habits = await habitRepo.watchActiveHabits().first;
    final map = <String, Map<String, CheckInStatus>>{};
    for (final h in habits) {
      map[h.id] = await checkInRepo.mapForHabit(h.id);
    }
    final plan = planReminders(
      habits: habits,
      checkInsByHabit: map,
      now: clock.now(),
      rolloverHours: await settings.rolloverHours(),
      hideNames: await settings.hideNames(),
    );
    await NotificationScheduler.instance.apply(plan);
    await settings.set('last_plan_count', plan.length.toString());
    await settings.set(
      'last_plan_at',
      clock.now().millisecondsSinceEpoch.toString(),
    );
    logger.info('topUp planned', data: {'count': plan.length});
  } finally {
    await db.close();
  }
}

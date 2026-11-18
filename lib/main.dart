import 'dart:async';

import 'package:emberday/app.dart';
import 'package:emberday/app_providers.dart';
import 'package:emberday/background/callback_dispatcher.dart';
import 'package:emberday/background/tasks.dart';
import 'package:emberday/core/dates.dart';
import 'package:emberday/core/logger.dart';
import 'package:emberday/data/api/auth.dart';
import 'package:emberday/data/db/app_database.dart' show AppDatabase;
import 'package:emberday/data/sync/status.dart';
import 'package:emberday/domain/models.dart';
import 'package:emberday/domain/notification_planner.dart';
import 'package:emberday/notifications/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    const ConsoleLogger().error(
      'FlutterError',
      error: details.exception,
      stack: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    const ConsoleLogger().error('PlatformError', error: error, stack: stack);
    return true;
  };

  final db = await AppDatabase.open();
  late ProviderContainer container;

  Future<void> replan() async {
    final habits =
        await container.read(habitRepositoryProvider).watchActiveHabits().first;
    final checkInRepo = container.read(checkInRepositoryProvider);
    final settings = container.read(settingsRepositoryProvider);
    final clock = container.read(clockProvider);
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
    await settings.set('last_plan_count', '${plan.length}');
    await settings.set(
      'last_plan_at',
      '${clock.now().millisecondsSinceEpoch}',
    );
    final today =
        effectiveLocalDate(clock.now(), await settings.rolloverHours());
    if (container.read(selectedDateProvider) == null) {
      container.read(selectedDateProvider.notifier).state = today;
    }
  }

  container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      replanRemindersProvider.overrideWithValue(replan),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: _Lifecycle(
        onResume: () async {
          await container
              .read(habitRepositoryProvider)
              .recomputeAllIfDateChanged();
          await replan();
          unawaited(container.read(syncEngineProvider).runOnce());
        },
        onFirstFrame: () async {
          await container.read(pbClientProvider).restore();
          await replan();
          await container
              .read(habitRepositoryProvider)
              .recomputeAllIfDateChanged();
          try {
            await Workmanager().initialize(callbackDispatcher);
            await Workmanager().registerPeriodicTask(
              topUpTaskName,
              topUpTaskName,
              frequency: const Duration(hours: 6),
              constraints: Constraints(
                networkType: NetworkType.notRequired,
              ),
            );
          } on Object catch (e) {
            container.read(loggerProvider).warn(
              'workmanager init failed',
              data: {'error': e.runtimeType.toString()},
            );
          }
          unawaited(container.read(syncEngineProvider).runOnce());
        },
        child: const EmberdayApp(),
      ),
    ),
  );
}

class _Lifecycle extends StatefulWidget {
  const _Lifecycle({
    required this.child,
    required this.onFirstFrame,
    required this.onResume,
  });

  final Widget child;
  final Future<void> Function() onFirstFrame;
  final Future<void> Function() onResume;

  @override
  State<_Lifecycle> createState() => _LifecycleState();
}

class _LifecycleState extends State<_Lifecycle> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(widget.onFirstFrame());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.onResume());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

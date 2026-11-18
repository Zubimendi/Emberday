import 'package:emberday/app_providers.dart';
import 'package:emberday/domain/models.dart';
import 'package:emberday/domain/notification_planner.dart';
import 'package:emberday/notifications/scheduler.dart';
import 'package:emberday/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RemindersHelpScreen extends ConsumerWidget {
  const RemindersHelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final settings = ref.watch(settingsMapProvider).value ?? {};
    final lastPlan = settings['last_plan_count'] ?? '0';

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(title: const Text('Reminders help')),
      body: ListView(
        padding: EdgeInsets.all(t.screenPadding),
        children: [
          Text(
            'Some phones delay reminders to save battery. Use this checklist if reminders are late or missing.',
            style: TextStyle(color: t.textSecondary),
          ),
          SizedBox(height: t.space16),
          const _CheckItem(text: 'Allow notifications for Emberday'),
          const _CheckItem(text: 'Allow the app to run in the background'),
          const _CheckItem(text: 'Set battery usage to unrestricted'),
          const _CheckItem(
            text: 'Lock the app in recents (on phones that support it)',
          ),
          SizedBox(height: t.space24),
          Text(
            'Last scheduled: $lastPlan reminders over the next 7 days',
            style: TextStyle(color: t.text),
          ),
          SizedBox(height: t.space16),
          FilledButton(
            onPressed: () async {
              final scheduler = NotificationScheduler.instance;
              await scheduler.scheduleTestIn(const Duration(seconds: 10));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test reminder in 10 seconds.'),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: t.primary),
            child: const Text('Send a test reminder in 10 seconds'),
          ),
          SizedBox(height: t.space12),
          OutlinedButton(
            onPressed: () async {
              await ref.read(replanRemindersProvider)();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminders re-planned.')),
                );
              }
            },
            child: const Text('Re-plan now'),
          ),
        ],
      ),
    );
  }
}

Future<int> countPlanned(WidgetRef ref) async {
  final habits = await ref.read(habitsStreamProvider.future);
  final checkInRepo = ref.read(checkInRepositoryProvider);
  final settings = ref.read(settingsRepositoryProvider);
  final clock = ref.read(clockProvider);
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
  return plan.length;
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: t.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_box_outlined, color: t.primary, size: 20),
          SizedBox(width: t.space8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

import 'package:emberday/app_providers.dart';
import 'package:emberday/core/dates.dart';
import 'package:emberday/domain/models.dart';
import 'package:emberday/domain/schedule.dart';
import 'package:emberday/ui/tokens.dart';
import 'package:emberday/ui/widgets/date_strip.dart';
import 'package:emberday/ui/widgets/empty_state.dart';
import 'package:emberday/ui/widgets/habit_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final theme = Theme.of(context).textTheme;
    final clock = ref.watch(clockProvider);
    final settings = ref.watch(settingsMapProvider).value ?? {};
    final rollover = int.tryParse(settings['rollover_hours'] ?? '0') ?? 0;
    final today = effectiveLocalDate(clock.now(), rollover);
    final selected = ref.watch(selectedDateProvider) ?? today;
    final habitsAsync = ref.watch(habitsStreamProvider);
    final checkInsAsync = ref.watch(checkInsForDateProvider(selected));
    final editable = daysBetween(today, selected) <= 0;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: habitsAsync.when(
          loading: () => const LoadingState(),
          error: (_, _) => ErrorState(
            onRetry: () => ref.invalidate(habitsStreamProvider),
          ),
          data: (habits) {
            final checkIns = {
              for (final c in checkInsAsync.value ?? <CheckIn>[]) c.habitId: c,
            };
            final scheduled = <Habit>[];
            final notToday = <Habit>[];
            for (final h in habits) {
              if (daysBetween(selected, h.startDate) > 0) {
                notToday.add(h);
                continue;
              }
              if (isScheduledOn(h.schedule, parseLocalDate(selected)) ||
                  h.schedule is WeeklyTarget) {
                scheduled.add(h);
              } else {
                notToday.add(h);
              }
            }
            final doneCount = scheduled
                .where((h) => checkIns[h.id]?.status == CheckInStatus.done)
                .length;
            final weekday =
                DateFormat('EEEE').format(parseLocalDate(selected));

            if (habits.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: t.screenPadding),
                child: EmptyState(
                  message:
                      'No habits yet. Start with one that takes under two minutes.',
                  actionLabel: 'Add a habit',
                  onAction: () => context.push('/habits/add'),
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    t.screenPadding,
                    t.spaceLg,
                    t.screenPadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('d MMMM').format(parseLocalDate(selected)),
                          style: theme.bodyMedium?.copyWith(
                            color: t.textSecondary,
                          ),
                        ),
                        SizedBox(height: t.spaceXs),
                        // Hero: progress figure, not a ring.
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$doneCount',
                                style: theme.displayLarge?.copyWith(
                                  color: t.text,
                                ),
                              ),
                              TextSpan(
                                text: ' of ${scheduled.length}',
                                style: theme.displayMedium?.copyWith(
                                  color: t.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: t.spaceXs),
                        Text(
                          scheduled.isEmpty
                              ? 'Nothing scheduled for $weekday.'
                              : doneCount == scheduled.length
                                  ? 'All set for $weekday.'
                                  : '${scheduled.length - doneCount} left for $weekday.',
                          style: theme.bodyLarge?.copyWith(
                            color: t.textSecondary,
                          ),
                        ),
                        SizedBox(height: t.spaceXl),
                        DateStrip(
                          selectedDate: selected,
                          todayDate: today,
                          onSelect: (d) =>
                              ref.read(selectedDateProvider.notifier).state = d,
                        ),
                        SizedBox(height: t.spaceXl),
                        Text(
                          'Habits',
                          style: theme.labelLarge?.copyWith(
                            color: t.textFaint,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: t.spaceSm),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: t.screenPadding),
                  sliver: SliverList.builder(
                    itemCount: scheduled.length,
                    itemBuilder: (context, i) {
                      final h = scheduled[i];
                      final stats =
                          ref.watch(habitStatsProvider(h.id)).value;
                      final status = checkIns[h.id]?.status;
                      final atRisk = (stats?.currentStreak ?? 0) > 0 &&
                          status == null &&
                          selected == today;
                      return HabitTile(
                        habit: h,
                        status: status,
                        stats: stats,
                        enabled: editable,
                        atRisk: atRisk,
                        last: i == scheduled.length - 1 && notToday.isEmpty,
                        onToggle: () async {
                          await ref.read(checkInRepositoryProvider).toggleDone(
                                habitId: h.id,
                                localDate: selected,
                              );
                          await ref.read(replanRemindersProvider)();
                        },
                        onLongPress: () => _showActions(
                          context,
                          ref,
                          h,
                          selected,
                          status,
                          editable,
                        ),
                        onOpen: () => context.push('/habits/${h.id}'),
                      );
                    },
                  ),
                ),
                if (notToday.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      t.screenPadding,
                      t.spaceXl,
                      t.screenPadding,
                      t.spaceHuge,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: t.hairline),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            'Not today · ${notToday.length}',
                            style: theme.titleMedium?.copyWith(
                              color: t.textSecondary,
                            ),
                          ),
                          children: [
                            for (var i = 0; i < notToday.length; i++)
                              HabitTile(
                                habit: notToday[i],
                                status: null,
                                stats: ref
                                    .watch(habitStatsProvider(notToday[i].id))
                                    .value,
                                dimmed: true,
                                last: i == notToday.length - 1,
                                onToggle: () {},
                                onLongPress: () {},
                                onOpen: () =>
                                    context.push('/habits/${notToday[i].id}'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(child: SizedBox(height: t.spaceHuge)),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
    String date,
    CheckInStatus? status,
    bool editable,
  ) async {
    if (!editable) return;
    final t = context.tokens;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.surface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(t.radiusLg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Skip today'),
                subtitle: const Text('Your streak stays intact'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(checkInRepositoryProvider).setStatus(
                        habitId: habit.id,
                        localDate: date,
                        status: CheckInStatus.skipped,
                      );
                  await ref.read(replanRemindersProvider)();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Skipped. Your streak is safe.'),
                      ),
                    );
                  }
                },
              ),
              if (status != null)
                ListTile(
                  title: const Text('Mark not done'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(checkInRepositoryProvider).setStatus(
                          habitId: habit.id,
                          localDate: date,
                          status: null,
                        );
                    await ref.read(replanRemindersProvider)();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Marked not done.')),
                      );
                    }
                  },
                ),
              ListTile(
                title: const Text('Open habit'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/habits/${habit.id}');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

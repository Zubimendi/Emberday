import 'package:emberday/app_providers.dart';
import 'package:emberday/core/dates.dart';
import 'package:emberday/domain/models.dart';
import 'package:emberday/domain/schedule.dart';
import 'package:emberday/domain/streak_engine.dart';
import 'package:emberday/ui/painters/weekly_bars_painter.dart';
import 'package:emberday/ui/tokens.dart';
import 'package:emberday/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _rangeDays = 30;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context).textTheme;
    final habitsAsync = ref.watch(habitsStreamProvider);

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: habitsAsync.when(
          loading: () => const LoadingState(),
          error: (_, _) => ErrorState(
            onRetry: () => ref.invalidate(habitsStreamProvider),
          ),
          data: (habits) {
            if (habits.isEmpty) {
              return EmptyState(
                message:
                    'Stats appear after your first check-in. Add a habit on Today to begin.',
                actionLabel: 'Go to Today',
                onAction: () {},
              );
            }
            return FutureBuilder<_StatsView>(
              future: _compute(habits),
              builder: (context, snap) {
                if (snap.hasError) {
                  return ErrorState(onRetry: () => setState(() {}));
                }
                final data = snap.data;
                if (data == null) return const LoadingState();
                final pct = data.rate == null
                    ? null
                    : (data.rate! * 100).round();
                return ListView(
                  padding: EdgeInsets.all(t.screenPadding),
                  children: [
                    Text('Last $_rangeDays days',
                        style: theme.bodyMedium?.copyWith(color: t.textSecondary)),
                    SizedBox(height: t.spaceXs),
                    Text(
                      pct == null ? 'No data yet' : '$pct%',
                      style: theme.displayLarge,
                    ),
                    Text(
                      pct == null
                          ? 'Complete a scheduled habit to see a rate.'
                          : 'completion · ${data.totalDone} check-ins overall',
                      style: theme.bodyLarge?.copyWith(color: t.textSecondary),
                    ),
                    SizedBox(height: t.spaceXl),
                    Wrap(
                      spacing: t.spaceSm,
                      children: [7, 30, 90].map((d) {
                        final selected = _rangeDays == d;
                        return ChoiceChip(
                          label: Text('$d days'),
                          selected: selected,
                          selectedColor: t.primary.withValues(alpha: 0.16),
                          labelStyle: theme.labelLarge?.copyWith(
                            color: selected ? t.primary : t.textSecondary,
                          ),
                          side: BorderSide(color: t.hairline),
                          onSelected: (_) => setState(() => _rangeDays = d),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: t.spaceXl),
                    Text(
                      'This week',
                      style: theme.labelLarge?.copyWith(color: t.textFaint),
                    ),
                    SizedBox(height: t.spaceMd),
                    SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: WeeklyBarsPainter(
                          values: data.weeklyBars,
                          barColor: t.surfaceMuted,
                          highlightColor: t.primary,
                          highlightIndex: data.weeklyBars.length - 1,
                        ),
                      ),
                    ),
                    SizedBox(height: t.spaceXxl),
                    Text(
                      'Longest streaks',
                      style: theme.labelLarge?.copyWith(color: t.textFaint),
                    ),
                    SizedBox(height: t.spaceSm),
                    ...data.best.asMap().entries.map((e) {
                      final b = e.value;
                      final last = e.key == data.best.length - 1;
                      return Container(
                        constraints: const BoxConstraints(minHeight: 60),
                        padding: EdgeInsets.symmetric(vertical: t.spaceMd),
                        decoration: BoxDecoration(
                          border: last
                              ? null
                              : Border(bottom: BorderSide(color: t.hairline)),
                        ),
                        child: Row(
                          children: [
                            Text(b.habit.icon,
                                style: const TextStyle(fontSize: 22)),
                            SizedBox(width: t.spaceMd),
                            Expanded(
                              child: Text(b.habit.name, style: theme.titleLarge),
                            ),
                            Text(
                              '${b.streak}',
                              style: theme.labelSmall?.copyWith(color: t.flame),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<_StatsView> _compute(List<Habit> habits) async {
    final clock = ref.read(clockProvider);
    final settings = ref.read(settingsRepositoryProvider);
    final checkIns = ref.read(checkInRepositoryProvider);
    final rollover = await settings.rolloverHours();
    final today = effectiveLocalDate(clock.now(), rollover);
    final start = addDaysYmd(today, -(_rangeDays - 1));

    var totalDone = 0;
    var scheduled = 0;
    var done = 0;
    final best = <({Habit habit, int streak})>[];

    for (final h in habits) {
      final map = await checkIns.mapForHabit(h.id);
      final stats = computeStats(
        schedule: h.schedule,
        startDate: h.startDate,
        checkIns: map,
        referenceDate: today,
      );
      best.add((habit: h, streak: stats.currentStreak));
      totalDone += stats.totalDone;

      var d = start;
      while (daysBetween(today, d) <= 0) {
        if (daysBetween(d, h.startDate) <= 0) {
          final c = classifyDay(
            schedule: h.schedule,
            startDate: h.startDate,
            date: d,
            referenceDate: today,
            checkIns: map,
          );
          if (c == DayClass.done) {
            done++;
            scheduled++;
          } else if (c == DayClass.missed || c == DayClass.pending) {
            scheduled++;
          }
        }
        d = addDaysYmd(d, 1);
      }
    }

    best.sort((a, b) => b.streak.compareTo(a.streak));

    final bars = <double>[];
    for (var i = 6; i >= 0; i--) {
      final day = addDaysYmd(today, -i);
      var daySched = 0;
      var dayDone = 0;
      for (final h in habits) {
        final map = await checkIns.mapForHabit(h.id);
        if (daysBetween(day, h.startDate) > 0) continue;
        if (!isScheduledOn(h.schedule, parseLocalDate(day)) &&
            h.schedule is! WeeklyTarget) {
          continue;
        }
        daySched++;
        if (map[day] == CheckInStatus.done) dayDone++;
      }
      bars.add(daySched == 0 ? 0 : dayDone / daySched);
    }

    return _StatsView(
      totalDone: totalDone,
      rate: scheduled == 0 ? null : done / scheduled,
      weeklyBars: bars,
      best: best.take(5).toList(),
    );
  }
}

class _StatsView {
  _StatsView({
    required this.totalDone,
    required this.rate,
    required this.weeklyBars,
    required this.best,
  });
  final int totalDone;
  final double? rate;
  final List<double> weeklyBars;
  final List<({Habit habit, int streak})> best;
}

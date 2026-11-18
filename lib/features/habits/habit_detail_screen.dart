import 'package:emberday/app_providers.dart';
import 'package:emberday/core/dates.dart';
import 'package:emberday/domain/models.dart';
import 'package:emberday/domain/schedule.dart';
import 'package:emberday/domain/streak_engine.dart';
import 'package:emberday/ui/painters/heatmap_painter.dart';
import 'package:emberday/ui/tokens.dart';
import 'package:emberday/ui/widgets/streak_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final habitAsync =
        ref.watch(habitRepositoryProvider).watchHabit(widget.habitId);
    final statsAsync = ref.watch(habitStatsProvider(widget.habitId));
    final historyAsync =
        ref.watch(checkInRepositoryProvider).watchForHabit(widget.habitId);

    return StreamBuilder<Habit?>(
      stream: habitAsync,
      builder: (context, snap) {
        final habit = snap.data;
        if (habit == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final stats = statsAsync.value;
        return Scaffold(
          backgroundColor: t.bg,
          appBar: AppBar(
            title: Text(habit.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    context.push('/habits/${habit.id}/edit'),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  final repo = ref.read(habitRepositoryProvider);
                  if (v == 'archive') {
                    await repo.archive(habit.id);
                    if (context.mounted) context.pop();
                  } else if (v == 'delete') {
                    await repo.softDelete(habit.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Habit removed. Undo'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () async {
                              // Soft-delete undo is limited; recreate note.
                            },
                          ),
                        ),
                      );
                      context.pop();
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'archive', child: Text('Archive')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.all(t.screenPadding),
            children: [
              Row(
                children: [
                  Text(habit.icon, style: const TextStyle(fontSize: 40)),
                  SizedBox(width: t.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scheduleSummary(habit.schedule),
                          style: TextStyle(color: t.textSecondary),
                        ),
                        SizedBox(height: t.space8),
                        Row(
                          children: [
                            StreakBadge(count: stats?.currentStreak ?? 0),
                            SizedBox(width: t.space16),
                            Text(
                              'Best ${stats?.bestStreak ?? 0}',
                              style: TextStyle(color: t.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: t.space24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatChip(
                    label: '30-day',
                    value: stats?.completionRate30 == null
                        ? 'No data yet'
                        : '${(stats!.completionRate30! * 100).round()}%',
                  ),
                  _StatChip(
                    label: 'Total',
                    value: '${stats?.totalDone ?? 0}',
                  ),
                  _StatChip(
                    label: 'Since',
                    value: habit.startDate,
                  ),
                ],
              ),
              SizedBox(height: t.space24),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      _month = DateTime(_month.year, _month.month - 1);
                    }),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy').format(_month),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: t.text,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _month = DateTime(_month.year, _month.month + 1);
                    }),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              SizedBox(height: t.space8),
              StreamBuilder<List<CheckIn>>(
                stream: historyAsync,
                builder: (context, histSnap) {
                  final map = <String, CheckInStatus>{
                    for (final c in histSnap.data ?? <CheckIn>[])
                      c.localDate: c.status,
                  };
                  final settings =
                      ref.watch(settingsMapProvider).value ?? {};
                  final rollover =
                      int.tryParse(settings['rollover_hours'] ?? '0') ?? 0;
                  final today = effectiveLocalDate(
                    ref.read(clockProvider).now(),
                    rollover,
                  );
                  final cells = _monthCells(
                    habit: habit,
                    month: _month,
                    checkIns: map,
                    today: today,
                  );
                  final doneCount = cells
                      .where((c) => c == DayClass.done)
                      .length;
                  final scheduledCount = cells
                      .where(
                        (c) =>
                            c == DayClass.done ||
                            c == DayClass.missed ||
                            c == DayClass.skipped ||
                            c == DayClass.pending,
                      )
                      .length;
                  return Semantics(
                    label:
                        '${DateFormat('MMMM').format(_month)}: $doneCount of $scheduledCount scheduled days done',
                    child: SizedBox(
                      height: 180,
                      child: GestureDetector(
                        onTapUp: (details) async {
                          final box =
                              context.findRenderObject() as RenderBox?;
                          if (box == null) return;
                          // Simple cell hit via index
                          final local = details.localPosition;
                          final col = (local.dx / (box.size.width / 7))
                              .floor()
                              .clamp(0, 6);
                          final row = (local.dy / (180 / 6)).floor();
                          final idx = row * 7 + col;
                          final dates = _monthDates(_month);
                          if (idx < 0 || idx >= dates.length) return;
                          final ymd = dates[idx];
                          if (ymd == null) return;
                          if (daysBetween(today, ymd) > 0) return;
                          if (daysBetween(ymd, habit.startDate) > 0) return;
                          await _editCell(habit.id, ymd, map[ymd]);
                        },
                        child: CustomPaint(
                          painter: HeatmapPainter(
                            cells: cells,
                            doneColor: t.habitColor(habit.colorKey),
                            missedColor: t.textSecondary,
                            skippedColor: t.skipped,
                            emptyColor: t.border,
                            futureColor: t.border,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: t.space24),
              Text(
                'History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: t.text,
                ),
              ),
              SizedBox(height: t.space8),
              StreamBuilder<List<CheckIn>>(
                stream: historyAsync,
                builder: (context, histSnap) {
                  final items = histSnap.data ?? [];
                  if (items.isEmpty) {
                    return Text(
                      'Check in today to start your streak.',
                      style: TextStyle(color: t.textSecondary),
                    );
                  }
                  return Column(
                    children: items.take(30).map((c) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(c.localDate),
                        subtitle: c.note == null ? null : Text(c.note!),
                        trailing: Text(
                          c.status == CheckInStatus.done
                              ? 'Done'
                              : 'Skipped',
                          style: TextStyle(
                            color: c.status == CheckInStatus.done
                                ? t.success
                                : t.skipped,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editCell(
    String habitId,
    String ymd,
    CheckInStatus? current,
  ) async {
    final t = context.tokens;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Mark done'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(checkInRepositoryProvider).setStatus(
                      habitId: habitId,
                      localDate: ymd,
                      status: CheckInStatus.done,
                    );
                await ref.read(replanRemindersProvider)();
              },
            ),
            ListTile(
              title: const Text('Skip'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(checkInRepositoryProvider).setStatus(
                      habitId: habitId,
                      localDate: ymd,
                      status: CheckInStatus.skipped,
                    );
                await ref.read(replanRemindersProvider)();
              },
            ),
            if (current != null)
              ListTile(
                title: const Text('Clear'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(checkInRepositoryProvider).setStatus(
                        habitId: habitId,
                        localDate: ymd,
                        status: null,
                      );
                  await ref.read(replanRemindersProvider)();
                },
              ),
          ],
        ),
      ),
    );
  }

  List<String?> _monthDates(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final startPad = first.weekday - 1;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final list = <String?>[];
    for (var i = 0; i < startPad; i++) {
      list.add(null);
    }
    for (var d = 1; d <= daysInMonth; d++) {
      list.add(formatLocalDate(DateTime(month.year, month.month, d)));
    }
    while (list.length % 7 != 0) {
      list.add(null);
    }
    return list;
  }

  List<DayClass?> _monthCells({
    required Habit habit,
    required DateTime month,
    required Map<String, CheckInStatus> checkIns,
    required String today,
  }) {
    return _monthDates(month).map((ymd) {
      if (ymd == null) return null;
      if (daysBetween(today, ymd) > 0) return DayClass.neutral;
      return classifyDay(
        schedule: habit.schedule,
        startDate: habit.startDate,
        date: ymd,
        referenceDate: today,
        checkIns: checkIns,
      );
    }).toList();
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: t.textSecondary)),
        SizedBox(height: t.space4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w600, color: t.text),
        ),
      ],
    );
  }
}

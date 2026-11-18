import 'package:emberday/domain/models.dart';
import 'package:emberday/domain/schedule.dart';
import 'package:emberday/ui/tokens.dart';
import 'package:emberday/ui/widgets/check_circle.dart';
import 'package:emberday/ui/widgets/press.dart';
import 'package:emberday/ui/widgets/streak_badge.dart';
import 'package:flutter/material.dart';

/// Habit row: hairline separation, no pastel cards.
class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.status,
    required this.stats,
    required this.onToggle,
    required this.onLongPress,
    required this.onOpen,
    this.enabled = true,
    this.dimmed = false,
    this.atRisk = false,
    this.last = false,
  });

  final Habit habit;
  final CheckInStatus? status;
  final StreakStats? stats;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;
  final VoidCallback onOpen;
  final bool enabled;
  final bool dimmed;
  final bool atRisk;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context).textTheme;
    final label = switch (status) {
      CheckInStatus.done => '${habit.name}, done',
      CheckInStatus.skipped => '${habit.name}, skipped',
      _ => '${habit.name}, not done',
    };

    return Opacity(
      opacity: dimmed ? 0.45 : 1,
      child: Press(
        onPressed: onOpen,
        onLongPress: onLongPress,
        scaleTo: 0.99,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: EdgeInsets.symmetric(vertical: t.spaceMd),
          decoration: BoxDecoration(
            border: last
                ? null
                : Border(bottom: BorderSide(color: t.hairline)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.habitTint(habit.colorKey),
                  borderRadius: BorderRadius.circular(t.radiusSm),
                ),
                child: Text(habit.icon, style: const TextStyle(fontSize: 22)),
              ),
              SizedBox(width: t.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleLarge?.copyWith(color: t.text),
                    ),
                    SizedBox(height: t.spaceXxs),
                    Text(
                      scheduleSummary(habit.schedule),
                      style: theme.bodyMedium?.copyWith(color: t.textSecondary),
                    ),
                  ],
                ),
              ),
              StreakBadge(
                count: stats?.currentStreak ?? 0,
                atRisk: atRisk,
              ),
              SizedBox(width: t.spaceSm),
              if (!dimmed)
                CheckCircle(
                  status: status,
                  label: label,
                  onTap: onToggle,
                  enabled: enabled,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

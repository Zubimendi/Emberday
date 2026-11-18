import 'package:emberday/app_providers.dart';
import 'package:emberday/domain/schedule.dart';
import 'package:emberday/ui/tokens.dart';
import 'package:emberday/ui/widgets/empty_state.dart';
import 'package:emberday/ui/widgets/streak_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final theme = Theme.of(context).textTheme;
    final habitsAsync = ref.watch(allHabitsStreamProvider);

    return Scaffold(
      backgroundColor: t.bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: t.primary,
        foregroundColor: t.onPrimary,
        elevation: 2,
        onPressed: () => context.push('/habits/add'),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: habitsAsync.when(
          loading: () => const LoadingState(),
          error: (_, _) => ErrorState(
            onRetry: () => ref.invalidate(allHabitsStreamProvider),
          ),
          data: (habits) {
            final active = habits.where((h) => !h.isArchived).toList();
            final archived = habits.where((h) => h.isArchived).toList();
            if (habits.isEmpty) {
              return EmptyState(
                message:
                    'No habits yet. Start with one that takes under two minutes.',
                actionLabel: 'Add habit',
                onAction: () => context.push('/habits/add'),
              );
            }
            return ListView(
              padding: EdgeInsets.fromLTRB(
                t.screenPadding,
                t.spaceLg,
                t.screenPadding,
                t.spaceHuge,
              ),
              children: [
                Text('Habits', style: theme.displayMedium),
                SizedBox(height: t.spaceXs),
                Text(
                  '${active.length} active',
                  style: theme.bodyMedium?.copyWith(color: t.textSecondary),
                ),
                SizedBox(height: t.spaceXl),
                ...active.asMap().entries.map((e) {
                  final h = e.value;
                  final last = e.key == active.length - 1 && archived.isEmpty;
                  final stats = ref.watch(habitStatsProvider(h.id)).value;
                  return InkWell(
                    onTap: () => context.push('/habits/${h.id}'),
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
                              color: t.habitTint(h.colorKey),
                              borderRadius: BorderRadius.circular(t.radiusSm),
                            ),
                            child: Text(h.icon),
                          ),
                          SizedBox(width: t.spaceMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h.name, style: theme.titleLarge),
                                Text(
                                  scheduleSummary(h.schedule),
                                  style: theme.bodyMedium
                                      ?.copyWith(color: t.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          StreakBadge(count: stats?.currentStreak ?? 0),
                        ],
                      ),
                    ),
                  );
                }),
                if (archived.isNotEmpty) ...[
                  SizedBox(height: t.spaceXl),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Archived · ${archived.length}',
                      style: theme.titleMedium
                          ?.copyWith(color: t.textSecondary),
                    ),
                    children: archived
                        .map(
                          (h) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(h.name),
                            onTap: () => context.push('/habits/${h.id}'),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

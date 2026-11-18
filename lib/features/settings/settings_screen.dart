import 'dart:convert';

import 'package:emberday/app_providers.dart';
import 'package:emberday/core/dates.dart';
import 'package:emberday/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final theme = Theme.of(context).textTheme;
    final settings = ref.watch(settingsMapProvider).value ?? {};
    final rollover = int.tryParse(settings['rollover_hours'] ?? '0') ?? 0;
    final themeMode = settings['theme'] ?? 'system';
    final hideNames = settings['hide_names'] == 'true';
    final clock = ref.watch(clockProvider);
    final previewDate = effectiveLocalDate(clock.now(), rollover);
    final previewLabel =
        DateFormat('EEEE').format(parseLocalDate(previewDate));

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(t.screenPadding),
          children: [
            Text('Settings', style: theme.displayMedium),
            SizedBox(height: t.spaceXxl),
            Text('DAY', style: theme.labelLarge?.copyWith(color: t.textFaint)),
            SizedBox(height: t.spaceSm),
            Text(
              rollover == 0 ? 'Starts at midnight' : 'Starts at $rollover:00',
              style: theme.titleLarge,
            ),
            Slider(
              value: rollover.toDouble(),
              min: 0,
              max: 6,
              divisions: 6,
              activeColor: t.primary,
              onChanged: (v) async {
                await ref
                    .read(settingsRepositoryProvider)
                    .set('rollover_hours', v.round().toString());
                await ref
                    .read(habitRepositoryProvider)
                    .recomputeAllIfDateChanged();
              },
            ),
            Text(
              'Right now it counts as $previewLabel.',
              style: theme.bodyMedium?.copyWith(color: t.textSecondary),
            ),
            SizedBox(height: t.spaceXxl),
            Text('LOOK', style: theme.labelLarge?.copyWith(color: t.textFaint)),
            SizedBox(height: t.spaceMd),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'system', label: Text('System')),
                ButtonSegment(value: 'light', label: Text('Light')),
                ButtonSegment(value: 'dark', label: Text('Dark')),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) async {
                await ref
                    .read(settingsRepositoryProvider)
                    .set('theme', s.first);
              },
            ),
            SizedBox(height: t.spaceXl),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Hide habit names in notifications',
                  style: theme.titleMedium),
              subtitle: Text(
                'Lock screen shows “Time for your habit”',
                style: theme.bodyMedium?.copyWith(color: t.textSecondary),
              ),
              value: hideNames,
              activeThumbColor: t.primary,
              onChanged: (v) async {
                await ref
                    .read(settingsRepositoryProvider)
                    .set('hide_names', v.toString());
                await ref.read(replanRemindersProvider)();
              },
            ),
            Divider(color: t.hairline),
            _LinkRow(
              title: 'Reminders help',
              onTap: () => context.push('/settings/reminders'),
            ),
            _LinkRow(
              title: 'Account and sync',
              onTap: () => context.push('/settings/account'),
            ),
            _LinkRow(
              title: 'Export JSON',
              onTap: () => _export(ref),
            ),
            SizedBox(height: t.spaceXl),
            Text(
              'Emberday · honest streaks on your phone',
              style: theme.bodyMedium?.copyWith(color: t.textFaint),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final habits = await db.select(db.habits).get();
    final checkIns = await db.select(db.checkIns).get();
    final payload = {
      'schema_version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'habits': habits
          .map((h) => {
                'id': h.id,
                'name': h.name,
                'icon': h.icon,
                'color_key': h.colorKey,
                'schedule_type': h.scheduleType,
                'weekdays_mask': h.weekdaysMask,
                'weekly_target': h.weeklyTarget,
                'start_date': h.startDate,
              })
          .toList(),
      'check_ins': checkIns
          .where((c) => c.deletedAt == null)
          .map((c) => {
                'id': c.id,
                'habit_id': c.habitId,
                'local_date': c.localDate,
                'status': c.status,
                'note': c.note,
              })
          .toList(),
    };
    await SharePlus.instance.share(
      ShareParams(text: jsonEncode(payload), subject: 'Emberday export'),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: theme.titleMedium),
      trailing: Icon(Icons.chevron_right, color: t.textFaint),
      onTap: onTap,
    );
  }
}

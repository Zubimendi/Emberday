import 'package:emberday/app_providers.dart';
import 'package:emberday/core/dates.dart';
import 'package:emberday/domain/models.dart';
import 'package:emberday/domain/schedule.dart';
import 'package:emberday/notifications/permissions.dart';
import 'package:emberday/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _icons = ['💧', '📖', '🚶', '🧘', '✍️', '💰', '📞', '🌙', '🏃', '🚴'];
const _colors = [
  'habit1',
  'habit2',
  'habit3',
  'habit4',
  'habit5',
  'habit6',
  'habit7',
  'habit8',
];

class HabitFormScreen extends ConsumerStatefulWidget {
  const HabitFormScreen({super.key, this.habitId});

  final String? habitId;

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  final _nameCtrl = TextEditingController();
  String _icon = _icons.first;
  String _colorKey = _colors.first;
  int _scheduleIndex = 0; // 0 daily, 1 weekdays, 2 weekly target
  int _mask = 31; // Mon-Fri
  int _weeklyTarget = 3;
  bool _reminder = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  var _loaded = false;
  Habit? _existing;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadIfNeeded() async {
    if (_loaded || widget.habitId == null) {
      _loaded = true;
      return;
    }
    _loaded = true;
    final habit = await ref
        .read(habitRepositoryProvider)
        .watchHabit(widget.habitId!)
        .first;
    if (habit == null || !mounted) return;
    setState(() {
      _existing = habit;
      _nameCtrl.text = habit.name;
      _icon = habit.icon;
      _colorKey = habit.colorKey;
      _reminder = habit.reminderEnabled;
      if (habit.reminderMinutes != null) {
        _reminderTime = TimeOfDay(
          hour: habit.reminderMinutes! ~/ 60,
          minute: habit.reminderMinutes! % 60,
        );
      }
      switch (habit.schedule) {
        case Daily():
          _scheduleIndex = 0;
        case Weekdays(:final mask):
          _scheduleIndex = 1;
          _mask = mask;
        case WeeklyTarget(:final n):
          _scheduleIndex = 2;
          _weeklyTarget = n;
      }
    });
  }

  Schedule get _schedule => switch (_scheduleIndex) {
        1 => Weekdays(_mask),
        2 => WeeklyTarget(_weeklyTarget),
        _ => const Daily(),
      };

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    if (_reminder) {
      final granted = await requestNotificationPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Reminders are off. You can turn them on in system settings.',
            ),
          ),
        );
      }
    }

    final settings = ref.read(settingsRepositoryProvider);
    final clock = ref.read(clockProvider);
    final today =
        effectiveLocalDate(clock.now(), await settings.rolloverHours());
    final minutes = _reminderTime.hour * 60 + _reminderTime.minute;
    final repo = ref.read(habitRepositoryProvider);

    if (_existing != null) {
      final scheduleChanged =
          scheduleToDb(_existing!.schedule) != scheduleToDb(_schedule);
      if (scheduleChanged && mounted) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Change schedule?'),
            content: const Text(
              'Changing the schedule recalculates past streaks.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
        if (ok != true) return;
      }
      await repo.update(
        _existing!.copyWith(
          name: name,
          icon: _icon,
          colorKey: _colorKey,
          schedule: _schedule,
          reminderEnabled: _reminder,
          reminderMinutes: _reminder ? minutes : null,
          clearReminderMinutes: !_reminder,
          reminderWeekdaysMask: weekdaysMaskFromSchedule(_schedule),
        ),
      );
    } else {
      await repo.create(
        name: name,
        icon: _icon,
        colorKey: _colorKey,
        schedule: _schedule,
        startDate: today,
        reminderEnabled: _reminder,
        reminderMinutes: _reminder ? minutes : null,
        reminderWeekdaysMask: weekdaysMaskFromSchedule(_schedule),
      );
      await settings.setOnboardingDone();
    }
    await ref.read(replanRemindersProvider)();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    _loadIfNeeded();
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        title: Text(widget.habitId == null ? 'Add habit' : 'Edit habit'),
      ),
      body: ListView(
        padding: EdgeInsets.all(t.screenPadding),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(t.radiusInput),
              ),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          SizedBox(height: t.space16),
          Text('Icon', style: TextStyle(color: t.textSecondary)),
          SizedBox(height: t.space8),
          Wrap(
            spacing: t.space8,
            children: _icons
                .map(
                  (ic) => ChoiceChip(
                    label: Text(ic),
                    selected: _icon == ic,
                    onSelected: (_) => setState(() => _icon = ic),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: t.space16),
          Text('Color', style: TextStyle(color: t.textSecondary)),
          SizedBox(height: t.space8),
          Wrap(
            spacing: t.space8,
            children: _colors
                .map(
                  (c) => GestureDetector(
                    onTap: () => setState(() => _colorKey = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: t.habitColor(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _colorKey == c ? t.text : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: t.space16),
          Text('Schedule', style: TextStyle(color: t.textSecondary)),
          SizedBox(height: t.space8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Every day')),
              ButtonSegment(value: 1, label: Text('Weekdays')),
              ButtonSegment(value: 2, label: Text('Times/week')),
            ],
            selected: {_scheduleIndex},
            onSelectionChanged: (s) =>
                setState(() => _scheduleIndex = s.first),
          ),
          if (_scheduleIndex == 1) ...[
            SizedBox(height: t.space12),
            Wrap(
              spacing: t.space8,
              children: List.generate(7, (i) {
                const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final bit = 1 << i;
                final on = (_mask & bit) != 0;
                return FilterChip(
                  label: Text(labels[i]),
                  selected: on,
                  onSelected: (v) {
                    setState(() {
                      _mask = v ? (_mask | bit) : (_mask & ~bit);
                      if (_mask == 0) _mask = bit;
                    });
                  },
                );
              }),
            ),
          ],
          if (_scheduleIndex == 2) ...[
            SizedBox(height: t.space12),
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(
                    () => _weeklyTarget = (_weeklyTarget - 1).clamp(1, 7),
                  ),
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  '$_weeklyTarget',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(
                    () => _weeklyTarget = (_weeklyTarget + 1).clamp(1, 7),
                  ),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
          SizedBox(height: t.space16),
          SwitchListTile(
            title: const Text('Reminder'),
            value: _reminder,
            onChanged: (v) => setState(() => _reminder = v),
          ),
          if (_reminder)
            ListTile(
              title: Text('Time: ${_reminderTime.format(context)}'),
              trailing: const Icon(Icons.schedule),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _reminderTime,
                );
                if (picked != null) setState(() => _reminderTime = picked);
              },
            ),
          SizedBox(height: t.space24),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: t.primary,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(t.radiusCard),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

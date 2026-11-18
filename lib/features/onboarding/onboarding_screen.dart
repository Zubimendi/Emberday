import 'package:emberday/app_providers.dart';
import 'package:emberday/core/dates.dart';
import 'package:emberday/domain/models.dart';
import 'package:emberday/ui/tokens.dart';
import 'package:emberday/ui/widgets/press.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StarterHabit {
  const StarterHabit({
    required this.name,
    required this.icon,
    required this.colorKey,
  });
  final String name;
  final String icon;
  final String colorKey;
}

const starterHabits = [
  StarterHabit(name: 'Drink water', icon: '💧', colorKey: 'habit5'),
  StarterHabit(name: 'Read', icon: '📖', colorKey: 'habit4'),
  StarterHabit(name: 'Walk', icon: '🚶', colorKey: 'habit1'),
  StarterHabit(name: 'Stretch', icon: '🧘', colorKey: 'habit7'),
  StarterHabit(name: 'Journal', icon: '✍️', colorKey: 'habit3'),
  StarterHabit(name: 'Save money', icon: '💰', colorKey: 'habit2'),
  StarterHabit(name: 'Call family', icon: '📞', colorKey: 'habit6'),
  StarterHabit(name: 'Quiet time', icon: '🌙', colorKey: 'habit8'),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _selected = <int>{0, 1}; // seeded selection — realistic, not empty
  var _busy = false;

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    final repo = ref.read(habitRepositoryProvider);
    final clock = ref.read(clockProvider);
    final settings = ref.read(settingsRepositoryProvider);
    final today =
        effectiveLocalDate(clock.now(), await settings.rolloverHours());

    for (final i in _selected) {
      final s = starterHabits[i];
      await repo.create(
        name: s.name,
        icon: s.icon,
        colorKey: s.colorKey,
        schedule: const Daily(),
        startDate: today,
      );
    }
    await settings.setOnboardingDone();
    if (mounted) context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(t.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: t.spaceLg),
              Text('Emberday', style: theme.displayMedium),
              SizedBox(height: t.spaceSm),
              Text(
                'Honest streaks that live on this phone. Pick habits that take under two minutes.',
                style: theme.bodyLarge?.copyWith(color: t.textSecondary),
              ),
              SizedBox(height: t.spaceXl),
              Expanded(
                child: ListView.separated(
                  itemCount: starterHabits.length,
                  separatorBuilder: (_, _) => Divider(height: 1, color: t.hairline),
                  itemBuilder: (context, i) {
                    final s = starterHabits[i];
                    final selected = _selected.contains(i);
                    return Press(
                      onPressed: () {
                        setState(() {
                          if (selected) {
                            _selected.remove(i);
                          } else {
                            _selected.add(i);
                          }
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: t.spaceMd),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: t.habitTint(s.colorKey),
                                borderRadius:
                                    BorderRadius.circular(t.radiusSm),
                              ),
                              child: Text(s.icon,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                            SizedBox(width: t.spaceMd),
                            Expanded(
                              child: Text(
                                s.name,
                                style: theme.titleLarge,
                              ),
                            ),
                            Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: selected ? t.primary : t.textFaint,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () async {
                  await ref
                      .read(settingsRepositoryProvider)
                      .setOnboardingDone();
                  if (context.mounted) context.go('/habits/add');
                },
                child: Text(
                  'Create my own',
                  style: theme.titleMedium?.copyWith(color: t.primary),
                ),
              ),
              SizedBox(height: t.spaceSm),
              FilledButton(
                onPressed: _busy || _selected.isEmpty ? null : _start,
                style: FilledButton.styleFrom(
                  backgroundColor: t.text,
                  foregroundColor: t.bg,
                  disabledBackgroundColor: t.surfaceMuted,
                ),
                child: Text(_busy ? 'Starting…' : 'Start with ${_selected.length}'),
              ),
              SizedBox(height: t.spaceSm),
            ],
          ),
        ),
      ),
    );
  }
}

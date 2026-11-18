import 'package:emberday/app_providers.dart';
import 'package:emberday/features/account/account_screen.dart';
import 'package:emberday/features/habits/habit_detail_screen.dart';
import 'package:emberday/features/habits/habit_form_screen.dart';
import 'package:emberday/features/habits/habits_screen.dart';
import 'package:emberday/features/onboarding/onboarding_screen.dart';
import 'package:emberday/features/settings/reminders_help_screen.dart';
import 'package:emberday/features/settings/settings_screen.dart';
import 'package:emberday/features/stats/stats_screen.dart';
import 'package:emberday/features/today/today_screen.dart';
import 'package:emberday/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingDone = ref.watch(onboardingDoneProvider);

  return GoRouter(
    initialLocation: onboardingDone ? '/today' : '/onboarding',
    redirect: (context, state) {
      final onOnboarding = state.uri.path == '/onboarding';
      if (!onboardingDone && !onOnboarding) return '/onboarding';
      if (onboardingDone && onOnboarding) return '/today';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _TabShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (_, __) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/habits',
                builder: (_, __) => const HabitsScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (_, __) => const HabitFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => HabitDetailScreen(
                      habitId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (_, state) => HabitFormScreen(
                          habitId: state.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (_, __) => const StatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'reminders',
                    builder: (_, __) => const RemindersHelpScreen(),
                  ),
                  GoRoute(
                    path: 'account',
                    builder: (_, __) => const AccountScreen(),
                  ),
                  GoRoute(
                    path: 'sync',
                    builder: (_, __) => const SyncCenterScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _TabShell extends StatelessWidget {
  const _TabShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        backgroundColor: t.surface,
        indicatorColor: t.primary.withValues(alpha: 0.14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: navigationShell.goBranch,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.today_outlined, color: t.textFaint),
            selectedIcon: Icon(Icons.today, color: t.primary),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined, color: t.textFaint),
            selectedIcon: Icon(Icons.checklist, color: t.primary),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined, color: t.textFaint),
            selectedIcon: Icon(Icons.insights, color: t.primary),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: t.textFaint),
            selectedIcon: Icon(Icons.settings, color: t.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

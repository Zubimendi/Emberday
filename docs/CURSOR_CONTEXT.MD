# Emberday: Agent Context (Cursor)

Read this file, `docs/architecture.md`, `docs/prd.md` and `docs/design.md` before writing code. Work one task at a time from section 12. After each task, stop, summarize what changed, and wait for the next instruction.

## 1. Project snapshot

Emberday is a local-first habit tracker. Flutter (Dart 3), Riverpod, Drift (SQLite). Streaks are computed by a pure engine and cached per habit. Reminders use a pure planner and a thin scheduler. An optional account syncs through a custom outbox to PocketBase. No paid services, no analytics SDKs.

The React Native projects (Hearthlist, Pennywick) used the same sync design. You cannot see that code; implement sync from `docs/architecture.md` section 8.

## 2. Non-negotiable rules

1. **Time is injected.** Never call `DateTime.now()` outside `lib/core/clock.dart`. All logic takes a `Clock` (or a `DateTime now` argument for pure functions).
2. **Dates are local calendar strings** (`YYYY-MM-DD`). Never derive a check-in's day from UTC. The effective date is `localDate(now - rolloverHours)`.
3. **Pure domain logic.** `streak_engine.dart`, `schedule.dart` and `notification_planner.dart` have no Flutter, Drift or platform imports.
4. UI code never touches the network, the database or the notification plugin directly. It uses providers and repositories.
5. Every repository write that changes habits or check-ins runs in **one Drift transaction**: entity change, stats recompute for the affected habit, and (if signed in) an outbox row. Reminder replanning is called after the transaction commits.
6. UI reads via Drift streams exposed through Riverpod providers. No fetching in widgets.
7. Tokens live in `flutter_secure_storage` only.
8. No new dependency without a one-line justification and my approval.
9. No raw colors, spacing or font sizes in widgets; use the theme extension tokens.
10. No `dynamic`. No `// ignore` without an explanatory comment and my approval. Enable strict analysis (`strict-casts`, `strict-inference`, `strict-raw-types`).
11. Minimal diffs when editing existing files; do not rewrite whole files or reformat unrelated code.
12. Do not invent package APIs. If unsure, read the installed package source or docs and say what you checked. Versions change; verify with `flutter pub add` and the package README.
13. Never log habit names, notes or emails. Log ids and error classes only.
14. No silent TODOs. State anything deferred in your summary.

## 3. Tech stack and install policy

- Flutter stable, Dart 3 (sealed classes, records, pattern matching)
- State: `flutter_riverpod` (manual providers; no `riverpod_generator`)
- Data: `drift`, `drift_flutter` (or `sqlite3_flutter_libs` and `path_provider`), dev: `drift_dev`, `build_runner`
- Navigation: `go_router` with a shell route for the tab bar
- Notifications: `flutter_local_notifications`, `timezone`, `flutter_timezone`
- Background: `workmanager`
- Network and storage: `pocketbase`, `flutter_secure_storage`, `connectivity_plus`
- Utilities: `crypto` (SHA-256 for deterministic IDs), `intl`, `share_plus`, `path_provider`
- Tests: `flutter_test`, `mocktail`
- Lints: `flutter_lints` plus strict analysis options
- Platform setup (follow each package's README, verify): Android 13+ notification permission, boot receiver for scheduled notifications, core library desugaring if the notification plugin requires it, WorkManager initialization; iOS background task identifiers in Info.plist and AppDelegate

## 4. Folder structure

```text
lib/
  main.dart, app.dart                 startup, router, theme
  core/                               clock.dart, ids.dart, logger.dart, result.dart, errors.dart, dates.dart
  domain/
    models.dart                       Habit, CheckIn, Schedule (sealed), StreakStats
    schedule.dart                     isScheduled, weekKey helpers
    streak_engine.dart                computeStats(...)
    notification_planner.dart         planReminders(...)
  data/
    db/                               app_database.dart, tables.dart, daos
    repositories/                     habit_repository.dart, check_in_repository.dart, settings_repository.dart, outbox_repository.dart
    sync/                             engine.dart, push.dart, pull.dart, backoff.dart, merge.dart, status.dart
    api/                              pb_client.dart, auth.dart, error_mapper.dart
  notifications/                      scheduler.dart, channels.dart, permissions.dart
  background/                         callback_dispatcher.dart, tasks.dart
  features/                           today/, habits/, stats/, settings/, onboarding/, account/
  ui/                                 theme.dart, tokens.dart, widgets/, painters/
test/
backend/
docs/
```

## 5. Domain rules (specify exactly; see architecture section 5)

- Habit schedule (sealed): `Daily`, `Weekdays(mask)` with Mon=1..Sun=7, `WeeklyTarget(n)` with n 1..7. Weeks run Monday to Sunday.
- Check-in status: `done` or `skipped`, at most one per (habit, date).
- Dates before `startDate` are ignored. Future dates cannot be checked in.
- Day-based schedules (daily, weekdays): a scheduled day is `done`, `skipped` (neutral), `missed` (past, no check-in) or `pending` (today, no check-in). Unscheduled days are neutral.
- Current streak counts consecutive `done` scheduled days going back from the reference day; skipped and unscheduled days are skipped over without counting; a `missed` scheduled day ends the run. Today pending does not break the streak. If today is scheduled and done, today counts.
- Best streak is the longest run under the same rules over the whole history.
- Weekly target: a week is `met` if `done` count is at least n. Current streak counts consecutive met weeks ending at the latest completed week, plus the current week if already met. The current week unmet is pending. The first week (containing `startDate`) is neutral unless met.
- 30-day completion rate (day-based): `done / (scheduled non-skipped days)` over the last 30 effective days, ignoring days before start; weekly target: weeks met over the last 12 weeks.
- Changing a schedule recalculates all history (warn in the UI).

## 6. Reminders rules

- `planReminders(habits, checkIns, now, rolloverHours, horizonDays: 7, cap: 60, hideNames)` returns a list of planned notifications (id, habitId, fireAt, title, body). It is pure.
- For each habit with reminders on and each day in the horizon: include if the habit is scheduled that day (weekly-target habits: every day the reminder weekdays allow), the fire time is after `now`, and the day is not already `done` or `skipped`.
- Sort by `fireAt`, keep the first `cap`.
- Notification ID: 31-bit integer from SHA-256 of `habitId|YYYY-MM-DD`; same inputs yield the same ID.
- Copy: names shown "Time for: {name}", hidden "Time for your habit". No guilt wording.
- `NotificationScheduler.apply(plan)`: cancel this app's pending notifications, then schedule each with `zonedSchedule` using inexact scheduling that allows while idle (verify the parameter name in the installed version). Do not request exact alarm permission.
- Replan after: habit create, edit or delete, check-in change, settings change, app start, app resume, boot (via top-up on next open), background task.
- Request notification permission only when the user first turns on a reminder.

## 7. Background rules

- `workmanager` periodic task (every 6 hours target; Android minimum is 15 minutes) runs `topUp()`: open its own database connection, read habits and check-ins, replan, apply; then, if signed in and online, run one sync pass.
- Background code must not use Riverpod providers or Flutter UI. It builds its own small dependency set.
- Tasks must be short and idempotent. Return success even when there is nothing to do.
- iOS background refresh is best effort; the app also replans on resume.

## 8. Sync rules (only when signed in)

- Entities: habit, check_in. One LWW timestamp (`updated_at`, integer ms from `Clock`) per record.
- Outbox: coalesce before drain (create+updates becomes one create; create+delete for an unsynced entity drops both; updates+delete becomes delete). Order: habits before check-ins.
- Retryable (network, timeout, 5xx, 429): backoff base 2 s, factor 2, jitter plus or minus 20%, cap 5 minutes; stop the drain to preserve order. Permanent (400, 403, 422): park the op and continue. 401: refresh once, then flag "needs sign-in", keep local use intact. 409 `stale_write`: fetch the server record, apply, drop the op. Duplicate create: GET and treat as success. Delete 404: success.
- Pull `updated >= cursor`, sorted `updated,id`, 200 per page, idempotent apply. Skip records with pending outbox ops. After a page, recompute stats for affected habits and replan reminders.
- Check-in IDs are deterministic: `ci` + first 13 hex chars of SHA-256(`habitId:YYYY-MM-DD`).
- Account guard: store `sync_owner_id`; signing in as a different user prompts "Replace local data or cancel".
- Start the engine after the first frame, never during startup initialization.

## 9. Error handling rules

- Use `Result<T, AppError>` in repositories and API wrappers.
- Map errors to: `network`, `transient`, `auth`, `forbidden`, `validation`, `conflict`, `notFound`, `local`, `unknown`.
- UI never shows raw exception text; use microcopy from `docs/design.md`.
- Wrap the app in a global error handler (`FlutterError.onError`, `PlatformDispatcher.instance.onError`) that logs and shows a fallback, plus route-level error widgets.
- Local database failure shows a recovery screen with Restart; never auto-delete data.

## 10. UI rules

- Follow `docs/design.md`: tokens, 48 dp targets (check circles 52 dp), tabular digits for counts, calm copy.
- Every tappable has `Semantics` (label, role, state such as `checked`). Respect `MediaQuery.disableAnimations`.
- Use `ListView.builder`, `const` constructors, `RepaintBoundary` around the heatmap and progress ring.
- Painters (heatmap, weekly bars, ring) must not allocate per frame; cache geometry.
- Use `HapticFeedback` from the framework; no extra haptics package.

## 11. Testing rules

- Domain first, before UI: `streak_engine_test.dart` (table-driven: daily, weekdays, weekly target, skips, missed, today pending, backfill, start date, rollover, month and year boundaries, leap day), `notification_planner_test.dart` (cap, past times, done and skipped days, weekday masks, ID stability).
- Repository tests with an in-memory Drift database (verify it runs under `flutter test` on the host).
- A stats consistency test: random sequences of check-in operations, assert cached stats equal recomputation.
- Sync engine integration tests with a fake server and injected failures (network, 500, 429, 401, 409, duplicate create, crash between success and outbox delete).
- Widget tests: Today toggle, skip via long press, empty state.
- Run `flutter analyze` and `flutter test` before declaring a task done.

## 12. Build order

Each task is done only when its acceptance check passes.

| Task | Work | Acceptance |
|---|---|---|
| T1 | Scaffold Flutter app, strict analysis, folder structure, go_router shell with four tabs | App boots on emulator; analyze passes |
| T2 | Theme tokens (light and dark `ThemeExtension`), base widgets | Both themes render; no raw literals |
| T3 | `Clock`, `ids`, `dates` (effective date with rollover), `logger`, `errors`, `Result` with tests | Tests pass |
| T4 | Domain models and `schedule.dart` with tests | Tests pass |
| T5 | `streak_engine.dart` with the full rule table | At least 40 cases pass |
| T6 | Drift schema, database, migrations; seed settings | DB created on first launch |
| T7 | Repositories with transactional writes and stats recompute | Consistency test passes |
| T8 | Onboarding with starter habit templates | First launch creates chosen habits |
| T9 | Today screen: date strip, habit tiles, check, uncheck, skip, backfill | Works in airplane mode |
| T10 | Add and edit habit, archive and delete with undo | All three schedule types work |
| T11 | Habit detail with heatmap painter and history | Tapping past cells edits and updates streaks |
| T12 | Stats screen with weekly bars painter | Numbers match engine output |
| T13 | Settings: day starts at, theme, hide names | Rollover test passes manually (1 AM check-in) |
| T14 | `notification_planner.dart` with tests | Tests pass |
| T15 | Scheduler, permission flow, channels, replan triggers | Test reminder fires on a real device; completing a habit cancels today's reminder |
| T16 | Reminders help screen with scheduled count and 10 s test | Count matches planner output |
| T17 | Background task and top-up | Task runs on device (log or help-screen status) |
| T18 | Backend: collections, rules, hooks, migrations | Cross-user access rejected (manual) |
| T19 | PocketBase client, secure-storage auth, optional sign in, owner guard | Different-account prompt works |
| T20 | Outbox, coalescing, backoff, push (port the design in section 8) | Integration tests pass |
| T21 | Pull and merge with stats and reminder replan | Second device shows identical data |
| T22 | Sync chip and sync center | All states reachable |
| T23 | JSON export | Share sheet opens with valid JSON |
| T24 | Error handlers, accessibility pass, empty states | Screen reader and 200% text checks pass |
| T25 | Dev tools (demo data, clock override, test reminder); profile-mode measurements | Budgets recorded in `story.md` |
| T26 | README, scripts, docs sync | New clone runs from README alone |

## 13. Definition of done (every task)

- Acceptance check passes
- `flutter analyze` and `flutter test` green
- No new dependency without approval
- No raw literals in UI; Semantics present
- Summary lists files changed, decisions made, and anything deferred

## 14. Stop and ask when

- A requirement conflicts with a package's actual behavior
- A new dependency seems necessary
- The data model would need to change
- Background isolate database access does not work as planned

## 15. Starter prompts

> "Read cursorcontext.md, architecture.md, prd.md and design.md. Do T1 only. Stop when its acceptance check passes and summarize."

> "Do T5. Before coding, list every rule case you will test (by schedule type) and show the table, then implement the engine to pass it."
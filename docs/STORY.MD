# Emberday: Story

## The problem

Building a habit is mostly about showing up on ordinary days, and most tools punish the days that are not ordinary. A night-shift worker checks in at 1 AM and the app counts it for tomorrow. Someone travels, loses signal and the streak resets. A tracker wants an account before it will let you add "drink water". A reminder fires at the wrong time, or never, because the phone's battery manager killed the app.

None of that is a motivation problem. It is an engineering problem, and it is solvable with clear rules and a local-first design.

## Who it's for

- **The routine builder:** wants a quick daily check-in and a streak that is fair.
- **The irregular schedule:** shift workers, students with changing timetables and travellers who need skip days, weekday-only habits and a day that ends when they say it does.

(Validation note, fill in after talking to 3 people: what they use today, why they stopped, what broke their last streak.)

## Honest framing

Habit trackers are one of the most crowded app categories, and this one does not try to out-feature the incumbents. It is a vehicle for demonstrating engineering you can feel: a streak engine whose rules are written down and tested, reminders that survive platform limits, background work that tops up a schedule, and an app that is fully useful offline with no account. I say that plainly in interviews.

## What I set out to prove

1. I can specify tricky domain logic (streaks across schedule types, skips, backfill, day rollover) as a pure function and test it exhaustively.
2. I can keep cached stats consistent with their source rows by writing both in one transaction.
3. I can schedule reminders reliably under real platform constraints (the iOS limit on pending local notifications, Android battery managers) by separating planning from applying.
4. I can run background work safely, including opening the database from a background isolate.
5. I treat time as a dependency: an injected clock, local dates and a configurable day start, so tests never depend on the real time.
6. I can make an account optional and still deliver sync as a bonus.

## Key decisions

| Decision | Why |
|---|---|
| Check-ins keyed by (habit, local date) | A habit can only be done once per day; local dates avoid UTC mistakes |
| Day-starts-at setting (rollover hour) | Night-owls' late check-ins belong to the day they feel like |
| Skipped is a status, neutral to streaks | Honest and forgiving: neither counted as done nor as a miss |
| Streaks computed by a pure function, cached per habit | Testable rules, instant UI |
| Rolling 7-day reminder window with a global cap | Works within the iOS pending notification limit; lets a completed day cancel its own reminder |
| Planner and scheduler are separate | The planner is pure and fully testable; the scheduler is thin platform glue |
| Inexact reminder scheduling | Avoids the exact alarm permission; habit nudges do not need to-the-second accuracy |
| No streak-loss notifications | Ethical engagement: reminders only when the user asked for them |
| Deterministic check-in IDs | Two devices checking in the same day merge into one record |
| Optional account, outbox sync | Time-to-value and privacy first; same proven pattern as my previous projects |
| Riverpod without code generation | Fewer moving parts under a two-day deadline; Drift already needs build_runner |

## What happened (fill in after the build)

- Built in: ~1 day focused implementation from docs to runnable Flutter app
- Measured on [device] in profile mode: cold start __ ms; Today scroll with 50 habits __ fps; release APK size per ABI __ MB (record after `flutter build apk --release --split-per-abi`)
- Streak engine: 28+ table-driven cases across daily, weekday, weekly-target, skips, backfill, month/year/leap edges
- Reminder test: planner unit-tested (cap, masks, cancel-on-done); 24-hour device test still to record
- Bugs worth telling: Drift vs domain `Habit` name clash; Riverpod 3 dropped `valueOrNull` / moved `StateProvider` to legacy; `flutter_local_notifications` named-only `zonedSchedule`
- What I would change: extract Drift row types behind a DAO layer to avoid model name clashes; add schedule history instead of recalculating past streaks on edit

## What I'd do next

Numeric goals, JSON import, a home-screen widget, skip reasons, and moving the backend to Go or Python on Postgres with the same push and pull protocol.

## Interview pitch (2 minutes)

"Emberday is a habit tracker built around fair, explainable streaks. Check-ins are rows keyed by habit and local date, with a configurable day start so a 1 AM check-in counts for the right day. Streak logic lives in a pure Dart function with table-driven tests for daily, weekday and weekly-target schedules, skips and backfill. Reminders are split into a pure planner that picks the next 7 days of notifications under the iOS 64-notification limit and a thin scheduler that applies the plan, so completing a habit today cancels today's reminder. A WorkManager task tops the schedule up in the background. Everything works offline with no account, and if the user signs in, an outbox pushes changes to PocketBase with idempotent, deterministic IDs."

## Likely deep-dive questions

| Question | Short answer |
|---|---|
| How are streaks defined? | Consecutive scheduled days that are done. Skipped and unscheduled days are neutral. A scheduled day in the past with no check-in breaks the streak. Today pending does not break it. Weekly-target habits count consecutive weeks that meet the target. |
| Why local dates instead of timestamps? | A check-in belongs to the user's calendar day. Storing instants would move entries when the timezone changes or at DST edges. |
| What is day rollover? | A setting that shifts the day boundary (for example 3 AM). The effective date is the date of (now minus rollover hours). |
| Why not schedule repeating notifications? | You cannot cancel a single occurrence, so a reminder would still fire after you had done the habit. A rolling window of individual notifications fixes that. |
| What is the notification limit problem? | iOS keeps only a limited number of pending local notifications (64). The planner sorts by fire time and caps the list, then the next top-up extends it. |
| What about phones that kill background apps? | There is no code fix; the app re-plans on every open, runs a periodic task, and the help screen walks users through the battery settings. I say that honestly. |
| How do you test time? | An injected `Clock` everywhere, so tests set "now", timezone and rollover explicitly. |
| How does background work reach the database? | The background isolate opens its own connection to the same SQLite file (WAL mode). I verify concurrent access and keep background tasks short and idempotent. |
| What happens when the schedule changes? | Streaks are derived from the current schedule, so past streaks are recalculated. The UI warns first. A versioned schedule history is the upgrade path. |
| Conflicts in sync? | Last-write-wins per record with a clamped client timestamp; check-in IDs are deterministic so concurrent same-day check-ins merge. |
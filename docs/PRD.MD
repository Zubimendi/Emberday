# Emberday: Product Requirements Document

| Field | Value |
|---|---|
| Owner | Francis Offiong |
| Status | Draft v1 |
| Track | Mobile portfolio, Week 2, Project 3 |
| Stack | Flutter (Dart 3) |
| Build window | Tue 17 Nov to Wed 18 Nov 2026 |
| Target ship | Wed 18 Nov 2026, 11 PM (hard stop) |

## 1. Summary

Emberday is a habit tracker with honest, documented streak rules. It works fully offline with no account. Users create habits on flexible schedules, check in with one tap, skip days without breaking streaks, and get reminders that cancel themselves once the habit is done. An optional account backs up and syncs data.

## 2. Problem

Habit trackers often break streaks for reasons unrelated to motivation (travel, night shifts, lost signal), force an account before any value, and send reminders that fire late, never, or after the habit is already done. (Validate with 3 people before or during the build.)

## 3. Users

| Persona | Needs |
|---|---|
| Routine builder | Fast daily check-in, fair streak, simple reminders |
| Irregular schedule | Weekday-only and weekly-target habits, skip days, custom day start |

## 4. Goals and non-goals

**Goals**
- G1. Check in with one tap in under 1 second of UI time
- G2. Streak rules are explicit, tested and explainable
- G3. Reminders are reliable within platform limits and cancel when the habit is done
- G4. All core features work offline with no account
- G5. Optional account syncs without loss or duplication
- G6. Smooth on a low-end Android phone

**Non-goals**
- Social features, leaderboards, public profiles
- Streak-loss or guilt notifications
- Numeric goals, home-screen widgets, import (roadmap)
- Wearable support, Web or desktop targets
- Encryption at rest

## 5. Scope and priorities

| Priority | Items |
|---|---|
| **P0** (must ship, fully local) | Onboarding with starter habits; create, edit, archive, delete habits with 3 schedule types; Today with check, uncheck, skip and 7-day backfill; streak engine (current, best, 30-day rate) with tests; habit detail with month heatmap; basic Stats; day-starts-at setting; reminders via planner and scheduler with contextual permission, reboot-safe, and the help screen; empty and error states; docs |
| **P1** (should ship) | Periodic background task to top up reminders (and sync); optional account with outbox push, pull and sync chip; hide names in notifications; JSON export; dark theme; haptics; undo toasts |
| **P2** (if time allows) | Dev demo-data loader and dev clock override; skip notes; sync center details; numeric goals (stretch) |

**Cut order if behind schedule:** sync center details, then JSON export, then dark theme, then background sync (keep the reminder top-up), then account sync. If account sync is cut, say so in Known limitations; local-only ships on its own.

## 6. User stories and acceptance criteria

| ID | Story | Acceptance criteria | Pri |
|---|---|---|---|
| US-01 | As a new user, I can start without an account | First launch shows starter habits; no signup or permission prompt | P0 |
| US-02 | I can create a habit | Name (required), icon, color, schedule (every day, weekdays, N per week), start date; appears on Today when scheduled | P0 |
| US-03 | I can edit, archive and delete habits | Edit saves; archive hides from Today but keeps history; delete shows undo toast | P0 |
| US-04 | I can check in with one tap | Tap toggles done instantly with haptic; works offline; ring updates | P0 |
| US-05 | I can skip a day | Long press, Skip; the day shows dashed; streak neither extends nor breaks | P0 |
| US-06 | I can backfill the last 7 days | Date strip selects a past day; toggling works; dates before start or in the future are disabled | P0 |
| US-07 | I can edit older days from the heatmap | Tap a past cell to toggle or skip; streaks recalculate | P0 |
| US-08 | Streaks follow the documented rules | Table-driven tests cover each rule in architecture section 5 | P0 |
| US-09 | I can see current streak, best streak and 30-day rate | Shown on Today tiles and habit detail; numbers match tests | P0 |
| US-10 | I can see a heatmap | Month view with done, skipped, missed, not scheduled and future cells; text alternative provided | P0 |
| US-11 | I can see overall stats | Range chips (7, 30, 90); completion rate; weekly bars; best habits | P0 |
| US-12 | I can set when my day starts | 0 to 6 AM; preview line; a 1 AM check-in with 3 AM rollover counts for the previous day | P0 |
| US-13 | I can set reminders | Time, weekdays; permission asked only when first enabled; denied state explained | P0 |
| US-14 | Reminders cancel when I have done the habit | Completing or skipping a habit removes today's pending reminder for it | P0 |
| US-15 | Reminders stay scheduled | Planner keeps the next 7 days within the cap; reschedules on app open, on boot and after changes | P0 |
| US-16 | I can troubleshoot reminders | Help screen with checklist, scheduled count, and a 10-second test reminder | P0 |
| US-17 | Reminders respect privacy | Setting hides habit names in notification text | P1 |
| US-18 | Background top-up works | Periodic task re-plans reminders without opening the app (Android; best effort on iOS) | P1 |
| US-19 | I can use dark theme | System, light, dark; applies instantly | P1 |
| US-20 | I can export my data | JSON file with schema version through the share sheet | P1 |
| US-21 | I can sign in to back up and sync | Optional; local data uploads; chip shows state; app stays fully usable without it | P1 |
| US-22 | Sync is safe | Killing the app mid-sync loses nothing; retries use backoff; same-day check-ins on two devices merge | P1 |
| US-23 | Accounts never mix silently | Signing in as a different account than the local data's owner prompts to replace or cancel | P1 |
| US-24 | The app is accessible | Semantics labels and states, 48 dp targets, 200% text scale, reduce motion | P0 |
| US-25 | I can demo with fictional data and a dev clock | Dev-only tools absent from release builds | P2 |

## 7. Functional requirements

- FR-1. Every read comes from local SQLite via Drift streams; no screen blocks on the network
- FR-2. Check-ins are unique per (habit, local date); toggling creates, updates or soft-deletes the row
- FR-3. The effective date uses `Clock.now()` minus the rollover hours, in local time
- FR-4. Every check-in or habit write recomputes that habit's cached stats and replans reminders in the same flow
- FR-5. Reminder plan: next 7 days, capped at 60 pending notifications, skipping days already done or skipped and times in the past
- FR-6. Notification IDs are deterministic from (habit, date); apply the plan by cancelling this app's pending notifications and scheduling the new set
- FR-7. Sync is opt-in; when signed in, each write also inserts an outbox row in the same transaction
- FR-8. Client generates IDs; check-in IDs are deterministic from (habit, date)
- FR-9. Deletes are soft (tombstones)
- FR-10. Tokens are stored in secure storage
- FR-11. API rules restrict each user to their own records

## 8. Non-functional requirements

| Area | Requirement (targets, measure in profile or release mode on a low-end Android phone) |
|---|---|
| Startup | Cold start to first interactive frame under 2 s |
| Interaction | Check-in reflected in UI under 100 ms |
| Frames | Under 1% of frames over budget while scrolling Today with 50 habits |
| Size | Release APK (per ABI) under 30 MB |
| Correctness | Streak engine and planner tests pass; cache equals recomputation |
| Offline | All P0 flows pass in airplane mode |
| Reminders | Over a 24-hour test on a real phone, scheduled reminders fire within 15 minutes of their time (document phone model and battery settings) |
| Security | Token in secure storage; owner-scoped API rules; no secrets in repo |
| Privacy | No analytics SDKs; option to hide names in notifications; no data leaves the phone unless the user signs in |
| Accessibility | WCAG AA contrast targets; Semantics labels; 200% text scale |

## 9. Success criteria

- [ ] Streak engine passes the full rule table (at least 40 cases) including month, year and rollover edges
- [ ] Notification planner tests pass (cap, skipping done days, past times, weekday masks)
- [ ] 24-hour reminder test recorded in `story.md`
- [ ] Airplane-mode test: 20 offline check-ins sync with 0 lost and 0 duplicated (if sync ships)
- [ ] Performance budgets measured and recorded
- [ ] All seven docs complete and the demo recorded

## 10. Schedule

| When | Work | Done when |
|---|---|---|
| Tue midday | Docs complete, SDK check | `cursorcontext.md` ready for the agent |
| Tue PM | Scaffold, theme, Drift schema, core utilities, streak engine with tests, repositories with stats recompute | T1 to T6 pass |
| Tue evening | Onboarding, Today, check-in, skip, backfill, add and edit habit | Fully usable offline, single device |
| Wed AM | Habit detail with heatmap, Stats, day-start setting, planner, scheduler, permissions, help screen | All P0 stories pass |
| Wed midday | Background task, backend, auth, outbox push and pull, sync chip | Two devices converge |
| Wed PM | Dark theme, export, accessibility pass, performance measurements, docs, demo | Everything recorded |
| Wed 11 PM | **Hard stop.** Unfinished items go to Known limitations | Shipped |

Thursday morning is not a buffer; Tickwalk starts Thursday.

## 11. Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Flutter and Dart are a stack switch from Week 1 | Slower start | Keep the dependency set small; no code generation except Drift |
| Streak edge cases | Wrong numbers, lost credibility | Rules written first, table-driven tests before any UI |
| Notification plugin setup (permissions, boot receiver, desugaring) | Hours lost | Follow the plugin README exactly; test on a real device early on Tuesday evening |
| Background isolate cannot open the database | P1 slips | Keep the task a thin call into a function that opens its own connection; if it fails, cut background sync and keep top-up on app open |
| Dart port of sync takes longer than planned | Sync slips | It is P1 and last in the build order; local-only ships alone |
| OEM battery managers drop reminders | Reminder test fails | Document phone and settings; help screen; do not promise exact delivery |
| Timezone package initialization mistakes | Reminders fire at the wrong time | Initialize with the device's timezone name at startup; test with a timezone change |

## 12. Assumptions and open questions

- Assumption: under 50 active habits and under 5 years of history per user
- Assumption: Mon to Sun weeks (Monday start), matching the Pennywick convention
- Question: should the weekly-target week start be configurable? (MVP: no)
- Question: should skips have a monthly limit? (MVP: no limit)

## 13. Future

Numeric goals, JSON import, home-screen widget, skip reasons, versioned schedule history, backend move to Go or Python with Postgres.
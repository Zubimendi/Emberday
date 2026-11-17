# Emberday: Demo Guide

## Goals

- A 90 to 120 second recorded demo for the README and portfolio
- A 5 minute live version for interviews
- Prove three things: fair streak rules, reminders that cancel when you are done, and full offline use with no account

## Setup (the evening before)

| Item | Detail |
|---|---|
| Demo data | A dev-only "Load demo data" action (Settings, developer section, absent from release builds) that creates 5 habits with about 90 days of realistic history, including a skip, a missed day and a weekday-only habit |
| Dev clock | A dev-only date override so you can show rollover and "tomorrow" without waiting |
| Test reminder | The "Send a test reminder in 10 seconds" button on the reminders help screen |
| Backend | PocketBase running and reachable, only for the sync segment |
| Recording | Android built-in recorder or `adb shell screenrecord`; iOS Simulator (Mac only): `xcrun simctl io booted recordVideo demo.mp4` |
| Cleanup | Notifications cleared, battery above 50%, clean wallpaper |

Demo data must be clearly fictional.

## 90 second script

| Time | Screen | Action | Voiceover |
|---|---|---|---|
| 0:00 | Today | Show list, ring and streak flames | "Emberday is a habit tracker with honest streaks that live on the phone." |
| 0:08 | Today | Tap a check circle | "One tap, haptic and a ring update." |
| 0:14 | Today | Long press a habit, choose Skip | "Skipping a day keeps the streak safe, and it is neutral: it does not count as done." |
| 0:24 | Habit detail | Show heatmap and best streak | "The heatmap shows done, skipped and missed days. Streak rules are written down and tested." |
| 0:36 | Habit detail | Tap an old missed cell, mark done | "Backfill is easy, and the streak recalculates instantly." |
| 0:46 | Settings | Show Day starts at 3 AM, preview line | "Night owls can set the day to start at 3 AM, so a 1 AM check-in counts for the right day." |
| 0:56 | Reminders help | Tap test reminder, lock the screen, show notification | "Reminders come from a planned rolling schedule." |
| 1:08 | Today | Check in the habit, show that its pending reminder is gone | "When I complete the habit, today's reminder is cancelled." |
| 1:18 | Phone | Airplane mode, check in | "No signal and no account needed." |
| 1:28 | Close | Show the repo and architecture doc | "Pure streak engine, notification planner and local-first data." |

## Rules demo (live version)

1. Weekday-only habit (Mon, Wed, Fri): show that Tuesday is "not scheduled" and does not break the streak.
2. Daily habit: leave a day unchecked in the past, show the streak resets there and the best streak is kept.
3. Weekly-target habit (3 per week): show a week meeting the target counted as a streak week.
4. Use the dev clock to show today pending is "at risk" but not broken.

## Reminder demo (live version)

1. Open the reminder help screen and show "14 reminders scheduled over the next 7 days".
2. Fire the test reminder and show the lock-screen notification (names hidden if the setting is on).
3. Explain the planner and the 64-notification limit in 30 seconds.

## Sync segment (optional)

1. Settings, Account, sign in on device A and show Up to date.
2. Sign in on device B and show the first pull with skeletons, then identical habits and history.
3. Check in on A and show it appear on B after a sync.

## Shots to capture for the README

1. Today (light)
2. Habit detail with heatmap
3. Stats
4. Reminder help screen
5. Dark theme Today
6. Add habit with the schedule picker

## Turning the recording into a GIF

```bash
ffmpeg -i demo.mp4 -vf "fps=12,scale=360:-1:flags=lanczos" -loop 0 demo.gif
```

Keep the GIF under about 8 MB; keep the full MP4 for the portfolio site.

## Pre-demo checklist

- [ ] Demo data loaded and verified fictional
- [ ] Notification permission granted and test reminder works
- [ ] Airplane mode toggle tested
- [ ] Backend reachable (if showing sync)
- [ ] Notifications cleared, battery above 50%
- [ ] 10 second test recording done
- [ ] Fallback video ready

## If something breaks live

Say what you expect, show the reminders help screen (it reports what is scheduled), and switch to the recorded demo. Interviewers care more about how you reason about failure than a perfect run.
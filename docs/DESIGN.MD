# Emberday: Design

## 1. Design goals

1. **Checking in is the whole job.** One tap on Today, with instant, satisfying feedback.
2. **Honest and calm.** Streaks follow visible rules. No guilt, no loss-aversion tricks, no nagging notifications.
3. **Forgiving.** Skipping a day is a first-class action, not a failure. Backfill is easy.
4. **Private.** Habit names can be personal; notifications can hide them.
5. **Light on low-end phones.** No images, custom painters instead of chart packages, minimal animation cost.

## 2. Patterns replicated from top apps

| Pattern | Seen in | How Emberday uses it | Why it works |
|---|---|---|---|
| Streak flame with a clear number | Duolingo | Flame and count on each habit and in the Today header | Makes consistency visible at a glance |
| Streak protection | Duolingo | Skip day: neutral, never breaks or extends the streak | Life happens; protection keeps people coming back |
| Progress rings | Apple Fitness | Today ring shows "3 of 5 done" | Gives the day a finish line |
| Tap to complete, long press for options | Streaks (iOS habit app) | Tap the circle to check in; long press to skip or add a note | Fast primary action, secondary actions nearby |
| Contribution heatmap | GitHub | Month heatmap on habit detail | Shows consistency over time without numbers |
| Checkbox haptic and fill animation | Todoist, Things | Light haptic and 150 ms fill on check-in | Confirms the tap registered |
| Contextual permission request | Best-practice mobile onboarding | Notification permission asked only when the first reminder is set | Higher grant rates, less friction |
| Undo toast instead of confirm | Gmail | Delete habit or check-in shows "Removed. Undo" | Faster and recoverable |
| Empty states with a first action | Polished apps | Empty Today offers starter habits | Avoids a blank screen |
| Skeletons only where the network is unavoidable | Instagram | Only during the first pull after signing in on a new device | Local reads are instant |

## 3. Design tokens

All colors are targets; confirm contrast with a checker before release. Expose tokens through a `ThemeExtension` so widgets never use raw colors.

### Color (light)

| Token | Hex | Use | Approx. contrast |
|---|---|---|---|
| `bg` | `#F5F5F4` | Screen background | n/a |
| `surface` | `#FFFFFF` | Cards, sheets | n/a |
| `text` | `#1C1917` | Primary text | about 15:1 on bg |
| `textSecondary` | `#57534E` | Secondary text | about 6.5:1 on bg |
| `primary` | `#B93815` | Buttons, active states | about 5.8:1 with white text |
| `primaryPressed` | `#962C10` | Pressed | higher |
| `flame` | `#B45309` | Streak flame and count on light | about 5:1 on white |
| `success` | `#15803D` | Completed state | about 5:1 on white |
| `skipped` | `#78716C` | Skipped state | about 4.8:1 on white |
| `danger` | `#B91C1C` | Destructive actions | about 6.5:1 on white |
| `border` | `#E7E5E4` | Dividers | decorative |

### Color (dark)

| Token | Hex |
|---|---|
| `bg` | `#12100E` |
| `surface` | `#1C1917` |
| `text` | `#F5F5F4` |
| `textSecondary` | `#A8A29E` |
| `primary` | `#FB923C` (use `#12100E` text on it) |
| `flame` | `#FBBF24` |
| `success` / `skipped` / `danger` | `#4ADE80` / `#A8A29E` / `#F87171` |
| `border` | `#2B2623` |

### Habit colors

Eight fixed hues (`habit1` to `habit8`, light and dark variants) used for habit icons and heatmap tint. Every habit also has an icon and a name, so color is never the only cue.

### Typography (system fonts)

| Style | Size / line height | Weight |
|---|---|---|
| Streak number | 32 / 36 | Bold, tabular digits |
| Title | 28 / 34 | Bold |
| Heading | 20 / 26 | Semibold |
| Body | 16 / 22 | Regular |
| Label | 14 / 20 | Medium |
| Caption | 13 / 18 | Regular |

Must hold at 200% text scale: habit names wrap to two lines, then truncate.

### Spacing, shape, motion

| Token | Value |
|---|---|
| Spacing scale | 4, 8, 12, 16, 24, 32 |
| Screen horizontal padding | 16 |
| Minimum touch target | 48 x 48 (check circle at least 52 x 52) |
| Radius | 16 (cards), 12 (inputs), 999 (chips) |
| Motion | 150 ms check fill, 200 ms layout, 250 ms sheets, ease-out |

## 4. Information architecture

```text
Onboarding (first run): Welcome and starter habits
Main tabs
  Today  (date strip, habit list)
  Habits (list of all habits)
    Habit detail (streaks, heatmap, history)
      Edit habit
  Stats
  Settings
    Reminders and help
    Account and sync (sign in, sync center)
    Data (export JSON)
Add habit (modal from Habits or Today empty state)
```

Rules: four tabs, every screen within 3 taps, back always pops one level.

## 5. Screen specifications

### S1. Onboarding
- One screen: short pitch, a grid of 8 starter habit templates (multi-select), "Create my own" link, "Start" button. No account prompt, no permission prompt.
- Templates: Drink water, Read, Walk, Stretch, Journal, Save money, Call family, Quiet time.
- Lands on Today with the chosen habits.

### S2. Today
- Header: greeting-free, shows the date and a progress ring ("3 of 5")
- Date strip: last 7 days (tap to view or edit that day); today selected by default
- Habit list for the selected day: icon, name, streak flame with count, check circle (52 dp)
- Interactions: tap circle toggles done (haptic, fill animation); long press opens menu (Skip today, Add note, Open habit); swipe is not used
- States: scheduled today, done, skipped (dashed circle with a dash icon), not scheduled today (shown dimmed in a collapsed "Not today" section), future days not editable
- "At risk" cue: for a habit with a streak that is pending today, the flame is outlined; no notification is sent for this
- Empty state: "No habits yet. Start with one that takes under two minutes." with starter chips

```text
+------------------------------------------+
| Tue 17 Nov                    (3 of 5)   |
| M  T  W  T  F  S  S                      |
|   [17]                                   |
+------------------------------------------+
| (o) Drink water                  12 flame|
| (v) Read 10 pages                 4 flame|
| (-) Walk 20 minutes (skipped)     9 flame|
| (o) Journal                       0      |
+------------------------------------------+
| NOT TODAY (2)                         v  |
+------------------------------------------+
| Today   Habits   Stats   Settings        |
+------------------------------------------+
```

### S3. Habits
- List of all habits with schedule summary ("Mon, Wed, Fri" or "3 times a week") and current streak
- Reorder by drag; archived habits in a collapsed section
- FAB: Add habit

### S4. Habit detail
- Header: icon, name, schedule, flame with current streak, best streak
- Stats row: 30-day completion rate, total done, since date
- Month heatmap with previous and next month arrows; cell states: done (filled), skipped (dash), missed (outlined dot), not scheduled (empty), future (faint); tap a past cell to toggle or skip
- History list of recent check-ins with notes
- Menu: Edit, Archive, Delete (with undo)
- Empty (new habit): "Check in today to start your streak."

### S5. Add and edit habit
- Name (required), icon and color pickers, schedule type segmented control (Every day, Weekdays, Times per week)
- Weekday chips (Mon to Sun) or a stepper (1 to 7)
- Reminder: switch, time picker, weekday chips (defaults to the schedule)
- Start date (defaults to today)
- Warning on schedule change when history exists: "Changing the schedule recalculates past streaks."
- Notification permission is requested here, only when the user turns a reminder on

### S6. Stats
- Range chips: 7 days, 30 days, 90 days
- Completion rate for the range, weekly completion bars (custom painter), best habits list, longest current streaks
- Empty: "Stats appear after your first check-in."

### S7. Settings
- Day starts at (0 to 6 AM, with a plain-language explanation and a preview line "Right now it counts as Tuesday")
- Theme (system, light, dark)
- Reminders: permission status, Hide habit names in notifications, "Reminders not arriving?" help
- Account and sync, Data export, About

### S8. Reminders help
- Explains in plain language why some phones delay reminders, with a checklist: allow notifications, allow the app to run in the background, set battery to unrestricted, lock the app in recents (on phones that support it). Includes a "Send a test reminder in 10 seconds" button and a status line ("Last scheduled: 14 reminders over the next 7 days").

### S9. Account and sync
- Optional sign in or sign up; copy: "Optional. Your habits stay on this phone unless you sign in."
- Sync status and a sync center with waiting and failed changes

## 6. Widget inventory

`AppScaffold`, `ProgressRing`, `DateStrip`, `HabitTile`, `CheckCircle`, `StreakBadge`, `Heatmap` (CustomPainter), `WeeklyBars` (CustomPainter), `HabitIconPicker`, `ColorPicker`, `WeekdayChips`, `EmptyState`, `Toast` (SnackBar with action), `BottomSheet`, `Skeleton`, `ErrorFallback`. All take tokens from the theme extension; no raw colors or magic numbers.

## 7. Check-in states

| State | Visual | Semantics label |
|---|---|---|
| Pending | Empty circle | "Drink water, not done" |
| Done | Filled circle with check | "Drink water, done" |
| Skipped | Dashed circle with dash | "Drink water, skipped" |
| Not scheduled | Dimmed, no circle | "Drink water, not scheduled today" |

Never color alone: each state has a distinct shape.

## 8. Motion and haptics

- Check fill 150 ms with `HapticFeedback.lightImpact`; skipped uses a selection click
- Ring animates 250 ms to the new value
- Respect `MediaQuery.disableAnimations` (reduce motion): replace with instant state changes
- No animation on first build of a list

## 9. Accessibility

- Every tappable has `Semantics` with label, role and state (`checked` for check circles)
- Minimum 48 dp targets (check circles 52 dp), 8 dp spacing
- Contrast at least 4.5:1 for text, 3:1 for graphics
- Layout holds at 200% text scale
- Heatmap exposes a text alternative: "November: 18 of 22 scheduled days done"
- Long-press actions also available in the habit detail menu

## 10. Microcopy

| Situation | Copy |
|---|---|
| Empty Today | "No habits yet. Start with one that takes under two minutes." |
| Skip | "Skipped. Your streak is safe." |
| Check-in undone | "Marked not done." |
| Delete habit | "Habit removed. Undo" |
| Reminder body (names shown) | "Time for: Drink water" |
| Reminder body (names hidden) | "Time for your habit" |
| Permission denied | "Reminders are off. You can turn them on in system settings." |
| Day start preview | "Right now it counts as Tuesday." |
| Schedule change warning | "Changing the schedule recalculates past streaks." |
| Different account | "This phone has data from another account. Replace it with this account's data, or cancel?" |

Tone: short, calm, plain. No exclamation marks, no guilt, no streak-loss threats.

## 11. Low-end device considerations

- System fonts, no image assets beyond the app icon
- `ListView.builder` for lists, `const` widgets where possible, `RepaintBoundary` around the heatmap and ring
- Painters cache geometry; no per-frame allocations
- Defer notification planning, background registration and sync boot until after the first frame
- Profile on a phone with 3 GB RAM or less in profile mode
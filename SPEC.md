# Nim for Garmin

A family of Connect IQ (Garmin) apps with the visual identity of Nim, a minimalist Android launcher written in Kotlin. Language: Monkey C, using the Connect IQ SDK, the Monkey C extension for VS Code, and the simulator.

## Visual identity (applies to every app)

- Text only. No icons, graphics, or decoration.
- Text is centered horizontally.
- Hierarchy comes only from size and shade of gray:
  - primary: #F1EFE8, large font
  - secondary: #B4B2A9, small font
  - tertiary: #888780, small font
  - dimmed: #5F5E5A
- Black background (#000000).
- The only color is the alert orange (#D85A30), used only when it matters (for example, low battery).
- All positions are calculated from `dc.getWidth()` / `dc.getHeight()`, never hard-coded in pixels, so they work at every resolution.

## Phase 1: watch face (start here)

Three-line layout, centered horizontally and vertically:

1. Time, prominent: `18:34`. Large font, primary color. Follows the 12h/24h setting.
2. Date: `mon, 9 nov` (pt-BR: `seg, 9 nov`). Small font, secondary color. Abbreviated weekday, day, and abbreviated month, lowercase, in the watch's language (pt-BR and en).
3. Battery: `82%`. Just the number, no "battery" label. Small font, tertiary color. Turns orange (#D85A30) below the configured threshold.

Low-power / always-on mode (AMOLED): same layout, with dimmed text and only the time and date, updating once per minute.

Settings (in the Connect IQ phone app, via `properties.xml` / `settings.xml`):
- Show battery (on/off, default on)
- Orange battery threshold (default 20%)
- Date format (default `mon, 9 nov`)

## Phase 2: running data field

Same structure as the watch face:
1. Elapsed time: `42:18`. Large, primary color.
2. Distance: `6.2 km` (pt-BR: `6,2 km`). Small, secondary color.
3. Pace: `6:49 /km`. Small, tertiary color.

Units follow the watch settings.

## Phase 3: glance

A dimmed title line (`next`, pt-BR: `próximo`) and a main line (`19:00 meeting`). Plain text, same style.

> **Skipped for now (2026-11-11).** On API 5 watches a glance belongs to a watch app, and Connect IQ only allows the `ComplicationSubscriber` permission (needed to read the calendar) for watch faces and data fields. The calendar complication also gives only the event's time, not its title. Revisit with phase 5, when the phone can send the next event with its title.

## Phase 4: list app

A device app with a text menu. The focused item is large and in the primary color; neighboring items shrink and darken with distance. Initial items: fixed timers (1, 5, and 25 min) and a checklist. Launching other apps isn't possible (Connect IQ limitation).

> **Removed (2026-11-11).** Built twice and dropped: first with timers and a checklist (not useful day to day), then as an info list (weather, steps, body, watch status), which also didn't stick. Notes for a future attempt: other Connect IQ apps can be opened with `System.exitTo` (after a confirmation), Garmin's built-in apps can't, and a watch app on API 5 can't read the calendar complication. The timers and checklist version is in git history (`e4c8e71`); the info list was never committed.

## Phase 5: integration with Nim on the phone

The Android launcher sends a short note to the watch through the Connect IQ Mobile SDK. The watch shows `from phone` (dimmed; pt-BR: `do celular`), the note in prominent text, and a single `done` button (pt-BR: `feito`) that sends a confirmation back to the phone.

## Phase 6: breathing app (Nim Breathe)

A device app that guides a breathing session with text only.

1. A text menu (same style as the phase 4 list) with the techniques: `box` (4-4-4-4), `4-7-8` and `coherent` (5-5). It opens on the technique used last.
2. The session shows three lines: the current step (`inhale`, `hold`, `exhale`; pt-BR: `inspire`, `segure`, `expire`) in large text, the seconds left in the step, and the time left in the session.
3. The step word brightens from dimmed to primary while inhaling and darkens while exhaling. A short buzz marks each step (one to inhale, two to exhale, a faint one to hold), so it works with eyes closed.
4. The session lasts a whole number of cycles, as close as possible to the configured length. At the end: `done` (pt-BR: `pronto`), the heart rate at the start and at the end (`72 > 64`, when available) and the session length.

START pauses and resumes; BACK leaves.

Settings: session length (1, 3, 5 or 10 min, default 5) and vibrate on each step (default on).

## Phase 7: pomodoro (Nim Focus)

A device app that starts counting as soon as it opens. Three lines:

1. Time left in the phase: `24:12`. Large, primary color. Secondary while paused, orange when the phase is over and waiting.
2. Phase: `focus`, `break` or `long break` (pt-BR: `foco`, `intervalo`, `intervalo longo`). Small, secondary color.
3. Current focus block: `2 / 4`, or `paused`. Small, tertiary color.

START pauses and resumes; holding MENU opens a text menu with `skip` and `restart`. At the end of a phase the watch buzzes and, by default, the next phase starts by itself.

The app only alerts while it is open (no background service). Leaving it saves the session with the wall clock: reopening within an hour picks the countdown up where it would be, and a phase that ended while away waits in orange for START.

Settings: focus (default 25 min), break (5), long break (15), focus blocks before a long break (4), start the next phase automatically (on).

## Conventions

- One Connect IQ project per app, in a single repository (`watchface/`, `datafield/`, `breathe/`, `focus/`), with a shared style module (colors, fonts, and layout) to keep the identity consistent across them. Building blocks only device apps need (phase sequencer, text list) live in `shared/app-source/`.
- Test in the simulator on at least one small MIP screen (for example, the Instinct family or the Forerunner 255) and one large AMOLED screen (for example, the Fenix 8 or the Venu 3).

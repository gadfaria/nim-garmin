# Nim for Garmin

A family of Connect IQ (Garmin) apps with the visual identity of Nim, a minimalist Android launcher written in Kotlin. Language: Monkey C, using the Connect IQ SDK, the Monkey C extension for VS Code, and the simulator.

## Visual identity (applies to every app)

- Text only. No icons, graphics, or decoration.
- Text is left-aligned, inset from the left edge of the round screen.
- Hierarchy comes only from size and shade of gray:
  - primary: #F1EFE8, large font
  - secondary: #B4B2A9, small font
  - tertiary: #888780, small font
  - dimmed: #5F5E5A
- Black background (#000000).
- The only color is the alert orange (#D85A30), used only when it matters (for example, low battery).
- All positions are calculated from `dc.getWidth()` / `dc.getHeight()`, never hard-coded in pixels, so they work at every resolution.

## Phase 1: watch face (start here)

Three-line layout, vertically centered and left-aligned:

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

## Phase 4: list app

A device app with a text menu. The focused item is large and in the primary color; neighboring items shrink and darken with distance. Initial items: fixed timers (1, 5, and 25 min) and a checklist. Launching other apps isn't possible (Connect IQ limitation).

## Phase 5: integration with Nim on the phone

The Android launcher sends a short note to the watch through the Connect IQ Mobile SDK. The watch shows `from phone` (dimmed; pt-BR: `do celular`), the note in prominent text, and a single `done` button (pt-BR: `feito`) that sends a confirmation back to the phone.

## Conventions

- One Connect IQ project per app, in a single repository (`watchface/`, `datafield/`, `glance/`, `listapp/`), with a shared style module (colors, inset, and fonts) to keep the identity consistent across them.
- Test in the simulator on at least one small MIP screen (for example, the Instinct family or the Forerunner 255) and one large AMOLED screen (for example, the Fenix 8 or the Venu 3).

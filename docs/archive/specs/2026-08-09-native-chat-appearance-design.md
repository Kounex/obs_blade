# Native chat appearance + options sheet navigation — design

**Date:** 2026-08-09 · **Status:** approved (design) · **Process tier:** S

## Intent

Give native chat readable density controls (text size, emote size, message
spacing, optional separators) and stop the options sheet from growing into
one tall scroll of mixed toggles. Group settings behind a short root list
with drill-in pages.

## Ratified decisions

| Question | Decision |
|---|---|
| Sheet organization | **Nested drill-in** via in-sheet page swap (not nested `Navigator`, not expand/collapse) |
| Appearance preview | **Yes** — sample message row at top of Appearance page, updates live with sliders |
| Persistence | Additive Settings-box keys (same pattern as badge/emote toggles); defaults = today's hardcodes |
| Scope | Native chat list only — WebView untouched; badge size / input font out of scope |

## 1. Options sheet navigation

`NativeChatOptionsSheet` becomes stateful with an enum page:
`root | appearance | emotes | badges`.

**Root** — title “Native chat options”, three rows with trailing chevron:

| Row | Opens | Visibility |
|---|---|---|
| Appearance | Appearance page | Always (native options entry) |
| Emotes | Emotes page | Twitch only |
| Badges | Badges page | Twitch only |

Sub-pages show a leading back control (chevron + “Native chat options” or
just back) that returns to root. Same bottom-sheet dismiss (drag / barrier)
as today. No nested `Navigator`.

## 2. Appearance controls

Persisted keys (new `SettingsKeys`, string names in the existing map):

| Key | Type | Default | Range / notes |
|---|---|---|---|
| `TwitchChatTextSize` | `double` (sp) | `14` | slider 11–20 |
| `TwitchChatEmoteSize` | `double` (px) | `20` | slider 14–32 |
| `TwitchChatMessageSpacing` | `double` (px) | `4` | slider 0–12 (vertical padding per row) |
| `TwitchChatMessageSeparators` | `bool` | `false` | toggle — very thin hairline between messages |

Naming keeps the `TwitchChat*` prefix for consistency with existing chat
keys even though Appearance is shown for the native options entry generally;
today only Twitch consumes the message row.

**Appearance page layout (top → bottom):**

1. Live preview — one sample line (optional badge, colored name, text,
   sample emote) rendered with the current values.
2. Text size slider + label showing current value.
3. Emote size slider + value.
4. Message spacing slider + value.
5. Separators toggle.

Sliders use discrete-friendly steps (1.0). Writes go straight to the
Settings box on change (live), same as existing switches.

## 3. Rendering

- `TwitchChatMessageRow` reads text/emote size and vertical spacing from
  the settings box (via the list’s existing `HiveBuilder` rebuild keys, or
  an equivalent read path). Replace `_emoteSize` and the hardcoded
  vertical padding.
- Message list (`NativeTwitchChatView` / list separator) draws a hairline
  `Divider` between items when separators are on — not inside the row
  body, so tombstones/system notices stay consistent.
- Preview widget shares the same sizing inputs (can wrap a lightweight
  sample or reuse row styling) so preview and list cannot drift.

## 4. Emotes / Badges pages

Move today’s content unchanged:

- **Emotes** — third-party (7TV/BTTV) toggle.
- **Badges** — the seven visibility toggles.

## 5. Testing

- Sheet: root shows the three rows (Twitch); tapping Appearance shows
  sliders + preview; back returns to root; Emotes/Badges still toggle
  the same keys.
- Appearance: changing a slider persists the key; separators default off;
  message row / list honor text size, emote size, spacing, separators
  (widget tests with a seeded settings box).
- No persistence migration test beyond “missing key → default” (additive).

## Out of scope

- WebView chat appearance.
- Badge size slider, username color overrides, input field font.
- Per-channel appearance overrides.
- Nested `Navigator` / separate modal per section.

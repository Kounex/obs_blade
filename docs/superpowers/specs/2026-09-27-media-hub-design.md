# Media hub (soundboard) — design

**Status:** shipped 2026-09-27 (changelog "Media hub (soundboard)"). Process tier S+.

## Goal

A third dashboard surface next to Scene Items and Audio that plays media
sources in one tap while live (soundboard) and gives full transport for
every media input (hub). Scene item rows got play/pause/restart on
2026-09-26 (`e01e0fe7`), but they're one scene deep and not built for
split-second triggers.

## Decisions (user-confirmed)

| Question | Decision |
|---|---|
| Shape | One **Media** tab/card, two views: **Pads** (soundboard) and **List** (full transport). View persisted (`MediaHubViewMode`). |
| Sources | Every `ffmpeg_source` / `vlc_source` input appears automatically; the user can **hide + reorder**, saved per connection. |
| Tablet | Scene Items + Audio stay side by side; **full-width Media card below**. |
| Gating | Customisation → Features toggle `ExposeMediaHub`, **on by default, free**. |
| Scene item rows | While the hub is on, rows drop the media transport and get the lock back. Hub off → rows keep today's controls, so turning the hub off never removes media control. |

## OBS protocol

- Status: `GetMediaInputStatus` → state + duration + cursor (ms).
- Actions: `TriggerMediaInputAction` (PLAY / PAUSE / STOP / RESTART /
  NEXT / PREVIOUS), `SetMediaInputCursor` for seek.
- Events: `MediaInputPlaybackStarted/Ended`, `MediaInputActionTriggered` →
  re-read the status of tracked inputs (existing pattern).
- **Heard or not:** OBS only outputs a media source's audio while it is
  active in program. `GetSourceActive` (`videoActive`) is read per tracked
  input and re-read on `CurrentProgramSceneChanged`,
  `SceneTransitionEnded`, `SceneItemEnableStateChanged` and every input
  list reload. Pads and list rows that aren't in program are dimmed with a
  speaker-slash marker ("Not in program"). The high-volume
  `InputActiveStateChanged` subscription is deliberately not used.
- **Progress:** OBS sends no cursor events. The client extrapolates
  `cursor + (now − receivedAt)` while PLAYING (wrapped by duration for
  looping clips) and re-syncs on every media event. A ticker runs only
  while something visible is playing.

## Interaction

- **Pad tap = restart** (soundboard semantics, including on a playing pad).
  **Long press** opens the transport sheet.
- **Transport sheet** (pad long press / list row tap): play/pause, restart,
  stop, seek slider, and VLC previous/next.
- **List row:** name, time `0:12 / 0:45` or state, trailing restart +
  play/pause + stop.
- **Toolbar:** Pads | List switch, **Stop all** (stops every visible
  playing/paused input), **Arrange** (sheet with a reorderable list and a
  show/hide toggle per input).
- **Empty states:** no media inputs → how to add one, plus the
  nested-"Soundboard"-scene tip; all hidden → hint + Arrange.

## Persistence (500k users — additive only)

- No Hive type/field changes. Hide + order live in one settings entry,
  `MediaHubLayouts`: `Map<connectionKey, {hidden: [names], order: [names]}>`,
  where the key is `name:<connection name>`, falling back to
  `host:<host>` (same identity rule as `HiddenScene`). Parsing is
  defensive: a malformed entry reads as the default layout.
- `ExposeMediaHub` (bool, default true) and `MediaHubViewMode` (String,
  default `pads`) are plain settings keys with safe defaults.
- Names are OBS input names (no stable ids in the v5 subset used). A
  rename drops the entry back to default order/visible (same limitation as
  hidden scenes).

## Out of scope (later, additive)

Per-pad colours/icons, pad size setting, hotkey-style "cut" (stop
others on trigger), volume per pad (Audio tab covers it).

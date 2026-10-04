# Intro v2 — design

Date: 2026-09-27 · Status: ratified + implemented 2026-09-27 · Branch target: `master`

## Context

The current intro (`lib/views/intro/`) has two stages: Getting Started, then 5
slides. It is text-heavy (an icon tile and a paragraph per slide), its content
is outdated (pre-4.0 screenshots and copy), and the first two slides are
WebSocket setup steps behind a forced 5 s lock with swiping disabled. It does
not meet the polish of the rest of the 4.0 app.

Decided in brainstorm (2026-09-27):

- **Job: minimal welcome.** A short, polished first impression that drops the
  user on Home. It does not walk through setup.
- **OBS WebSocket setup help leaves the intro entirely.** The FAQ
  (Settings → FAQ) and the connect box's tooltips and error hints already
  cover it. The setup screenshots (`assets/images/intro/*.png`) are deleted.
- **4 screens, one flow.** Getting Started is merged into screen 1, so there
  is no two-stage flow and no "‹ Getting Started" back bar.
- **Visuals:** the welcome screen uses brand art (logo and glyph motion). The
  feature screens use **realistic, animated live UI mockups** built in code
  from real app leaves where possible. They follow light, dark and True Dark,
  and they don't go stale the way screenshots do.
- **Navigation:** free swiping, Back/Next buttons, a visible **Skip** and
  page dots. No slide lock. The lock only existed for the setup slides,
  which are gone now.
- **Re-show once to everyone:** a new seen-key, so existing users see v2 once
  after updating, as a "what's new in 4.0" moment.
- **End:** Start goes to the Home tab (as today). The manual entry from
  Settings goes back to Settings.

## Screens

| # | Name | Visual | Copy (headline · one line) |
|---|---|---|---|
| 1 | Welcome | Vortex mark turning inside sweeping accent rings, wordmark below; "Unofficial and open source · built on obs-websocket" small print with links | "Your OBS, in your pocket." · Control your streams and recordings from your phone or tablet. |
| 2 | Control everything | Dashboard mockup: scene buttons (one switches on a loop), audio meters moving, a stream/record control with LIVE pill and timer. **Morphs from the phone column to the tablet side-by-side layout** (covers "Phone + tablet") | "Your control room" · Scenes, audio, sources, stream and record, on phone and tablet. |
| 3 | Make it yours | Customisation mockup: toggles flip on (Studio Mode, Recording / Replay controls, Hotkeys), then the element list reorders (a drag in motion). Explicit pointer: **Settings → Customisation** | "Make it yours" · Turn on Studio Mode, extra controls and hotkeys, and reorder the dashboard. |
| 4 | Stats | Real `StatTile`s counting up (FPS, CPU, bitrate) plus a small past-session history strip | "Know how it went" · Live stats while you're on air, plus a history of every stream and recording. |

Copy is placeholder wording. Final wording goes through a copy pass during
implementation (same tone as the FAQ).

## Layout and behaviour

- **Phone:** the mockup fills the space above a fixed-height copy slot, so
  the visual sits at the same height on every page. The bottom bar holds
  Back, expanding dots and Next; on the last page the dots fade out and the
  button stretches into "Get started". Skip sits at the top right (it reads
  "Close" from Settings). Phones stay portrait-locked, now decided by the
  shortest side instead of the deprecated `ui.window`.
- **Tablet / landscape:** mockup and copy sit side by side
  (`ResponsiveWidgetWrapper`, same threshold as the rest of the app).
- **Motion:** mockup loops run only on the visible page, pause off-screen and
  go static under `AppMotion.reduce`. Pages use a parallax/fade page
  transition. The existing `StaggeredEntrance` is used for copy.
- **Reuse:** the mockups use the real leaves where they are state-free
  (`StatTile`, `OnAirPill`, `SceneTallyChip`, `BaseAdaptiveSwitch`,
  `DecorativeIconTile`). Store-bound widgets (scene button, audio slider)
  get state-free replicas in `intro/widgets/visuals/mock_kit.dart` that
  follow the same color contracts. Every visual is authored at a fixed
  size and scaled as a whole (`FittedBox`), and ignores the text scale.

## Persistence

- New key `SettingsKeys.HasUserSeenIntro202609` (`has-user-seen-intro-202609`)
  gates the initial route. `HasUserSeenIntro202208` is kept for history (like
  the older deprecated key) and is no longer read.
- Skip and Start both persist the new key. The manual entry from Settings
  writes nothing.
- `IntroStore` shrinks to `currentPage`. The stage and lock state are removed
  (the `.g.dart` was hand-trimmed to match; the generator would emit the same).
- `integration_test/screenshot_walk_test.dart` is updated to use the new key
  and structure.

## Out of scope

Setup help on Home (FAQ only, by decision), combined chat and Pro on the
slides, and custom illustration assets.

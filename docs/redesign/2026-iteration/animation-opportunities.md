# Animation opportunities — 2026-09 audit input

Output of the `find-animation-opportunities` advisor pass, scoped to
`lib/views/` + `lib/shared/` (read-only; proposes motion, never implements).

## Recon

- **Stack**: Flutter, MobX + GetIt. No motion packages — all animation is
  hand-rolled (design-system.md forbids Lottie/Rive), driven by
  `AnimationController`, `AnimatedSwitcher`, and implicit animated widgets.
- **Motion tokens** (`lib/shared/design/app_motion.dart`): `instant` 80ms,
  `fast` 150ms, `medium` 250ms, `slow` 400ms, `dramatic` 700ms,
  `staggerStep` 30ms / `staggerMax` 12; curves `standard` (easeOutCubic),
  `emphasized` Cubic(0.2, 0, 0, 1), `spring` (easeOutBack, press/selection
  only), `exit` (easeInCubic). Every suggestion below uses these — no ad-hoc
  values.
- **Personality**: a crisp broadcast-utility dashboard, not a playful
  consumer app. Daily-use argues for less motion; the delight budget lives in
  connect/purchase/first-run moments only.
- **Frequency map**: scene buttons, mute/visibility toggles, sliders, tab
  bar = tens-to-hundreds/day. Chat timeline = 100+/day in busy channels.
  Dialogs, sheets, toasts, settings, refresh = occasional. Intro, paywall,
  unlock, first connect = rare.

## Part 1 — Opportunities table

Ordered by leverage. Every row passed all four gate questions (frequency →
purpose → speed budget → function); the gate answers are in the columns.

| # | Location | Today | Purpose | Frequency | Suggested motion |
| --- | --- | --- | --- | --- | --- |
| 1 | `lib/shared/general/custom_expansion_tile.dart:95` (header tap), `lib/shared/general/social_block.dart:92`, `lib/views/settings/logs/log_detail/widgets/log_entry.dart:186`, `lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/native_channel_dropdown.dart:155`, `…/youtube_native_channel_dropdown.dart:98` | Bare `GestureDetector` taps with no pressed state — dead taps the design system already promised to kill ("Pressable … replaces dead GestureDetector taps", design-system.md §Motion language) | Feedback | Tens/day | Wrap in the existing `Pressable` (`lib/shared/design/pressable.dart`): scale 0.97 + opacity 0.88, press at `AppMotion.instant` (80ms) with `AppMotion.standard`, release at `AppMotion.fast` (150ms) with `AppMotion.spring`. Subtle enough for the frequency tier — that is exactly what Pressable was built for. No new code, adoption only. |
| 2 | `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart:478-514` (mirror: `native_youtube_chat_view.dart` ~:270-300) | The scroll-pause/"New messages ↓" chip pops in and out instantly on a conditional render (`if (!this._pinnedToBottom)`) | Preventing a jarring change + spatial consistency (chip is anchored to the timeline's bottom edge) | Occasional (appears when the user scrolls up, leaves on resume) | Wrap in `AnimatedSwitcher` with `duration: AppMotion.fast`, `switchInCurve: AppMotion.standard`, `switchOutCurve: AppMotion.exit`, transition = `FadeTransition` + `SlideTransition` `Tween<Offset>(begin: Offset(0, 0.25), end: Offset.zero)` (fractional offset — no hardcoded pixels). Key the chip on `_unreadWhileScrolledUp` so the label/color swap crossfades too. Chip already has `Pressable` feedback — keep. |
| 3 | `lib/views/pro/widgets/pro_unlocked.dart:61-66` | The `AnimatedResultIcon` check draws (450ms, `AppMotion.emphasized`) while the headline/body copy below it pops in unanimated — the one true celebration moment in the app is half-staged | Delight (explicitly allowed at this tier) | Rare (once per purchase/restore) | After the draw completes, stagger the remaining content: wrap headline / body / CTA in `StaggeredEntrance` with `index` 1..3 (30ms steps, `AppMotion.slow` 400ms fade + 12px rise, `AppMotion.standard`), gated to start at ~`_kDrawDuration` (450ms) so the glyph lands first. One-shot per lifecycle, never blocks interaction. |
| 4 | `lib/views/home/widgets/saved_connections/saved_connections.dart:152-224` | After a pull-to-refresh re-sorts/replaces connection cards, the list swaps with only the per-box `AnimatedSwitcher` (identity changes) — reordering itself teleports | Spatial consistency (cards moved because reachability was re-probed) | Occasional (per refresh) | On refresh completion, replay a fast stagger: key the `StaggeredEntrance` wrappers on a refresh generation counter so the new order rises in with 30ms steps (`AppMotion.staggerStep`), `AppMotion.slow`, clamped at `staggerMax`. Feel-check required — if a full replay reads as too much on repeat refreshes, drop to a single 150ms `AnimatedOpacity` settle on the list body instead. |
| 5 | `lib/views/dashboard/widgets/dashboard_content/exposed_controls/hotkeys_control/hotkey_entry.dart:48-67` | Tapping the hotkey trigger pops the sheet and fires the OBS request 500ms later with zero visible confirmation — action and effect are disconnected | Feedback | Occasional | Keep it cheap: after the pop, reuse the existing connect-flow language — a brief `BaseResult` (Positive) via `OverlayHandler.showStatusOverlay` with a short `showDuration`, so the stroke-drawn check (`AnimatedResultIcon`, 450ms, `AppMotion.emphasized`) confirms the trigger. If that reads too heavy for a repeat action, fall back to haptic-only (`HapticFeedback.lightImpact()` on fire) — but silent is the one option that fails the gate. |

Every "Suggested motion" cell animates `transform`/`opacity` (or the
existing token-driven widgets that do) and stays inside the UI budget
(≤300ms except the rare-tier celebration row, which is allowed more).

Reduced-motion note for whoever implements any row: there is currently
**no** `MediaQuery.disableAnimations` handling anywhere in `lib/` (see
`motion-audit.md`, finding A1). New motion added from this table should not
make that worse — the gentle version is fade-only (drop the rise/scale,
keep the opacity) rather than zero animation.

## Part 2 — Rejected candidates (required)

- **Native chat message insertion** (`native_twitch_chat_view.dart`,
  `native_youtube_chat_view.dart` timelines) — animating each incoming
  chat row. **Rejected: frequency gate — 100+/day in a busy channel;
  animating arrivals makes a live chat feel laggy and delayed. Never
  animate.**
- **Statistics chart data updates** (`lib/views/statistics/statistic_detail/widgets/stats_chart.dart`)
  — tweening the line when data refreshes, or replaying the draw-in.
  **Rejected: functional data the user is reading; decoration hinders.
  The existing one-shot draw-in (`AppMotion.dramatic`, `AppMotion.emphasized`)
  is the right amount.**
- **Scene-button selection fill** (`lib/shared/animator/selectable_box.dart`
  via `scene_button.dart:102-111`) — re-timing or re-curving the selection
  animation. **Rejected: settled design decision — the fill stays bound to
  the real OBS transition duration (design-system.md:24). Don't re-litigate.**
- **Tab-switch transition** (`lib/tab_base.dart:201-263`) — speeding up or
  removing the 200ms fade+scale. **Rejected: documented motion contract
  (design-system.md §Motion language); the `_TabSwitchTransition`
  implementation exists specifically to keep per-tab navigators alive.
  Frequent, but deliberate.**
- **Audio meter ballistics** (`lib/views/dashboard/widgets/dashboard_content/scene_content/audio_inputs/audio_slider.dart:145-185`)
  — spring physics on the dB fill. **Rejected: live functional telemetry;
  the current 50ms fill / 200ms peak-tick follow is already near
  imperceptible, which is correct for something updating many times per
  second.**

## Part 3 — Verdict

This interface is already close to right. The "On Air" wave landed the
structural motion (Pressable, StaggeredEntrance, the status cluster, chart
draw-in, connect-success morph), and the honest gaps that remain are small:
five dead-tap sites that predate Pressable, one popping chip, a half-staged
celebration, and one silent hotkey action. The single highest-leverage row
is **#1 (Pressable adoption)** — it's pure adoption of an existing,
design-system-mandated widget, and it closes the gap the redesign explicitly
promised to close. Hand any row to an implementer via
`improve-animations plan <suggestion>`.

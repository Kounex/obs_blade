# 4.0 iteration — current-state audit (2026-09-08)

Screenshots: `2026-iteration/before-phone/` (38 PNGs), `2026-iteration/before-tablet/`
(36 PNGs) — untracked, local. Raw inputs: `2026-iteration/*.md`.

**Theme caveat (read before using the screenshots):** the phone set was captured
on a simulator with a **custom purple theme** active (persisted user data). The
tablet set runs the **default theme** (red accent `#FF4654`, system-blue
highlight) on a fresh install. Layout/structure findings are valid on both, but
the **default-theme tablet set is the authoritative color reference** — do not
read the phone shots' near-black flat scaffold or purple accents as the shipped
look.

**Direction these findings are measured against:** the ratified 4.0 direction is
*Liquid Glass inspired* — layered translucency, specular edges, content-aware
blur, bouncier motion — evolving the existing "On Air" identity (dark broadcast
utility, 12-radius cards, hairline borders, red/blue accent split), on top of
the existing tokens (`lib/shared/design/app_motion.dart`,
`app_spacing.dart`, `app_radius.dart`). This digest names gaps; it does not
design the solutions.

## Quick wins

Small, well-scoped fixes with high felt impact — most are token/curve
corrections or adoption of widgets that already exist.

- **`FullOverlay` entrance curve** (`lib/shared/animator/full_overlay.dart:44-47`):
  blur+opacity tweens use `Curves.easeIn` on entrance — a sluggish head at
  exactly the highest-emotion moments (every connect/purchase flow). Swap to
  `AppMotion.standard` in / `AppMotion.exit` out; keep the settled spring scale
  and 250ms timing.
- **`StudioModeTransitionButton`** (`lib/views/dashboard/widgets/dashboard_content/studio_mode_transition_button.dart:37-53`):
  dashboard chrome on `Curves.easeInQuad` at an ad-hoc 200ms, plus a delayed
  fade interval. → `AppMotion.medium` + standard/exit curves.
- **Dead-tap sites → `Pressable`** (5 call sites: custom expansion tile header,
  social block, log entries, both native chat channel dropdowns): the design
  system promised this; `Pressable` already exists — adoption only, no new code.
- **Reconnect toast + translucent sliver app bar** (`reconnect_toast.dart:34-55`,
  `translucent_sliver_app_bar.dart:1165-1168`): both run 500ms, over the 300ms
  UI budget → token durations.
- **Tab re-tap scroll-to-top** (`lib/tab_base.dart:169-171`): `Curves.easeIn`
  decelerates late into the destination → `AppMotion.standard`/`medium`.
- **`Fader` defaults** (`lib/shared/animator/fader.dart:15-17`): linear curve at
  an ad-hoc 200ms on a modal entrance → `fast`/`standard`.
- **`SelectableBox` defaults** (`lib/shared/animator/selectable_box.dart:25-26,68`):
  off-token defaults (300ms fill / 50ms border). The scene-button call site
  intentionally overrides the fill with the real OBS transition duration —
  settled, don't touch; only the defaults migrate.
- **Chat scroll-pause chip** (`native_twitch_chat_view.dart:478-514`, YouTube
  mirror): pops in/out instantly on conditional render → `AnimatedSwitcher`
  fade+slide at `AppMotion.fast`, keyed so the unread-label swap crossfades.
- **Pro-unlock celebration half-staged** (`lib/views/pro/widgets/pro_unlocked.dart:61-66`):
  the check draws (450ms) while the copy pops in unanimated → stagger the
  headline/body/CTA after the draw (`StaggeredEntrance`, gated to the draw
  duration). Rare-tier delight budget, explicitly allowed.
- **Hotkey trigger is silent** (`hotkey_entry.dart:48-67`): the sheet pops and
  the OBS request fires 500ms later with zero confirmation → reuse the
  `BaseResult`/status-overlay check or haptic feedback; silent is the one
  unacceptable option.
- **Saved-connections refresh reorder teleports** (`saved_connections.dart:152-224`):
  after reachability re-probing re-sorts the cards, only identity swaps animate.
  → replay a fast stagger on refresh generation (feel-check: may need to drop
  to a single opacity settle on repeat refreshes).

## Systemic issues

- **Zero reduced-motion handling.** No `MediaQuery.disableAnimations` /
  `accessibleNavigation` handling anywhere in `lib/`. Perpetual motion
  (`StatusDot` pulse, `SupportSkeleton` breathing), entrances
  (`StaggeredEntrance`, tab switch), and the chart draw-in all ignore it. Treat
  this as **one design-module seam decision** (e.g. an
  `AppMotion.reduceMotion(context)` helper consumed by the motion primitives)
  — not per-widget fixes. The gentle target is "drop movement, keep
  opacity/color feedback," not zero animation. New motion from the Quick wins
  must not make this worse.
- **Token debt, concentrated in chat chrome.** Sweep counts (upper bounds —
  see note): **211** hardcoded colors outside `lib/shared/design`, of which
  ~62 are in `stream_chat/` alone (top hotspot:
  `chat_notice_chrome.dart` 28, then `youtube_chat_message_row.dart` 14,
  `chat_message_display.dart` 11, `native_chat_window.dart` 9); **87** ad-hoc
  `BorderRadius`; **16** ad-hoc `Curves.*`; **41** ad-hoc
  `Duration(milliseconds…)`. The durations count is an **upper bound** — it
  includes legitimate non-motion uses (timers, timeouts, poll intervals); the
  actionable motion subset is largely enumerated in `2026-iteration/motion-audit.md`.
  A Liquid-Glass-flavored pass over chat chrome can't start cleanly until these
  call sites resolve against theme slots / `AppStatusColors`.
- **Build side-effects in `ScrollRefreshIcon`**
  (`lib/views/home/widgets/refresher_app_bar/scroll_refresh_icon.dart:71-84`):
  `build()` fires haptics, mutates the store, and drives an animation
  controller — the same defect class the design system already fixed in
  `Fader`. Rebuilds can re-trigger haptics and restart animation state. Move
  the threshold-crossing logic into `didUpdateWidget`/the scroll listener.
- **Audio meter animates a layout property**
  (`audio_slider.dart:145-163`): the live dB fill is an `AnimatedContainer`
  animating **width** at 50ms — a layout pass per meter update per input.
  Swap to a clipped full-width fill or `Transform.scaleX` (compositor-only);
  the 200ms peak-tick `AnimatedPositioned` is the same class at lower cost.
- **Pre-existing functional bugs surfaced by the capture walks** (evidence:
  walk logs; not redesign items, but they block a clean "after" capture and
  should be fixed first):
  - `LateInitializationError: Field '_controller…' has already been
    initialized` + duplicate `GlobalKey` in
    `lib/shared/general/date_range/text_field_date.dart:29`, thrown while
    rebuilding the statistics date-range filter (both phone and tablet walks).
  - Hit-test miss on the "Tip Jar" settings entry (tap only landed via
    fallback).
- **Settled contracts — explicitly not findings:** scene-button selection fill
  bound to the real OBS transition duration; tab-switch 200ms fade+scale
  (navigator-preservation contract); `FullOverlay` spring scale 0.96→1.0 at
  250ms; centered modal dialogs; the stats-chart one-shot draw-in. Don't
  re-litigate these in the redesign.

## Where the 2026 feel is missing

Per screen, the concrete gap against the Liquid-Glass-inspired direction —
naming the gap only, not the design.

- **Dashboard shell** (`2026-iteration/before-tablet/52_dashboard_main.png`):
  the highest-traffic screen is entirely flat — opaque cards on an opaque
  scaffold with minimal luminance separation, static outline pills for the
  LIVE/REC cluster, and scene tiles that are plain flat squares (on the phone's
  purple theme they nearly merge into the scaffold). No layering, no
  translucency, no specular edge anywhere on the screen users live in.
  ![dashboard tablet](2026-iteration/before-tablet/52_dashboard_main.png)
- **Dashboard actions menu** (`2026-iteration/before-phone/57_dashboard_actions_menu.png`):
  a stock Cupertino action sheet — system-blue text rows on a system blur, the
  most off-identity surface in the app; nothing about it says "On Air," and
  it's the gateway to streaming/recording/replay actions.
  ![actions menu](2026-iteration/before-phone/57_dashboard_actions_menu.png)
- **Connect flow / Home** (`2026-iteration/before-phone/50_connecting_overlay.png`):
  the connecting state is a dimmed screen with a small spinner — the
  highest-emotion flow has no layered treatment, despite `FullOverlay`'s blur
  capability (currently hobbled by the ease-in curve, see Quick wins). Home
  itself is a large flat logo over flat cards; reachability is a text pill,
  with no ambient/live quality.
  ![connecting overlay](2026-iteration/before-phone/50_connecting_overlay.png)
- **Intro** (`2026-iteration/before-tablet/40_intro_welcome.png`,
  `2026-iteration/before-phone/44_intro_tour_dashboard.png`): sparse — a logo,
  a paragraph, one CTA on a flat background, with large dead areas (especially
  on tablet). Tour slides are icon + paragraphs. For a first-run surface this
  is the cheapest place to establish the glass/depth language and it currently
  establishes nothing.
  ![intro welcome](2026-iteration/before-tablet/40_intro_welcome.png)
- **Settings** (`2026-iteration/before-tablet/20_settings_top.png`): the "On
  Air" inset-grouped rows already landed, but the row icon chips are flat
  accent-tinted squares and the groups sit on the flat scaffold — functional,
  zero depth. The settings hierarchy is a natural candidate for layered
  grouping/translucency.
  ![settings](2026-iteration/before-tablet/20_settings_top.png)
- **Statistics** (`2026-iteration/before-phone/10_statistics_landing.png`,
  `2026-iteration/before-phone/12_statistics_detail.png`): entry cards carry
  disabled-textfield-style From/To pills; the detail charts have the gradient
  draw-in (settled, keep) inside otherwise flat containers. Telemetry reads as
  forms, not instruments.
  ![statistics detail](2026-iteration/before-phone/12_statistics_detail.png)
- **Stream chat** (`2026-iteration/before-phone/55_dashboard_widgets_chat.png`,
  `2026-iteration/before-tablet/53_dashboard_scene_items.png`): chat chrome is
  the hardcoded-color epicenter (see Systemic issues) and renders as flat pills
  over flat cards; empty states are icon + caption. The engine switch /
  Pro-lock affordances are functional but visually plain.
- **Custom theme editor** (`2026-iteration/before-phone/25_theme_editor.png`):
  a form page — text fields, a dropdown, off-palette pill buttons — with no
  preview surface; the user forges a glass-adjacent theme in a UI that has none
  of it.

## Tablet-specific findings

- **Side-by-side composition works and is verified**:
  `before-tablet/52_dashboard_main.png` shows Scene Items + Audio in two
  columns; `before-tablet/53_dashboard_scene_items.png` shows Chat + Stats in
  two columns. The 640/700 responsive contract holds — protect it in the
  redesign.
- **Shots 53–56 are scroll variants, not tab captures.** The tablet dashboard
  has no tabbed Scene Items/Audio or Chat/Stats blocks, so the walk's tab taps
  no-op'd and the shots differ by scroll position; the filenames reflect the
  phone walk's intent. Don't diff them as if they were distinct states.
- **Home feels unbalanced at tablet width**
  (`2026-iteration/before-tablet/01_home_top.png`): the hero logo and
  autodiscover card sit in a narrow centered column with large empty margins;
  the saved-connections empty state floats alone. The content-column cap works
  but the screen doesn't compose for the width.
- **Fullscreen preview framing**
  (`2026-iteration/before-tablet/60_dashboard_preview_fullscreen.png`): the
  preview texture renders offset-left on the black canvas rather than
  centered/fit. Possibly a capture-timing artifact — verify on device before
  treating as a defect, but check it during the preview pass either way.
- **Pro gating differs between the sets:** the fresh tablet sim has no Pro, so
  `25_theme_editor_locked_by_pro.png` shows the locked state, while the phone
  set (persisted data) shows the full editor + color picker
  (`25_theme_editor.png`, `26_theme_color_picker.png`). Useful accident — both
  gate states are in the inventory.
- **The tablet set is the color baseline** (see the theme caveat up top): all
  color/contrast judgements in the mockup phase should be made against it.
